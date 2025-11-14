class_name ExaminationCrosshair
extends Control
## Simple crosshair for look mode - stays in viewport (can have effects applied)

# Node references
var vertical_line: ColorRect
var horizontal_line: ColorRect

func _ready() -> void:
	# Fill viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_crosshair()

	# Hidden by default
	visible = false

func _build_crosshair() -> void:
	"""Build simple crosshair at center of viewport"""
	# Vertical line
	vertical_line = ColorRect.new()
	vertical_line.name = "VerticalLine"
	vertical_line.size = Vector2(2, 20)
	vertical_line.color = Color.WHITE
	vertical_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vertical_line.set_anchors_preset(Control.PRESET_CENTER)
	vertical_line.position = Vector2(-1, -10)
	add_child(vertical_line)

	# Horizontal line
	horizontal_line = ColorRect.new()
	horizontal_line.name = "HorizontalLine"
	horizontal_line.size = Vector2(20, 2)
	horizontal_line.color = Color.WHITE
	horizontal_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_line.set_anchors_preset(Control.PRESET_CENTER)
	horizontal_line.position = Vector2(-10, -1)
	add_child(horizontal_line)

func show_crosshair() -> void:
	"""Show the crosshair"""
	visible = true
	modulate = Color.WHITE

func hide_crosshair() -> void:
	"""Hide the crosshair"""
	visible = false

func set_crosshair_color(color: Color) -> void:
	"""Change crosshair color"""
	modulate = color
