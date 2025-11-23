class_name ControlHintAction
extends Action
## Informational action for displaying control hints in action preview UI
##
## This is not an executable action - it's only used for UI display purposes.
## Shows available controls in pause mode or during special states like item reordering.

var hint_icon: String
var hint_name: String
var hint_target: String

func _init(icon: String, name: String, target: String = "") -> void:
	action_name = "ControlHint"
	hint_icon = icon
	hint_name = name
	hint_target = target

func can_execute(_player) -> bool:
	return false  # Never executable - display only

func execute(_player) -> void:
	pass  # No-op - this is display-only

func get_preview_info(_player) -> Dictionary:
	return {
		"name": hint_name,
		"target": hint_target,
		"icon": hint_icon,
		"cost": ""
	}
