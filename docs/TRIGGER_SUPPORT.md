# Trigger Support Implementation Plan

**Status**: Planning
**Created**: 2025-11-08
**Issue**: Xbox controller triggers (LT/RT) are analog axes, not digital buttons. Need proper support.

---

## Problem Statement

Modern controllers have **analog triggers** (LT/RT on Xbox) that send axis data (0.0-1.0), not button presses. Our current input system only handles digital buttons properly.

**Current workaround**: Added axis mapping to `move_confirm` action in project.godot
**Why it's not sufficient**:
- Doesn't centralize trigger logic in InputManager (violates architecture)
- Can't expose trigger analog values for future features
- Scattered configuration (some in project.godot, some in InputManager)
- Hard to add features like trigger sensitivity, deadzone tuning, etc.

---

## Goals

1. **Centralize all input logic in InputManager** (including triggers)
2. **Expose triggers as both analog and digital** values
3. **Maintain controller-first design** - triggers should "just work"
4. **Keep existing architecture** - don't break state machine/action patterns
5. **Future-proof** for features like:
   - Variable trigger sensitivity
   - Trigger-based abilities (e.g., hold LT to aim, RT pressure = attack strength)
   - Rebinding/accessibility options

---

## Design Options

### Option A: InputManager Synthesizes Trigger Button Events

**Approach:**
- InputManager reads trigger axes directly
- When trigger > threshold, treat as "button pressed"
- Expose through existing API: `is_action_just_pressed("move_confirm")`
- Game code unchanged, just works

**Pros:**
- Minimal changes to existing code
- States/actions don't need to know about triggers vs buttons
- Clean abstraction

**Cons:**
- Can't expose analog trigger values easily
- Tied to action names instead of generic "left trigger", "right trigger"

### Option B: InputManager Exposes Triggers Directly

**Approach:**
- Add trigger-specific API:
  - `get_trigger_value(trigger: String) -> float` (0.0-1.0)
  - `is_trigger_pressed(trigger: String) -> bool` (> threshold)
  - `is_trigger_just_pressed(trigger: String) -> bool`
- States query triggers directly: `InputManager.is_trigger_just_pressed("right")`
- Remove trigger from action mapping, handle purely in code

**Pros:**
- Full control over trigger behavior
- Can expose both analog and digital
- Very explicit in code what's being checked

**Cons:**
- States need to know "right trigger confirms movement" (less data-driven)
- Have to update state code to use new API

### Option C: Hybrid - Triggers in InputManager, Actions Stay

**Approach:**
- InputManager tracks trigger state internally
- Still map to actions in project.godot for high-level semantics
- InputManager provides BOTH:
  - Action API: `is_action_just_pressed("move_confirm")` (works for buttons + triggers)
  - Trigger API: `get_trigger_value("left")` (for future analog features)

**Pros:**
- Best of both worlds
- States use actions (semantic: "confirm move")
- Can add analog features later without changing states
- Centralized but flexible

**Cons:**
- More code to write
- Slightly more complex

---

## Recommended Approach: **Option C (Hybrid)**

**Rationale:**
- Maintains existing architecture (states use actions)
- Centralizes trigger logic in InputManager
- Enables future analog features without refactoring
- Controller-first: triggers work transparently
- Follows design principle: "clean abstractions that scale"

---

## Implementation Plan

### Phase 1: Read Trigger Axes in InputManager

**File**: `/scripts/autoload/input_manager.gd`

**Add:**
```gdscript
# Trigger configuration
const TRIGGER_THRESHOLD: float = 0.5  # Treat as "pressed" above this
const TRIGGER_AXIS_LEFT: int = 4      # Xbox LT axis
const TRIGGER_AXIS_RIGHT: int = 5     # Xbox RT axis

# Trigger state
var left_trigger_value: float = 0.0
var right_trigger_value: float = 0.0
var left_trigger_pressed: bool = false
var right_trigger_pressed: bool = false
var _left_trigger_just_pressed: bool = false
var _right_trigger_just_pressed: bool = false
```

**Update `_process()`:**
```gdscript
func _process(_delta: float) -> void:
    # Clear frame-based state
    _actions_this_frame.clear()
    _left_trigger_just_pressed = false
    _right_trigger_just_pressed = false

    # Read triggers
    _update_triggers()

    # Update aim direction
    _update_aim_direction()
```

**Add `_update_triggers()`:**
```gdscript
func _update_triggers() -> void:
    # Read raw axis values
    left_trigger_value = Input.get_joy_axis(0, TRIGGER_AXIS_LEFT)
    right_trigger_value = Input.get_joy_axis(0, TRIGGER_AXIS_RIGHT)

    # Convert to digital state
    var left_now_pressed = left_trigger_value > TRIGGER_THRESHOLD
    var right_now_pressed = right_trigger_value > TRIGGER_THRESHOLD

    # Track just_pressed (transition from not pressed -> pressed)
    _left_trigger_just_pressed = left_now_pressed and not left_trigger_pressed
    _right_trigger_just_pressed = right_now_pressed and not right_trigger_pressed

    # Update pressed state
    left_trigger_pressed = left_now_pressed
    right_trigger_pressed = right_now_pressed

    # Synthesize action events for triggers
    if _right_trigger_just_pressed:
        _actions_this_frame["move_confirm"] = true
        if debug_input:
            print("[InputManager] Right trigger pressed -> move_confirm")
```

**Complexity**: ~15 minutes
- Read axes
- Track state transitions
- Synthesize action events

---

### Phase 2: Expose Trigger API

**Add public API to InputManager:**
```gdscript
## Get raw trigger value (0.0 to 1.0)
func get_trigger_value(trigger: String) -> float:
    match trigger.to_lower():
        "left", "lt": return left_trigger_value
        "right", "rt": return right_trigger_value
    return 0.0

## Check if trigger is currently pressed (above threshold)
func is_trigger_pressed(trigger: String) -> bool:
    match trigger.to_lower():
        "left", "lt": return left_trigger_pressed
        "right", "rt": return right_trigger_pressed
    return false

## Check if trigger was just pressed this frame
func is_trigger_just_pressed(trigger: String) -> bool:
    match trigger.to_lower():
        "left", "lt": return _left_trigger_just_pressed
        "right", "rt": return _right_trigger_just_pressed
    return false
```

**Complexity**: ~5 minutes
- Simple getter methods

---

### Phase 3: Remove Axis from project.godot (Clean Up)

**Revert `move_confirm` action to just button + keyboard:**
```gdscript
move_confirm={
"deadzone": 0.13,
"events": [Object(InputEventKey, ...)]  # Just SPACE key
}
```

**Why**: Trigger logic now fully in InputManager, don't need axis in action map

**Complexity**: ~2 minutes
- Just remove the axis event object

---

### Phase 4: Test & Validate

**Test cases:**
1. Press RT -> movement executes (digital trigger detection works)
2. Check `InputManager.get_trigger_value("right")` shows 0.0-1.0
3. Both controller and keyboard (SPACE) work identically
4. Debug logs show trigger events

**Complexity**: ~5-10 minutes (your testing time)

---

### Phase 5: Update Documentation

**Update ARCHITECTURE.md:**
- Add trigger support to InputManager section
- Document trigger API
- Explain hybrid approach (actions + direct trigger access)

**Complexity**: ~5 minutes

---

## Total Time Estimate: 30-45 minutes

**Breakdown:**
- Phase 1 (read triggers): 15 min
- Phase 2 (API): 5 min
- Phase 3 (cleanup): 2 min
- Phase 4 (testing): 5-10 min
- Phase 5 (docs): 5 min
- **Contingency**: 5-10 min for unexpected issues

**What could reduce this?**
- Skip Phase 2 if we only need action synthesis (not analog API) → Save 5 min
- Skip Phase 5 for now, document later → Save 5 min
- **Minimum viable**: Just Phase 1 + Phase 3 = ~20 minutes

---

## Future Enhancements

Once this is working, we can add:

1. **Configurable trigger sensitivity**
   ```gdscript
   InputManager.set_trigger_threshold(0.3)  # More sensitive
   ```

2. **Per-trigger thresholds**
   ```gdscript
   InputManager.set_trigger_threshold("left", 0.3)
   InputManager.set_trigger_threshold("right", 0.7)
   ```

3. **Analog-based features**
   - Hold trigger partially for "aim mode", fully for "fire"
   - Trigger pressure controls ability strength
   - Racing game-style throttle control

4. **Input rebinding UI**
   - User can remap "confirm move" to LB, RT, face button, etc.
   - Trigger mappings stored in InputManager, not hardcoded

---

## Questions to Resolve

1. **Should we synthesize trigger events only for specific actions, or generically?**
   - Current plan: Only for `move_confirm` (right trigger)
   - Alternative: Any action mapped to triggers auto-synthesizes

2. **What should LT (left trigger) do?**
   - Currently unmapped
   - Suggestions: Examine mode? Ability targeting? Wait/pass turn?

3. **Should trigger threshold be configurable per-action or global?**
   - Current plan: Global threshold (0.5)
   - Future: Per-action thresholds for fine control

---

## Success Criteria

✅ Right trigger (RT) executes movement when pressed
✅ Trigger logic centralized in InputManager
✅ Can expose analog trigger values for future features
✅ Keyboard (SPACE) still works identically
✅ Debug logs show trigger state clearly
✅ No breaking changes to existing state/action code

---

**Next Steps**: Review this plan, answer questions, then implement Phase 1-3 in one go.
