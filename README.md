# Backrooms Power Crawl

A turn-based roguelike combining Caves of Qud's deep simulation and character building with Vampire Survivors' automatic combat and horde survival mechanics, set in the liminal horror of the Backrooms universe.

## Core Concept

Navigate the endless, reality-bending corridors of the Backrooms as a researcher. Choose between survival-focused horde missions or careful containment hunts. Build your character through mutations and anomalies while managing automatic abilities. Knowledge is your only persistent progression - learn entity patterns, discover optimal builds, and uncover the secrets of the Backrooms.

## Inspirations

- **Caves of Qud**: Deep simulation, mutation system, turn-based tactical gameplay
- **Vampire Survivors**: Automatic combat, toggleable abilities, build-focused gameplay
- **The Backrooms / SCP Foundation**: Liminal horror, entity documentation, knowledge progression

## Key Features

### Turn-Based Tactical Combat
- Deliberate, turn-based movement like Caves of Qud
- Fast when you're confident, slow when you're cautious
- Examine mode for studying entities and environment

### Automatic Ability System
- Toggle abilities on/off with controller buttons (RB, LB, X, Y)
- Abilities auto-proc based on conditions
- Tactical depth through ability management

### Dual Mission Types
- **Horde Missions**: Survive waves of entities, maximize damage
- **Hunt Missions**: Locate and contain specific entities without killing them
- Conflicting build priorities create meaningful choices

### Knowledge-Based Progression
- No arbitrary unlocks - progression is player knowledge
- SCP-style documentation with redacted information
- Clearance levels unlock info during runs
- Learn entity behaviors, weaknesses, and optimal strategies

### Physics Simulation
- Qud-inspired material interactions
- Liquids spread, mix, and create emergent effects
- Temperature, combustion, and material state changes
- Combine items and environment for tactical advantages

### Visual Corruption
- Graphical glitches and shader effects based on reality stability
- Simple sprites with complex corruption overlays
- Generative art approach to visual degradation

## Development Setup

### Requirements
- **Godot 4.3+**
- **Development Environment**: WSL2 + Windows Godot (or native Linux)
- Controller recommended for testing

### Project Structure
```
backrooms_power_crawl/
├── docs/              # Design documents
├── scenes/            # Godot scene files (.tscn)
├── scripts/           # GDScript files (.gd)
├── assets/
│   ├── sprites/       # Pixel art and sprite sheets
│   ├── shaders/       # Custom shaders for corruption effects
│   ├── fonts/         # Monospace fonts for SCP aesthetic
│   └── audio/         # Sound effects and music
├── data/              # JSON/data files for entities, abilities, etc.
└── systems/           # Core game systems (simulation, entity management)
```

### Getting Started

1. Open `project.godot` in Godot 4.3+
2. Controller input is pre-configured (see Input Map)
3. Start building systems one at a time
4. See `docs/DESIGN.md` for full design documentation

### Input Scheme (Controller-First)

**Current Implementation:**
- **Right Stick / Mouse**: Rotate camera (third-person perspective)
- **RT / Space / Left Click**: Move forward (camera-relative direction)
- **Left Stick**: Move camera pivot (tactical camera mode - not yet implemented)
- **D-Pad Up**: Toggle examination mode (on-demand tile generation)
- **Start**: Pause/Menu (not yet implemented)

**Future Features:**
- **RB/LB/X/Y**: Toggle automatic abilities (ability system planned)
- **Select**: Inventory/Character Sheet (UI planned)

## Development Philosophy

### Iterative System Building
Build and test one system at a time:
1. Core turn-based movement + controller input
2. Examination system with SCP-style tooltips
3. Basic entity spawning and AI
4. Automatic ability system
5. Physics simulation layer
6. Visual corruption shaders
7. Hub area and NPCs
8. Mission types and containment mechanics

### Open Source
This project will be open source when ready. Free software ethos throughout.

## Current Status

**Phase**: Core Systems Implementation - Procedural Generation & Infinite World

**Implemented:**
- ✅ 3D grid system with chunk-based streaming
- ✅ Wave Function Collapse (WFC) procedural maze generation
- ✅ Infinite world exploration (island-of-mazes chunks)
- ✅ Input system (controller + mouse/keyboard parity)
- ✅ State machine architecture (IdleState, LookModeState, ExecutingTurnState, PostTurnState)
- ✅ Action/command pattern (MovementAction, WaitAction)
- ✅ Turn-based movement with forward indicator
- ✅ Third-person camera controls
- ✅ Examination mode with on-demand tile generation
- ✅ Logging system with category/level filtering
- ✅ Level configuration system (LevelConfig resources)
- ✅ PSX-style materials and shaders
- ✅ Knowledge database system (SCP-style progressive revelation)

**In Progress:**
- 🚧 Bug fixes and stabilization
- 🚧 Entity spawning system
- 🚧 Ceiling vignette transparency system

**Planned:**
- 📋 Automatic ability system
- 📋 Enemy AI and pathfinding
- 📋 Physics simulation (liquids, temperature)
- 📋 Visual corruption shaders
- 📋 Hub area and NPCs

See `docs/DESIGN.md` for full design documentation and `docs/ARCHITECTURE_AUDIT.md` for complete system inventory.

## License

TBD - will be open source

## Credits

Developed by aebrer

Inspired by Caves of Qud (Freehold Games), Vampire Survivors (poncle), and the Backrooms collaborative fiction community.
