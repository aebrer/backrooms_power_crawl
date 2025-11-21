# Stats System - Robust Implementation Plan

**Created**: 2025-01-19
**Status**: Planning (Robust Architecture)
**Related**: STATS_DESIGN.md, Agent Reviews

---

## Philosophy: Build It Right, Build It Once

This implementation builds the **production-ready architecture** from the start:
- ✅ Modifier system (not just direct bonuses)
- ✅ Resource-based templates (inspector-editable stat configs)
- ✅ Signal-based decoupling (no direct method calls between systems)
- ✅ Source tracking (know where every bonus comes from)
- ✅ Computed properties (Godot-idiomatic API)
- ✅ Validation and safety (no invalid states)

**Why now?** Because refactoring later is more expensive than building it right today.

---

## Phase 1: Core Stat Architecture

### 1.1: StatModifier System

**File**: `scripts/components/stat_modifier.gd`

```gdscript
class_name StatModifier extends RefCounted
"""Represents a single stat modification with source tracking.

Used for: items, buffs, debuffs, temporary effects, permanent bonuses.
"""

enum ModifierType {
    ADD,        # Add to base value (e.g., +20 HP from armor)
    MULTIPLY    # Multiply final value (e.g., ×1.5 damage from rage)
}

var stat_name: String          # "hp", "body", "strength", etc.
var value: float               # Amount to add/multiply
var type: ModifierType         # ADD or MULTIPLY
var source: String             # "Leather Armor", "Rage Potion", etc.
var duration: int = -1         # Turns remaining (-1 = permanent)
var unique_id: String          # For removal (generated from source + timestamp)

func _init(p_stat: String, p_value: float, p_type: ModifierType, p_source: String, p_duration: int = -1):
    stat_name = p_stat
    value = p_value
    type = p_type
    source = p_source
    duration = p_duration
    unique_id = "%s_%d" % [source, Time.get_ticks_usec()]

func tick_duration() -> bool:
    """Decrease duration by 1 turn. Returns true if expired."""
    if duration > 0:
        duration -= 1
    return duration == 0

func is_permanent() -> bool:
    return duration == -1
```

---

### 1.2: StatTemplate Resource

**File**: `scripts/resources/stat_template.gd`

```gdscript
@tool
class_name StatTemplate extends Resource
"""Inspector-editable stat configuration for entities/players.

Save as .tres files (e.g., starting_stats.tres, goblin_stats.tres).
"""

@export_group("Base Stats")
@export var base_body: int = 5
@export var base_mind: int = 5
@export var base_null: int = 0

@export_group("Direct Bonuses")
@export var bonus_hp: float = 0.0
@export var bonus_sanity: float = 0.0
@export var bonus_mana: float = 0.0
@export var bonus_strength: float = 0.0
@export var bonus_perception: float = 0.0
@export var bonus_anomaly: float = 0.0

func to_dict() -> Dictionary:
    """Convert to dictionary for StatBlock initialization."""
    return {
        "body": base_body,
        "mind": base_mind,
        "null_stat": base_null,
        "bonus_hp": bonus_hp,
        "bonus_sanity": bonus_sanity,
        "bonus_mana": bonus_mana,
        "bonus_strength": bonus_strength,
        "bonus_perception": bonus_perception,
        "bonus_anomaly": bonus_anomaly
    }
```

**Why Resource?**
- Editable in inspector (`@export`)
- Save as `.tres` files for different entity types
- Separate data from logic (StatBlock handles runtime, StatTemplate handles config)

---

### 1.3: StatBlock with Modifiers

**File**: `scripts/components/stat_block.gd`

```gdscript
class_name StatBlock extends RefCounted
"""Runtime stat management with modifier system.

Handles: base stats, modifiers, resources, formulas, signals.
Used by: Player3D, entities.
"""

# ============================================================
# SIGNALS
# ============================================================

signal stat_changed(stat_name: String)
signal resource_changed(resource_name: String, current: float, maximum: float)
signal resource_depleted(resource_name: String)
signal modifier_added(modifier: StatModifier)
signal modifier_removed(modifier: StatModifier)

# ============================================================
# BASE STATS
# ============================================================

var body: int = 5
var mind: int = 5
var null_stat: int = 0

# ============================================================
# CURRENT RESOURCES
# ============================================================

var current_hp: float = 0.0
var current_sanity: float = 0.0
var current_mana: float = 0.0

# ============================================================
# MODIFIERS
# ============================================================

var modifiers: Array[StatModifier] = []

# ============================================================
# CACHED VALUES (invalidated on stat change)
# ============================================================

var _cache_dirty: Dictionary = {
    "hp": true,
    "sanity": true,
    "mana": true,
    "strength": true,
    "perception": true,
    "anomaly": true
}

var _cache: Dictionary = {
    "hp": 0.0,
    "sanity": 0.0,
    "mana": 0.0,
    "strength": 0.0,
    "perception": 0.0,
    "anomaly": 0.0
}

# ============================================================
# INITIALIZATION
# ============================================================

func from_template(template: StatTemplate) -> StatBlock:
    """Initialize from a StatTemplate resource."""
    var data = template.to_dict()
    body = data.body
    mind = data.mind
    null_stat = data.null_stat

    # Add direct bonuses as permanent modifiers
    if data.bonus_hp > 0:
        add_modifier("hp", data.bonus_hp, StatModifier.ModifierType.ADD, "Base Template")
    if data.bonus_sanity > 0:
        add_modifier("sanity", data.bonus_sanity, StatModifier.ModifierType.ADD, "Base Template")
    if data.bonus_mana > 0:
        add_modifier("mana", data.bonus_mana, StatModifier.ModifierType.ADD, "Base Template")
    if data.bonus_strength > 0:
        add_modifier("strength", data.bonus_strength, StatModifier.ModifierType.ADD, "Base Template")
    if data.bonus_perception > 0:
        add_modifier("perception", data.bonus_perception, StatModifier.ModifierType.ADD, "Base Template")
    if data.bonus_anomaly > 0:
        add_modifier("anomaly", data.bonus_anomaly, StatModifier.ModifierType.ADD, "Base Template")

    initialize_resources()
    return self

func initialize_resources():
    """Set current resources to max. Call once at creation."""
    current_hp = max_hp
    current_sanity = max_sanity
    current_mana = max_mana

# ============================================================
# COMPUTED PROPERTIES (Godot idiom)
# ============================================================

var max_hp: float:
    get:
        if _cache_dirty["hp"]:
            _cache["hp"] = _calculate_stat("hp", body, 10.0)
            _cache_dirty["hp"] = false
        return _cache["hp"]

var max_sanity: float:
    get:
        if _cache_dirty["sanity"]:
            _cache["sanity"] = _calculate_stat("sanity", mind, 10.0)
            _cache_dirty["sanity"] = false
        return _cache["sanity"]

var max_mana: float:
    get:
        if _cache_dirty["mana"]:
            _cache["mana"] = _calculate_stat("mana", null_stat, 10.0)
            _cache_dirty["mana"] = false
        return _cache["mana"]

var strength: float:
    get:
        if _cache_dirty["strength"]:
            _cache["strength"] = _calculate_stat("strength", body, 1.0)
            _cache_dirty["strength"] = false
        return _cache["strength"]

var perception: float:
    get:
        if _cache_dirty["perception"]:
            _cache["perception"] = _calculate_stat("perception", mind, 1.0)
            _cache_dirty["perception"] = false
        return _cache["perception"]

var anomaly: float:
    get:
        if _cache_dirty["anomaly"]:
            _cache["anomaly"] = _calculate_stat("anomaly", null_stat, 1.0)
            _cache_dirty["anomaly"] = false
        return _cache["anomaly"]

# ============================================================
# STAT CALCULATION (with modifier system)
# ============================================================

func _calculate_stat(stat_name: String, base_stat: int, multiplier: float) -> float:
    """Calculate effective stat with modifiers.

    Formula:
        1. base = (base_stat × multiplier) + ADD modifiers
        2. effective = base × (1 + base_stat/100) × MULTIPLY modifiers
    """
    # Step 1: Calculate base with ADD modifiers
    var base = base_stat * multiplier
    for mod in modifiers:
        if mod.stat_name == stat_name and mod.type == StatModifier.ModifierType.ADD:
            base += mod.value

    # Step 2: Apply percentage multiplier from base stat
    var effective = base * (1.0 + base_stat / 100.0)

    # Step 3: Apply MULTIPLY modifiers
    for mod in modifiers:
        if mod.stat_name == stat_name and mod.type == StatModifier.ModifierType.MULTIPLY:
            effective *= mod.value

    # Round to int for cleaner display
    return round(effective)

# ============================================================
# BASE STAT MODIFICATION
# ============================================================

func modify_body(amount: int):
    if body + amount < 0:
        Log.warn(Log.Category.SYSTEM, "Cannot reduce BODY below 0")
        return
    body += amount
    _invalidate_cache(["hp", "strength"])
    emit_signal("stat_changed", "body")

func modify_mind(amount: int):
    if mind + amount < 0:
        Log.warn(Log.Category.SYSTEM, "Cannot reduce MIND below 0")
        return
    mind += amount
    _invalidate_cache(["sanity", "perception"])
    emit_signal("stat_changed", "mind")

func modify_null(amount: int):
    var was_locked = null_stat == 0
    if null_stat + amount < 0:
        Log.warn(Log.Category.SYSTEM, "Cannot reduce NULL below 0")
        return
    null_stat += amount
    _invalidate_cache(["mana", "anomaly"])
    emit_signal("stat_changed", "null")

    # Special: mana unlock
    if was_locked and null_stat > 0:
        current_mana = max_mana
        emit_signal("mana_unlocked")

# ============================================================
# MODIFIER MANAGEMENT
# ============================================================

func add_modifier(stat: String, value: float, type: StatModifier.ModifierType, source: String, duration: int = -1) -> StatModifier:
    """Add a modifier and return it for tracking."""
    var mod = StatModifier.new(stat, value, type, source, duration)
    modifiers.append(mod)
    _invalidate_cache([stat])
    emit_signal("modifier_added", mod)
    emit_signal("stat_changed", stat)
    return mod

func remove_modifier(unique_id: String) -> bool:
    """Remove modifier by unique ID. Returns true if found."""
    for i in range(modifiers.size()):
        if modifiers[i].unique_id == unique_id:
            var mod = modifiers[i]
            modifiers.remove_at(i)
            _invalidate_cache([mod.stat_name])
            emit_signal("modifier_removed", mod)
            emit_signal("stat_changed", mod.stat_name)
            return true
    return false

func remove_modifiers_from_source(source: String):
    """Remove all modifiers from a specific source (e.g., when unequipping item)."""
    var removed = []
    for mod in modifiers:
        if mod.source == source:
            removed.append(mod)

    for mod in removed:
        remove_modifier(mod.unique_id)

func tick_temporary_modifiers():
    """Called each turn - decreases duration of temporary modifiers."""
    var expired = []
    for mod in modifiers:
        if not mod.is_permanent() and mod.tick_duration():
            expired.append(mod.unique_id)

    for id in expired:
        remove_modifier(id)

func get_modifiers_for_stat(stat_name: String) -> Array[StatModifier]:
    """Get all modifiers affecting a specific stat."""
    var result: Array[StatModifier] = []
    for mod in modifiers:
        if mod.stat_name == stat_name:
            result.append(mod)
    return result

# ============================================================
# RESOURCE MANAGEMENT
# ============================================================

func take_damage(amount: float):
    """Damage HP with validation and signals."""
    if amount <= 0:
        return

    current_hp = max(0.0, current_hp - amount)
    emit_signal("resource_changed", "HP", current_hp, max_hp)

    if current_hp <= 0:
        emit_signal("resource_depleted", "HP")

func heal(amount: float):
    """Heal HP with clamping."""
    if amount <= 0:
        return

    current_hp = min(max_hp, current_hp + amount)
    emit_signal("resource_changed", "HP", current_hp, max_hp)

func drain_sanity(amount: float):
    """Drain sanity with validation and signals."""
    if amount <= 0:
        return

    current_sanity = max(0.0, current_sanity - amount)
    emit_signal("resource_changed", "Sanity", current_sanity, max_sanity)

    if current_sanity <= 0:
        emit_signal("resource_depleted", "Sanity")

func restore_sanity(amount: float):
    """Restore sanity with clamping."""
    if amount <= 0:
        return

    current_sanity = min(max_sanity, current_sanity + amount)
    emit_signal("resource_changed", "Sanity", current_sanity, max_sanity)

func consume_mana(amount: float) -> bool:
    """Consume mana. Returns false if not enough."""
    if current_mana < amount:
        return false

    current_mana -= amount
    emit_signal("resource_changed", "Mana", current_mana, max_mana)
    return true

func restore_mana(amount: float):
    """Restore mana with clamping."""
    if amount <= 0 or max_mana <= 0:
        return

    current_mana = min(max_mana, current_mana + amount)
    emit_signal("resource_changed", "Mana", current_mana, max_mana)

# ============================================================
# UTILITY
# ============================================================

func _invalidate_cache(stats: Array):
    """Mark cached stats as dirty."""
    for stat in stats:
        _cache_dirty[stat] = true

func has_mana_unlocked() -> bool:
    return null_stat > 0

func get_stat_breakdown(stat_name: String) -> Dictionary:
    """Get detailed breakdown of a stat for tooltips/debugging.

    Returns: {
        "base": 50.0,
        "modifiers": [{"source": "Armor", "value": 20, "type": "ADD"}, ...],
        "final": 73.5
    }
    """
    var mods = get_modifiers_for_stat(stat_name)
    var breakdown = {
        "base": 0.0,
        "modifiers": [],
        "final": 0.0
    }

    # Get base stat
    match stat_name:
        "hp": breakdown.base = body * 10.0
        "sanity": breakdown.base = mind * 10.0
        "mana": breakdown.base = null_stat * 10.0
        "strength": breakdown.base = body * 1.0
        "perception": breakdown.base = mind * 1.0
        "anomaly": breakdown.base = null_stat * 1.0

    # Add modifiers
    for mod in mods:
        breakdown.modifiers.append({
            "source": mod.source,
            "value": mod.value,
            "type": "ADD" if mod.type == StatModifier.ModifierType.ADD else "MULTIPLY",
            "duration": mod.duration
        })

    # Get final value
    match stat_name:
        "hp": breakdown.final = max_hp
        "sanity": breakdown.final = max_sanity
        "mana": breakdown.final = max_mana
        "strength": breakdown.final = strength
        "perception": breakdown.final = perception
        "anomaly": breakdown.final = anomaly

    return breakdown
```

---

## Phase 2: Player Integration

### 2.1: Player3D with Signal-Based Updates

**File**: `scripts/player/player_3d.gd` (modifications)

```gdscript
# ============================================================
# STATS & PROGRESSION
# ============================================================

var stats: StatBlock

# EXP & Clearance
var exp: int = 0
var clearance_level: int = 0

# EXP Constants
const EXP_PER_KILL = 1
const EXP_ENVIRONMENT_EXAMINATION = 10
const EXP_ITEM_COMMON = 50
const EXP_ITEM_UNCOMMON = 150
const EXP_ITEM_RARE = 500
const EXP_ITEM_LEGENDARY = 1500
const EXP_ENTITY_EXAMINATION = 1000
const EXP_BASE = 100.0
const EXP_EXPONENT = 1.5

# Signals
signal died(cause: String)
signal exp_gained(amount: int, source: String)
signal clearance_increased(new_level: int)

# ============================================================
# INITIALIZATION
# ============================================================

@export var starting_stats: StatTemplate  # Assign in inspector

func _ready():
    # ... existing code ...

    # Initialize stats
    if starting_stats:
        stats = StatBlock.new().from_template(starting_stats)
    else:
        # Fallback: create default stats
        var default_template = StatTemplate.new()
        default_template.base_body = 5
        default_template.base_mind = 8
        default_template.base_null = 0
        stats = StatBlock.new().from_template(default_template)

    # Connect signals
    stats.resource_depleted.connect(_on_resource_depleted)

    # Connect to KnowledgeDB for EXP
    KnowledgeDB.entity_discovered.connect(_on_entity_discovered)

# ============================================================
# DEATH HANDLING
# ============================================================

func _on_resource_depleted(resource_name: String):
    match resource_name:
        "HP":
            emit_signal("died", "Physical damage")
        "Sanity":
            emit_signal("died", "Insanity")

    Log.system("Player death: %s depleted" % resource_name)
    # TODO: Transition to death state

# ============================================================
# EXP & PROGRESSION
# ============================================================

func get_exp_for_level(level: int) -> int:
    if level <= 0:
        return 0
    return int(EXP_BASE * pow(level, EXP_EXPONENT))

func get_exp_to_next_level() -> int:
    return get_exp_for_level(clearance_level + 1)

func get_exp_multiplier() -> int:
    return clearance_level + 1

func gain_exp(amount: int, source: String):
    var multiplied = amount * get_exp_multiplier()
    exp += multiplied
    emit_signal("exp_gained", multiplied, source)

    if get_exp_multiplier() > 1:
        Log.system("Gained %d EXP (×%d) from %s (total: %d)" % [
            multiplied, get_exp_multiplier(), source, exp
        ])
    else:
        Log.system("Gained %d EXP from %s (total: %d)" % [multiplied, source, exp])

    _check_level_up()

func _check_level_up():
    var threshold = get_exp_to_next_level()

    while exp >= threshold:
        clearance_level += 1
        emit_signal("clearance_increased", clearance_level)
        Log.system("Clearance increased to Level %d (EXP multiplier now ×%d)" % [
            clearance_level, get_exp_multiplier()
        ])

        # Reset novelty
        KnowledgeDB.reset_all_novelty()

        threshold = get_exp_to_next_level()

func _on_entity_discovered(entity_id: String, base_exp: int):
    """Called when KnowledgeDB discovers a novel entity."""
    gain_exp(base_exp, "examining %s" % entity_id)

# ============================================================
# TURN PROCESSING
# ============================================================

# In your existing turn processing:
func _process_turn():
    # ... existing turn logic ...

    # Tick temporary modifiers
    stats.tick_temporary_modifiers()
```

---

### 2.2: KnowledgeDB with Signal-Based EXP

**File**: `scripts/autoload/knowledge_db.gd` (modifications)

```gdscript
# ============================================================
# SIGNALS (for decoupling)
# ============================================================

signal entity_discovered(entity_id: String, base_exp: int)

# ============================================================
# NOVELTY TRACKING
# ============================================================

var examined_this_clearance: Dictionary = {}  # entity_id → bool

func reset_all_novelty():
    examined_this_clearance.clear()
    Log.system("Novelty reset - all entities can be re-examined for EXP")

# ============================================================
# EXAMINATION
# ============================================================

func examine_entity(entity_id: String):
    # Check if novel at current Clearance
    var is_novel = not examined_this_clearance.has(entity_id)
    examined_this_clearance[entity_id] = true

    # Update discovery level (existing logic)
    if not discovered_entities.has(entity_id):
        discovered_entities[entity_id] = 0

    var current_level = discovered_entities[entity_id]
    if current_level < 3:
        discovered_entities[entity_id] = current_level + 1
        researcher_classification += 1

    # Award EXP for novel examinations
    if is_novel:
        var base_exp = _get_examination_exp(entity_id)
        emit_signal("entity_discovered", entity_id, base_exp)

func _get_examination_exp(entity_id: String) -> int:
    """Determine EXP based on entity type."""
    var entity_info = get_entity_info(entity_id)

    # Environment tiles
    if entity_id.begins_with("level_0_"):
        return 10  # EXP_ENVIRONMENT_EXAMINATION

    # Items (check rarity)
    if entity_info.has("rarity"):
        match entity_info.rarity:
            "common": return 50
            "uncommon": return 150
            "rare": return 500
            "legendary": return 1500

    # Entities (killable)
    return 1000
```

---

## Phase 3: Pause System & HUD Interaction

### 3.1: Pause State Management

**File**: `scripts/autoload/pause_manager.gd` (new autoload)

```gdscript
extends Node
"""Manages game pause and HUD interaction mode.

Handles:
- ESC/START to pause game viewport
- Mouse/controller navigation of HUD when paused
- Input mode switching (gameplay vs HUD interaction)
"""

signal pause_toggled(is_paused: bool)
signal hud_focus_changed(focused_element: Control)

var is_paused: bool = false
var current_focus: Control = null
var focusable_elements: Array[Control] = []

func _ready():
    # Don't pause the entire tree - just the 3D viewport
    process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
    # ESC (keyboard) or START (controller) toggles pause
    if event.is_action_pressed("ui_cancel") or InputManager.is_action_just_pressed("pause"):
        toggle_pause()

func toggle_pause():
    is_paused = not is_paused
    emit_signal("pause_toggled", is_paused)

    if is_paused:
        _enter_hud_mode()
    else:
        _exit_hud_mode()

func _enter_hud_mode():
    """Pause gameplay viewport, enable HUD interaction."""
    # Pause the 3D viewport (not the entire tree)
    var game_3d = get_tree().get_first_node_in_group("game_3d_viewport")
    if game_3d:
        game_3d.process_mode = Node.PROCESS_MODE_DISABLED

    # Show mouse cursor
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    # Register focusable HUD elements
    _refresh_focusable_elements()

    # Focus first element
    if focusable_elements.size() > 0:
        set_hud_focus(focusable_elements[0])

    Log.system("Entered HUD interaction mode (paused)")

func _exit_hud_mode():
    """Resume gameplay viewport, disable HUD interaction."""
    # Resume the 3D viewport
    var game_3d = get_tree().get_first_node_in_group("game_3d_viewport")
    if game_3d:
        game_3d.process_mode = Node.PROCESS_MODE_INHERIT

    # Capture mouse for camera control
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    # Clear focus
    if current_focus:
        current_focus.release_focus()
    current_focus = null

    Log.system("Resumed gameplay (unpaused)")

func _refresh_focusable_elements():
    """Find all HUD elements that can be focused."""
    focusable_elements.clear()

    # Find all nodes in "hud_focusable" group
    for node in get_tree().get_nodes_in_group("hud_focusable"):
        if node is Control and node.visible:
            focusable_elements.append(node)

    # Sort by position (top to bottom, left to right)
    focusable_elements.sort_custom(_sort_by_position)

func _sort_by_position(a: Control, b: Control) -> bool:
    """Sort controls by visual position."""
    var pos_a = a.global_position
    var pos_b = b.global_position

    # Top to bottom first
    if abs(pos_a.y - pos_b.y) > 10:
        return pos_a.y < pos_b.y

    # Then left to right
    return pos_a.x < pos_b.x

func set_hud_focus(element: Control):
    """Focus a HUD element."""
    if current_focus:
        current_focus.release_focus()

    current_focus = element
    element.grab_focus()
    emit_signal("hud_focus_changed", element)

func navigate_hud(direction: Vector2i):
    """Navigate HUD with controller (up/down/left/right)."""
    if not is_paused or focusable_elements.is_empty():
        return

    var current_index = focusable_elements.find(current_focus)
    if current_index == -1:
        current_index = 0

    # Simple vertical navigation for now
    if direction.y != 0:
        current_index += direction.y
        current_index = clamp(current_index, 0, focusable_elements.size() - 1)
        set_hud_focus(focusable_elements[current_index])

func _process(_delta):
    if not is_paused:
        return

    # Handle controller navigation
    var stick_direction = InputManager.get_aim_direction_grid()
    if stick_direction != Vector2i.ZERO:
        navigate_hud(stick_direction)
```

---

### 3.2: HUD Element Base Class

**File**: `scripts/ui/hud_element.gd`

```gdscript
class_name HUDElement extends Control
"""Base class for interactive HUD elements.

Add to "hud_focusable" group to make it navigable when paused.
"""

signal element_activated()
signal element_hovered()

var is_hovered: bool = false
var is_focused: bool = false

func _ready():
    # Make focusable
    focus_mode = Control.FOCUS_ALL

    # Connect signals
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)

    # Add to focusable group
    add_to_group("hud_focusable")

func _on_mouse_entered():
    """Mouse hover - only when paused."""
    if PauseManager.is_paused:
        is_hovered = true
        PauseManager.set_hud_focus(self)
        emit_signal("element_hovered")
        _update_visual_state()

func _on_mouse_exited():
    is_hovered = false
    _update_visual_state()

func _on_focus_entered():
    """Controller/keyboard focus."""
    is_focused = true
    _update_visual_state()

func _on_focus_exited():
    is_focused = false
    _update_visual_state()

func _gui_input(event):
    """Handle activation (click or A button)."""
    if event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if PauseManager.is_paused:
            activate()

func activate():
    """Override in subclasses."""
    emit_signal("element_activated")

func _update_visual_state():
    """Override to show focus/hover state."""
    # Example: change background color, add outline, etc.
    if is_focused or is_hovered:
        modulate = Color(1.2, 1.2, 1.2, 1.0)  # Highlight
    else:
        modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal
```

---

## Phase 4: HUD with Stat Breakdown

**File**: `scripts/ui/stats_panel.gd`

```gdscript
class_name StatsPanel extends VBoxContainer

var player: Player3D

@onready var body_label: Label = %BodyLabel
@onready var mind_label: Label = %MindLabel
@onready var null_label: Label = %NullLabel
@onready var strength_label: Label = %StrengthLabel
@onready var perception_label: Label = %PerceptionLabel
@onready var anomaly_label: Label = %AnomalyLabel
@onready var clearance_label: Label = %ClearanceLabel
@onready var exp_label: Label = %ExpLabel

func _ready():
    player = get_tree().get_first_node_in_group("player")
    if not player:
        Log.error(Log.Category.SYSTEM, "StatsPanel: Player not found")
        return

    # Connect to stat changes
    player.stats.stat_changed.connect(_on_stat_changed)
    player.stats.resource_changed.connect(_on_resource_changed)
    player.exp_gained.connect(_on_exp_gained)
    player.clearance_increased.connect(_on_clearance_increased)

    _update_all()

func _on_stat_changed(_stat_name: String):
    _update_all()

func _on_resource_changed(_resource: String, _current: float, _max: float):
    _update_resources()

func _on_exp_gained(_amount: int, _source: String):
    _update_progression()

func _on_clearance_increased(_new_level: int):
    _update_progression()

func _update_all():
    var s = player.stats

    # Base stats + resources (rounded to int)
    body_label.text = "BODY: %d    HP: %d/%d" % [
        s.body, int(s.current_hp), int(s.max_hp)
    ]
    mind_label.text = "MIND: %d    Sanity: %d/%d" % [
        s.mind, int(s.current_sanity), int(s.max_sanity)
    ]

    # Mana (locked or unlocked)
    if s.has_mana_unlocked():
        null_label.text = "NULL: %d    Mana: %d/%d" % [
            s.null_stat, int(s.current_mana), int(s.max_mana)
        ]
    else:
        null_label.text = "NULL: 0    Mana: [LOCKED]"

    # Derived stats (rounded to int)
    strength_label.text = "STRENGTH: %d" % int(s.strength)
    perception_label.text = "PERCEPTION: %d" % int(s.perception)
    anomaly_label.text = "ANOMALY: %d" % int(s.anomaly)

    _update_progression()

func _update_resources():
    var s = player.stats
    body_label.text = "BODY: %d    HP: %d/%d" % [
        s.body, int(s.current_hp), int(s.max_hp)
    ]
    mind_label.text = "MIND: %d    Sanity: %d/%d" % [
        s.mind, int(s.current_sanity), int(s.max_sanity)
    ]

    if s.has_mana_unlocked():
        null_label.text = "NULL: %d    Mana: %d/%d" % [
            s.null_stat, int(s.current_mana), int(s.max_mana)
        ]

func _update_progression():
    clearance_label.text = "Clearance: Level %d (×%d EXP)" % [
        player.clearance_level, player.get_exp_multiplier()
    ]
    exp_label.text = "EXP: %d / %d" % [
        player.exp, player.get_exp_to_next_level()
    ]
```

---

## Files Summary

**New files**:
- `scripts/components/stat_modifier.gd` - Modifier system
- `scripts/resources/stat_template.gd` - Inspector-editable stat configs
- `scripts/components/stat_block.gd` - Runtime stat management (robust version)
- `scripts/autoload/pause_manager.gd` - Pause and HUD interaction management
- `scripts/ui/hud_element.gd` - Base class for interactive HUD elements
- `scripts/ui/stats_panel.gd` - HUD component
- `scenes/ui/stats_panel.tscn` - HUD scene
- `assets/stats/starting_stats.tres` - Default player stats (StatTemplate)

**Modified files**:
- `scripts/player/player_3d.gd` - Add stats, EXP, signal connections
- `scripts/autoload/knowledge_db.gd` - Add signals, novelty tracking
- `scenes/game.tscn` - Add StatsPanel to right panel
- `scenes/game_3d.tscn` - Add to "game_3d_viewport" group for pause system
- `project.godot` - Add PauseManager autoload, add "pause" input action

---

## What This Architecture Gives Us

### ✅ Immediate Benefits
1. **Source tracking** - Hover over HP stat, see "Base: 50, Armor +20, BODY +5%"
2. **Temporary buffs** - Add "Rage: +50% damage for 5 turns" with one line
3. **Item removal** - Unequip armor, all its modifiers auto-remove
4. **Inspector editing** - Tweak starting stats without code changes
5. **Entity templates** - Create `.tres` files for each enemy type
6. **Debug tooltips** - `get_stat_breakdown()` shows complete calculation

### ✅ Future-Ready
1. **Equipment system** - Items add modifiers by source, remove on unequip
2. **Status effects** - Poison, buffs, debuffs all use modifiers
3. **Mutation system** - Each mutation adds modifiers
4. **Item stacking** - Multiple sources of +HP stack automatically
5. **Synergy detection** - Can query modifiers to find combos

### ✅ No Refactoring Needed
- Adding equipment? Just call `stats.add_modifier()`
- Adding status effects? Same modifier system
- Adding complex buffs? Duration already built in
- Need to show tooltips? `get_stat_breakdown()` already exists

---

## Implementation Order

1. ✅ StatModifier class
2. ✅ StatTemplate resource
3. ✅ StatBlock with modifier system
4. ✅ PauseManager autoload
5. ✅ HUDElement base class
6. ✅ Create starting_stats.tres in inspector
7. ✅ Player3D integration
8. ✅ KnowledgeDB signal decoupling
9. ✅ StatsPanel HUD with interactive elements
10. ✅ Test pause system and HUD navigation
11. ✅ Test stat system

**Estimated implementation time**: ~3-4 hours (robust architecture with pause/HUD interaction)

---

## Input Parity: Pause & HUD Navigation

### Mouse + Keyboard (When Paused):
- **ESC**: Toggle pause
- **Mouse movement**: Hover over HUD elements to focus them
- **Left click**: Activate focused element
- **Mouse wheel**: Scroll through lists (future: item menu)

### Controller (When Paused):
- **START**: Toggle pause
- **Left stick (D-pad)**: Navigate between HUD elements
- **A button**: Activate focused element
- **Right stick**: Scroll through lists (future: item menu)

### Visual Feedback:
- Focused element highlighted (brighter/outlined)
- Mouse cursor visible when paused
- Clear indication of current selection

### Future HUD Components:
This system supports:
- **Item menu** - Select/use/drop items
- **Stat breakdown tooltips** - Hover to see modifier sources
- **Equipment slots** - Equip/unequip items
- **Ability bar** - Toggle abilities on/off
- **Map overlay** - Pan and zoom

All with perfect mouse/controller parity.

---

Ready to build this properly?
