class_name StatModifier extends RefCounted
"""Represents a single modification to a stat.

Used for equipment bonuses, temporary buffs, debuffs, mutations, etc.
Enables source tracking for tooltips and stat breakdowns.

Example:
	var armor_bonus = StatModifier.new("hp", 20, StatModifier.ModifierType.ADD, "Leather Armor")
	var rage_buff = StatModifier.new("strength", 1.5, StatModifier.ModifierType.MULTIPLY, "Rage Potion", 5)
"""

enum ModifierType {
	ADD,        # Add to base value (before percentage scaling)
	MULTIPLY    # Multiply final value (after percentage scaling)
}

var stat_name: String              # "hp", "strength", "body", etc.
var value: float                   # Amount to add/multiply
var type: ModifierType             # ADD or MULTIPLY
var source: String                 # "Leather Armor", "Rage Potion", etc.
var duration: int = -1             # Turns remaining (-1 = permanent)
var unique_id: String              # For removal (auto-generated)

func _init(
	p_stat_name: String,
	p_value: float,
	p_type: ModifierType,
	p_source: String,
	p_duration: int = -1):
	stat_name = p_stat_name
	value = p_value
	type = p_type
	source = p_source
	duration = p_duration
	unique_id = "%s_%s_%d" % [source, stat_name, Time.get_ticks_msec()]

func tick_duration() -> bool:
	"""Decrease duration by 1 turn. Returns true if expired."""
	if duration < 0:
		return false  # Permanent modifier

	duration -= 1
	return duration <= 0

func _to_string() -> String:
	"""Human-readable representation for debugging/tooltips."""
	var type_str = "+" if type == ModifierType.ADD else "×"
	var duration_str = "" if duration < 0 else " (%d turns)" % duration
	return "%s%s %s from %s%s" % [type_str, value, stat_name, source, duration_str]
