extends Node
## Mouse grid input helper - click tiles to move
##
## Handles mouse input for grid-based movement in 3D

var player: Player3D
var grid: Grid3D
var camera: Camera3D

func _ready() -> void:
	# Wait for player to be ready
	await get_tree().process_frame

	player = get_parent() as Player3D
	if player:
		grid = player.grid
		camera = player.get_node_or_null("Camera")

func _unhandled_input(event: InputEvent) -> void:
	if not player or not grid or not camera:
		return

	# Left click to set movement target
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_mouse_click(event.position)

func _handle_mouse_click(screen_pos: Vector2) -> void:
	"""Convert mouse click to grid position"""
	# Raycast from camera
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 1000.0

	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	if result:
		# Convert world position to grid position
		var world_pos = result.position
		var grid_pos = grid.world_to_grid(world_pos)

		# Calculate direction from player to clicked tile
		var direction = grid_pos - player.grid_position

		# Clamp to 1-tile movement (can't jump multiple tiles)
		direction.x = clampi(direction.x, -1, 1)
		direction.y = clampi(direction.y, -1, 1)

		# Only allow 8-way movement (no standing still clicks)
		if direction != Vector2i.ZERO:
			# Set as movement target
			player.movement_target = direction

			# Trigger state machine to handle it
			if player.state_machine:
				var current_state = player.state_machine.current_state
				if current_state and current_state.name == "IdleState":
					# Transition to aiming state
					player.state_machine.change_state("AimingMoveState")

			if InputManager and InputManager.debug_input:
				print("[MouseInput] Clicked grid: %s, direction: %s" % [grid_pos, direction])
