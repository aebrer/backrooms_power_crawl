# CLAUDE.md - Guide for Future Claude Instances

**Project**: Backrooms Power Crawl - Turn-based Roguelike in Godot 4.x
**Developer**: Drew Brereton (aebrer) - Python/generative art background, new to game dev
**Last Updated**: 2025-11-08

---

## 1. Behavioral Patterns Observed

### What Worked Well

**Thoughtful Architecture First**
- User requested careful architecture planning before implementation
- Three-layer system (InputManager → State Machine → Actions) was discussed thoroughly
- Each component has clear separation of concerns
- Clean abstractions that will scale for future features

**Comprehensive Documentation**
- User values thorough documentation in code (docstrings, comments)
- Commit messages are detailed with rationale, not just "what" but "why"
- Architecture diagrams in ARCHITECTURE.md show visual representations
- Everything is well-explained for future maintainers

**Iterative, Test-First Approach**
- User wants to TEST before committing
- Build one system at a time, validate it works, then move on
- No rush to ship - quality over speed
- "Ready for testing" means actual human testing, not assumptions

### What Issues Occurred

**Premature Commit Attempt**
- In initial session, there was a rush to commit before user could test
- User explicitly said "I want to test this first"
- **LESSON**: NEVER commit until user explicitly confirms testing is complete and successful
- User will say "okay let's commit this" when ready

**Assumption About Game Dev Knowledge**
- User is experienced in Python/generative art but NEW to game dev
- Don't assume knowledge of Godot-specific patterns or game dev terminology
- Explain concepts clearly, reference Python equivalents when helpful
- Example: "State Machine is like a dict of handler functions that switch based on current mode"

### User Preferences & Working Style

**Open Source Ethos**
- User cares deeply about open source principles
- Code will be published under GPL-friendly license
- Chose Godot specifically because it's FOSS
- Document everything as if teaching others

**Deliberate, Thoughtful Development**
- User takes time to understand architecture before building
- Questions decisions ("why this pattern vs that one?")
- Values clean, maintainable code over quick hacks
- Thinks in systems, not features

**Controller-First Design**
- User is building for controller from day one
- Keyboard is fallback, not primary
- Test with actual controller hardware
- Input abstraction is critical

**Python Background Benefits**
- GDScript is Python-like, so user picks it up quickly
- User thinks in classes, objects, and clean APIs
- Functional programming concepts familiar (e.g., command pattern)
- Can reference Python patterns when explaining Godot concepts

---

## 2. Design Patterns & Architecture

### Current Implemented Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   RAW INPUT LAYER                           │
│  Controller / Keyboard → Godot Input Actions                │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│              INPUTMANAGER (Autoload)                        │
│  - Device abstraction (controller + keyboard identical)     │
│  - Deadzone handling (radial, 0.2 default)                  │
│  - Analog → 8-direction grid conversion (angle-based)       │
│  - Action tracking for frame-based queries                  │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│              STATE MACHINE LAYER                            │
│  Player → InputStateMachine → Current State                 │
│    States: IdleState, AimingMoveState, ExecutingTurnState   │
│  - State-specific input handling                            │
│  - Turn boundaries explicit                                 │
│  - Queries InputManager for normalized input                │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│              ACTION LAYER (Command Pattern)                 │
│  States create Actions → Actions validate & execute         │
│    Actions: MovementAction, WaitAction, (future: others)    │
│  - Decouples input from execution                           │
│  - Enables replays, AI, undo (future)                       │
└─────────────────────────────────────────────────────────────┘
```

### Why These Patterns Were Chosen

**InputManager (Singleton/Autoload)**
- **Why**: Centralize input handling, normalize controller + keyboard
- **Alternative Rejected**: Per-node input handling (too scattered, hard to debug)
- **Benefits**: Single source of truth, easy testing, device abstraction
- **Future-proof**: Can add replay system, input remapping, accessibility features

**State Machine**
- **Why**: Turn-based game has distinct input modes (aiming, executing, examining)
- **Alternative Rejected**: Giant if/else in player script (unmaintainable)
- **Benefits**: Clear turn boundaries, easy to add new modes (examine, ability targeting)
- **Pattern**: Each state is isolated, transitions explicit via signals

**Command Pattern (Actions)**
- **Why**: Decouple "what player wants" from "how it executes"
- **Alternative Rejected**: Direct execution in state handlers (can't replay, undo, or reuse for AI)
- **Benefits**: AI can use same actions, replays possible, undo in future
- **Pattern**: Validate before execute, immutable action objects

### Key Design Decisions

**Turn-Based, Not Real-Time**
- Deliberate, tactical gameplay like Caves of Qud
- Fast when confident, slow when cautious
- Allows for examination mode without time pressure
- **Never** add real-time pressure unless explicitly designed (e.g., resource drain over turns, not seconds)

**Controller-First, Not Controller-Optional**
- Left stick aims, R2 confirms (committed movement)
- WASD + Space as fallback for keyboard users
- All inputs have BOTH controller and keyboard mappings
- **Test with controller** before considering a feature "done"

**8-Way Grid Movement**
- Angle-based conversion for clean diagonals
- Radial deadzone (0.2) prevents drift
- No free analog movement - snaps to 8 directions
- **Why**: Grid-based tactics require precise direction input

**Viewport Culling from Day One**
- 128x128 grid = 16,384 tiles (would crash without culling)
- Only render ~400 tiles around player
- Update on player movement
- **Performance**: Scalability built in from start, not bolted on later

---

## 3. Important Documentation Locations

### Design Documents

- **`/home/andrew/projects/backrooms_power_crawl/docs/DESIGN.md`**
  - Core game concept and vision
  - Inspirations: Caves of Qud, Vampire Survivors, SCP/Backrooms
  - Mission types (Horde vs Hunt)
  - Progression philosophy (knowledge-based, no meta-progression)
  - Control scheme and design philosophy
  - Open questions and decisions still being made

- **`/home/andrew/projects/backrooms_power_crawl/docs/ARCHITECTURE.md`**
  - Technical architecture and patterns
  - **Top section (✅ Implemented)**: Current working systems
  - **Bottom section (🔮 Planned)**: Future systems design
  - File structure and organization
  - Code examples and API documentation
  - Update this when implementing new systems

- **`/home/andrew/projects/backrooms_power_crawl/README.md`**
  - Project overview and setup
  - High-level feature list
  - Development philosophy
  - Quick reference for new contributors

### Key Files and Their Purposes

**Autoloads (Singletons)**
- `/scripts/autoload/input_manager.gd` - Input normalization and device abstraction

**Player System**
- `/scripts/player/player.gd` - Player controller, visual representation, grid position
- `/scripts/player/input_state_machine.gd` - State manager, delegates to current state
- `/scripts/player/states/player_input_state.gd` - Base state class with transition signals
- `/scripts/player/states/idle_state.gd` - Waiting for input
- `/scripts/player/states/aiming_move_state.gd` - Aiming movement with preview
- `/scripts/player/states/executing_turn_state.gd` - Processing turn actions

**Actions (Command Pattern)**
- `/scripts/actions/action.gd` - Base action class
- `/scripts/actions/movement_action.gd` - Grid movement with validation
- `/scripts/actions/wait_action.gd` - Pass turn without moving

**Core Systems**
- `/scripts/grid.gd` - Map data, tile rendering, viewport culling
- `/scripts/game.gd` - Main game scene coordinator

**Scenes**
- `/scenes/game.tscn` - Main gameplay scene
- `/scenes/main_menu.tscn` - Menu (placeholder)

---

## 4. User Preferences & Context

### User Background

**Python + Generative Art Expert**
- Comfortable with OOP, functional patterns, clean architecture
- Understands abstractions, design patterns, separation of concerns
- **Caveat**: New to game development and Godot specifically

**What This Means for You**
- Use Python analogies when helpful ("Autoload is like a module-level singleton")
- Don't over-explain OOP concepts, user gets those
- DO explain game-dev-specific concepts (scene trees, nodes, signals)
- DO explain Godot-specific patterns (resources, autoloads, exported vars)

### User's Ethos

**Open Source & Thoughtful Design**
- Chose Godot because it's FOSS, not despite it
- Code quality matters - this will be published
- Document for future contributors and learners
- Prefer clean patterns over clever hacks

**Deliberate Development**
- Think before coding, plan before implementing
- One system at a time, fully tested before moving on
- No arbitrary deadlines, no rushed features
- "Done" means tested and documented, not just "compiles"

### Communication Style Preferences

**Clear and Detailed**
- User asks "why" questions - explain rationale, not just "what"
- Provide context: "We use X instead of Y because..."
- Reference design docs when making decisions
- Be explicit about tradeoffs

**No Condescension**
- User is new to game dev, not new to programming
- Don't explain basic programming concepts unless asked
- DO explain Godot-specific or game-dev-specific patterns
- Assume competence, provide context

**Collaborative, Not Prescriptive**
- Present options, explain tradeoffs, let user decide
- "We could do X (pros/cons) or Y (pros/cons), what do you think?"
- User will often ask follow-up questions before deciding
- Respect the user's vision - this is their project

### Testing & Validation Approach

**Test Before Commit**
- User wants to actually TEST the code with controller in hand
- **NEVER** rush to commit before testing
- Wait for user to say "this works, let's commit"
- If user says "let me test this first", STOP and WAIT

**Controller Testing**
- User tests on real hardware (Xbox controller likely)
- Keyboard fallback also tested
- Debug logging helps user understand what's happening
- `InputManager.debug_input` flag is user's friend

---

## 5. Common Pitfalls to Avoid

### Don't Commit Before User Tests

**THE CARDINAL SIN**: Rushing to commit before user validates
- User explicitly values testing before committing
- Wait for user to say "okay this works" or "let's commit"
- Even if code looks perfect, user wants hands-on validation
- **Correct flow**: Implement → User tests → User approves → Create commit

### Don't Make Game Dev Assumptions

**User is learning game development**
- Explain Godot patterns: nodes, scenes, signals, resources
- Explain game dev concepts: state machines, command pattern, ECS
- Don't assume knowledge of common game dev terminology
- **DO** reference Python equivalents when helpful

### Don't Skip Architecture Updates

**Keep ARCHITECTURE.md current**
- When implementing systems, update the "✅ Implemented" section
- Move planned features from "🔮 Planned" to "✅ Implemented"
- Keep file structure diagrams accurate
- Document architectural decisions and rationale

### Don't Add Features Not in Design Docs

**Stick to the vision**
- DESIGN.md defines the game's scope and philosophy
- Don't add features that contradict design goals
- If suggesting new features, reference design docs
- Ask user before deviating from documented plans

### Don't Forget Controller-First

**Keyboard is fallback, not primary**
- Every feature must work with controller
- Test scenarios with controller in mind
- Input mappings must have BOTH controller and keyboard
- If designing UI, design for controller navigation first

### Don't Use Real-Time Where Turn-Based Belongs

**This is a turn-based game**
- NO `delta` time for gameplay logic (only for animations/polish)
- NO continuous movement or real-time reactions
- Pressure comes from resources/escalation, not timers
- Each action is discrete and turn-based

---

## 6. Next Steps / TODO

### Working but Needs Testing

**Current Implementation (Phase 1)**
- ✅ InputManager implemented (needs controller testing)
- ✅ State Machine implemented (needs validation)
- ✅ Action Pattern implemented (needs testing in gameplay)
- ✅ Grid with viewport culling (needs performance testing)
- ⏳ **USER TESTING IN PROGRESS** - waiting for validation

### Known Issues to Address

**After User Testing**
- Movement feel (is 8-way snapping comfortable?)
- Indicator visibility (green arrow clear enough?)
- Debug logging (too verbose? Just right?)
- Turn counter UI (shows state, but is it useful?)

### Future Features Planned

**Phase 2: Examination Mode**
- Add ExamineState to state machine
- Right stick moves examine cursor
- Show SCP-style tooltips for tiles/entities
- Knowledge database integration

**Phase 3: Automatic Abilities**
- Ability system (toggleable with RB/LB/X/Y)
- Auto-proc conditions (on move, on nearby enemy, interval)
- Ability activation during ExecutingTurnState
- Resource management (stamina, sanity)

**Phase 4: Enemy AI**
- Entity spawning system
- Basic pathfinding (A* or simpler)
- Turn queue (player, enemy1, enemy2, etc.)
- Entity actions using same Action system

**Phase 5: Physics Simulation**
- Liquid spreading and mixing
- Temperature simulation
- Material interactions
- Emergent gameplay possibilities

### Long-Term Vision

**See docs/DESIGN.md for full roadmap**
- Hub area with NPCs
- Mission types (Horde vs Hunt)
- Knowledge/examination system
- Containment mechanics
- Visual corruption shaders
- Audio integration

---

## 7. Example Interactions

### Good Interaction Pattern

**User**: "I want to add an examine mode where you can look around with the right stick"

**You**: "Great! That fits perfectly into the state machine architecture. Here's how we'd approach it:

1. Create `ExamineState` in `/scripts/player/states/`
2. Add transition from `IdleState` when examine button held
3. Use `InputManager` to read right stick direction
4. Show cursor at grid position + stick offset
5. Display tooltip for tile under cursor

This follows the same pattern as `AimingMoveState`. The state handles input, updates cursor position, and shows UI. When examine button released, transition back to `IdleState`.

Should I implement this, or do you want to discuss the tooltip system first?"

### Bad Interaction Pattern (DON'T DO THIS)

**User**: "I want to add an examine mode"

**You**: "Sure, I'll add that now. *implements entire system* Okay it's done, let me commit this."

**Why it's bad**:
- No discussion of approach
- No architectural explanation
- Assumes user wants immediate implementation
- Rushes to commit without testing

---

## 8. Godot-Specific Patterns for This Project

### Autoload Singletons

**What**: Globally accessible nodes (like `InputManager`)
**When**: For cross-cutting concerns (input, audio, game state)
**How**: Add to Project Settings → Autoload
**Why**: Avoid passing references everywhere, single source of truth

### State Pattern with Nodes

**What**: States as child nodes of state machine
**When**: Complex input modes or behavior changes
**How**: Base class with enter/exit/process, register children in _ready()
**Why**: Godot's scene tree makes this natural, easy to debug

### Command Pattern with RefCounted

**What**: Actions as lightweight objects (extend RefCounted)
**When**: Discrete game actions (move, attack, interact)
**How**: can_execute() validates, execute() performs action
**Why**: Decouples input from execution, enables AI/replays

### Viewport Culling

**What**: Only render tiles near player
**When**: Large grids that exceed performance budget
**How**: Calculate visible rect, only update those tiles
**Why**: 128x128 grid = 16k tiles, but only ~400 visible

---

## 9. Communication Templates

### When Explaining Godot Concepts

"In Godot, [concept] works like this: [explanation]. This is similar to [Python equivalent] that you're familiar with. In our project, we use it for [specific purpose]."

**Example**: "In Godot, signals are like event emitters or callbacks. They're similar to Python's signal/slot pattern or observer pattern. In our project, we use them for state transitions - when a state wants to change, it emits `state_transition_requested` which the state machine catches."

### When Proposing Architectures

"For [feature], we have a few options:

**Option A**: [Approach]
- Pros: [benefits]
- Cons: [drawbacks]
- Fits with: [existing patterns]

**Option B**: [Alternative approach]
- Pros: [benefits]
- Cons: [drawbacks]
- Fits with: [existing patterns]

Based on our design goals of [relevant goals from DESIGN.md], I'd recommend [choice] because [rationale]. What do you think?"

### When Ready to Commit

"This implementation is complete and ready for testing. When you've validated it works with your controller:

**What was implemented**:
- [Feature list]

**How to test**:
- [Test steps]

**Expected behavior**:
- [What should happen]

Let me know if you find any issues, or if it works as expected and you'd like to commit."

---

## 10. Quick Reference

### File Naming Conventions
- Scripts: `snake_case.gd`
- Scenes: `snake_case.tscn`
- Classes: `PascalCase` (class_name declaration)
- Constants: `UPPER_SNAKE_CASE`

### Project Structure
```
/home/andrew/projects/backrooms_power_crawl/
├── docs/              # Design and architecture docs (READ THESE!)
├── scenes/            # .tscn files
├── scripts/           # .gd files
│   ├── autoload/      # Singleton systems
│   ├── actions/       # Command pattern actions
│   ├── player/        # Player controller and states
│   └── [systems]/     # Future: grid, entities, etc.
├── assets/            # Art, audio, fonts (future)
└── data/              # JSON configs (future)
```

### When to Update Documentation
- **ARCHITECTURE.md**: After implementing any system
- **DESIGN.md**: After major design decisions
- **README.md**: After setup changes or new requirements
- **This file (CLAUDE.md)**: After learning new user preferences or patterns

### Commit Message Format

User values detailed commit messages:
- Concise title (what was done)
- Paragraph explaining why and how
- Bullet points for specific changes
- File structure changes
- Testing notes
- "🤖 Generated with Claude Code" footer (auto-added)

---

## Final Notes

**This project is a learning journey** - user is learning game dev, you're helping them build good habits and understanding. Take time to explain, be patient with questions, and respect the deliberate pace.

**Quality over speed** - no deadlines, no rush. Each system should be thoughtful, tested, and documented before moving on.

**Test before commit** - seriously, this is the most important lesson. User will tell you when they're ready to commit.

**Stay true to the vision** - read DESIGN.md to understand the game's goals. Don't suggest features that contradict the core vision.

Good luck, future Claude! This is a fascinating project with a thoughtful developer. Take your time, explain well, and build something great together.

---

**Generated**: 2025-11-08 by Claude Code reviewing initial architecture implementation session
