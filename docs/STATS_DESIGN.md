# Resource Pools & Stats System - Design Document

**Created**: 2025-01-19
**Status**: Design Phase
**Related**: DESIGN.md, ARCHITECTURE.md

---

## Design Principles

1. **Unified system** - Players and entities (mobs) use the same stat/item architecture
2. **Base stats vs derived stats** - Some stats directly modify others (multiplicative scaling)
3. **Contextual resource changes** - No arbitrary drains; everything has a cause (darkness, proximity, etc.)
4. **Progressive discovery** - Massive EXP bonuses for first-time examination (knowledge > combat)

---

## Stat Categories

### Base Stats (Primary Attributes)

These are the foundation - items/mutations modify these directly.

| Stat | Base Contribution | Percentage Multiplier |
|------|-------------------|----------------------|
| **BODY** | +10 base HP, +1 base STRENGTH | Both HP and STRENGTH multiplied by (1 + BODY%) |
| **MIND** | +10 base Sanity, +1 base PERCEPTION | Both Sanity and PERCEPTION multiplied by (1 + MIND%) |
| **NULL** | +10 base Mana, +1 base ANOMALY | Both Mana and ANOMALY multiplied by (1 + NULL%) |

**Why percentage scaling?**
- Creates exponential returns: higher base stats become increasingly valuable
- BODY = 5: 5% bonus to HP and STRENGTH
- BODY = 20: 20% bonus to HP and STRENGTH
- Direct stat bonuses from items also benefit from percentage multiplier
- Encourages build diversity: stack base stats for scaling, or direct stats for immediate power

---

### Resource Pools (Depletable)

These are consumed and regenerated during gameplay.

| Resource | Max Derived From | Depleted Consequence |
|----------|------------------|----------------------|
| **HP** | [(BODY × 10) + direct HP bonuses] × (1 + BODY%) | Death (physical) |
| **Sanity** | [(MIND × 10) + direct Sanity bonuses] × (1 + MIND%) | Death (insanity) |
| **Mana** | [(NULL × 10) + direct Mana bonuses] × (1 + NULL%) | Can't use NULL abilities |

**Special case: Mana**
- Starts at 0 max / 0 current (doesn't exist until first NULL item acquired)
- NULL stat starts at 0 (players begin with no anomalous capacity)
- First NULL item grants +1 NULL → unlocks mana pool

---

### Derived Combat Stats

These determine offensive/defensive capabilities.

| Stat | Derived From | Purpose |
|------|--------------|---------|
| **STRENGTH** | [(BODY × 1) + direct STR bonuses] × (1 + BODY%) | Physical damage (BODY attacks) |
| **PERCEPTION** | [(MIND × 1) + direct PER bonuses] × (1 + MIND%) | Detection range, examination detail |
| **ANOMALY** | [(NULL × 1) + direct ANOM bonuses] × (1 + NULL%) | NULL ability power |

---

### Environmental/Meta Stats

These track player state in the world.

| Stat | Type | Purpose |
|------|------|---------|
| **Visibility** | Dynamic | How visible player is to entities (light radius, movement) |
| **Sound Level** | Dynamic | How much noise player generates (attracts entities) |
| **Corruption** | Persistent | Reality instability (increases with chunk exploration) |

**Not resources** - these don't have max/current, they're calculated or tracked differently:
- **Visibility**: Calculated from equipped LIGHT item + environmental light
- **Sound Level**: Calculated from movement speed + ability effects
- **Corruption**: Tracked per-level by CorruptionTracker (already exists)

---

### Progression Stats

| Stat | Gains From | Purpose |
|------|------------|---------|
| **EXP (Exploration Points)** | Kills (1 per kill), Examination (varies by type) | Increases Clearance Level |
| **Clearance Level** | EXP thresholds (pseudo-exponential formula) | Unlocks deeper knowledge, resets novelty, multiplies EXP gain |

**EXP Rewards (Base Values):**
- Kill entity: +1 EXP
- Examine environment (wall/floor/ceiling, first time): +10 EXP
- Examine item (first time): +EXP based on rarity
  - Common: +50 EXP
  - Uncommon: +150 EXP
  - Rare: +500 EXP
  - Legendary: +1500 EXP
- Examine entity (first time): +1000 EXP
- Examine (repeat): +0 EXP (unless novelty reset by Clearance increase)

**EXP Multiplier:**
- Base EXP is multiplied by Clearance Level
- Clearance 0: ×1 (no bonus)
- Clearance 1: ×2 (double EXP)
- Clearance 2: ×3 (triple EXP)
- Clearance N: ×(N+1) multiplier

**Clearance Level Effects:**
1. **Unlocks deeper knowledge**: Reveals more detailed descriptions for all entities/items
2. **Resets novelty**: All previously examined things become "novel" again (can re-examine for EXP with new description)
3. **Multiplies EXP gain**: Permanent (N+1)× multiplier to all future EXP sources

**Why examination-focused rewards?**
- Encourages exploration and knowledge-seeking over pure combat
- Fits Backrooms/SCP theme (researchers > soldiers)
- First-time examination is a significant discovery moment
- Clearance system creates exponential progression (better knowledge → more EXP → faster progression)

---

## Stat Formulas (Reference)

### Base Stats Calculation
```
base_hp = (BODY × 10) + direct_hp_bonuses
base_sanity = (MIND × 10) + direct_sanity_bonuses
base_mana = (NULL × 10) + direct_mana_bonuses

base_strength = (BODY × 1) + direct_str_bonuses
base_perception = (MIND × 1) + direct_per_bonuses
base_anomaly = (NULL × 1) + direct_anom_bonuses
```

### Effective Stats (After Percentage Multiplier)
```
HP (max) = base_hp × (1 + BODY/100)
Sanity (max) = base_sanity × (1 + MIND/100)
Mana (max) = base_mana × (1 + NULL/100)

STRENGTH = base_strength × (1 + BODY/100)
PERCEPTION = base_perception × (1 + MIND/100)
ANOMALY = base_anomaly × (1 + NULL/100)
```

### Example 1: Starting Character
- BODY = 5, MIND = 8, NULL = 0
- No item bonuses yet

**Calculations:**
- base_hp = 50, effective HP = 50 × 1.05 = **52.5**
- base_sanity = 80, effective Sanity = 80 × 1.08 = **86.4**
- base_mana = 0, effective Mana = **0** (NULL system locked)
- base_strength = 5, effective STRENGTH = 5 × 1.05 = **5.25**
- base_perception = 8, effective PERCEPTION = 8 × 1.08 = **8.64**
- base_anomaly = 0, effective ANOMALY = **0**

### Example 2: With +20 HP Item
Same character finds "+20 HP" item:
- base_hp = 50 + 20 = 70
- effective HP = 70 × 1.05 = **73.5**

Direct bonuses benefit from percentage multiplier!

### Example 3: With +1 BODY Item
Same character finds "+1 BODY" item instead:
- New BODY = 6
- base_hp = 60, effective HP = 60 × 1.06 = **63.6**
- base_strength = 6, effective STRENGTH = 6 × 1.06 = **6.36**

Better long-term scaling: +1 BODY gives +11.1 effective HP AND +1.11 effective STRENGTH!

### Example 4: High BODY Character
- BODY = 20, MIND = 5, NULL = 0

**Calculations:**
- base_hp = 200, effective HP = 200 × 1.20 = **240**
- base_strength = 20, effective STRENGTH = 20 × 1.20 = **24**

Exponential scaling: 20% multiplier makes BODY increasingly valuable!

---

## Resource Changes (When & Why)

### HP changes:
- ❌ NOT per-turn drain
- ✅ Damage from entities
- ✅ Damage from environmental hazards (fire, acid, etc.)
- ✅ Healing from items/abilities

### Sanity changes:
- ❌ NOT per-turn drain
- ✅ Drain from darkness (no light source equipped)
- ✅ Drain from proximity to cognitohazards
- ✅ Drain from witnessing disturbing events
- ✅ Restoration from items/abilities

### Mana changes:
- ❌ NOT per-turn drain
- ✅ Consumption from using NULL abilities
- ✅ Regeneration from anomalous sources

---

## HUD Display Requirements

**Must show:**

```
┌─────────────────────────────────────┐
│  STATS                              │
│  ├─ BODY: 5    HP: 50/50            │
│  ├─ MIND: 8    Sanity: 80/80        │
│  └─ NULL: 0    Mana: [LOCKED]       │
│                                     │
│  COMBAT                             │
│  ├─ STRENGTH: 10                    │
│  ├─ PERCEPTION: 16                  │
│  └─ ANOMALY: 0                      │
│                                     │
│  PROGRESSION                        │
│  ├─ Clearance: Level 0              │
│  └─ EXP: 0 / 100 (next level)       │
│                                     │
│  ENVIRONMENTAL                      │
│  ├─ Visibility: [future]            │
│  ├─ Sound: [future]                 │
│  └─ Corruption: 0.00                │
└─────────────────────────────────────┘
```

**Future-proofing:**
- Visibility/Sound greyed out until lighting/sound systems implemented
- Mana shows "[LOCKED]" until NULL > 0
- Corruption value pulled from CorruptionTracker (already exists)

---

## Entity/Player Shared Architecture

**Both players and entities have:**
- Base stats (BODY, MIND, NULL)
- Resource pools (HP, Sanity, Mana)
- Derived stats (STRENGTH, PERCEPTION, ANOMALY)

**Differences:**
- Players have: EXP, Clearance Level, item pools (BODY/MIND/NULL/LIGHT)
- Entities have: AI behaviors, loot tables, spawn conditions

**Why share the system?**
- Entities can have high MIND (psychic enemies)
- Entities can have NULL abilities (anomalous threats)
- Consistent damage/defense calculations
- Items that "steal stats" work naturally

---

## Clearance Level-Up Formula

**EXP Required Formula:**
```
EXP_for_level(N) = BASE × (N ^ EXPONENT)

BASE = 100
EXPONENT = 1.5

Examples:
  Level 1:  100 × (1^1.5) = 100
  Level 2:  100 × (2^1.5) = 283
  Level 5:  100 × (5^1.5) = 1118
  Level 10: 100 × (10^1.5) = 3162
  Level 20: 100 × (20^1.5) = 8944
```

**No level cap** - formula scales infinitely

---

## Open Questions for Implementation

1. **Starting stats** - What are default BODY/MIND/NULL values for player? (Proposed: 5/5/0)
2. **Item rarity tiers** - Exact EXP values for each rarity level? (Proposed: 50/150/500/1500)
3. **Stat caps** - Do base stats have a maximum? (Proposed: No hard cap, but diminishing returns from items)
4. **Sanity darkness drain** - How much per turn in darkness? (Deferred until lighting system)
5. **Visibility/Sound formulas** - Exact calculations (Deferred until lighting/sound systems)

---

## Design Summary

This system creates:
- **Meaningful stat choices** (base stats scale multiplicatively)
- **Knowledge-driven progression** (1000× EXP for examination)
- **Unified architecture** (players and entities use same stats)
- **Future-proof foundation** (visibility/sound/lighting integration ready)
- **No arbitrary drains** (all resource changes have in-world causes)
