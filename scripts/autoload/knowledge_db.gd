extends Node
## KnowledgeDB - Singleton for tracking player knowledge and discoveries
##
## This autoload handles:
## - Discovery level tracking for entities (0-3 scale)
## - Novelty tracking per Clearance level (for EXP rewards)
## - Clearance level tracking (now managed by Player's StatBlock)
## - Researcher classification (total research score)
## - Entity information retrieval with progressive revelation
##
## Usage:
##   KnowledgeDB.examine_entity("skin_stealer")
##   KnowledgeDB.examine_item("flashlight", "common")
##   KnowledgeDB.examine_environment("wall")
##   var info = KnowledgeDB.get_entity_info("skin_stealer")
##
## Signals:
##   discovery_made(subject_type, subject_id, exp_reward) - Emitted on first examination at current Clearance

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when player discovers something novel (first time at current Clearance)
## subject_type: "entity", "item", or "environment"
## subject_id: Unique identifier (e.g., "skin_stealer", "flashlight_common", "wall_yellow")
## exp_reward: EXP awarded for this discovery
signal discovery_made(subject_type: String, subject_id: String, exp_reward: int)

# ============================================================================
# PLAYER KNOWLEDGE STATE
# ============================================================================

## Entity discovery levels: {entity_id: discovery_level}
## Discovery 0 = Unknown (never seen)
## Discovery 1 = Detected (first examination)
## Discovery 2 = Identified (multiple examinations or combat)
## Discovery 3 = Fully Known (complete understanding)
var discovered_entities: Dictionary = {}

## Player clearance level (0-5)
## 0 = No clearance
## 1-4 = Progressive access
## 5 = Maximum clearance (Omega)
var clearance_level: int = 0

## Total research score (meta-progression tracking)
## Increases with each discovery, examination, and objective completion
var researcher_classification: int = 0

## Novelty tracking: {subject_key: [clearance_levels_examined_at]}
## Example: {"entity:skin_stealer": [0, 1], "item:flashlight": [0], "environment:wall": [0, 1, 2]}
## When Clearance increases, items not in the list become "novel" again
var examined_at_clearance: Dictionary = {}

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	Log.system("KnowledgeDB initialized - Clearance: %d" % clearance_level)

# ============================================================================
# EXAMINATION API
# ============================================================================

func examine_entity(entity_id: String) -> void:
	"""Called when player examines an entity - increases discovery level and awards EXP if novel"""
	if entity_id.is_empty():
		push_warning("[KnowledgeDB] Cannot examine entity with empty ID")
		return

	var current_level = discovered_entities.get(entity_id, 0)

	# Max discovery level is 3
	if current_level < 3:
		discovered_entities[entity_id] = current_level + 1
		researcher_classification += 1
		Log.system("Entity examined: %s (discovery level: %d -> %d)" % [
			entity_id,
			current_level,
			current_level + 1
		])
	else:
		Log.trace(Log.Category.SYSTEM, "Entity already fully known: %s (level 3)" % entity_id)

	# Check for EXP reward (first time at current Clearance)
	var key = "entity:%s" % entity_id
	if _is_novel(key):
		_mark_examined(key)
		var exp = _get_entity_exp()
		emit_signal("discovery_made", "entity", entity_id, exp)
		Log.system("Novel entity discovery! +%d EXP (Clearance %d)" % [exp, clearance_level])

func get_discovery_level(entity_id: String) -> int:
	"""Get current discovery level for entity (0-3)"""
	return discovered_entities.get(entity_id, 0)

func get_entity_info(entity_id: String) -> Dictionary:
	"""Get display information for entity based on discovery and clearance"""
	var discovery = get_discovery_level(entity_id)

	# Query EntityRegistry for entity info
	return EntityRegistry.get_info(entity_id, discovery, clearance_level)

func examine_item(item_id: String, item_rarity: String = "common") -> void:
	"""Called when player examines an item - awards EXP if novel"""
	if item_id.is_empty():
		push_warning("[KnowledgeDB] Cannot examine item with empty ID")
		return

	var key = "item:%s" % item_id

	if _is_novel(key):
		_mark_examined(key)
		var exp = _get_item_exp(item_rarity)
		emit_signal("discovery_made", "item", item_id, exp)
		Log.system("Novel item discovery! %s (%s) +%d EXP (Clearance %d)" % [item_id, item_rarity, exp, clearance_level])
	else:
		Log.trace(Log.Category.SYSTEM, "Item already examined at Clearance %d: %s" % [clearance_level, item_id])

func examine_environment(env_type: String) -> void:
	"""Called when player examines environment (wall, floor, ceiling) - awards EXP if novel"""
	if env_type.is_empty():
		push_warning("[KnowledgeDB] Cannot examine environment with empty type")
		return

	var key = "environment:%s" % env_type

	if _is_novel(key):
		_mark_examined(key)
		var exp = 10  # Fixed 10 EXP for environment examination
		emit_signal("discovery_made", "environment", env_type, exp)
		Log.system("Novel environment discovery! %s +%d EXP (Clearance %d)" % [env_type, exp, clearance_level])
	else:
		Log.trace(Log.Category.SYSTEM, "Environment already examined at Clearance %d: %s" % [clearance_level, env_type])

# ============================================================================
# CLEARANCE MANAGEMENT
# ============================================================================

func set_clearance_level(level: int) -> void:
	"""Set player clearance level (0-5)"""
	clearance_level = clampi(level, 0, 5)
	Log.system("Clearance level set to: %d" % clearance_level)

func increase_clearance() -> void:
	"""Increase clearance level by 1 (max 5)"""
	if clearance_level < 5:
		clearance_level += 1
		Log.system("Clearance increased to: %d" % clearance_level)

# ============================================================================
# NOVELTY TRACKING (PRIVATE)
# ============================================================================

func _is_novel(key: String) -> bool:
	"""Check if subject is novel at current Clearance level"""
	if not examined_at_clearance.has(key):
		return true  # Never examined before

	var clearances: Array = examined_at_clearance[key]
	return not (clearance_level in clearances)

func _mark_examined(key: String) -> void:
	"""Mark subject as examined at current Clearance level"""
	if not examined_at_clearance.has(key):
		examined_at_clearance[key] = []

	var clearances: Array = examined_at_clearance[key]
	if not (clearance_level in clearances):
		clearances.append(clearance_level)

func _get_item_exp(rarity: String) -> int:
	"""Get EXP reward for item based on rarity"""
	match rarity.to_lower():
		"common": return 50
		"uncommon": return 150
		"rare": return 500
		"legendary": return 1500
	return 50  # Default to common if unknown rarity

func _get_entity_exp() -> int:
	"""Get EXP reward for examining an entity"""
	return 1000

# ============================================================================
# DEBUG / DEVELOPMENT
# ============================================================================

func reset_knowledge() -> void:
	"""Reset all knowledge (for debugging)"""
	discovered_entities.clear()
	clearance_level = 0
	researcher_classification = 0
	Log.system("Knowledge database reset")

func get_stats() -> Dictionary:
	"""Get knowledge statistics for debugging"""
	return {
		"discovered_entities": discovered_entities.size(),
		"clearance_level": clearance_level,
		"researcher_classification": researcher_classification,
		"entities": discovered_entities.keys()
	}

func print_stats() -> void:
	"""Print knowledge stats to console"""
	var stats = get_stats()
	print("\n=== KnowledgeDB Stats ===")
	print("Discovered entities: %d" % stats.discovered_entities)
	print("Clearance level: %d" % stats.clearance_level)
	print("Research score: %d" % stats.researcher_classification)
	print("Entities: %s" % str(stats.entities))
	print("========================\n")
