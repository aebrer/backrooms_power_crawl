class_name TouchControls
extends Control
## Touch control overlay for mobile/portrait mode
##
## Features:
## - Left side: Touchpad for camera rotation (drag like mouse/controller stick)
## - Right side: Action buttons (Confirm Move, Look Mode)
## - Only visible in portrait mode
## - Camera rotation: continuous drag (no snapping)
## - Confirm/Look buttons: via InputManager

## Touch areas
@onready var touchpad: Control = $HBoxContainer/Touchpad
@onready var button_container: VBoxContainer = $HBoxContainer/ButtonContainer
@onready var confirm_button: Button = $HBoxContainer/ButtonContainer/ConfirmButton
@onready var look_button: Button = $HBoxContainer/ButtonContainer/LookButton

## Touchpad state
var touchpad_touch_index: int = -1
var touchpad_last_pos: Vector2 = Vector2.ZERO  # Track last position for delta calculation

## Player reference (for camera control)
var player: Node3D = null
var tactical_camera: Node = null

func _ready() -> void:
	# Connect button signals (use button_down/button_up for hold tracking)
	confirm_button.button_down.connect(_on_confirm_button_down)
	confirm_button.button_up.connect(_on_confirm_button_up)
	look_button.button_down.connect(_on_look_button_down)
	look_button.button_up.connect(_on_look_button_up)

	# Add visual border to touchpad for clarity
	var touchpad_style = StyleBoxFlat.new()
	touchpad_style.bg_color = Color(0, 0, 0, 0)  # Transparent background
	touchpad_style.border_color = Color(1, 1, 1, 0.3)  # Semi-transparent white border
	touchpad_style.set_border_width_all(2)
	touchpad.add_theme_stylebox_override("panel", touchpad_style)

	Log.system("TouchControls ready (camera reference will be set by game.gd)")

func set_camera_reference(camera: Node) -> void:
	"""Set the tactical camera reference (called by game.gd)"""
	tactical_camera = camera
	if tactical_camera:
		Log.system("TouchControls: Camera reference set successfully")
	else:
		Log.warn(Log.Category.SYSTEM, "TouchControls: Camera reference is null")

	# Debug: Log initial sizes and mouse_filter settings
	await get_tree().process_frame  # Wait for layout
	_debug_log_layout()

func _input(event: InputEvent) -> void:
	"""Handle touch input globally (allows mouse to pass through to viewport)"""
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		# Debug: Log ALL touch events
		Log.system("[TouchControls] Touch event received: %s at position %v" % [
			"ScreenTouch" if event is InputEventScreenTouch else "ScreenDrag",
			event.position
		])

		# Get touchpad bounds for debugging
		if touchpad:
			var touchpad_rect = touchpad.get_global_rect()
			Log.system("[TouchControls] Touchpad bounds: pos=%v, size=%v" % [
				touchpad_rect.position, touchpad_rect.size
			])

		# Check if touch is within touchpad bounds
		var in_touchpad = _is_touch_in_touchpad(event.position)
		Log.system("[TouchControls] Touch in touchpad? %s" % in_touchpad)

		if in_touchpad:
			_on_touchpad_input(event)

func _on_touchpad_input(event: InputEvent) -> void:
	"""Handle touch input on touchpad - works like mouse drag for camera rotation"""
	if event is InputEventScreenTouch:
		if event.pressed:
			# Touch started - record initial position
			touchpad_touch_index = event.index
			touchpad_last_pos = event.position
			Log.system("[TouchControls] Touchpad touch STARTED - index=%d, pos=%v" % [event.index, touchpad_last_pos])
		else:
			# Touch ended - stop tracking
			Log.system("[TouchControls] Touchpad touch ENDED - index=%d" % event.index)
			if touchpad_touch_index == event.index:
				touchpad_touch_index = -1

	elif event is InputEventScreenDrag:
		if touchpad_touch_index == event.index:
			# Calculate drag delta (like mouse motion)
			var drag_delta: Vector2 = event.position - touchpad_last_pos
			touchpad_last_pos = event.position

			Log.system("[TouchControls] Touchpad DRAG - delta=%v" % [drag_delta])

			# Apply delta to camera rotation (like mouse movement)
			_rotate_camera(drag_delta)

func _rotate_camera(drag_delta: Vector2) -> void:
	"""Rotate camera based on touch drag (like mouse movement)"""
	if not tactical_camera:
		Log.warn(Log.Category.SYSTEM, "TouchControls: Cannot rotate camera - tactical_camera not available")
		return

	# Touch sensitivity (similar to mouse sensitivity in tactical_camera)
	const TOUCH_SENSITIVITY: float = 0.3

	# Access camera pivots directly (same as mouse rotation in tactical_camera)
	var h_pivot = tactical_camera.get_node_or_null("HorizontalPivot")
	var v_pivot = tactical_camera.get_node_or_null("HorizontalPivot/VerticalPivot")

	if not h_pivot or not v_pivot:
		Log.warn(Log.Category.SYSTEM, "TouchControls: Camera pivots not found")
		return

	# Horizontal rotation (yaw) - drag X axis
	h_pivot.rotation_degrees.y -= drag_delta.x * TOUCH_SENSITIVITY
	h_pivot.rotation_degrees.y = fmod(h_pivot.rotation_degrees.y, 360.0)

	# Vertical rotation (pitch) - drag Y axis
	v_pivot.rotation_degrees.x -= drag_delta.y * TOUCH_SENSITIVITY
	v_pivot.rotation_degrees.x = clamp(v_pivot.rotation_degrees.x, tactical_camera.pitch_min, tactical_camera.pitch_max)

	Log.camera("Touch camera rotation - yaw: %.1f°, pitch: %.1f°" % [
		h_pivot.rotation_degrees.y, v_pivot.rotation_degrees.x
	])

func _on_confirm_button_down() -> void:
	"""Handle confirm button down (RT pressed)"""
	Log.system("[TouchControls] Confirm button DOWN - calling InputManager")
	InputManager.set_confirm_button_pressed(true)

func _on_confirm_button_up() -> void:
	"""Handle confirm button up (RT released)"""
	Log.system("[TouchControls] Confirm button UP - calling InputManager")
	InputManager.set_confirm_button_pressed(false)

func _on_look_button_down() -> void:
	"""Handle look button down (LT pressed)"""
	Log.system("[TouchControls] Look button DOWN - calling InputManager")
	InputManager.set_look_button_pressed(true)

func _on_look_button_up() -> void:
	"""Handle look button up (LT released)"""
	Log.system("[TouchControls] Look button UP - calling InputManager")
	InputManager.set_look_button_pressed(false)

func _is_touch_in_touchpad(touch_pos: Vector2) -> bool:
	"""Check if touch position is within touchpad area"""
	if not touchpad:
		return false

	# Get touchpad global rect
	var touchpad_rect = touchpad.get_global_rect()
	return touchpad_rect.has_point(touch_pos)

func _debug_log_layout() -> void:
	"""Debug logging for touch controls layout and settings"""
	Log.system("=== TouchControls Layout Debug ===")

	# Root control
	var root_rect = get_global_rect()
	Log.system("Root (TouchControls): size=%v, pos=%v, mouse_filter=%d" % [
		root_rect.size, root_rect.position, mouse_filter
	])

	# HBoxContainer
	var hbox = $HBoxContainer
	var hbox_rect = hbox.get_global_rect()
	Log.system("HBoxContainer: size=%v, pos=%v, mouse_filter=%d" % [
		hbox_rect.size, hbox_rect.position, hbox.mouse_filter
	])

	# Touchpad
	if touchpad:
		var touchpad_rect = touchpad.get_global_rect()
		Log.system("Touchpad: size=%v, pos=%v, mouse_filter=%d, visible=%s" % [
			touchpad_rect.size, touchpad_rect.position, touchpad.mouse_filter, touchpad.visible
		])

	# ButtonContainer
	if button_container:
		var btn_container_rect = button_container.get_global_rect()
		Log.system("ButtonContainer: size=%v, pos=%v, mouse_filter=%d" % [
			btn_container_rect.size, btn_container_rect.position, button_container.mouse_filter
		])

	# Confirm button
	if confirm_button:
		var confirm_rect = confirm_button.get_global_rect()
		Log.system("ConfirmButton: size=%v, pos=%v, visible=%s, min_size=%v" % [
			confirm_rect.size, confirm_rect.position, confirm_button.visible,
			confirm_button.custom_minimum_size
		])

	# Look button
	if look_button:
		var look_rect = look_button.get_global_rect()
		Log.system("LookButton: size=%v, pos=%v, visible=%s, min_size=%v" % [
			look_rect.size, look_rect.position, look_button.visible,
			look_button.custom_minimum_size
		])

	Log.system("=== End TouchControls Debug ===")
