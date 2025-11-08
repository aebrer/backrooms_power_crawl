class_name Player3D
extends CharacterBody3D
## 3D player controller for turn-based movement
##
## Maintains same grid-based logic as 2D version,
## but operates in 3D space with smooth interpolation.

# Movement configuration
const MOVE_DURATION := 0.2  # Smooth movement animation time

# Grid state (SAME AS 2D VERSION)
var grid_position: Vector2i = Vector2i(64, 64)
var movement_target: Vector2i = Vector2i.ZERO
var pending_action = null
var turn_count: int = 0

# 3D-specific state
var target_world_position: Vector3
var is_moving: bool = false

# Node references
var grid: Grid3D = null
@onready var model: Node3D = $Model
@onready var state_machine = $InputStateMachine

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Grid reference will be set by Game node
	await get_tree().process_frame

	if grid:
		# Start at debug position
		grid_position = Vector2i(69, 1)

		# Set position immediately (no falling animation on start)
		var start_pos = grid.grid_to_world(grid_position)
		start_pos.y = 1.0  # Slightly above ground (adjusted for new cell size)
		global_position = start_pos
		target_world_position = start_pos

		print("[Player3D] Ready at position: ", grid_position)

func _unhandled_input(event: InputEvent) -> void:
	# Delegate to state machine
	if state_machine:
		state_machine.handle_input(event)

func _process(delta: float) -> void:
	# Delegate to state machine
	if state_machine:
		state_machine.process_frame(delta)

	# Smooth movement animation
	if is_moving:
		global_position = global_position.move_toward(
			target_world_position,
			10.0 * delta  # Movement speed
		)

		if global_position.distance_to(target_world_position) < 0.01:
			global_position = target_world_position
			is_moving = false

# ============================================================================
# MOVEMENT (SAME API AS 2D VERSION)
# ============================================================================

func update_visual_position() -> void:
	"""Update 3D position to match grid position"""
	if not grid:
		return

	target_world_position = grid.grid_to_world(grid_position)
	target_world_position.y = 1.0  # Slightly above ground (adjusted for new cell size)

	# Start smooth movement
	if global_position.distance_to(target_world_position) > 0.1:
		is_moving = true
	else:
		global_position = target_world_position

# ============================================================================
# MOVEMENT INDICATOR (Adapted for 3D)
# ============================================================================

func update_move_indicator() -> void:
	"""Show movement preview (TODO: 3D indicator)"""
	# For now, just show it
	# TODO: Create 3D arrow or highlight target tile
	pass

func hide_move_indicator() -> void:
	"""Hide movement preview"""
	pass
