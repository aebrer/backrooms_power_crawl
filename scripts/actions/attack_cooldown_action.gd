class_name AttackCooldownAction
extends Action
## Informational action for displaying attack cooldowns in action preview UI
##
## Shows attacks that are on cooldown and will tick down next turn.
## Displayed at bottom of preview in understated style.

var attack_name: String
var cooldown_current: int  # Current cooldown
var cooldown_after: int    # Cooldown after tick (what it will be next turn)

func _init(name: String, current: int, after: int) -> void:
	action_name = "AttackCooldown"
	attack_name = name
	cooldown_current = current
	cooldown_after = after

func can_execute(_player) -> bool:
	return false  # Never executable - display only

func execute(_player) -> void:
	pass  # No-op - this is display-only

func get_preview_info(_player) -> Dictionary:
	return {
		"name": attack_name,
		"target": "%d → %d" % [cooldown_current, cooldown_after],
		"icon": "🕐",
		"cost": ""
	}
