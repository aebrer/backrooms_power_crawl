extends Control
## Main Menu
## Temporary placeholder during initial development

@onready var status_label: Label = $CenterContainer/VBoxContainer/Status

func _ready() -> void:
	print("Backrooms Power Crawl - Main Menu loaded")
	print("Project initialized successfully!")
	print("Waiting for input... (Controller START or keyboard SPACE)")

	# List connected joypads for debugging
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		print("Connected controllers: ", joypads)
		for joypad in joypads:
			print("  - ", Input.get_joy_name(joypad))
	else:
		print("WARNING: No controllers detected!")

func _input(event: InputEvent) -> void:
	# Debug: Print ALL input events to help debug controller
	if event is InputEventJoypadButton:
		print("Joypad button pressed: ", event.button_index, " (", event.as_text(), ")")

	# Check for START button (pause action)
	if Input.is_action_just_pressed("pause"):
		_on_start_pressed()

	# Keyboard fallback for testing
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_start_pressed()

func _on_start_pressed() -> void:
	print("========================================")
	print("START PRESSED - No game scene yet!")
	print("========================================")
	status_label.text = "Button detected! No game scene to load yet."
	status_label.modulate = Color.GREEN
	# TODO: Load game scene when ready
	# get_tree().change_scene_to_file("res://scenes/game.tscn")
