extends Node
"""Manages game pause and HUD interaction mode.

Handles:
- ESC/START to pause game viewport
- Mouse/controller navigation of HUD when paused
- Input mode switching (gameplay vs HUD interaction)

Usage:
	PauseManager.toggle_pause()
	PauseManager.is_paused  # Query current state

Signals:
	pause_toggled(is_paused: bool) - When pause state changes
	hud_focus_changed(focused_element: Control) - When HUD focus changes
"""

signal pause_toggled(is_paused: bool)
signal hud_focus_changed(focused_element: Control)

var is_paused: bool = false
var current_focus: Control = null
var focusable_elements: Array[Control] = []

func _ready():
	# Don't pause the entire tree - just the 3D viewport
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	# ESC (keyboard) or START (controller) toggles pause
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause():
	"""Toggle pause state."""
	is_paused = not is_paused
	emit_signal("pause_toggled", is_paused)

	if is_paused:
		_enter_hud_mode()
	else:
		_exit_hud_mode()

func _enter_hud_mode():
	"""Pause gameplay viewport, enable HUD interaction."""
	# Pause the 3D viewport (not the entire tree)
	var game_3d = get_tree().get_first_node_in_group("game_3d_viewport")
	if game_3d:
		game_3d.process_mode = Node.PROCESS_MODE_DISABLED

	# Show mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Register focusable HUD elements
	_refresh_focusable_elements()

	# Focus first element
	if focusable_elements.size() > 0:
		set_hud_focus(focusable_elements[0])

	Log.system("Entered HUD interaction mode (paused)")

func _exit_hud_mode():
	"""Resume gameplay viewport, disable HUD interaction."""
	# Resume the 3D viewport
	var game_3d = get_tree().get_first_node_in_group("game_3d_viewport")
	if game_3d:
		game_3d.process_mode = Node.PROCESS_MODE_INHERIT

	# Capture mouse for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Clear focus
	if current_focus:
		current_focus.release_focus()
	current_focus = null

	Log.system("Resumed gameplay (unpaused)")

func _refresh_focusable_elements():
	"""Find all HUD elements that can be focused."""
	focusable_elements.clear()

	# Find all nodes in "hud_focusable" group
	for node in get_tree().get_nodes_in_group("hud_focusable"):
		if node is Control and node.visible:
			focusable_elements.append(node)

	# Sort by position (top to bottom, left to right)
	focusable_elements.sort_custom(_sort_by_position)

func _sort_by_position(a: Control, b: Control) -> bool:
	"""Sort controls by visual position."""
	var pos_a = a.global_position
	var pos_b = b.global_position

	# Top to bottom first
	if abs(pos_a.y - pos_b.y) > 10:
		return pos_a.y < pos_b.y

	# Then left to right
	return pos_a.x < pos_b.x

func set_hud_focus(element: Control):
	"""Focus a HUD element."""
	if current_focus:
		current_focus.release_focus()

	current_focus = element
	element.grab_focus()
	emit_signal("hud_focus_changed", element)

func navigate_hud(direction: Vector2i):
	"""Navigate HUD with controller (up/down/left/right)."""
	if not is_paused or focusable_elements.is_empty():
		return

	var current_index = focusable_elements.find(current_focus)
	if current_index == -1:
		current_index = 0

	# Simple vertical navigation for now
	if direction.y != 0:
		current_index += direction.y
		current_index = clamp(current_index, 0, focusable_elements.size() - 1)
		set_hud_focus(focusable_elements[current_index])

func _process(_delta):
	if not is_paused:
		return

	# Handle controller navigation
	var stick_direction = InputManager.get_aim_direction_grid()
	if stick_direction != Vector2i.ZERO:
		navigate_hud(stick_direction)
