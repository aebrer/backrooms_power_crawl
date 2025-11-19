@tool
class_name StatTemplate extends Resource
"""Inspector-editable stat configuration template.

Save as .tres files in assets/stats/ directory for different entity types:
- starting_stats.tres (player default)
- skeleton_stats.tres (enemy template)
- rat_stats.tres (another enemy)

Changes in inspector are immediately visible and saved.
"""

@export_group("Base Stats")
@export var base_body: int = 5
@export var base_mind: int = 5
@export var base_null: int = 0

@export_group("Direct HP Bonuses")
@export var bonus_hp: float = 0.0

@export_group("Direct Sanity Bonuses")
@export var bonus_sanity: float = 0.0

@export_group("Direct Mana Bonuses")
@export var bonus_mana: float = 0.0

@export_group("Direct Combat Stat Bonuses")
@export var bonus_strength: float = 0.0
@export var bonus_perception: float = 0.0
@export var bonus_anomaly: float = 0.0

@export_group("Progression (Player Only)")
@export var starting_exp: int = 0
@export var starting_clearance: int = 0

func _to_string() -> String:
	"""Debug representation."""
	return "StatTemplate(BODY:%d MIND:%d NULL:%d HP+%.1f SAN+%.1f MANA+%.1f)" % [
		base_body, base_mind, base_null,
		bonus_hp, bonus_sanity, bonus_mana
	]
