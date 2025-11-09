# Issue 5: Camera Obstruction by Walls

**Status**: Research Complete - Awaiting Design Decision
**Date**: 2025-11-09
**Type**: Camera System / Visual Clarity

---

## Problem Analysis

### Current Behavior
The camera uses a `SpringArm3D` (spring_length=15.0, collision_mask=2) that automatically shortens when it collides with walls. When the player is near corners, edges, or in tight spaces:

1. SpringArm detects wall collision
2. Camera position adjusts closer to player
3. View angle changes, potentially losing tactical overview
4. Walls physically block line of sight to player

**Question**: Is this a problem that needs solving, or is SpringArm collision handling sufficient for a turn-based tactical game?

### Current Setup (from game_3d.tscn)
```
Player3D
  └─ CameraRig (tactical_camera.gd)
       └─ HorizontalPivot
            └─ VerticalPivot
                 └─ SpringArm3D (spring_length=15.0, collision_mask=2)
                      └─ Camera3D (fov=70.0)
```

**SpringArm Configuration**:
- Spring length: 15.0 units (7.5m in world space with cell_size=2)
- Collision mask: Layer 2 (walls/environment)
- No collision shape specified (falls back to raycast)
- Default margin behavior

---

## How Tactical Games Handle This

### Research Findings

**XCOM Series**:
- Uses automatic wall cutaway/transparency system
- Walls between camera and soldiers become semi-transparent
- Multi-story buildings have entire floors hidden/shown
- First major patch (March 2016) specifically addressed "reduced camera obstructions"
- Community feedback: "Maps with multistory buildings had issues with walls not cutting away properly"
- Design priority: **Perfect tactical information over atmosphere**

**Divinity: Original Sin Series**:
- Fixed isometric camera with restricted rotation (4 cardinal directions)
- Design choice: Rooms have bare walls on 2 sides specifically because camera can rotate
- Players complained about camera restrictions, but developers chose gameplay clarity
- When rotating camera so wall is between camera and object, "it was difficult to see through the wall"
- Solution: Don't let the camera go there - restrict angles
- Design priority: **Simplified environment geometry over complex occlusion**

**General Tactical/RTS Pattern**:
- **Perfect Information Philosophy**: Turn-based tactics games favor complete, consistent information
  - Shadow Tactics: "almost perfect information with no fog of war, no random enemy spawns"
  - Sharp edges and clearly defined areas are critical for pixel-perfect tactical decisions
  - The more difficult and tactical the game, the more important perfect information becomes
- **Common Solutions**:
  1. Restrict camera angles to prevent problematic views (Divinity approach)
  2. Make walls transparent when obstructing (XCOM approach)
  3. Hide entire floors/ceilings when indoors (Sims, old-school RPGs)
  4. Keep camera high enough that obstruction rarely occurs (many RTS games)

**Industry Standard Third-Person Action**:
- Fortnite, Gears of War, etc.: SpringArm is usually sufficient
- These games prioritize cinematic feel and atmospheric immersion
- Brief obstruction adds tension (peeking around corners, tight spaces)
- But these are **real-time action games**, not turn-based tactics

---

## Current SpringArm Behavior

### How SpringArm3D Works (Godot 4.x)

**Collision Detection**:
- Casts a shape (or ray if no shape) from origin to `spring_length` endpoint
- Snaps to first collision point between origin and end
- `margin` property offsets camera from exact collision point

**Best Practices** (from Godot docs):
- Add collision shape for accurate detection (sphere shape recommended)
- Without shape, falls back to raycast (less accurate for camera collision)
- Common hierarchy: CharacterBody3D → HorizontalPivot → VerticalPivot → SpringArm3D → Camera3D

**Known Limitations**:
- Always casts shape, resulting in constant snapping at ANY collision
- Can cause camera jitter in complex geometry (like mazes!)
- Some developers disable SpringArm collision and use custom detection only when camera itself collides
- GitHub issue #12098: Request for SpringArm to only work when colliding its *end*, not objects between

**Current Project Issues**:
- No collision shape assigned → Using less accurate raycast
- Backrooms maze = dense walls everywhere = constant potential for collision
- SpringArm snapping could be jarring in turn-based context (no animation smoothing needed)

---

## Research Findings

### Approach 1: SpringArm Only (Current)

**Description**: Let SpringArm handle all collision, camera moves closer when obstructed.

**Pros**:
- Zero additional code/shaders required
- Godot built-in solution
- Works automatically
- Low performance cost
- Familiar behavior from action games

**Cons**:
- Loss of tactical overview when cornered
- Camera angle changes unexpectedly
- Walls still block view (camera closer but still obstructed)
- Not standard for turn-based tactics genre
- Constant snapping in maze environment may feel janky
- Currently using raycast fallback (less accurate)

**Improvements Possible**:
- Add sphere collision shape to SpringArm for better detection
- Tune `margin` property to keep camera slightly away from walls
- Adjust `spring_length` and pitch constraints to minimize obstruction angles

**Recommendation**: Could work if combined with wall transparency, but alone insufficient for perfect information.

---

### Approach 2: Wall Transparency/Ghosting (Industry Standard)

**Description**: Detect walls between camera and player, render them semi-transparent or with x-ray shader.

#### Implementation Techniques

**2A: RayCast + Material Swapping**
```gdscript
# In tactical_camera.gd or player script
var raycast: RayCast3D
raycast.target_position = camera.global_position - player.global_position

# Each frame:
var hit = raycast.get_collider()
if hit and hit.is_in_group("walls"):
    hit.material_override = transparent_material
else:
    hit.material_override = null  # Restore original
```

**Pros**:
- Simple to implement
- CPU-based (no shader complexity)
- Can store/restore original materials
- Works with existing PSX shaders

**Cons**:
- Only handles single raycast (misses wide walls)
- Material swapping has 1-frame delay
- Needs material duplication (memory)

**2B: Sphere Cast + Material Swapping**
- Cast a sphere along camera-to-player line
- Detects multiple walls/obstacles
- Get all colliders in sphere, make transparent
- More accurate than single ray

**2C: Shader-Based Distance Fade**
```gdscript
# Add to wall shader uniforms
uniform vec3 player_position;
uniform float fade_start = 5.0;
uniform float fade_complete = 2.0;

// In fragment():
float dist = distance(VERTEX, player_position);
float alpha_mult = smoothstep(fade_complete, fade_start, dist);
ALPHA *= alpha_mult;
```

**Pros**:
- Gradual fade looks polished
- No material swapping
- GPU-accelerated
- Can affect shadows independently

**Cons**:
- Requires modifying PSX shaders
- All walls need player_position uniform updated
- Fade based on distance, not actual occlusion
- Complexity with existing shader pipeline

**2D: X-Ray Vision Shader (Godot Shaders)**
```glsl
shader_type spatial;
render_mode unshaded, depth_test_disable;

// Fresnel glow on edges
float fresnel = pow(1.0 - dot(normalize(NORMAL), normalize(VIEW)), 3.0);
ALBEDO = mix(base_color, glow_color, fresnel);
ALPHA = 0.3 + fresnel * 0.5;
```

**Pros**:
- Cool sci-fi aesthetic
- Clear edge visibility (fresnel glow)
- Can combine with dithering for PSX style
- "Next Pass" system preserves original material

**Cons**:
- Aesthetic may not match Backrooms theme
- `depth_test_disable` can cause sorting issues
- More complex shader setup
- Performance cost on many walls

**2E: Dithered Transparency (PSX-Style)**
```glsl
// In fragment shader:
float dist = distance(VERTEX, player_position);
float dither_alpha = smoothstep(fade_complete, fade_start, dist);

// Use dither pattern for transparency (matches existing PSX aesthetic!)
float dither = texture(dither_texture, SCREEN_UV * dither_scale).r;
if (dither_alpha < dither) discard;
```

**Pros**:
- Matches existing PSX aesthetic perfectly
- No alpha blending (maintains PSX hard edges)
- Works with existing dithering post-process
- Performance-friendly (discard vs alpha blend)

**Cons**:
- Requires dither texture
- Needs integration with psx_base.gdshaderinc
- Still needs player_position updates

**RECOMMENDED SHADER APPROACH**: 2E (Dithered Transparency) - best fit for PSX aesthetic and existing tech

---

### Approach 3: Camera Cutting/Clipping Plane

**Description**: Hide all geometry behind camera using depth testing or stencil buffer.

**Implementation**:
- Set a clipping plane at camera position
- Anything between camera and clipping plane is culled
- Or use render layers to skip walls "behind" camera

**Pros**:
- Handles all obstruction automatically
- No per-wall detection needed
- Common in first-person games

**Cons**:
- Not standard for tactical games
- Loses wall information entirely (not transparent, just gone)
- Confusing in maze navigation (walls appear/disappear abruptly)
- Harder to implement in Godot than Unity/Unreal

**Recommendation**: Poor fit for turn-based tactics - too aggressive

---

### Approach 4: Wall Fade by Camera Distance (Proximity Fade)

**Description**: Walls fade out as camera gets close to them, regardless of player position.

**Implementation**:
- Use Godot's built-in `Distance Fade` material property
- Or shader uniform: `uniform float fade_distance = 3.0;`
- Fade based on `distance(CAMERA_POSITION_WORLD, VERTEX)`

**Pros**:
- Built-in Godot feature (easiest to implement)
- No raycasting needed
- Automatic per-wall
- GPU-accelerated

**Cons**:
- **Distance Fade disables shadow casting in Godot 4.3** (known bug #97537)
- Fades walls near camera even if not obstructing player
- Less precise than raycast detection
- Can fade walls you want to see

**Recommendation**: Only viable if shadow bug is fixed and acceptable to fade nearby walls

---

### Approach 5: Hybrid - SpringArm + Transparency

**Description**: Keep SpringArm collision for camera positioning, ADD wall transparency for obstructed walls.

**Implementation**:
1. SpringArm moves camera when it would clip through walls
2. Separately, raycast from camera to player
3. Make walls hit by raycast semi-transparent
4. Best of both worlds: good camera position AND clear view

**Pros**:
- Camera never clips through geometry (SpringArm)
- Player always visible (transparency)
- Maintains tactical overview when possible
- Falls back gracefully when cornered

**Cons**:
- Most complex implementation
- Two systems to maintain
- Potential for conflicts between systems

**Recommendation**: Best solution if perfect information is priority

---

## Recommended Solution

### Analysis Framework: What Kind of Game Is This?

**Backrooms Power Crawl is**:
- Turn-based tactical roguelike
- Inspiration: Caves of Qud (perfect information, no hidden RNG)
- Indoor maze environment (walls everywhere)
- Controller-first design (limited camera manipulation during gameplay)
- PSX aesthetic (dithering, vertex snapping, limited colors)

**Design Philosophy from DESIGN.md**:
- Knowledge-based progression (examining enemies, learning patterns)
- Perfect information preferred (see XCOM, not Dark Souls)
- Tactical decision-making over twitch reflexes
- Deliberate, thoughtful gameplay

### Recommendation: **Hybrid Approach (SpringArm + Dithered Wall Transparency)**

**Why This Fits**:
1. **Perfect Information**: Players can always see their character and nearby tiles clearly
2. **PSX Aesthetic**: Dithered transparency matches existing visual style perfectly
3. **Turn-Based Needs**: No camera obstruction interrupting tactical planning
4. **Backrooms Theme**: Semi-transparent walls feel appropriately liminal/unsettling
5. **Performance**: Dithering is cheap, matches existing post-process pipeline

**Implementation Priority**:
- **Phase 1**: Add collision shape to SpringArm (improve current system)
- **Phase 2**: Implement raycast-based wall detection in `tactical_camera.gd`
- **Phase 3**: Create `psx_wall_transparent.gdshader` with dithered fade
- **Phase 4**: Swap materials on obstructing walls (restore on clear)

---

## Implementation Plan

### Phase 1: Improve SpringArm (Immediate)

**Goal**: Better collision detection without transparency

**Changes to game_3d.tscn**:
```gdscript
# Add collision shape to SpringArm3D
[sub_resource type="SphereShape3D" id="SpringArmShape"]
radius = 0.3

[node name="SpringArm3D" ...]
shape = SubResource("SpringArmShape")
margin = 0.2
```

**Expected Result**: More accurate camera collision, slight margin from walls

**Test**: Move player to corners, check camera behavior

---

### Phase 2: Wall Detection System

**Goal**: Identify which walls are obstructing view

**Add to tactical_camera.gd**:
```gdscript
# New variables
var wall_raycast: RayCast3D
var obstructed_walls: Array[Node3D] = []

func _ready():
    wall_raycast = RayCast3D.new()
    wall_raycast.collision_mask = 2  # Wall layer
    wall_raycast.hit_from_inside = true
    add_child(wall_raycast)

func _process(delta):
    # After camera rotation/zoom:
    update_wall_transparency()

func update_wall_transparency():
    var player_pos = player.global_position
    var camera_pos = camera.global_position

    wall_raycast.global_position = camera_pos
    wall_raycast.target_position = player_pos - camera_pos
    wall_raycast.force_raycast_update()

    # Clear previous
    for wall in obstructed_walls:
        restore_wall_material(wall)
    obstructed_walls.clear()

    # Detect new obstructions
    var collider = wall_raycast.get_collider()
    if collider and collider.is_in_group("walls"):
        make_wall_transparent(collider)
        obstructed_walls.append(collider)
```

**Expected Result**: Know which walls are blocking view

**Test**: Debug draw raycast, print obstructed wall names

---

### Phase 3: Dithered Transparency Shader

**Goal**: PSX-style transparent walls that match aesthetic

**Create shaders/psx_wall_transparent.gdshader**:
```glsl
shader_type spatial;

#define LIT diffuse_lambert, vertex_lighting
#define CULL cull_back
#define DEPTH depth_draw_opaque
#define BLEND blend_mix  // Keep opaque blend for dither

#include "psx_base.gdshaderinc"

// Override alpha section:
uniform float transparency : hint_range(0.0, 1.0) = 0.3;
uniform sampler2D dither_texture;
uniform float dither_scale = 1.0;

// After base color calculation:
float dither = texture(dither_texture, SCREEN_UV * dither_scale).r;
if (transparency < dither) {
    discard;  // PSX-style dithered transparency
}
```

**Create Transparent Material Resource**:
- `assets/materials/wall_transparent.tres`
- Uses `psx_wall_transparent.gdshader`
- Same texture as normal walls
- Pre-configured dither settings

**Expected Result**: Walls can be made semi-transparent with dithering

**Test**: Manually apply material to wall, verify appearance

---

### Phase 4: Material Swapping System

**Goal**: Automatically swap materials when walls obstruct

**Extend tactical_camera.gd**:
```gdscript
# Cache original materials
var original_materials: Dictionary = {}  # Node -> Material

func make_wall_transparent(wall: Node3D):
    if wall is GridMap:
        # GridMap cells are trickier - may need different approach
        # For now, note limitation
        push_warning("GridMap transparency not yet supported")
        return

    if wall is MeshInstance3D:
        if not wall in original_materials:
            original_materials[wall] = wall.material_override
        wall.material_override = preload("res://assets/materials/wall_transparent.tres")

func restore_wall_material(wall: Node3D):
    if wall is MeshInstance3D and wall in original_materials:
        wall.material_override = original_materials[wall]
```

**Expected Result**: Walls between camera and player become dithered/transparent

**Test**:
- Position player near wall
- Rotate camera to obstruct view
- Wall should become transparent
- Rotate away, wall should become opaque again

---

### Phase 5: GridMap Support (Advanced)

**Challenge**: Walls are GridMap cells, not individual MeshInstance3D nodes

**Options**:
1. **Shader-based**: Pass player_position uniform to wall shader, fade in shader
2. **GridMap cell manipulation**: Hide individual cells (may cause visual gaps)
3. **Separate transparent layer**: Render transparent copy of obstructed cells

**Recommended**: Shader-based approach
```gdscript
# In grid_3d.gd or tactical_camera.gd
var wall_material: ShaderMaterial = gridmap.mesh_library.get_item_mesh(WALL_ITEM_ID).surface_get_material(0)

func update_wall_transparency():
    var camera_pos = camera.global_position
    wall_material.set_shader_parameter("camera_position", camera_pos)
    wall_material.set_shader_parameter("player_position", player.global_position)
```

**Shader modification**:
```glsl
uniform vec3 camera_position;
uniform vec3 player_position;

// In fragment():
vec3 to_player = player_position - camera_position;
vec3 to_fragment = VERTEX - camera_position;

// Check if fragment is between camera and player
float dist_to_line = /* calculate distance to camera-player line */;
float depth = dot(to_fragment, normalize(to_player));

if (depth > 0.0 && depth < length(to_player) && dist_to_line < 1.0) {
    // This fragment obstructs view - apply transparency
    float dither = texture(dither_texture, SCREEN_UV * dither_scale).r;
    if (0.3 < dither) discard;
}
```

---

## Performance Considerations

### SpringArm Only
- **Cost**: Minimal (built-in Godot system)
- **Frame impact**: <0.1ms (single raycast per frame)

### RayCast + Material Swapping
- **Cost**: Low
- **Frame impact**: ~0.1-0.5ms depending on wall count
- **Memory**: Duplicate materials for each wall type

### Shader-Based Transparency
- **Cost**: Medium (GPU)
- **Fragment shader**: Runs per-pixel on visible walls
- **Uniform updates**: Minimal (2 vec3 per frame)
- **Dithering**: Cheaper than alpha blending (discard vs blend)

### GridMap Uniform Updates
- **Cost**: Low (single shader_material shared by all cells)
- **Update frequency**: Once per camera move (turn-based = rare!)

**Conclusion**: All approaches viable performance-wise. Turn-based nature means updates only on player action, not 60fps.

---

## Design Philosophy

### Perfect Information vs Atmospheric Occlusion

**Perfect Information Argument** (Favor Transparency):
- Turn-based tactics REQUIRE seeing the tactical situation clearly
- Hidden information should be *designed* (fog of war, examination), not accidental (camera angles)
- Players shouldn't lose a run because camera angle hid an enemy
- Genre expectation: XCOM, Into the Breach, Slay the Spire all prioritize clarity

**Atmospheric Occlusion Argument** (Favor SpringArm Only):
- Backrooms aesthetic is about disorientation and claustrophobia
- Not seeing around corners adds tension
- Walls blocking view makes tight spaces feel tighter
- Examination mode can reveal what's behind walls if needed

**Hybrid Position** (Recommended):
- Perfect tactical information for things player character can "see"
- Transparent walls show what's in line of sight
- Fog of war / examination mode for things character can't see
- Atmosphere from visual style (PSX, dithering, liminal spaces), not from obstructed UI

**Design Goals from DESIGN.md**:
> "Knowledge-based progression: learning enemy patterns, understanding SCP behaviors"
> "Inspiration: Caves of Qud (systemic depth, perfect information)"

**Conclusion**: Backrooms Power Crawl aligns with perfect information philosophy. Walls obstructing camera view would be **accidental occlusion**, not designed information hiding.

---

## References

### Academic/Industry Resources
- [Real-Time Cameras - Navigation and Occlusion (Game Developer)](https://www.gamedeveloper.com/design/real-time-cameras---navigation-and-occlusion)
- [Third Person Camera View in Games (Game Developer)](https://www.gamedeveloper.com/design/third-person-camera-view-in-games)
- [Understanding Camera Systems in Game Design (Game Wisdom)](https://game-wisdom.com/critical/camera-systems-game-design)
- [Analysis: RTS Camera Angles And Design Decisions (Game Developer)](https://www.gamedeveloper.com/design/analysis-wide-angle-lens---rts-camera-angles-and-design-decisions)

### Godot Technical Resources
- [SpringArm3D Official Documentation](https://docs.godotengine.org/en/stable/classes/class_springarm3d.html)
- [Third-person camera with spring arm Tutorial](https://docs.godotengine.org/en/stable/tutorials/3d/spring_arm.html)
- [X-Ray Vision Effect Shader (Godot Shaders)](https://godotshaders.com/shader/x-ray-vision-effect/)
- [Fade by distance to character (Godot Shaders)](https://godotshaders.com/shader/fade-by-distance-to-character/)
- [Transparency Dither Shader (Godot Shaders)](https://godotshaders.com/shader/transparency-dither/)

### Game-Specific Research
- [XCOM 2 First Major Patch - Reduced Camera Obstructions (Tom's Hardware, 2016)](https://www.tomshardware.com/news/xcom-2-first-major-patch,31384.html)
- [Divinity: Original Sin Camera Discussions (Steam Community)](https://steamcommunity.com/app/230230/discussions/)
- [Game Design Deep Dive: Shadow Tactics (Game Developer)](https://www.gamedeveloper.com/design/game-design-deep-dive-dynamic-detection-in-i-shadow-tactics-i-)

### Technical Discussions
- [Godot Forum: Transparent objects between camera and player](https://forum.godotengine.org/t/shader-that-hides-cuts-objects-between-the-player-and-the-camera/52273)
- [Stack Overflow: Making walls transparent in Godot 4](https://stackoverflow.com/questions/78687112/in-godot4-3d-how-to-make-objects-close-to-the-camera-transparent-for-a-camera)
- [GitHub: SpringArm collision behavior issue #12098](https://github.com/godotengine/godot-proposals/issues/12098)

---

## Next Steps

### Immediate (User Decision Required):
1. **Design Decision**: SpringArm only vs Hybrid approach?
   - If SpringArm only: Improve collision shape and test
   - If Hybrid: Proceed with implementation phases

### If Hybrid Approach Chosen:
1. Phase 1: Add collision shape to SpringArm (5 minutes)
2. Phase 2: Implement wall detection raycast (30 minutes)
3. Phase 3: Create dithered transparency shader (1-2 hours)
4. Phase 4: Material swapping system (30 minutes)
5. Phase 5: GridMap shader integration (2-3 hours)

### Testing Checklist:
- [ ] Camera behavior in open spaces (no obstruction)
- [ ] Camera behavior in tight corners (maximum obstruction)
- [ ] Wall transparency triggers correctly
- [ ] Wall transparency restores correctly
- [ ] Performance impact acceptable (<1ms frame time)
- [ ] Visual style matches PSX aesthetic
- [ ] Doesn't interfere with ceiling transparency system
- [ ] Works with controller camera controls

---

## Conclusion

**SpringArm alone is insufficient for turn-based tactical gameplay.** While it works well for action games, Backrooms Power Crawl's design philosophy aligns with perfect tactical information (à la XCOM, Caves of Qud).

**Recommended: Hybrid approach with dithered wall transparency**
- Maintains PSX aesthetic
- Provides perfect tactical information
- Respects turn-based genre conventions
- Relatively simple implementation
- Low performance cost

**Alternative if simplicity preferred**: Add collision shape to SpringArm, accept occasional obstruction as acceptable trade-off. Test with users to see if complaints arise.

**Not Recommended**:
- Distance fade (shadow casting bug, imprecise)
- Clipping planes (too aggressive, confusing in maze)
- X-ray shaders (aesthetic mismatch)

The decision ultimately depends on priority: **Backrooms atmosphere vs tactical clarity**. Given design doc philosophy, tactical clarity should win.
