class_name Binoculars extends Item
"""Binoculars - Dramatic PERCEPTION boost.

Properties (scale with level N):
- +5 PERCEPTION per level (dramatic boost)
- Standard MIND stat bonus (+N MIND)

Example Scaling:
- Level 1: +5 PERCEPTION, +1 MIND
- Level 2: +10 PERCEPTION, +2 MIND
- Level 3: +15 PERCEPTION, +3 MIND

Design Intent:
- Dramatically increases vision/detection capabilities
- PERCEPTION affects enemy detection range and examination detail
- Moderate scaling (not exponential like damage multipliers)
"""

# ============================================================================
# STATIC CONFIGURATION
# ============================================================================

const ITEM_ID = "binoculars"
const ITEM_NAME = "Binoculars"
const POOL = Item.PoolType.MIND
const RARITY_TYPE = ItemRarity.Tier.UNCOMMON

# PERCEPTION bonus per level (dramatic boost)
const PERCEPTION_PER_LEVEL = 5.0

# Texture path
const TEXTURE_PATH = "res://assets/textures/items/binoculars.png"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init():
	"""Initialize Binoculars with default properties."""
	item_id = ITEM_ID
	item_name = ITEM_NAME
	pool_type = POOL
	rarity = RARITY_TYPE

	# Visual description (CONSTANT - always shown)
	visual_description = "A pair of heavy rubber-coated binoculars. The lenses are scratched but functional. Military surplus, judging by the olive drab coloring."

	# Scaling hint (CONSTANT - always shown)
	scaling_hint = "PERCEPTION bonus increases with level"

	# Load sprite texture (will fail gracefully if missing)
	if ResourceLoader.exists(TEXTURE_PATH):
		ground_sprite = load(TEXTURE_PATH)

# ============================================================================
# EQUIP/UNEQUIP (Override for PERCEPTION modifier)
# ============================================================================

func on_equip(player: Player3D) -> void:
	"""Apply PERCEPTION bonus when equipped."""
	super.on_equip(player)  # Apply base stat bonus (+N MIND)

	# Add PERCEPTION bonus directly
	var perception_bonus = PERCEPTION_PER_LEVEL * level
	player.stats.bonus_perception += perception_bonus

	Log.player("BINOCULARS equipped: +%.0f PERCEPTION" % perception_bonus)

func on_unequip(player: Player3D) -> void:
	"""Remove PERCEPTION bonus when unequipped."""
	super.on_unequip(player)  # Remove base stat bonus

	# Remove PERCEPTION bonus
	var perception_bonus = PERCEPTION_PER_LEVEL * level
	player.stats.bonus_perception -= perception_bonus

	Log.player("BINOCULARS unequipped")

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
	desc += "\nDesignation: Optical Enhancement Device"
	desc += "\nProperties: Dramatically enhances visual acuity"

	# Clearance 3+: Add specific mechanics
	if clearance_level >= 3:
		var total_perception = PERCEPTION_PER_LEVEL * level
		desc += "\n\nMechanics:"
		desc += "\n- PERCEPTION bonus: +%.0f" % total_perception
		desc += "\n- Also grants +%d MIND" % level
		desc += "\n- Improves detection and examination"

	# Clearance 4+: Add code revelation
	if clearance_level >= 4:
		desc += "\n\n--- SYSTEM DATA (CLEARANCE OMEGA) ---"
		desc += "\nclass_name: Binoculars extends Item"
		desc += "\npool: MIND"
		desc += "\n\non_equip():"
		desc += "\n  stats.bonus_perception += %.1f * level" % PERCEPTION_PER_LEVEL

	return desc

# ============================================================================
# UTILITY
# ============================================================================

func _to_string() -> String:
	"""Debug representation."""
	var total_perception = PERCEPTION_PER_LEVEL * level
	return "Binoculars(Level %d, +%.0f PERCEPTION, %s)" % [
		level,
		total_perception,
		"Equipped" if equipped else "Ground"
	]
