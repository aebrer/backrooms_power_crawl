# Auto-Attack System Architecture Plan

**Created**: 2026-01-08
**Status**: Planning Phase - Ready for Implementation

---

## Executive Summary

This plan designs an auto-attack system for a **turn-based auto-battler** where:
- Player does NOT manually attack
- There are THREE attack types: BODY, MIND, NULL (no LIGHT attack)
- Each pool has ONE attack that fires automatically
- Items in a pool MODIFY the properties of that pool's attack
- Attacks happen every relevant turn based on cooldown (movement/wait is irrelevant)
- with no items in a pool, the BASE attack for that type is used
    + BODY: punch
    + MIND: whistle
    + NULL: nothing? sense? idk yet

---

## Core Design Principle

**Items do NOT have their own attacks. Items MODIFY the pool's single attack.**

```
BODY Pool Attack:
  Base: 5 damage, 1 range, every turn
  + Brass Knuckles: +3 damage
  + Power Gloves: +2 range
  + Rage Serum: ×1.5 damage multiplier
  = Final: 12 damage, 3 range, every turn

MIND Pool Attack:
  Base: 3 sanity damage, 3 range, area, every 5 turns
  + Psychic Focus: +10 damage
  + Third Eye: -1 cooldown (attacks more often)
  = Final: 13 sanity damage, 3 range, every 4 turns

NULL Pool Attack:
  Base: MANA TOTAL damage, 5 range, every 4 turns, costs mana
  + Void Shard: +5 damage
  + Mana Efficiency: -50% mana cost
  = Final: MANA TOTAL+5 damage, 5 range, every 4 turns, half mana cost

  (conceptually, I think it makes sense that as the player starts as a normal "human" they have no anomoly attack, but as they lvl up or find items the backrooms changes them and things become possible that were impossible before)
```

---

## Key Architectural Decisions

### 1. AttackExecutor Calculates Pool Attacks (NOT Items)

Each turn, an `AttackExecutor` queries all items in each pool to build the final attack properties:

```gdscript
# Pseudocode for attack execution
func execute_attacks(player):
    # BODY attack
    var body_attack = build_attack_from_pool(player.body_pool, AttackType.BODY)
    if body_attack.is_ready():
        body_attack.execute(player)

    # MIND attack
    var mind_attack = build_attack_from_pool(player.mind_pool, AttackType.MIND)
    if mind_attack.is_ready():
        mind_attack.execute(player)

    # NULL attack
    var null_attack = build_attack_from_pool(player.null_pool, AttackType.NULL)
    if null_attack.is_ready():
        null_attack.execute(player)
```

### 2. Items Provide Attack Modifiers (NOT Attacks)

Items implement a method that returns their contribution to the pool's attack:

```gdscript
# In Item base class
func get_attack_modifiers() -> Dictionary:
    """Return this item's contribution to the pool's attack.

    Returns dict with any of:
    - damage_add: flat damage bonus
    - damage_multiply: damage multiplier
    - range_add: extra range
    - cooldown_add: cooldown modifier (negative = faster)
    - area: override attack area (if item provides one)
    - mana_cost_multiply: mana cost modifier (for NULL)
    - special_effects: Array of effect callbacks
    """
    return {}  # Base items don't modify attacks
```

### 3. Attack Properties Are Aggregated

The `AttackExecutor` aggregates modifiers from all equipped items:

```gdscript
func build_attack_from_pool(pool: ItemPool, attack_type: int) -> PoolAttack:
    var attack = PoolAttack.new(attack_type)

    # Start with base stats for this attack type
    attack.damage = BASE_DAMAGE[attack_type]
    attack.range = BASE_RANGE[attack_type]
    attack.cooldown = BASE_COOLDOWN[attack_type]
    attack.area = BASE_AREA[attack_type]

    # Aggregate ADD modifiers first
    for item in pool.get_enabled_items():
        var mods = item.get_attack_modifiers()
        attack.damage += mods.get("damage_add", 0)
        attack.range += mods.get("range_add", 0)
        attack.cooldown += mods.get("cooldown_add", 0)

    # Then MULTIPLY modifiers
    for item in pool.get_enabled_items():
        var mods = item.get_attack_modifiers()
        attack.damage *= mods.get("damage_multiply", 1.0)

    # Apply stat scaling
    attack.damage *= (1.0 + player.stats.get(SCALING_STAT[attack_type]) / 100.0)

    return attack
```

### 4. Cooldowns Are Per-Pool (NOT Per-Item)

Each attack type tracks its own cooldown:

```gdscript
# In Player or AttackExecutor
var _body_cooldown: int = 0
var _mind_cooldown: int = 0
var _null_cooldown: int = 0

func _tick_cooldowns():
    if _body_cooldown > 0: _body_cooldown -= 1
    if _mind_cooldown > 0: _mind_cooldown -= 1
    if _null_cooldown > 0: _null_cooldown -= 1
```

### 5. Attacks Fire Regardless of Player Action

Attacks execute during item pool execution phase, independent of whether player moved or waited:

```
Turn execution:
1. Player action (move/wait/pickup) - IRRELEVANT to attacks
2. turn_count increments
3. Tick attack cooldowns
4. If BODY cooldown ready → execute BODY attack
5. If MIND cooldown ready → execute MIND attack
6. If NULL cooldown ready → execute NULL attack
7. Execute item on_turn() for non-attack effects
```

---

## File Structure

```
scripts/
├── combat/
│   ├── attack_types.gd          # Enums, base stats, constants
│   ├── pool_attack.gd           # Single attack instance (built from pool)
│   └── attack_executor.gd       # Builds and executes pool attacks
├── items/
│   ├── item.gd                  # Add get_attack_modifiers() method
│   ├── debug_item.gd            # Existing (no changes needed)
│   ├── body/
│   │   ├── brass_knuckles.gd    # +damage_add
│   │   └── power_gloves.gd      # +range_add
│   ├── mind/
│   │   └── psychic_focus.gd     # +damage_add for MIND
│   └── null/
│       └── void_shard.gd        # +damage_add for NULL
```

---

## Implementation Plan

### Phase 1: Attack Foundation

**Step 1.1: Create attack_types.gd**
```gdscript
# scripts/combat/attack_types.gd
class_name AttackTypes

enum Type {
    BODY,   # Physical damage to HP
    MIND,   # Sanity damage
    NULL    # Anomalous damage (costs mana)
}

enum Area {
    SINGLE,    # Nearest enemy in range
    LINE,      # All in a line
    CONE,      # Triangle spread
    AOE_3X3,   # 3x3 centered on target
}

# Base attack properties per type (before item modifiers)
const BASE_DAMAGE = {
    Type.BODY: 5.0,
    Type.MIND: 3.0,
    Type.NULL: 8.0,
}

const BASE_RANGE = {
    Type.BODY: 1.5,   # Adjacent only
    Type.MIND: 3.0,   # Medium range
    Type.NULL: 5.0,   # Long range
}

const BASE_COOLDOWN = {
    Type.BODY: 1,     # Every turn
    Type.MIND: 2,     # Every 2 turns
    Type.NULL: 4,     # Every 4 turns
}

const BASE_AREA = {
    Type.BODY: Area.SINGLE,
    Type.MIND: Area.SINGLE,
    Type.NULL: Area.SINGLE,
}

const BASE_MANA_COST = {
    Type.BODY: 0.0,   # Free
    Type.MIND: 0.0,   # Free
    Type.NULL: 5.0,   # Costs mana
}

# Which stat scales damage for each type
const SCALING_STAT = {
    Type.BODY: "strength",
    Type.MIND: "perception",
    Type.NULL: "anomaly",
}
```

**Step 1.2: Create pool_attack.gd**
```gdscript
# scripts/combat/pool_attack.gd
class_name PoolAttack extends RefCounted
"""Represents a single pool's attack with all modifiers applied."""

var attack_type: int
var damage: float
var range_tiles: float
var cooldown: int
var area: int
var mana_cost: float
var special_effects: Array = []

# Runtime state
var _current_cooldown: int = 0

func _init(type: int):
    attack_type = type
    # Defaults from base stats
    damage = AttackTypes.BASE_DAMAGE[type]
    range_tiles = AttackTypes.BASE_RANGE[type]
    cooldown = AttackTypes.BASE_COOLDOWN[type]
    area = AttackTypes.BASE_AREA[type]
    mana_cost = AttackTypes.BASE_MANA_COST[type]

func is_ready() -> bool:
    return _current_cooldown <= 0

func tick_cooldown() -> void:
    if _current_cooldown > 0:
        _current_cooldown -= 1

func reset_cooldown() -> void:
    _current_cooldown = cooldown

func can_afford(player_stats: StatBlock) -> bool:
    if mana_cost <= 0:
        return true
    return player_stats.current_mana >= mana_cost

func pay_cost(player_stats: StatBlock) -> bool:
    if mana_cost <= 0:
        return true
    return player_stats.consume_mana(mana_cost)
```

**Step 1.3: Create attack_executor.gd**
```gdscript
# scripts/combat/attack_executor.gd
class_name AttackExecutor extends RefCounted
"""Builds and executes attacks for each pool."""

# Persistent cooldown state per attack type
var _cooldowns: Dictionary = {
    AttackTypes.Type.BODY: 0,
    AttackTypes.Type.MIND: 0,
    AttackTypes.Type.NULL: 0,
}

func execute_turn(player: Player3D) -> void:
    """Execute all ready attacks for this turn."""
    # Tick all cooldowns first
    for type in _cooldowns.keys():
        if _cooldowns[type] > 0:
            _cooldowns[type] -= 1

    # Execute BODY attack
    if _cooldowns[AttackTypes.Type.BODY] <= 0:
        var attack = _build_attack(player, player.body_pool, AttackTypes.Type.BODY)
        if attack and _execute_attack(player, attack):
            _cooldowns[AttackTypes.Type.BODY] = attack.cooldown

    # Execute MIND attack
    if _cooldowns[AttackTypes.Type.MIND] <= 0:
        var attack = _build_attack(player, player.mind_pool, AttackTypes.Type.MIND)
        if attack and _execute_attack(player, attack):
            _cooldowns[AttackTypes.Type.MIND] = attack.cooldown

    # Execute NULL attack
    if _cooldowns[AttackTypes.Type.NULL] <= 0:
        var attack = _build_attack(player, player.null_pool, AttackTypes.Type.NULL)
        if attack and _execute_attack(player, attack):
            _cooldowns[AttackTypes.Type.NULL] = attack.cooldown

func _build_attack(player: Player3D, pool: ItemPool, attack_type: int) -> PoolAttack:
    """Build attack from pool's equipped items."""
    if not pool:
        return null

    var attack = PoolAttack.new(attack_type)

    # Collect all modifiers from equipped items
    var damage_add: float = 0.0
    var damage_multiply: float = 1.0
    var range_add: float = 0.0
    var cooldown_add: int = 0
    var mana_cost_multiply: float = 1.0

    for item in pool.get_enabled_items():
        var mods = item.get_attack_modifiers()
        damage_add += mods.get("damage_add", 0.0)
        damage_multiply *= mods.get("damage_multiply", 1.0)
        range_add += mods.get("range_add", 0.0)
        cooldown_add += mods.get("cooldown_add", 0)
        mana_cost_multiply *= mods.get("mana_cost_multiply", 1.0)

        # Area override (last one wins)
        if mods.has("area"):
            attack.area = mods["area"]

        # Collect special effects
        if mods.has("special_effects"):
            attack.special_effects.append_array(mods["special_effects"])

    # Apply modifiers
    attack.damage = (attack.damage + damage_add) * damage_multiply
    attack.range_tiles = attack.range_tiles + range_add
    attack.cooldown = maxi(1, attack.cooldown + cooldown_add)  # Min 1 turn
    attack.mana_cost = attack.mana_cost * mana_cost_multiply

    # Apply stat scaling
    var scaling_stat = AttackTypes.SCALING_STAT[attack_type]
    var stat_value = player.stats.get(scaling_stat) if player.stats else 0
    attack.damage *= (1.0 + stat_value / 100.0)

    return attack

func _execute_attack(player: Player3D, attack: PoolAttack) -> bool:
    """Execute attack, return true if attack happened."""
    # Check mana cost
    if not attack.can_afford(player.stats):
        Log.action("Attack skipped - not enough mana (need %.0f)" % attack.mana_cost)
        return false

    # Find targets
    var targets = _find_targets(player, attack)
    if targets.is_empty():
        return false  # No targets, don't consume cooldown

    # Pay cost
    attack.pay_cost(player.stats)

    # Apply damage to targets
    for target_pos in targets:
        var success = player.grid.entity_renderer.damage_entity_at(target_pos, attack.damage)
        if success:
            var type_name = AttackTypes.Type.keys()[attack.attack_type]
            Log.action("%s attack hits %s for %.0f damage" % [type_name, target_pos, attack.damage])
            # TODO: Visual feedback

    # Apply special effects
    for effect in attack.special_effects:
        if effect.has_method("apply"):
            effect.apply(player, targets)

    return true

func _find_targets(player: Player3D, attack: PoolAttack) -> Array[Vector2i]:
    """Find valid targets for attack."""
    if not player.grid or not player.grid.entity_renderer:
        return []

    var candidates = player.grid.entity_renderer.get_entities_in_range(
        player.grid_position,
        attack.range_tiles
    )

    if candidates.is_empty():
        return []

    match attack.area:
        AttackTypes.Area.SINGLE:
            # Return nearest only
            candidates.sort_custom(func(a, b):
                return player.grid_position.distance_to(a) < player.grid_position.distance_to(b))
            return [candidates[0]]

        AttackTypes.Area.AOE_3X3:
            # Return all in range
            return candidates

        _:
            # Default: nearest
            candidates.sort_custom(func(a, b):
                return player.grid_position.distance_to(a) < player.grid_position.distance_to(b))
            return [candidates[0]]
```

**Step 1.4: Add get_attack_modifiers() to Item base class**
```gdscript
# Add to scripts/items/item.gd

func get_attack_modifiers() -> Dictionary:
    """Return this item's contribution to the pool's attack.

    Override in subclasses to modify the pool's attack.

    Possible keys:
    - damage_add: float (flat damage bonus)
    - damage_multiply: float (damage multiplier, default 1.0)
    - range_add: float (extra range in tiles)
    - cooldown_add: int (cooldown modifier, negative = faster)
    - area: AttackTypes.Area (override attack area)
    - mana_cost_multiply: float (mana cost modifier, default 1.0)
    - special_effects: Array (effect objects with apply() method)
    """
    return {}
```

**Step 1.5: Integrate AttackExecutor into turn flow**

Modify `Player3D.execute_item_pools()`:
```gdscript
# In player_3d.gd

var attack_executor: AttackExecutor = AttackExecutor.new()

func execute_item_pools() -> void:
    """Execute attacks then item effects."""
    # First: Execute pool attacks
    attack_executor.execute_turn(self)

    # Then: Execute item on_turn() for non-attack effects
    if body_pool:
        body_pool.execute_turn(self, turn_count)
    if mind_pool:
        mind_pool.execute_turn(self, turn_count)
    if null_pool:
        null_pool.execute_turn(self, turn_count)
    if light_pool:
        light_pool.execute_turn(self, turn_count)
```

### Phase 2: Example Items

**Step 2.1: Create debug attack modifier items**

```gdscript
# scripts/items/body/debug_melee_boost.gd
class_name DebugMeleeBoost extends Item
"""DEBUG_MELEE_BOOST - Increases BODY attack damage."""

func _init():
    item_id = "debug_melee_boost"
    item_name = "DEBUG_MELEE_BOOST"
    pool_type = PoolType.BODY
    rarity = ItemRarity.Tier.DEBUG
    visual_description = "Brass knuckles that crackle with energy."
    scaling_hint = "Damage bonus increases with level"

func get_attack_modifiers() -> Dictionary:
    return {
        "damage_add": 3.0 * level  # +3 damage per level
    }
```

```gdscript
# scripts/items/body/debug_range_boost.gd
class_name DebugRangeBoost extends Item
"""DEBUG_RANGE_BOOST - Increases BODY attack range."""

func _init():
    item_id = "debug_range_boost"
    item_name = "DEBUG_RANGE_BOOST"
    pool_type = PoolType.BODY
    rarity = ItemRarity.Tier.DEBUG
    visual_description = "Extendable metal gauntlet."
    scaling_hint = "Range increases with level"

func get_attack_modifiers() -> Dictionary:
    return {
        "range_add": 1.0 * level  # +1 range per level
    }
```

### Phase 3: Attack Preview UI

**Step 3.1: Query attack state for preview**

Add to `AttackExecutor`:
```gdscript
func get_attack_preview(player: Player3D, attack_type: int) -> Dictionary:
    """Get preview info for UI."""
    var pool = _get_pool_for_type(player, attack_type)
    var attack = _build_attack(player, pool, attack_type)

    return {
        "ready": _cooldowns[attack_type] <= 0,
        "cooldown_remaining": _cooldowns[attack_type],
        "damage": attack.damage if attack else 0,
        "range": attack.range_tiles if attack else 0,
        "targets": _find_targets(player, attack) if attack else [],
        "can_afford": attack.can_afford(player.stats) if attack else false,
    }
```

**Step 3.2: Show in IdleState**
- Highlight enemies in range of ready attacks
- Show damage preview in action preview UI

### Phase 4: Visual Feedback

**Step 4.1: Damage numbers**
- Floating text at target position
- Color-coded by attack type

**Step 4.2: Attack effects**
- Flash on hit
- Type-specific particles (future)

---

## Item Modifier Stacking Examples

### Example 1: Pure Damage Build
```
BODY Pool:
  Slot 1: Brass Knuckles (+5 damage_add)
  Slot 2: Power Fist (+8 damage_add)
  Slot 3: Rage Serum (×1.3 damage_multiply)

BODY Attack calculation:
  Base: 5
  + damage_add: 5 + 8 = 13
  Total before multiply: 5 + 13 = 18
  × damage_multiply: 18 × 1.3 = 23.4
  × stat scaling (strength=10): 23.4 × 1.10 = 25.74 → 26 damage
```

### Example 2: Speed Build
```
BODY Pool:
  Slot 1: Quick Jab (+2 damage_add, -1 cooldown_add)
  Slot 2: Adrenaline (-1 cooldown_add)
  Slot 3: [empty]

BODY Attack calculation:
  Base cooldown: 1
  + cooldown_add: -1 + -1 = -2
  Final cooldown: max(1, 1 + -2) = 1 (minimum 1)

Result: Still attacks every turn (can't go faster than 1)
But if base cooldown was 3:
  Final: max(1, 3 + -2) = 1 → Now attacks every turn instead of every 3
```

### Example 3: AOE Build
```
NULL Pool:
  Slot 1: Void Shard (+10 damage_add)
  Slot 2: Reality Fracture (area: AOE_3X3)
  Slot 3: Mana Efficiency (×0.5 mana_cost_multiply)

NULL Attack calculation:
  Base: 8 damage, SINGLE area, 5.0 mana cost
  + damage_add: 10
  Area override: AOE_3X3
  × mana_cost: 5.0 × 0.5 = 2.5

  Final: 18 damage to all enemies in 3x3, costs 2.5 mana
```

---

## Turn Execution Order (Complete)

```
PreTurnState:
  1. Resource regeneration (HP, Sanity, Mana)

ExecutingTurnState:
  2. Player action executes (Movement, Wait, Pickup)
  3. turn_count increments

  4. AttackExecutor.execute_turn():
     a. Tick all cooldowns
     b. If BODY cooldown ready:
        - Build attack from body_pool items
        - Find targets in range
        - If targets exist: deal damage, reset cooldown
     c. If MIND cooldown ready:
        - Build attack from mind_pool items
        - Find targets in range
        - If targets exist: deal sanity damage, reset cooldown
     d. If NULL cooldown ready:
        - Build attack from null_pool items
        - Check mana cost
        - Find targets in range
        - If targets exist AND can afford: deal damage, pay mana, reset cooldown

  5. Item on_turn() effects (non-attack):
     - body_pool.execute_turn() → each item's on_turn()
     - mind_pool.execute_turn() → each item's on_turn()
     - null_pool.execute_turn() → each item's on_turn()
     - light_pool.execute_turn() → each item's on_turn()

  6. (Future) Enemy turns

PostTurnState:
  7. Chunk loading/unloading
```

---

## Open Questions for User

1. **Base attack with no items**: Should pools attack even with 0 items equipped?
   - Option A: Yes, base attack always available
   - Option B: No, need at least 1 item to enable the attack
   - Recommendation: Option A (always have base attack)

2. **Targeting priority**: Nearest? Lowest HP? Random?
   - Recommendation: Nearest (most intuitive)

3. **Multi-target damage**: Full damage to all, or split?
   - Recommendation: Full damage to all

4. **NULL mana cost**: Can attack if not enough mana?
   - Current design: Skip attack, don't reset cooldown
   - Alternative: Attack anyway, just no mana bonus

---

## Next Steps After Approval

1. Create `scripts/combat/` directory
2. Implement `attack_types.gd` with enums and base stats
3. Implement `pool_attack.gd` for single attack instances
4. Implement `attack_executor.gd` for building and executing attacks
5. Add `get_attack_modifiers()` to `Item` base class
6. Add `attack_executor` to `Player3D`
7. Modify `execute_item_pools()` to call attack executor first
8. Create debug modifier items for testing
9. Test attack execution with debug enemies
10. Add attack preview to UI

---

*This plan correctly models attacks as pool-level with item modifiers, not item-level attacks.*
