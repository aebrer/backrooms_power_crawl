# Issue 3: Player Vignette Appears to Change with Zoom

## Problem Analysis

**Reported Issue**: The player-based cylinder vignette (3-8m radius) appears to change size on screen when camera zooms in/out. Zooming in makes the vignette "feel narrower", zooming out makes it "feel wider".

**Question**: Is this a bug or expected perceptual behavior of perspective projection?

## Current Implementation Review

### Code Analysis (`psx_ceiling.gdshader`, lines 62-68)

```gdscript
float calculate_world_space_fade() {
    vec2 player_pos_xz = player_world_position.xz;
    vec2 world_pos_xz = world_position.xz;
    float dist_from_player = length(world_pos_xz - player_pos_xz);
    float fade_factor = smoothstep(player_fade_inner_radius, player_fade_outer_radius, dist_from_player);
    fade_factor = pow(fade_factor, player_fade_power);
    return fade_factor;
}
```

**Verification**: This implementation is **correctly world-space**:
- ✅ Uses `world_position` from vertex shader (line 93: `world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz`)
- ✅ Calculates actual XZ-plane distance in world units via `length(world_pos_xz - player_pos_xz)`
- ✅ Compares against world-space radii (3.0m inner, 8.0m outer)
- ✅ Distance calculation is independent of camera position, zoom, or FOV

**Conclusion**: The shader is working exactly as designed - it maintains a **constant 3-8m world-space radius** around the player.

## Research Findings

### How World-Space Effects Appear at Different Zoom Levels

From technical research on perspective cameras and coordinate spaces:

1. **Perspective Projection Fundamentals**:
   - World-space circles appear differently on screen depending on camera distance/FOV
   - Same world-space radius takes up more/less screen space as camera zooms
   - This is **geometrically correct behavior** - not a bug!

2. **The "Feeling" of Width**:
   - When zoomed out: You see MORE of the world, so 8m radius looks "smaller" relative to visible area
   - When zoomed in: You see LESS of the world, so 8m radius fills more of the screen
   - **Perceptual effect**: The vignette "feels" like it changes size, even though world-space radius is constant

3. **Industry Examples**:
   - EVE Online: "When you zoom your camera out, the tactical overlay will come more clearly into view, showing concentric rings marking various ranges in kilometers"
   - RTS games: Vision radius circles appear smaller on screen when zoomed out, larger when zoomed in
   - This is **expected and standard behavior** for world-space effects

4. **Screen-Space vs World-Space Trade-offs**:
   - **Screen-space vignette** (existing in shader): Always takes up same screen percentage regardless of zoom
   - **World-space vignette** (player-based): Correct gameplay distance, variable screen coverage
   - Current implementation uses BOTH (combined via `min()` on line 74)

## Root Cause

### This is NOT a Bug - It's Correct Perspective Projection

**The vignette IS world-space and working correctly.** The "feeling" of width change is a natural consequence of perspective projection:

**Zoomed Out (camera distance ~25 units, wide FOV)**:
- More of the world visible on screen
- 8m radius is small relative to visible area
- Vignette covers ~30-40% of screen (estimate)
- **Feels wider** because you see the world beyond the vignette

**Zoomed In (camera distance ~8 units, narrow FOV)**:
- Less of the world visible on screen
- 8m radius is large relative to visible area
- Vignette covers ~60-80% of screen (estimate)
- **Feels narrower** because the vignette dominates view

### Why This Behavior is Actually Desirable

**Tactical Gameplay Benefits**:
1. **Zoomed out**: You sacrifice detail for awareness - seeing the vignette edge helps you know where visibility drops
2. **Zoomed in**: You focus on local area - vignette fills screen because you're "inside" the radius
3. **Realistic**: Matches how actual vision radius would behave in 3D space

**Mathematical Correctness**:
- The ceiling at 10m away from player IS 10m away, regardless of camera zoom
- Screen-space coverage changing with zoom is **geometrically correct**
- Changing this would make world distances inconsistent

## Recommendations

### 1. If Working Correctly (Current Assessment): No Code Changes Needed

**Explanation for User**:
The vignette is functioning exactly as designed. The "feeling" of width change is an inherent property of perspective cameras - world-space circles appear larger on screen when camera is closer. This matches how RTS vision radius overlays behave (EVE Online, StarCraft, etc.).

**Suggested UI/Visual Tweaks** (Optional):
- **None required** - current behavior is correct
- If user wants more consistent "feel", consider:
  - Adjusting inner/outer radius (e.g., 2m-10m instead of 3m-8m) for wider transition zone
  - Lowering `player_fade_power` from 2.0 to 1.5 for softer gradient
  - Adding a subtle circular outline at exactly 8m radius (debug feature) to make world-space distance clearer

### 2. Alternative: Screen-Space Only (NOT Recommended)

**If you wanted constant screen coverage** (hypothetical):
```gdscript
// Remove world-space fade entirely
float calculate_combined_fade() {
    return calculate_screen_space_fade();  // Screen-space only
}
```

**Why NOT to do this**:
- ❌ Breaks world-space gameplay distance (ceiling 10m away would fade differently based on zoom)
- ❌ Inconsistent with future lighting/visibility system
- ❌ Players lose spatial awareness of actual distances

### 3. Hybrid Approach: Weighted Blend (Complex, Not Worth It)

**Theoretical option** (not recommended):
```gdscript
float calculate_combined_fade() {
    float screen_fade = calculate_screen_space_fade();
    float world_fade = calculate_world_space_fade();

    // Weight based on camera distance (closer = more world-space)
    float camera_dist = length(CAMERA_POSITION_WORLD - player_world_position);
    float blend_factor = smoothstep(8.0, 25.0, camera_dist);

    return mix(world_fade, screen_fade, blend_factor);
}
```

**Why NOT to do this**:
- ⚠️ Overly complex for a temporary effect
- ⚠️ Breaks semantic clarity (what does vignette radius mean anymore?)
- ⚠️ Still needs replacement with lighting system anyway

## Implementation Plan

### Recommended Action: **NO CHANGES**

**Rationale**:
1. Current implementation is **mathematically correct** and **semantically meaningful**
2. Behavior matches industry standards (RTS vision radius, tactical overlays)
3. This is a **temporary visual effect** pending lighting system implementation
4. Changing it would introduce complexity without gameplay benefit

**User Education**:
The perceived width change is expected behavior for world-space effects under perspective cameras. When you zoom out, you see more of the world, so the fixed-radius vignette appears smaller relative to screen. This is correct and matches how actual 3D distances work.

**If User Still Wants Adjustment**:
Tweak radius parameters rather than changing coordinate space:
```gdscript
// In grid.gd or wherever shader uniforms are set
uniform float player_fade_inner_radius = 2.0;  // Was 3.0
uniform float player_fade_outer_radius = 10.0; // Was 8.0
```
- Wider transition zone (2m-10m) makes zoom-dependent appearance less noticeable
- Maintains world-space correctness
- Easy to tune based on playtesting feedback

## Future: Lighting-Based Visibility

### Transition Plan from Vignette to True Visibility

**Current System (Temporary)**:
- Dual vignette (screen-space + world-space combined)
- Simple fade based on distance from player
- No consideration of walls, obstacles, line-of-sight

**Future System (Proper Implementation)**:
This vignette will be replaced by a proper lighting/visibility simulation:

1. **Light Sources**:
   - Player carries a "light source" (flashlight, aura, psychic emanation)
   - Light intensity falls off with distance (inverse-square or custom curve)
   - Multiple lights can exist (other players, entities, environmental lights)

2. **Line-of-Sight / Occlusion**:
   - Walls block light propagation
   - Shadows cast by geometry
   - Possibly raycasting or shadow mapping

3. **Fog of War**:
   - Areas outside light radius are dark/invisible
   - Gradual falloff like current vignette
   - Possibly "memory" of previously seen areas (common in roguelikes)

### Research: Fog of War / Vision Radius Shader Techniques

From web research on RTS fog of war implementations:

**Common Approaches**:

1. **Texture-Based Rendering**:
   - Render visibility information into a RenderTexture
   - Each unit/player contributes a circular gradient
   - Combine multiple vision sources additively
   - Project texture onto world geometry via shader
   - **Example**: Unity RTS fog of war systems use black-to-white texture masks

2. **Grid-Based Visibility (Efficient for Tile Games)**:
   - Store visibility data per grid cell
   - Update only when player/units cross cell boundaries
   - Pass visibility data to shader as texture or uniform array
   - **Perfect fit for Backrooms' existing grid system!**

3. **Shader-Based Distance Checks**:
   - Pass array of "vision center" positions to shader (e.g., `uniform vec3 vision_sources[MAX_SOURCES]`)
   - Each fragment checks distance to nearest vision source
   - Combine multiple vision radii (max or additive)
   - **Scales poorly** beyond ~10-20 vision sources

4. **Godot-Specific Example** (from godotshaders.com):
   - "Basic Fog of War Shader" accepts array of points and camera variables
   - Uses `distance()` checks similar to current player vignette
   - Handles occlusion judgment in shader

**Recommended Approach for Backrooms**:

**Grid-Based Visibility Texture** (best for turn-based tile game):

```gdscript
# Pseudo-code for future system
# In Grid.gd or new VisibilityManager.gd:

func _ready():
    visibility_texture = ImageTexture.create_from_image(
        Image.create(GRID_SIZE, GRID_SIZE, false, Image.FORMAT_R8)
    )

func update_visibility(player_pos: Vector2i):
    var img = visibility_texture.get_image()

    # Clear previous visibility (fade to black)
    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            var dist = Vector2(x, y).distance_to(Vector2(player_pos))
            var visibility = 1.0 - smoothstep(INNER_RADIUS, OUTER_RADIUS, dist)
            img.set_pixel(x, y, Color(visibility, visibility, visibility, 1.0))

    # Future: Add line-of-sight checks here (raycast from player to each cell)
    # Future: Add "memory" (blend with previous frame, never fully black)

    visibility_texture.update(img)

# In shader:
uniform sampler2D visibility_map;
uniform vec2 grid_offset;  // For converting world XZ to grid UV

void fragment() {
    vec2 grid_uv = (world_position.xz - grid_offset) / GRID_SIZE;
    float visibility = texture(visibility_map, grid_uv).r;

    ALPHA *= visibility;  // Fade ceiling based on visibility
}
```

**Advantages**:
- ✅ Grid-aligned with existing tile system
- ✅ Easy to add line-of-sight (raycast on grid during update)
- ✅ Can implement "memory" (blend with previous visibility)
- ✅ Scales efficiently (128×128 texture = 16KB, updated only on player movement)
- ✅ Supports multiple vision sources (add contributions to same texture)
- ✅ Turn-based updates (no per-frame cost)

**Migration Path**:
1. Keep current vignette as "alpha 1" implementation
2. Build VisibilityManager as separate system
3. Add toggle to switch between vignette and visibility texture
4. Playtest both approaches
5. Once visibility system works, remove vignette code
6. Extend with line-of-sight, memory, multiple sources

### Future Feature: Dynamic Lighting

**Beyond Visibility** - actual light sources for atmosphere:

- **Light Propagation**: Simulate light bouncing off walls (simplified approximation)
- **Color Temperature**: Fluorescent flicker (Level 0), warm/cool zones
- **Animated Effects**: Electrical failure, pulsing anomalies
- **Sanity Integration**: Warp lighting colors/intensity based on player sanity stat

**Implementation**: Godot's existing lighting system (OmniLight3D, SpotLight3D) + custom shaders
- Use Forward+ rendering for multiple dynamic lights
- Screen-space shader for post-processing (bloom, aberration)
- Visibility texture as input to lighting calculations (only light visible areas)

## Summary

**Current Status**: ✅ **Working Correctly - No Changes Needed**

The player vignette is implemented correctly as a world-space effect. The perceived "width change" with zoom is mathematically correct perspective projection, not a bug. This behavior matches industry standards (RTS vision overlays, tactical cameras in EVE Online, etc.).

**Recommendation**: Keep current implementation unchanged. The vignette is a temporary visual aid pending proper lighting/visibility system implementation.

**Future Work**: Replace vignette with grid-based visibility texture system that includes:
- Line-of-sight occlusion
- Multiple vision sources
- "Memory" of seen areas (roguelike fog of war)
- Foundation for dynamic lighting effects

**If User Disagrees**: Tweak radius parameters (2m-10m instead of 3m-8m) to make zoom effect less noticeable, rather than changing coordinate space.

## References

### Web Research Sources

**Coordinate Spaces & Perspective**:
- [LearnOpenGL - Coordinate Systems](https://learnopengl.com/Getting-started/Coordinate-Systems)
- [Game Dev SE: Screen Space to World Space](https://gamedev.stackexchange.com/questions/189978/how-to-convert-screen-space-to-world-space)
- [Unity Perspective Camera Width in World Units](https://gamedev.stackexchange.com/questions/178599/unity-perspective-camera-width-height-in-visible-world-units)

**Vignette Effects**:
- [Harry Alisavakis: Shader Bits - Camera Distance](https://halisavakis.com/shader-bits-camera-distance-view-direction-and-normal-vectors/)
- GameDev.net: HLSL Vignetting (discusses zoom-dependent behavior)

**Fog of War Implementations**:
- [Godot Shaders: Basic Fog of War Shader](https://godotshaders.com/shader/basic-fog-of-war-shader/)
- [Gemserk: Implementing Fog of War for RTS Games in Unity (1/2)](https://blog.gemserk.com/2018/08/27/implementing-fog-of-war-for-rts-games-in-unity-1-2/)
- [Gemserk: Implementing Fog of War for RTS Games in Unity (2/2)](https://blog.gemserk.com/2018/11/20/implementing-fog-of-war-for-rts-games-in-unity-2-2/)
- [Game Dev SE: Efficient Fog of War Implementation](https://gamedev.stackexchange.com/questions/82432/how-to-implement-efficient-fog-of-war)

**RTS Camera & Vision Radius**:
- [EVE University Wiki: Tactical Overlay](https://wiki.eveuniversity.org/Tactical_overlay) (discusses concentric rings at various ranges)
- [Game Dev SE: Isometric RTS Camera](https://gamedev.stackexchange.com/questions/43281/how-to-add-isometric-rts-alike-perspective-and-scolling-in-unity)

**Technical Documentation**:
- [Shader Lesson 3: Screen-Space Effects](https://github.com/mattdesl/lwjgl-basics/wiki/ShaderLesson3)
- [codinBlack: Coordinate Spaces and Transformations](https://www.codinblack.com/coordinate-spaces-and-transformations-between-them/)
