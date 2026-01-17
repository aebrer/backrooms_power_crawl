class_name TrailMix extends Item
"""Trail Mix - Premium HP regeneration item.

Properties (scale with level N):
- +0.5% HP regen per turn per level
- Standard BODY stat bonus (+N BODY)

Example Scaling:
- Level 1: +0.5% HP regen/turn, +1 BODY
- Level 2: +1.0% HP regen/turn, +2 BODY
- Level 3: +1.5% HP regen/turn, +3 BODY

Design Intent:
- Rarest BODY pool item
- Provides sustained survivability through passive healing
- Complements other BODY items (damage from bat, attacks from knuckles)
"""

# ============================================================================
# STATIC CONFIGURATION
# ============================================================================

const ITEM_ID = "trail_mix"
const ITEM_NAME = "Trail Mix"
const POOL = Item.PoolType.BODY
const RARITY_TYPE = ItemRarity.Tier.RARE  # Rarest BODY item

# HP regen bonus per level (0.5% per level)
const HP_REGEN_PER_LEVEL = 0.5

# Texture path
const TEXTURE_PATH = "res://assets/textures/items/trail_mix.png"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init():
	"""Initialize Trail Mix with default properties."""
	item_id = ITEM_ID
	item_name = ITEM_NAME
	pool_type = POOL
	rarity = RARITY_TYPE

	# Visual description (CONSTANT - always shown)
	visual_description = "A glass jar filled with assorted trail mix. Peanuts, raisins, M&Ms, and sunflower seeds are visible through the glass. Someone's emergency snack stash."

	# Scaling hint (CONSTANT - always shown)
	scaling_hint = "HP regeneration increases with level"

	# Load sprite texture (will fail gracefully if missing)
	if ResourceLoader.exists(TEXTURE_PATH):
		ground_sprite = load(TEXTURE_PATH)

# ============================================================================
# EQUIP/UNEQUIP (Override for HP regen modifier)
# ============================================================================

func on_equip(player: Player3D) -> void:
	"""Apply HP regen bonus when equipped."""
	super.on_equip(player)  # Apply base stat bonus (+N BODY)

	# Add HP regen modifier
	var regen_bonus = HP_REGEN_PER_LEVEL * level
	player.stats.hp_regen_percent += regen_bonus

	Log.player("TRAIL_MIX equipped: +%.1f%% HP regen/turn" % regen_bonus)

func on_unequip(player: Player3D) -> void:
	"""Remove HP regen bonus when unequipped."""
	super.on_unequip(player)  # Remove base stat bonus

	# Remove HP regen modifier
	var regen_bonus = HP_REGEN_PER_LEVEL * level
	player.stats.hp_regen_percent -= regen_bonus

	Log.player("TRAIL_MIX unequipped")

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
	desc += "\nDesignation: Emergency Rations"
	desc += "\nProperties: Provides sustained nourishment"

	# Clearance 3+: Add specific mechanics
	if clearance_level >= 3:
		var total_regen = HP_REGEN_PER_LEVEL * level
		desc += "\n\nMechanics:"
		desc += "\n- HP regen: +%.1f%% per turn" % total_regen
		desc += "\n- Also grants +%d BODY" % level

	# Clearance 4+: Add code revelation
	if clearance_level >= 4:
		desc += "\n\n--- SYSTEM DATA (CLEARANCE OMEGA) ---"
		desc += "\nclass_name: TrailMix extends Item"
		desc += "\npool: BODY"
		desc += "\nrarity: RARE"
		desc += "\n\non_equip():"
		desc += "\n  stats.hp_regen_percent += %.1f * level" % HP_REGEN_PER_LEVEL

	return desc

# ============================================================================
# UTILITY
# ============================================================================

func _to_string() -> String:
	"""Debug representation."""
	var total_regen = HP_REGEN_PER_LEVEL * level
	return "TrailMix(Level %d, +%.1f%% HP regen, %s)" % [
		level,
		total_regen,
		"Equipped" if equipped else "Ground"
	]
