# Item System Implementation Plan

**Date**: 2025-11-23
**Status**: Planning → Implementation

---

## Design Specifications

### Item Spawning & Acquisition

**Ground Spawning**:
- Items appear on ground tiles based on level configuration
- Spawn chance per level defined in `LevelConfig` resource
- Scaling factors:
  - Rarity (common → rare → unique)
  - Corruption level (higher corruption = different loot tables)
  - Custom placement rules (e.g., "must spawn in center of 16x16 empty square")

**Player Interaction**:
- Walking over item triggers **equip prompt**
- Prompt shows available slots for that item type (BODY/MIND/NULL/LIGHT)
- Player can:
  - **Equip to slot**: Choose which slot to place item
  - **Decline**: Item stays on ground, player can walk away
- If slot already occupied:
  - **Different item**: Overwrite (old item is DESTROYED, not dropped)
  - **Same item**: Level up the existing item (see Item Leveling below)

**No Inventory System**:
- Items are either equipped (in a slot) or on the ground
- No "backpack" or "stash" storage
- Strategic choice: What do you equip NOW?

---

### Item Leveling System

**All items have properties that scale with item level**:

**Example: Brass Knuckles (BODY)**
- Level 1: 2 attacks per turn, range 1, +5 STRENGTH
- Level 2: 2 attacks per turn, range 2, +6 STRENGTH
- Level 3: 2 attacks per turn, range 3, +7 STRENGTH
- Formula: `N attacks per turn, within range N, +(5+N) STRENGTH`

**Leveling Mechanism**:
- Walk over same item type while equipped → Level up (stacks)
- Max level TBD (probably 5-10 for balance)
- Higher levels = significantly more powerful

**Design Intent**:
- Rewards finding duplicates (like Vampire Survivors)
- Creates build commitment (leveling your favorites)
- Risk/reward: Overwrite for diversity or level up for power?

---

### Item Pools & Slots

**Four Item Pools**:

1. **BODY Pool** (3 slots)
   - Physical attacks, damage, defense
   - Examples: Brass knuckles, steel pipe, armor

2. **MIND Pool** (3 slots)
   - Perception, knowledge, mental abilities
   - Examples: Researcher's notes, focus techniques

3. **NULL Pool** (3 slots)
   - Anomalous effects (requires NULL stat > 0)
   - **Display**: Shows "[LOCKED]" in UI until first NULL item acquired
   - Once unlocked, slots become usable
   - Examples: SCP artifacts, Backrooms anomalies

4. **LIGHT Pool** (1 slot)
   - Single light source active at a time
   - Examples: Flashlight, glowstick, corrupted lantern

**Execution Order**:
- Items in each pool execute **top-to-bottom**
- Order matters for synergy stacking
- Example: `[Fire Enchant] → [Double Strike] → [Life Steal]`
  - Attack gains fire → hits twice → heals from fire damage

---

### UI & Controls

**Equip Prompt (when walking over item)**:

**Mouse + Keyboard**:
- Prompt appears showing item info + available slots
- Click slot to equip
- Click "Decline" or press ESC to leave item on ground

**Controller**:
- Left stick: Move highlight between slots
- A button: Confirm selection (equip to highlighted slot)
- B button: Decline (default action, leave item on ground)

**Inventory Management (when paused)**:

**Mouse + Keyboard**:
- Click and drag items to reorder within a pool
- Drag item out of slot to unequip (drops on ground at player position)
- Right-click item for tooltip/details

**Controller (paused only)**:
- Left stick: Move highlight between items
- A button (first press): Pick up item
- Left stick: Move to new position
- A button (second press): Place item (swap with existing)
- B button: Cancel pickup (return to original position)

**Tooltip System**:
- Hover/focus on item shows tooltip panel
- Tooltip content scales with **Clearance Level**:

**Clearance 0-1** (Early game):
```
DEBUG_ITEM
An anomalous device of unknown origin. Appears to be
malfunctioning. Handle with extreme caution.
```

**Clearance 2-3** (Mid game):
```
DEBUG_ITEM
Designation: Experimental Containment Breach
Properties: Unstable energy fluctuations
Effects: [PARTIAL DATA] Self-damage, regeneration cycles
Threat Level: 2
```

**Clearance 4+** (Late game - Code Revelation):
```
DEBUG_ITEM (Level 3)
Designation: Experimental Containment Breach

--- SYSTEM DATA (CLEARANCE OMEGA) ---
class_name: DebugItem extends Item
pool: NULL
level: 3

on_turn(turn_number):
  if turn_number % 2 == 1:  # Odd turns
    player.take_damage(level * 1)
    player.drain_sanity(level * 1)
  else:  # Even turns
    player.heal(level * 2)
    player.restore_sanity(level * 2)

on_equip():
  player.stats.add_modifier(
    StatModifier.new("mana", 5 * level, ADD, "DEBUG_ITEM")
  )
```

---

### Examination System

**Examining Items on Ground**:
- Player enters Look Mode (RMB/LT)
- Aim at item tile
- Shows item description (based on Clearance)
- **First examination of item type**: Grants EXP (knowledge gain)
- **Subsequent examinations**: No EXP (already learned)

**EXP Gain Tracking**:
- Knowledge database tracks "examined item types"
- Prevents farming same item for infinite EXP
- Encourages exploration and finding new items

---

## First Item: DEBUG_ITEM

**Item Type**: NULL
**Rarity**: Common (for testing)
**Appearance**: "A malfunctioning device with flickering lights"

**Properties** (scale with level N):
- **Odd turns**: Deal N HP damage (to self) AND N Sanity damage (to self)
- **Even turns**: Heal N×2 HP (to self) AND restore N×2 Sanity (to self)
- **Passive**: +5×N max Mana

**Example Scaling**:
- Level 1: Odd turns -1 HP/-1 SAN, Even turns +2 HP/+2 SAN, +5 Mana
- Level 2: Odd turns -2 HP/-2 SAN, Even turns +4 HP/+4 SAN, +10 Mana
- Level 3: Odd turns -3 HP/-3 SAN, Even turns +6 HP/+6 SAN, +15 Mana

**Design Intent**:
- High-risk, high-reward NULL item
- Tests self-damage and healing mechanics
- Unlocks Mana pool for early testing
- Cyclic gameplay pattern (odd/even turns)

---

## Technical Architecture

### Item Class Structure

```gdscript
class_name Item extends Resource

@export var item_id: String  # Unique identifier (e.g., "brass_knuckles")
@export var item_name: String  # Display name
@export var pool_type: PoolType  # BODY, MIND, NULL, LIGHT
@export var rarity: Rarity  # COMMON, RARE, UNIQUE

# Descriptions for Clearance levels
@export_multiline var description_low: String  # Clearance 0-1
@export_multiline var description_mid: String  # Clearance 2-3
@export_multiline var description_high: String  # Clearance 4+

# Code revelation (shown at highest Clearance)
@export_multiline var code_description: String

# Current level of this item instance
var level: int = 1

# Core methods (override in subclasses)
func on_equip(player: Player3D) -> void
func on_unequip(player: Player3D) -> void
func on_turn(player: Player3D, turn_number: int) -> void
func level_up() -> void
```

### ItemPool Class

```gdscript
class_name ItemPool extends RefCounted

signal item_added(item: Item, slot_index: int)
signal item_removed(item: Item, slot_index: int)
signal item_reordered(from_index: int, to_index: int)

var pool_type: Item.PoolType
var max_slots: int  # 3 for BODY/MIND/NULL, 1 for LIGHT
var items: Array[Item] = []  # Current items (nulls for empty slots)

func add_item(item: Item, slot_index: int) -> bool
func remove_item(slot_index: int) -> Item
func reorder(from_index: int, to_index: int) -> void
func execute_turn(player: Player3D, turn_number: int) -> void
```

### Player Integration

```gdscript
# In Player3D.gd
var body_pool: ItemPool
var mind_pool: ItemPool
var null_pool: ItemPool
var light_pool: ItemPool

var null_unlocked: bool = false  # Unlocks when first NULL item equipped

func _ready():
    body_pool = ItemPool.new(Item.PoolType.BODY, 3)
    mind_pool = ItemPool.new(Item.PoolType.MIND, 3)
    null_pool = ItemPool.new(Item.PoolType.NULL, 3)
    light_pool = ItemPool.new(Item.PoolType.LIGHT, 1)

func execute_turn():
    var turn_num = # ... track turn counter
    body_pool.execute_turn(self, turn_num)
    mind_pool.execute_turn(self, turn_num)
    if null_unlocked:
        null_pool.execute_turn(self, turn_num)
    light_pool.execute_turn(self, turn_num)
```

---

## Implementation Phases

### Phase 1: Core Item Architecture ✅ (Today)
- [x] Create `Item` base class (Resource)
- [x] Create `ItemPool` class (component)
- [x] Create `DEBUG_ITEM` (first NULL item)
- [x] Add item pools to Player3D
- [x] Basic equip/unequip logic

### Phase 2: UI Integration ✅ (Today)
- [x] Update `CoreInventory` UI to display 4 pools
- [x] Show items in slots (with level indicators)
- [x] Show "[LOCKED]" for NULL pool when locked
- [x] Connect to Player signals for real-time updates

### Phase 3: Item Pickup & Interaction (Today if time, else next session)
- [ ] Item spawn system (ground tiles)
- [ ] Equip prompt UI (slot selection)
- [ ] Mouse + Controller input handling
- [ ] Item leveling logic (same item → level up)
- [ ] Examination system integration (EXP gain)

### Phase 4: Item Reordering (Next session)
- [ ] Drag-and-drop (mouse)
- [ ] Controller pick-up/swap system
- [ ] Visual feedback during reordering

### Phase 5: Tooltip System (Next session)
- [ ] Clearance-based description rendering
- [ ] Code revelation formatting
- [ ] Tooltip positioning (bottom-center overlay)

---

## Design Decisions ✅

1. **Item drop visualization**:
   - ✅ **Sprite billboard** (3D billboard facing camera)
   - ✅ **Minimap presence** if item has been "seen" by player

2. **NULL unlock trigger**:
   - ✅ NULL pool unlocks when **NULL stat > 0** (via any means)
   - ✅ **Picking up items grants stat bonus**: +N to corresponding stat (where N = item level)
     - BODY item → +N BODY
     - MIND item → +N MIND
     - NULL item → +N NULL
     - LIGHT item → no stat bonus

3. **Item level cap**:
   - ✅ **UNLIMITED** - let the fun scale infinitely!

4. **Tooltip system**:
   - ✅ Use **same tooltip overlay as StatsPanel** (bottom-center, ~400px width)

5. **Item destruction** (when overwriting):
   - ✅ **Player log message** ("Destroyed [item name]")
   - ✅ **Confirmation prompt** before overwrite

---

## Notes

- All items must support code revelation (highest Clearance)
- Item execution order is critical for synergy design
- NULL pool is special: locked until first NULL item/stat
- No separate inventory = strategic commitment to builds
- Item leveling encourages duplicate hunting (Vampire Survivors-style)

---

**Next Steps**: Implement Phase 1 & 2 today, test with DEBUG_ITEM, then plan Phase 3 based on results.
