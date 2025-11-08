# Phase 1 Setup Instructions

## Step-by-Step Guide to Create 3D Scene in Godot Editor

Follow these steps in the Godot editor to create the initial 3D scene structure.

---

## Step 1: Create MeshLibrary Scene

1. **Create New Scene**: Scene → New Scene
2. **Add Root Node**: Select "Other Node" → Search "Node3D" → Create
3. **Rename** root to `MeshLibrary`

4. **Add Floor Mesh**:
   - Right-click `MeshLibrary` → Add Child Node → `MeshInstance3D`
   - Rename to `Floor`
   - Inspector → Geometry → Mesh → Click `[empty]` → New PlaneMesh
   - Click the PlaneMesh → Set Size: X=1, Y=1
   - Inspector → Material → Click `[empty]` → New StandardMaterial3D
   - Click Material → Albedo → Color: Set to light brown `#D2B48C`

5. **Add Wall Mesh**:
   - Right-click `MeshLibrary` → Add Child Node → `MeshInstance3D`
   - Rename to `Wall`
   - Inspector → Geometry → Mesh → New BoxMesh
   - Click BoxMesh → Set Size: X=1, Y=1, Z=1
   - Material → New StandardMaterial3D
   - Albedo Color: Yellow `#E8D998`

6. **Export as MeshLibrary**:
   - Scene → Export As → MeshLibrary
   - Save as: `res://assets/grid_mesh_library.tres`
   - Create `assets` folder if needed

7. **Save Scene**:
   - Scene → Save Scene As → `res://assets/mesh_library_source.tscn`
   - (This is just for reference, the .tres file is what matters)

---

## Step 2: Create Game3D Scene

1. **Create New Scene**: Scene → New Scene
2. **Select "3D Scene"** (creates Node3D root automatically)
3. **Rename** root to `Game`
4. **Attach Script**:
   - Select `Game` node
   - Click attach script icon
   - Path: `res://scripts/game_3d.gd` (should already exist)
   - Click Load

### Add WorldEnvironment

1. Right-click `Game` → Add Child Node → `WorldEnvironment`
2. Inspector → Environment → New Environment
3. Click Environment resource:
   - Background → Mode: Sky
   - Background → Sky: New Sky
   - Click Sky → Sky Material: New ProceduralSkyMaterial
   - (This gives basic blue sky for now)

### Add DirectionalLight3D

1. Right-click `Game` → Add Child Node → `DirectionalLight3D`
2. Rename to `SunLight`
3. Transform → Rotation: X=-45, Y=45, Z=0 (angled down)
4. Light → Energy: 0.8

### Add Grid3D

1. Right-click `Game` → Add Child Node → `Node3D`
2. Rename to `Grid3D`
3. Attach script: `res://scripts/grid_3d.gd`
4. Right-click `Grid3D` → Add Child Node → `GridMap`
5. Select `GridMap` node:
   - Inspector → Mesh Library → Load `res://assets/grid_mesh_library.tres`
   - Cell → Size: X=1, Y=0.5, Z=1

### Add Player3D

1. Right-click `Game` → Add Child Node → `CharacterBody3D`
2. Rename to `Player3D`
3. Attach script: `res://scripts/player/player_3d.gd`

4. **Add CollisionShape3D**:
   - Right-click `Player3D` → Add Child Node → `CollisionShape3D`
   - Inspector → Shape → New CapsuleShape3D
   - Click CapsuleShape3D: Radius=0.4, Height=1.8

5. **Add Model (Temporary Label3D)**:
   - Right-click `Player3D` → Add Child Node → `Label3D`
   - Rename to `Model`
   - Inspector → Text: `🚶`
   - Font Size: 64
   - Billboard: Fixed Y
   - Modulate: White (full brightness)

6. **Add InputStateMachine** (copy from 2D scene):
   - Right-click `Player3D` → Add Child Node → `Node`
   - Rename to `InputStateMachine`
   - Attach script: `res://scripts/player/input_state_machine.gd`

7. **Add States** (as children of InputStateMachine):
   - Right-click `InputStateMachine` → Add Child Node → `Node`
   - Rename to `IdleState`
   - Attach script: `res://scripts/player/states/idle_state.gd`
   - Repeat for `AimingMoveState` (script: `aiming_move_state.gd`)
   - Repeat for `ExecutingTurnState` (script: `executing_turn_state.gd`)

8. **Add Camera Rig** (temporary simple camera):
   - Right-click `Player3D` → Add Child Node → `Camera3D`
   - Rename to `Camera`
   - Transform → Position: X=0, Y=10, Z=10
   - Transform → Rotation: X=-45, Y=0, Z=0
   - Inspector → Projection: Perspective
   - FOV: 70

### Add UI Layer

1. Right-click `Game` → Add Child Node → `CanvasLayer`
2. Rename to `UI`

3. **Add TurnCounter**:
   - Right-click `UI` → Add Child Node → `Label`
   - Rename to `TurnCounter`
   - Layout → Anchors Preset: Top Left
   - Position: X=10, Y=10
   - Size: X=500, Y=30
   - Text: "Turn: 0 | Pos: (0, 0) | State: None"
   - Theme Overrides → Colors → Font Color: Light gray
   - Theme Overrides → Font Sizes → Font Size: 16

4. **Add Instructions**:
   - Right-click `UI` → Add Child Node → `Label`
   - Rename to `Instructions`
   - Layout → Anchors Preset: Bottom Left
   - Position: X=10, Y=-100 (from bottom)
   - Size: X=600, Y=90
   - Text:
     ```
     LEFT STICK / WASD: Aim movement
     RIGHT TRIGGER / SPACE: Confirm move
     START / ESC: Return to menu

     PHASE 1: Testing 3D Grid System
     ```
   - Theme Overrides → Colors → Font Color: Gray
   - Theme Overrides → Font Sizes → Font Size: 14

---

## Step 3: Save and Set as Main Scene

1. **Save Scene**:
   - Scene → Save Scene As
   - `res://scenes/game_3d.tscn`

2. **Set as Main Scene** (optional for testing):
   - Project → Project Settings → Application → Run → Main Scene
   - Click folder icon → Select `game_3d.tscn`

---

## Step 4: Test the Scene

1. **Press F5** or click Play button
2. **Expected behavior**:
   - Grid appears (floor tiles with walls around edge)
   - Player emoji visible at center
   - Camera shows scene from angle
   - Turn counter displays at top
   - Can move with WASD/stick (movement will work!)

3. **If you see errors**:
   - Check that all scripts are attached correctly
   - Check GridMap has MeshLibrary assigned
   - Check Grid3D and Player3D node names match script expectations

---

## Step 5: Verify Node Paths

Open `game_3d.tscn` and verify this structure:

```
Game (Node3D) [script: game_3d.gd]
├─ WorldEnvironment
├─ SunLight (DirectionalLight3D)
├─ Grid3D (Node3D) [script: grid_3d.gd]
│  └─ GridMap [mesh_library: grid_mesh_library.tres]
├─ Player3D (CharacterBody3D) [script: player_3d.gd]
│  ├─ CollisionShape3D
│  ├─ Model (Label3D, text: "🚶")
│  ├─ InputStateMachine (Node) [script: input_state_machine.gd]
│  │  ├─ IdleState (Node) [script: idle_state.gd]
│  │  ├─ AimingMoveState (Node) [script: aiming_move_state.gd]
│  │  └─ ExecutingTurnState (Node) [script: executing_turn_state.gd]
│  └─ Camera (Camera3D)
└─ UI (CanvasLayer)
   ├─ TurnCounter (Label)
   └─ Instructions (Label)
```

---

## Troubleshooting

**Problem**: Grid doesn't appear
- **Solution**: Check GridMap has mesh_library assigned
- **Solution**: Check Grid3D.initialize() is being called

**Problem**: Player emoji doesn't show
- **Solution**: Check Label3D has text "🚶" and Billboard = Fixed Y
- **Solution**: Check Label3D is visible in scene tree

**Problem**: Movement doesn't work
- **Solution**: Check InputStateMachine has all three states as children
- **Solution**: Check player.grid reference is set in game_3d.gd

**Problem**: Camera shows nothing
- **Solution**: Adjust camera position/rotation to see the grid
- **Solution**: Try Position Y=15, Z=15, Rotation X=-45

---

## Next Steps

Once Phase 1 is working:
- ✅ Grid visible in 3D
- ✅ Player can move with WASD/controller
- ✅ Turn counter updates
- ✅ Movement feels turn-based

Then we move to **Phase 2: Third-Person Camera Rig**!

---

## Quick Reference: File Locations

**Scripts created**:
- `/scripts/grid_3d.gd` ✅
- `/scripts/player/player_3d.gd` ✅
- `/scripts/game_3d.gd` ✅

**Scenes to create in editor**:
- `/assets/mesh_library_source.tscn` (scene for reference)
- `/assets/grid_mesh_library.tres` (exported MeshLibrary)
- `/scenes/game_3d.tscn` (main game scene)

**Existing scripts to reuse**:
- `/scripts/autoload/input_manager.gd` (no changes needed!)
- `/scripts/player/input_state_machine.gd` (no changes needed!)
- `/scripts/player/states/*.gd` (no changes needed!)
- `/scripts/actions/*.gd` (no changes needed!)
