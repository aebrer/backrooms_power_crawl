class_name BaseballBat extends Item
"""Baseball Bat - Heavy hitting damage multiplier.

Properties (scale with level N):
- 1.25x damage multiplier per level (multiplicative)
- Changes attack name to "Swing Bat"

Example Scaling:
- Level 1: 1.25x damage multiplier
- Level 2: 1.5625x damage (1.25 * 1.25)
- Level 3: 1.953x damage (1.25^3)

Design Intent:
- Pure damage amplifier for BODY pool
- Multiplicative scaling rewards stacking
- Changes the flavor of the attack
"""

# ============================================================================
# STATIC CONFIGURATION
# ============================================================================

const ITEM_ID = "baseball_bat"
const ITEM_NAME = "Baseball Bat"
const POOL = Item.PoolType.BODY
const RARITY_TYPE = ItemRarity.Tier.COMMON

# Damage multiplier per level (multiplicative stacking)
const DAMAGE_MULT_PER_LEVEL = 1.25

# Texture path
const TEXTURE_PATH = "res://assets/textures/items/baseball_bat.png"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init():
	"""Initialize Baseball Bat with default properties."""
	item_id = ITEM_ID
	item_name = ITEM_NAME
	pool_type = POOL
	rarity = RARITY_TYPE

	# Visual description (CONSTANT - always shown)
	visual_description = "A well-worn wooden baseball bat. The grip is wrapped in faded athletic tape, and there are dents along the barrel from heavy use."

	# Scaling hint (CONSTANT - always shown)
	scaling_hint = "Damage multiplier increases with level"

	# Load sprite texture (will fail gracefully if missing)
	if ResourceLoader.exists(TEXTURE_PATH):
		ground_sprite = load(TEXTURE_PATH)

# ============================================================================
# ATTACK MODIFIERS
# ============================================================================

func get_attack_modifiers() -> Dictionary:
	"""Return attack modifiers for BODY pool.

	- damage_multiply: 1.25^level (exponential scaling)
	- attack_name: "Swing Bat"
	"""
	# Calculate multiplicative damage bonus: 1.25^level
	var total_mult = pow(DAMAGE_MULT_PER_LEVEL, level)

	return {
		"attack_name": "Swing Bat",
		"attack_emoji": "🏏",
		"damage_multiply": total_mult,
	}

# ============================================================================
# DESCRIPTIONS
# ============================================================================

func get_description(clearance_level: int) -> String:
	"""Get description that ADDITIVELY reveals info based on clearance level."""
	# Start with base description (visual + scaling hint)
	var desc = super.get_description(clearance_level)

	# Clearance 0-1: Just the basics (no additional info)
	if clearance_level < 2:
		return desc

	# Clearance 2+: Add designation and basic behavior
	desc += "\nDesignation: Improvised Bludgeon"
	desc += "\nProperties: Amplifies striking force"

	# Clearance 3+: Add specific mechanics
	if clearance_level >= 3:
		var total_mult = pow(DAMAGE_MULT_PER_LEVEL, level)
		desc += "\n\nMechanics:"
		desc += "\n- Damage multiplier: %.2fx" % total_mult
		desc += "\n- Attack renamed to: Swing Bat"

	# Clearance 4+: Add code revelation
	if clearance_level >= 4:
		desc += "\n\n--- SYSTEM DATA (CLEARANCE OMEGA) ---"
		desc += "\nclass_name: BaseballBat extends Item"
		desc += "\npool: BODY"
		desc += "\n\nget_attack_modifiers():"
		desc += "\n  return {"
		desc += "\n    \"damage_multiply\": pow(1.25, level),"
		desc += "\n    \"attack_name\": \"Swing Bat\","
		desc += "\n  }"

	return desc

# ============================================================================
# UTILITY
# ============================================================================

func _to_string() -> String:
	"""Debug representation."""
	var total_mult = pow(DAMAGE_MULT_PER_LEVEL, level)
	return "BaseballBat(Level %d, %.2fx damage, %s)" % [
		level,
		total_mult,
		"Equipped" if equipped else "Ground"
	]
