extends VBoxContainer
"""Stats display panel with interactive elements.

Shows:
- Base stats (BODY, MIND, NULL) with resource pools
- Combat stats (STRENGTH, PERCEPTION, ANOMALY)
- Progression (EXP, Clearance Level)

Updates in real-time as stats change.
"""

var player: Player3D = null

# Base Stats & Resources
@onready var body_label: Label = %BodyLabel
@onready var mind_label: Label = %MindLabel
@onready var null_label: Label = %NullLabel

@onready var hp_label: Label = %HPLabel
@onready var sanity_label: Label = %SanityLabel
@onready var mana_label: Label = %ManaLabel

# Combat Stats
@onready var strength_label: Label = %StrengthLabel
@onready var perception_label: Label = %PerceptionLabel
@onready var anomaly_label: Label = %AnomalyLabel

# Progression
@onready var level_label: Label = %LevelLabel
@onready var exp_label: Label = %EXPLabel
@onready var clearance_label: Label = %ClearanceLabel

func _ready():
	# Wait for player to be set by Game node
	await get_tree().process_frame

	if player and player.stats:
		_connect_signals()
		_update_all_stats()
	else:
		Log.warn(Log.Category.SYSTEM, "StatsPanel: No player or stats found")

func set_player(p: Player3D) -> void:
	"""Called by Game node to set player reference"""
	player = p
	if player and player.stats:
		_connect_signals()
		_update_all_stats()

func _connect_signals() -> void:
	"""Connect to StatBlock signals for real-time updates"""
	if not player or not player.stats:
		return

	# Check if already connected to avoid duplicate connections
	if player.stats.stat_changed.is_connected(_on_stat_changed):
		return  # Already connected

	# Stat changes
	player.stats.stat_changed.connect(_on_stat_changed)

	# Resource changes
	player.stats.resource_changed.connect(_on_resource_changed)

	# Progression
	player.stats.exp_gained.connect(_on_exp_gained)
	player.stats.level_increased.connect(_on_level_increased)
	player.stats.clearance_increased.connect(_on_clearance_increased)

func _update_all_stats() -> void:
	"""Update all stat displays"""
	if not player or not player.stats:
		return

	var s = player.stats

	# Base stats
	if body_label:
		body_label.text = "BODY: %d" % s.body
	if mind_label:
		mind_label.text = "MIND: %d" % s.mind
	if null_label:
		null_label.text = "NULL: %d" % s.null_stat

	# Resources
	if hp_label:
		hp_label.text = "HP: %.0f / %.0f" % [s.current_hp, s.max_hp]
	if sanity_label:
		sanity_label.text = "Sanity: %.0f / %.0f" % [s.current_sanity, s.max_sanity]
	if mana_label:
		if s.null_stat > 0:
			mana_label.text = "Mana: %.0f / %.0f" % [s.current_mana, s.max_mana]
		else:
			mana_label.text = "Mana: [LOCKED]"

	# Combat stats
	if strength_label:
		strength_label.text = "STRENGTH: %.0f" % s.strength
	if perception_label:
		perception_label.text = "PERCEPTION: %.0f" % s.perception
	if anomaly_label:
		anomaly_label.text = "ANOMALY: %.0f" % s.anomaly

	# Progression
	if level_label:
		level_label.text = "Level: %d" % s.level
	if exp_label:
		var next_exp = s.exp_to_next_level()
		exp_label.text = "EXP: %d / %d" % [s.exp, s.exp + next_exp]
	if clearance_label:
		clearance_label.text = "Clearance: %d" % s.clearance_level

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_stat_changed(stat_name: String, _old_value: float, _new_value: float) -> void:
	"""Update display when a stat changes"""
	# Just refresh everything for simplicity
	_update_all_stats()

func _on_resource_changed(resource_name: String, current: float, maximum: float) -> void:
	"""Update resource display"""
	match resource_name:
		"hp":
			if hp_label:
				hp_label.text = "HP: %.0f / %.0f" % [current, maximum]
		"sanity":
			if sanity_label:
				sanity_label.text = "Sanity: %.0f / %.0f" % [current, maximum]
		"mana":
			if mana_label:
				mana_label.text = "Mana: %.0f / %.0f" % [current, maximum]

func _on_exp_gained(_amount: int, new_total: int) -> void:
	"""Update EXP display"""
	if exp_label and player and player.stats:
		var next_exp = player.stats.exp_to_next_level()
		exp_label.text = "EXP: %d / %d" % [new_total, new_total + next_exp]

func _on_level_increased(_old_level: int, new_level: int) -> void:
	"""Update Level display"""
	if level_label:
		level_label.text = "Level: %d" % new_level

	# Refresh EXP display (threshold changed)
	if player and player.stats:
		_on_exp_gained(0, player.stats.exp)

func _on_clearance_increased(_old_level: int, new_level: int) -> void:
	"""Update Clearance display"""
	if clearance_label:
		clearance_label.text = "Clearance: %d" % new_level
