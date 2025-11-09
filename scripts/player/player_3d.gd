class_name Player3D
extends CharacterBody3D
## 3D player controller for turn-based movement
##
## TURN-BASED: Player SNAPs to grid positions instantly.
## Each action advances the entire game state by one discrete turn.
## No smooth interpolation - this is Caves of Qud style!

# Grid state (SAME AS 2D VERSION)
var grid_position: Vector2i = Vector2i(64, 64)
var movement_target: Vector2i = Vector2i.ZERO
var pending_action = null
var turn_count: int = 0

# Node references
var grid: Grid3D = null
var move_indicator: Node3D = null  # Set by Game node
@onready var model: Node3D = $Model
@onready var state_machine = $InputStateMachine
@onready var camera_rig: TacticalCamera = $CameraRig

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Grid reference will be set by Game node
	await get_tree().process_frame

	if grid:
		# Start at debug position
		grid_position = Vector2i(69, 1)

		# SNAP to grid position (turn-based = no smooth movement)
		update_visual_position()

		print("[Player3D] Ready at position: ", grid_position)

func _unhandled_input(event: InputEvent) -> void:
	# Delegate to state machine
	if state_machine:
		state_machine.handle_input(event)

func _process(delta: float) -> void:
	# Delegate to state machine
	if state_machine:
		state_machine.process_frame(delta)

# ============================================================================
# MOVEMENT (SAME API AS 2D VERSION)
# ============================================================================

func update_visual_position() -> void:
	"""Update 3D position to match grid position - SNAP instantly (turn-based!)"""
	if not grid:
		return

	var world_pos = grid.grid_to_world(grid_position)
	world_pos.y = 1.0  # Slightly above ground (adjusted for new cell size)

	# TURN-BASED: Snap instantly to grid position, no lerping
	global_position = world_pos

# ============================================================================
# CAMERA-RELATIVE MOVEMENT
# ============================================================================

func get_camera_relative_direction(input_dir: Vector2i) -> Vector2i:
	"""Transform input direction to be camera-relative"""
	if not camera_rig or input_dir == Vector2i.ZERO:
		return input_dir

	# Get camera yaw (horizontal rotation only, ignore pitch)
	var camera_yaw_deg = camera_rig.h_pivot.rotation_degrees.y

	# Convert to radians - NEGATIVE rotation (inverse of camera)
	# Use EXACT camera angle, don't snap (input already snaps to 8-way)
	var yaw_rad = -deg_to_rad(camera_yaw_deg)

	# Convert input Vector2i to Vector2 for rotation math
	var input_vec = Vector2(input_dir.x, input_dir.y)

	# Rotate input by camera yaw
	var rotated = input_vec.rotated(yaw_rad)

	# Round and snap to nearest 8-way direction
	var length = rotated.length()
	if length < 0.1:
		return Vector2i.ZERO

	# Normalize and re-snap to 8-way grid
	var angle = rotated.angle()
	var octant = int(round(angle / (PI / 4.0))) % 8

	var directions := [
		Vector2i(1, 0),   # 0: Right
		Vector2i(1, 1),   # 1: Down-Right
		Vector2i(0, 1),   # 2: Down
		Vector2i(-1, 1),  # 3: Down-Left
		Vector2i(-1, 0),  # 4: Left
		Vector2i(-1, -1), # 5: Up-Left
		Vector2i(0, -1),  # 6: Up
		Vector2i(1, -1)   # 7: Up-Right
	]

	var result = directions[octant]

	# Debug
	if result != Vector2i.ZERO:
		print("[Player3D] Camera-relative: %s → %s (yaw=%.0f° octant=%d)" % [input_dir, result, camera_yaw_deg, octant])

	return result

# ============================================================================
# MOVEMENT INDICATOR (3D)
# ============================================================================

func update_move_indicator() -> void:
	"""Show movement preview at target position"""
	if not grid or not move_indicator:
		return

	# Calculate target position with camera-relative direction
	var camera_relative_target = get_camera_relative_direction(movement_target)
	var target_pos = grid_position + camera_relative_target

	# Check if target is valid
	if grid.is_walkable(target_pos):
		# Show indicator at target position
		var world_pos = grid.grid_to_world(target_pos)
		world_pos.y = 0.1  # Just above floor to prevent z-fighting
		move_indicator.global_position = world_pos
		move_indicator.visible = true
	else:
		# Target is blocked - hide indicator or show as red
		move_indicator.visible = false

func hide_move_indicator() -> void:
	"""Hide movement preview"""
	if move_indicator:
		move_indicator.visible = false
