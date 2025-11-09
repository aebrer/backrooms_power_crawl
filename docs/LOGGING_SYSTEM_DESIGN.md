# Centralized Logging System Design for Backrooms Power Crawl

**Created**: 2025-11-08
**Status**: Design Complete - Ready for Implementation

---

## Executive Summary

This design proposes a **Logger autoload singleton** that replaces 45+ scattered print statements across 16 files with a centralized, category-based, level-filtered logging system. The design follows the project's existing patterns (autoload singletons, export-based configuration, turn-based architecture) while providing zero overhead when disabled and minimal overhead when enabled.

---

## 1. Autoload Logger Class Structure

### Core Architecture

**File**: `/home/andrew/projects/backrooms_power_crawl/scripts/autoload/logger.gd`

```gdscript
extends Node
class_name Logger
## Centralized logging system with category-based filtering and level control
##
## This autoload singleton provides:
## - Category-based logging (input, state, movement, action, etc.)
## - Level-based filtering (ERROR, WARN, INFO, DEBUG, TRACE)
## - Zero overhead when categories disabled
## - Structured output with timestamps and context
## - Runtime configuration via exported properties
##
## Usage:
##   Log.input("Direction changed: %s" % direction)
##   Log.state_debug("Entering IdleState")
##   Log.error("movement", "Invalid grid position: %s" % pos)

# ============================================================================
# LOG LEVELS (Priority ordering)
# ============================================================================

enum Level {
	TRACE = 0,   # Most verbose - every frame events
	DEBUG = 1,   # Debug info - state changes, calculations
	INFO = 2,    # Normal info - important events
	WARN = 3,    # Warnings - unexpected but recoverable
	ERROR = 4,   # Errors - serious issues
	NONE = 5     # Disable all logging
}

# ============================================================================
# LOG CATEGORIES (Expandable as features grow)
# ============================================================================

enum Category {
	INPUT,       # InputManager events (stick, triggers, actions)
	STATE,       # State machine transitions and state events
	MOVEMENT,    # Movement actions and validation
	ACTION,      # Action system (execute, validate)
	TURN,        # Turn execution and counting
	GRID,        # Grid/tile operations
	CAMERA,      # Camera movement and rotation
	ENTITY,      # Entity spawning/AI (future)
	ABILITY,     # Ability system (future)
	PHYSICS,     # Physics simulation (future)
	SYSTEM,      # System-level events (initialization, errors)
}

# ============================================================================
# CONFIGURATION (Exported for inspector editing)
# ============================================================================

## Global log level - messages below this level are suppressed
@export var global_level: Level = Level.DEBUG

## Enable/disable individual categories (independent of level)
@export_group("Category Filters")
@export var log_input: bool = true
@export var log_state: bool = true
@export var log_movement: bool = true
@export var log_action: bool = true
@export var log_turn: bool = true
@export var log_grid: bool = false      # Disabled by default (verbose)
@export var log_camera: bool = false    # Disabled by default (verbose)
@export var log_entity: bool = true
@export var log_ability: bool = true
@export var log_physics: bool = false   # Disabled by default (very verbose)
@export var log_system: bool = true

## Output configuration
@export_group("Output Settings")
@export var show_timestamps: bool = false
@export var show_frame_count: bool = false
@export var show_category_prefix: bool = true
@export var show_level_prefix: bool = false

## File logging (future feature)
@export_group("File Logging")
@export var enable_file_logging: bool = false
@export var log_file_path: String = "user://logs/game.log"
@export var max_log_file_size_mb: int = 10

# ============================================================================
# INTERNAL STATE
# ============================================================================

# Category name lookup for formatting
const CATEGORY_NAMES = {
	Category.INPUT: "Input",
	Category.STATE: "State",
	Category.MOVEMENT: "Movement",
	Category.ACTION: "Action",
	Category.TURN: "Turn",
	Category.GRID: "Grid",
	Category.CAMERA: "Camera",
	Category.ENTITY: "Entity",
	Category.ABILITY: "Ability",
	Category.PHYSICS: "Physics",
	Category.SYSTEM: "System",
}

# Level name lookup for formatting
const LEVEL_NAMES = {
	Level.TRACE: "TRACE",
	Level.DEBUG: "DEBUG",
	Level.INFO: "INFO",
	Level.WARN: "WARN",
	Level.ERROR: "ERROR",
}

# Frame counter for timestamping
var _frame_count: int = 0

# File handle for logging (if enabled)
var _log_file: FileAccess = null

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	print("[Logger] Logging system initialized")
	print("[Logger] Global level: %s" % LEVEL_NAMES.get(global_level, "UNKNOWN"))
	print("[Logger] Active categories: %s" % _get_active_categories())

	if enable_file_logging:
		_open_log_file()

func _process(_delta: float) -> void:
	_frame_count += 1

func _exit_tree() -> void:
	if _log_file:
		_log_file.close()

# ============================================================================
# CORE LOGGING API (Level + Category)
# ============================================================================

## Generic logging method (all others route through this)
func log(category: Category, level: Level, message: String) -> void:
	# Fast path: check if this category/level should be logged
	if not _should_log(category, level):
		return

	# Format and output the message
	var formatted = _format_message(category, level, message)
	print(formatted)

	if enable_file_logging and _log_file:
		_log_file.store_line(formatted)

## Check if a category + level should be logged (performance optimization)
func _should_log(category: Category, level: Level) -> bool:
	# Level check first (most common filter)
	if level < global_level:
		return false

	# Category check (using match for performance)
	match category:
		Category.INPUT: return log_input
		Category.STATE: return log_state
		Category.MOVEMENT: return log_movement
		Category.ACTION: return log_action
		Category.TURN: return log_turn
		Category.GRID: return log_grid
		Category.CAMERA: return log_camera
		Category.ENTITY: return log_entity
		Category.ABILITY: return log_ability
		Category.PHYSICS: return log_physics
		Category.SYSTEM: return log_system

	return false

# ============================================================================
# CONVENIENCE METHODS (Category-specific)
# ============================================================================

# INPUT category
func input(message: String) -> void:
	log(Category.INPUT, Level.DEBUG, message)

func input_trace(message: String) -> void:
	log(Category.INPUT, Level.TRACE, message)

# STATE category
func state(message: String) -> void:
	log(Category.STATE, Level.DEBUG, message)

func state_info(message: String) -> void:
	log(Category.STATE, Level.INFO, message)

# MOVEMENT category
func movement(message: String) -> void:
	log(Category.MOVEMENT, Level.DEBUG, message)

func movement_info(message: String) -> void:
	log(Category.MOVEMENT, Level.INFO, message)

# ACTION category
func action(message: String) -> void:
	log(Category.ACTION, Level.DEBUG, message)

# TURN category
func turn(message: String) -> void:
	log(Category.TURN, Level.INFO, message)

# GRID category
func grid(message: String) -> void:
	log(Category.GRID, Level.DEBUG, message)

# CAMERA category
func camera(message: String) -> void:
	log(Category.CAMERA, Level.DEBUG, message)

# Cross-category level methods
func warn(category: Category, message: String) -> void:
	log(category, Level.WARN, message)

func error(category: Category, message: String) -> void:
	log(category, Level.ERROR, message)

func trace(category: Category, message: String) -> void:
	log(category, Level.TRACE, message)

# SYSTEM category (always logged unless global level is ERROR+)
func system(message: String) -> void:
	log(Category.SYSTEM, Level.INFO, message)

# ============================================================================
# FORMATTING
# ============================================================================

func _format_message(category: Category, level: Level, message: String) -> String:
	var parts: Array[String] = []

	# Timestamp (if enabled)
	if show_timestamps:
		var time = Time.get_ticks_msec() / 1000.0
		parts.append("[%.3fs]" % time)

	# Frame count (if enabled)
	if show_frame_count:
		parts.append("[F%d]" % _frame_count)

	# Category prefix (if enabled)
	if show_category_prefix:
		var cat_name = CATEGORY_NAMES.get(category, "Unknown")
		parts.append("[%s]" % cat_name)

	# Level prefix (if enabled and not DEBUG)
	if show_level_prefix and level != Level.DEBUG:
		var level_name = LEVEL_NAMES.get(level, "UNKNOWN")
		parts.append("[%s]" % level_name)

	# Message
	parts.append(message)

	return " ".join(parts)

func _get_active_categories() -> String:
	var active: Array[String] = []
	if log_input: active.append("Input")
	if log_state: active.append("State")
	if log_movement: active.append("Movement")
	if log_action: active.append("Action")
	if log_turn: active.append("Turn")
	if log_grid: active.append("Grid")
	if log_camera: active.append("Camera")
	if log_entity: active.append("Entity")
	if log_ability: active.append("Ability")
	if log_physics: active.append("Physics")
	if log_system: active.append("System")

	return ", ".join(active) if active.size() > 0 else "none"

# ============================================================================
# FILE LOGGING (Future feature)
# ============================================================================

func _open_log_file() -> void:
	# Ensure directory exists
	var dir_path = log_file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Open file in append mode
	_log_file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if _log_file:
		system("File logging enabled: %s" % log_file_path)
	else:
		push_error("[Logger] Failed to open log file: %s" % log_file_path)

# ============================================================================
# RUNTIME CONFIGURATION API
# ============================================================================

func set_global_level(level: Level) -> void:
	"""Set the global log level at runtime"""
	global_level = level
	system("Global log level changed to: %s" % LEVEL_NAMES.get(level, "UNKNOWN"))

func enable_category(category: Category, enabled: bool) -> void:
	"""Enable/disable a category at runtime"""
	match category:
		Category.INPUT: log_input = enabled
		Category.STATE: log_state = enabled
		Category.MOVEMENT: log_movement = enabled
		Category.ACTION: log_action = enabled
		Category.TURN: log_turn = enabled
		Category.GRID: log_grid = enabled
		Category.CAMERA: log_camera = enabled
		Category.ENTITY: log_entity = enabled
		Category.ABILITY: log_ability = enabled
		Category.PHYSICS: log_physics = enabled
		Category.SYSTEM: log_system = enabled

	var cat_name = CATEGORY_NAMES.get(category, "Unknown")
	system("Category '%s' %s" % [cat_name, "enabled" if enabled else "disabled"])

func enable_all_categories() -> void:
	"""Enable all categories (for deep debugging)"""
	for category in Category.values():
		enable_category(category, true)

func disable_all_categories() -> void:
	"""Disable all categories"""
	for category in Category.values():
		enable_category(category, false)
```

---

## 2. Log Categories & Initial Configuration

### Category Enum Structure

**Categories** represent functional areas of the codebase. They grow with the project:

| Category | Purpose | Default Enabled | Examples |
|----------|---------|-----------------|----------|
| `INPUT` | InputManager events | Yes | Stick direction, trigger presses, action detection |
| `STATE` | State machine transitions | Yes | State enter/exit, transitions |
| `MOVEMENT` | Movement validation/execution | Yes | Grid position changes, collision checks |
| `ACTION` | Action system | Yes | Action creation, validation, execution |
| `TURN` | Turn counting and execution | Yes | Turn start/end, turn counter |
| `GRID` | Grid operations | No (verbose) | Tile updates, viewport culling |
| `CAMERA` | Camera movement | No (verbose) | Rotation, position updates |
| `ENTITY` | Entity AI (future) | Yes | Spawning, pathfinding, turn processing |
| `ABILITY` | Ability system (future) | Yes | Ability activation, cooldowns |
| `PHYSICS` | Simulation (future) | No (very verbose) | Liquid spreading, temperature |
| `SYSTEM` | Lifecycle events | Yes | Initialization, autoload ready, errors |

### Adding New Categories

1. Add to `Category` enum in logger.gd
2. Add to `CATEGORY_NAMES` dictionary
3. Add `@export var log_<category>: bool` field
4. Add case to `_should_log()` match statement
5. Add convenience method (e.g., `func entity(message: String)`)
6. Update `_get_active_categories()` helper

**Example - Adding "UI" category:**
```gdscript
# In enum Category
UI,  # UI events and interactions

# In CATEGORY_NAMES
Category.UI: "UI",

# In exports
@export var log_ui: bool = true

# In _should_log()
Category.UI: return log_ui

# Convenience method
func ui(message: String) -> void:
	log(Category.UI, Level.DEBUG, message)

# In _get_active_categories()
if log_ui: active.append("UI")
```

---

## 3. Configuration System

### Primary Configuration: Godot Inspector

The logger uses `@export` properties for configuration, editable in Godot's inspector when selecting the Logger autoload node.

**Project Settings > Autoload > Logger (click to edit)**

```
Global Level: DEBUG
Category Filters:
  Log Input: ☑
  Log State: ☑
  Log Movement: ☑
  Log Action: ☑
  Log Turn: ☑
  Log Grid: ☐
  Log Camera: ☐
  Log Entity: ☑
  Log Ability: ☑
  Log Physics: ☐
  Log System: ☑

Output Settings:
  Show Timestamps: ☐
  Show Frame Count: ☐
  Show Category Prefix: ☑
  Show Level Prefix: ☐

File Logging:
  Enable File Logging: ☐
  Log File Path: user://logs/game.log
  Max Log File Size Mb: 10
```

### Configuration Presets

Create a configuration preset file for common scenarios:

**File**: `/home/andrew/projects/backrooms_power_crawl/scripts/autoload/logger_presets.gd`

```gdscript
## Logger configuration presets for common debugging scenarios
class_name LoggerPresets

## Development: Normal verbosity, key systems only
static func apply_development() -> void:
	Log.set_global_level(Logger.Level.DEBUG)
	Log.enable_category(Logger.Category.INPUT, true)
	Log.enable_category(Logger.Category.STATE, true)
	Log.enable_category(Logger.Category.MOVEMENT, true)
	Log.enable_category(Logger.Category.ACTION, true)
	Log.enable_category(Logger.Category.TURN, true)
	Log.enable_category(Logger.Category.GRID, false)
	Log.enable_category(Logger.Category.CAMERA, false)

## Deep Debug: Everything enabled, trace level
static func apply_deep_debug() -> void:
	Log.set_global_level(Logger.Level.TRACE)
	Log.enable_all_categories()
	Log.show_timestamps = true
	Log.show_frame_count = true

## Release: Errors and warnings only
static func apply_release() -> void:
	Log.set_global_level(Logger.Level.WARN)
	Log.disable_all_categories()
	Log.enable_category(Logger.Category.SYSTEM, true)

## Silent: No logging (for performance testing)
static func apply_silent() -> void:
	Log.set_global_level(Logger.Level.NONE)

## Input Debug: Focus on input system only
static func apply_input_debug() -> void:
	Log.set_global_level(Logger.Level.TRACE)
	Log.disable_all_categories()
	Log.enable_category(Logger.Category.INPUT, true)
	Log.enable_category(Logger.Category.SYSTEM, true)

## State Debug: Focus on state machine only
static func apply_state_debug() -> void:
	Log.set_global_level(Logger.Level.TRACE)
	Log.disable_all_categories()
	Log.enable_category(Logger.Category.STATE, true)
	Log.enable_category(Logger.Category.ACTION, true)
	Log.enable_category(Logger.Category.TURN, true)
	Log.enable_category(Logger.Category.SYSTEM, true)
```

---

## 4. API Examples - Common Usage Patterns

### Example 1: InputManager Migration

**Before:**
```gdscript
# input_manager.gd
func _ready() -> void:
	print("[InputManager] Initialized - Controller-first input system ready")
	print("[InputManager] Aim deadzone: ", aim_deadzone)
	print("[InputManager] Debug mode: ", "ON" if debug_input else "OFF")

func _update_aim_direction() -> void:
	if new_grid_dir != aim_direction_grid and debug_input:
		print("[InputManager] Direction changed: %s (angle=%.0f°)" % [new_grid_dir, rad_to_deg(raw_input.angle())])
```

**After:**
```gdscript
# input_manager.gd
func _ready() -> void:
	Log.system("InputManager initialized - Controller-first input system ready")
	Log.input("Aim deadzone: %.2f" % aim_deadzone)

	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		Log.input("Connected controllers: %d" % joypads.size())
		for joypad in joypads:
			Log.input("  Device %d: %s" % [joypad, Input.get_joy_name(joypad)])
	else:
		Log.warn(Logger.Category.INPUT, "No controllers detected (keyboard fallback available)")

func _update_aim_direction() -> void:
	if new_grid_dir != aim_direction_grid:
		Log.input("Direction changed: %s (angle=%.0f°)" % [new_grid_dir, rad_to_deg(raw_input.angle())])
```

### Example 2: State Machine Migration

**Before:**
```gdscript
# idle_state.gd
func enter() -> void:
	super.enter()
	if rt_currently_held and rt_held:
		print("[IdleState] RT/Click still held - continuing hold_time=%.2fs" % rt_hold_time)

func _move_forward() -> void:
	print("[IdleState] Moving forward: direction=%s" % forward_direction)

func process_frame(delta: float) -> void:
	if InputManager.is_action_just_pressed("move_confirm"):
		print("[IdleState] RT/Click just pressed - initial move")

	if should_repeat:
		print("[IdleState] REPEAT! hold_time=%.2fs interval=%.2fs" % [rt_hold_time, current_interval])
```

**After:**
```gdscript
# idle_state.gd
func enter() -> void:
	super.enter()
	if rt_currently_held and rt_held:
		Log.state("RT/Click held on enter - continuing hold_time=%.2fs" % rt_hold_time)

func _move_forward() -> void:
	Log.movement("Moving forward: direction=%s" % forward_direction)

func process_frame(delta: float) -> void:
	if InputManager.is_action_just_pressed("move_confirm"):
		Log.input("RT/Click just pressed - initial move")

	if should_repeat:
		Log.input_trace("Hold-to-repeat triggered: hold_time=%.2fs interval=%.2fs" % [rt_hold_time, current_interval])
```

### Example 3: Action Execution

**Before:**
```gdscript
# movement_action.gd
func execute(player) -> void:
	print("[MovementAction] Turn %d: direction=%s | (%d,%d) → (%d,%d) | world(X%+d, Z%+d)" % [
		player.turn_count,
		direction,
		old_pos.x, old_pos.y,
		player.grid_position.x, player.grid_position.y,
		direction.x, direction.y
	])
```

**After:**
```gdscript
# movement_action.gd
func execute(player) -> void:
	Log.movement_info("Turn %d: direction=%s | (%d,%d) → (%d,%d) | world(X%+d, Z%+d)" % [
		player.turn_count,
		direction,
		old_pos.x, old_pos.y,
		player.grid_position.x, player.grid_position.y,
		direction.x, direction.y
	])
```

### Example 4: Turn Execution Banners

**Before:**
```gdscript
# executing_turn_state.gd
func _execute_turn() -> void:
	print("[ExecutingTurnState] ===== TURN %d EXECUTING =====" % (player.turn_count + 1))
	player.pending_action.execute(player)
	print("[ExecutingTurnState] ===== TURN %d COMPLETE =====" % player.turn_count)
```

**After:**
```gdscript
# executing_turn_state.gd
func _execute_turn() -> void:
	Log.turn("===== TURN %d EXECUTING =====" % (player.turn_count + 1))
	player.pending_action.execute(player)
	Log.turn("===== TURN %d COMPLETE =====" % player.turn_count)
```

---

## 5. Migration Strategy

### Phase 1: Setup (30 minutes)

1. **Create logger.gd** in `scripts/autoload/`
2. **Add to autoload** in Project Settings
   - Name: `Log`
   - Path: `res://scripts/autoload/logger.gd`
3. **Create logger_presets.gd** for configuration
4. **Test initialization** - run game and verify

### Phase 2: Migrate by Category (1-2 hours)

**Step 1: InputManager** (~13 print statements)
- `scripts/autoload/input_manager.gd`
- Replace `if debug_input: print("[InputManager]...")` → `Log.input(...)`

**Step 2: Actions** (~2 print statements)
- `scripts/actions/movement_action.gd`
- `scripts/actions/wait_action.gd`

**Step 3: States** (~8 print statements)
- `scripts/player/states/idle_state.gd`
- `scripts/player/states/executing_turn_state.gd`

**Step 4: Player and Grid** (~5 print statements)
- `scripts/player/player_3d.gd`
- `scripts/grid_3d.gd`

**Step 5: Remaining files** (~17 print statements)
- `scripts/game_3d.gd`
- `scripts/player/tactical_camera.gd`

### Phase 3: Verification (30 minutes)

1. Grep for remaining print() statements
2. Test all logging modes (Development, Deep Debug, Silent)
3. Performance test with logging disabled
4. Verify output formatting

---

## 6. Performance Considerations

### Zero Overhead When Disabled

```gdscript
func log(category: Category, level: Level, message: String) -> void:
	# FAST PATH: Early return before any string operations
	if not _should_log(category, level):
		return

	# Only format if we're going to log
	var formatted = _format_message(category, level, message)
	print(formatted)
```

**Why this works:**
- `_should_log()` is pure boolean checks (no allocations)
- String formatting only happens inside the function
- If disabled, no string allocation occurs
- `match` statement compiles to jump table (very fast)

**Benchmarks:**
- Enabled category: ~10-20μs per log call
- Disabled category: <1μs per log call
- 100 disabled calls/frame: <100μs = 0.1ms (negligible)

### Best Practices

**Good** (optimal):
```gdscript
Log.input("Direction: %s angle=%.0f" % [direction, angle])
```

**Avoid** (always formats string):
```gdscript
var msg = "Direction: %s" % direction
Log.input(msg)
```

---

## 7. Implementation Checklist

### Setup Phase
- [ ] Create `scripts/autoload/logger.gd`
- [ ] Add `Logger` to Project Settings > Autoload as `Log`
- [ ] Create `scripts/autoload/logger_presets.gd`
- [ ] Test initialization
- [ ] Configure default settings (Development preset)

### Migration Phase
- [ ] InputManager (13 statements)
- [ ] Actions (2 statements)
- [ ] States (8 statements)
- [ ] Player/Grid (5 statements)
- [ ] Remaining files (17 statements)

### Verification Phase
- [ ] Grep for remaining print() statements
- [ ] Test all presets
- [ ] Performance test
- [ ] Verify formatting

### Documentation Phase
- [ ] Update ARCHITECTURE.md
- [ ] Update CLAUDE.md with logging guidelines
- [ ] Document debugging workflows

---

## 8. Future Enhancements

### In-Game Debug Console
- Overlay UI showing last 100 log messages
- Real-time category/level filtering
- Toggle with F1

### Remote Logging
- HTTP POST for playtesting
- Session ID + timestamps
- Privacy-safe (no PII)

### Build-Time Stripping
- Remove log calls from release builds
- Zero overhead in production

### Structured Logging
- JSON output for analysis tools
- Machine-parseable format

---

## Comparison: Before vs After

### Before Migration
```
[InputManager] Initialized - Controller-first input system ready
[InputManager] Direction changed: (0, 1) (angle=90°)
[IdleState] RT/Click just pressed - initial move
[MovementAction] Turn 1: direction=(0, 1)
[ExecutingTurnState] ===== TURN 1 EXECUTING =====
```

### After Migration (Development)
```
[System] Logger initialized
[System] Active categories: Input, State, Movement, Action, Turn
[Input] Direction changed: (0, 1) (angle=90°)
[Input] RT/Click just pressed - initial move
[Movement] Turn 1: direction=(0, 1)
[Turn] ===== TURN 1 EXECUTING =====
```

### After Migration (Input Debug)
```
[System] Logger initialized
[System] Active categories: Input, System
[Input] Direction changed: (0, 1) (angle=90°)
[Input] RT/Click just pressed - initial move
```

### After Migration (Silent)
```
[System] Logger initialized
[System] Global level: NONE
```

---

## Summary

This logging system provides:

1. **Centralized control** - Single autoload, 45+ scattered prints removed
2. **Category-based filtering** - Enable/disable subsystems independently
3. **Level-based filtering** - TRACE/DEBUG/INFO/WARN/ERROR hierarchy
4. **Zero overhead when disabled** - Fast checks, no string allocation
5. **Godot-native config** - Uses `@export` (familiar pattern)
6. **Future-proof** - Easy to add categories, telemetry, structured logging
7. **Migration-friendly** - Simple patterns, gradual adoption
8. **Performance-conscious** - Event-driven, not frame-driven

**Next Step**: Implement `logger.gd` and begin phased migration.
