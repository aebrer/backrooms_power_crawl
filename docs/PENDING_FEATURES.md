# Pending Features - Backrooms Power Crawl

**Last Updated**: 2025-11-09
**Status**: Design Notes for Future Implementation

---

## Player Character Visual

### Concept
Billboard sprite of a person in a hazmat suit. Simple, iconic, maintains PSX aesthetic.

### Technical Approach
- **Rendering**: Billboard sprite (always faces camera)
- **Texture**: Procedurally generated or hand-drawn, then rendered on a plane
- **Size**: Small texture (64×64 or 128×128)
- **Style**: PSX low-poly aesthetic, simple silhouette
- **Colors**: Muted yellows/grays to contrast with environment
- **Animation**: Optional - could have idle breathing or simple frame animation

### Texture Generation Options

**Option 1: Multi-Agent Workflow** (like wallpaper/carpet)
- Describe hazmat suit appearance
- Generate with Python/PIL
- Iterate with critics
- Pros: Consistent with existing workflow
- Cons: Hazmat suit might need more precision than procedural allows

**Option 2: Simple Shapes**
- Draw programmatically (rectangle body, circle helmet, etc.)
- Add noise/grain for PSX feel
- Pros: Fast, guaranteed recognizable
- Cons: Less organic, might look too geometric

**Option 3: Find reference + trace**
- Find CC0 hazmat suit reference image
- Simplify to silhouette
- Apply PSX treatment
- Pros: Realistic proportions
- Cons: Manual work required

### Implementation Notes

**Scene Setup**:
```gdscript
# In player.tscn
Player (CharacterBody3D)
└── Sprite3D (billboard)
    └── material: PSX shader with alpha_scissor
    └── texture: hazmat_suit.png
```

**Shader Considerations**:
- Use `psx_base.gdshaderinc` with `ALPHA_SCISSOR` flag
- `billboard = true` for always-face-camera
- `y_billboard = true` if we only want horizontal rotation (feet stay on ground)

**Current Status**: Not yet started
**Priority**: Medium (visual polish, not gameplay critical)
**Dependencies**: None
**Estimated Time**: 2-3 hours (texture generation + integration)

---

## Action Preview UI

### Concept
Real-time UI element that shows what action will happen when the player presses RT/left-click. Updates dynamically based on what the player is highlighting/looking at.

### Design

**Location**: Right side of screen (or bottom-right corner)

**Example Display**:
```
┌─────────────────────────┐
│  [RT] Move Forward      │
│  ↑ Move to (12, 8)      │
└─────────────────────────┘

┌─────────────────────────┐
│  [RT] Wait              │
│  ⏸ Skip turn            │
└─────────────────────────┘

┌─────────────────────────┐
│  [RT] Attack            │
│  ⚔ Smiler (damaged)     │
└─────────────────────────┘

┌─────────────────────────┐
│  [RT] Examine           │
│  🔍 Yellow wallpaper    │
└─────────────────────────┘
```

### Information to Display

1. **Action Name**: "Move Forward", "Attack", "Wait", "Examine", etc.
2. **Target Info**: What/where the action affects
3. **Icon**: Visual indicator of action type
4. **Input**: Show RT (gamepad) or Left Click (mouse) - switch based on active input device

### Technical Implementation

**Architecture**:
```gdscript
# New UI element
ActionPreviewUI (Control)
├── _on_player_action_changed(action: Action) -> void
├── _update_display(action_name: String, target_info: String, icon: Texture) -> void
└── _get_current_input_icon() -> String  # "RT" or "Left Click"
```

**Integration Points**:
1. **AimingMoveState**: When movement target changes, emit signal with MovementAction preview
2. **IdleState**: When hovering over entity/item, emit signal with appropriate action
3. **ExamineState**: When cursor moves, emit signal with examine info
4. **InputManager**: Track which input device was last used (gamepad vs mouse)

**Signals**:
```gdscript
# In Player or InputStateMachine
signal action_preview_changed(action_name: String, target_info: String, action_icon: Texture)

# In InputManager
signal input_device_changed(device: InputDevice)  # GAMEPAD or MOUSE_KEYBOARD
```

**UI Layout**:
```
Right side panel:
┌────────────────┐
│ Turn: 42       │  ← Existing turn counter
│ Stamina: ███   │  ← Future resource bar
│                │
│ ┌────────────┐ │
│ │ [RT] Move  │ │  ← Action Preview (NEW)
│ │ ↑ (12, 8)  │ │
│ └────────────┘ │
└────────────────┘
```

### Edge Cases to Handle

1. **No action available**: Display "No action" or hide panel
2. **Multiple actions possible**: Show primary action (movement takes priority)
3. **Input device switching**: Update [RT] ↔ [Left Click] dynamically
4. **Rapid changes**: Debounce updates to avoid flickering
5. **Examine mode**: Show tile/entity info instead of action

### Visual Design

**Style**: Consistent with existing UI
- PSX aesthetic (chunky pixels, limited colors)
- Background: Semi-transparent dark panel
- Text: Monospace font, yellow/white
- Icons: Simple 16×16 sprites

**Animation**: Optional subtle fade when content changes

### Current Status
**Status**: Not yet started
**Priority**: High (improves gameplay clarity significantly)
**Dependencies**:
- Existing action system (✅ already implemented)
- UI framework (partially exists)
**Estimated Time**: 3-4 hours (UI setup + state integration + input device detection)

### Design Questions

1. **Show keyboard alternative?**: Display "[RT] / [Left Click]" simultaneously or switch based on last input?
   - **Recommendation**: Switch based on last input (cleaner UI)

2. **Show on gamepad only?**: Or also show for mouse users?
   - **Recommendation**: Show for both (helpful for all players)

3. **Position**: Right side, bottom-right, or configurable?
   - **Recommendation**: Bottom-right corner (least intrusive, near crosshair)

4. **Size**: Full action description or compact icon + short text?
   - **Recommendation**: Compact (icon + 1-2 words) to avoid clutter

---

## Implementation Priority

Based on gameplay impact:

1. **Action Preview UI** (High) - Significantly improves UX, clarifies turn-based input
2. **Player Character Texture** (Medium) - Visual polish, not gameplay-critical

---

## Notes for Future Claude Instances

### Player Texture
- User specifically mentioned "billboarding" - this is confirmed as the approach
- "Person in haz suit" - generic, not specific character
- Keep it simple and iconic
- Could use same multi-agent texture generation workflow as wallpaper/carpet

### Action Preview UI
- User wants "right side or something" - flexible on exact position
- "Real-time updates" - must respond instantly to player input/camera movement
- "What RT/left click will do" - shows the DEFAULT action (what happens if you click now)
- This connects to existing action system (MovementAction, WaitAction, etc.)
- Should respect input parity (show correct button for current input device)

---

**End of Document**
