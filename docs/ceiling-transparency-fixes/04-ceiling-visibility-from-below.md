# Issue 4: Ceiling Vignette Visible From Below

**Date**: 2025-11-09
**Status**: Research & Design Phase
**Priority**: Medium - Breaks immersion when viewing ceiling from inside room

---

## Problem

When the camera tilts upward and looks at the ceiling from below (player is inside the room, looking up), the vignette/transparency effects are still active. This creates a jarring visual issue where the ceiling appears wireframe or transparent even when the player is clearly underneath it looking up.

**Current behavior**: Ceiling fades/shows wireframe effects regardless of camera angle
**Desired behavior**: When camera pitch is steep (looking up from inside room), show full opaque ceiling without vignette

**Why this matters**:
- Breaks immersion - when inside a room looking up, you should see a solid ceiling
- The vignette system was designed for top-down viewing (looking down at ceiling from above)
- When underneath, the "hide distant ceiling" logic doesn't apply - you want to see what's above you

---

## Camera System Analysis

### TacticalCamera Pitch Angles

From `/home/andrew/projects/backrooms_power_crawl/scripts/player/tactical_camera.gd`:

```gdscript
# Camera control
@export var pitch_min: float = -80.0    # Look down limit (steep angle, looking up)
@export var pitch_max: float = -10.0    # Look up limit (shallow angle, looking down)
@export var pitch_near: float = -30.0   # Default when zoomed in
@export var pitch_far: float = -60.0    # Default when zoomed out
```

**Key insight**: Pitch values are negative (looking down is the default for tactical view)
- **pitch = -10°**: Shallow angle, camera nearly level, looking down at world from high angle
- **pitch = -45°**: Default tactical view, moderate top-down perspective
- **pitch = -80°**: Steep angle, camera looking almost straight down (or up from below!)

### Camera Hierarchy

```
TacticalCamera (Node3D)
└── HorizontalPivot (Node3D) - Yaw rotation
    └── VerticalPivot (Node3D) - Pitch rotation
        └── SpringArm3D
            └── Camera3D
```

**Camera positioning relative to player**:
- Player is at grid position (center of TacticalCamera node)
- SpringArm extends away from player
- When pitch = -45°, camera is behind and above player, looking down
- When pitch = -80° and player is inside a room, camera may be below ceiling, looking up at it

### The Critical Question

**When is the camera "looking up at ceiling from below" vs "looking down at ceiling from above"?**

The answer depends on:
1. **Camera pitch angle** (steep vs shallow)
2. **Camera Y position relative to ceiling** (below ceiling Y=3.0 vs above)
3. **View direction dot product with surface normal** (positive = same direction, negative = opposite)

---

## Research Findings

### Technique 1: View Direction Dot Product with Surface Normal

**The standard GLSL/shader approach for detecting surface orientation relative to camera:**

```glsl
// In fragment shader:
float view_dot_normal = dot(normalize(VIEW), normalize(NORMAL));
```

**Interpretation**:
- `VIEW` in Godot = vector from fragment to camera (in view space)
- `NORMAL` = surface normal vector (ceiling points up, Y+)
- **Dot product > 0**: Camera is on same side as normal (looking at front face)
- **Dot product < 0**: Camera is on opposite side (looking at back face)

**For ceiling (normal = Y+)**:
- Dot > 0: Camera is above ceiling, looking down at it (front face)
- Dot < 0: Camera is below ceiling, looking up at it (back face)

**Source**: [LearnOpenGL - Basic Lighting](https://learnopengl.com/Lighting/Basic-lighting), [GLSL Backface Detection](https://community.khronos.org/t/how-to-check-for-backface-in-fragment-shader/59252)

### Technique 2: Camera Position Relative to Surface

**Alternative approach: Compare camera world Y position to ceiling Y position**

```glsl
// In vertex shader:
uniform vec3 camera_world_position;
float camera_y = camera_world_position.y;
float ceiling_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
bool camera_below_ceiling = camera_y < ceiling_y;
```

**Pass to fragment as varying variable:**
```glsl
varying float camera_to_surface_y_offset;

void vertex() {
    camera_to_surface_y_offset = camera_world_position.y - world_position.y;
}

void fragment() {
    if (camera_to_surface_y_offset < 0.0) {
        // Camera is below surface, disable vignette
    }
}
```

**Pros**: Simple, explicit, works for flat horizontal surfaces
**Cons**: Doesn't account for angled surfaces or complex geometry

### Technique 3: Camera Pitch Angle Uniform

**Pass camera pitch angle from TacticalCamera to shader as uniform:**

```gdscript
# In TacticalCamera:
func _process(delta: float):
    var current_pitch = v_pivot.rotation_degrees.x
    # Update shader parameter
    ceiling_material.set_shader_parameter("camera_pitch", current_pitch)
```

```glsl
// In shader:
uniform float camera_pitch = -45.0;

void fragment() {
    // If pitch is steep (near -80), camera might be looking up
    // Disable vignette when looking up from inside
    if (camera_pitch < -60.0) {
        // Consider disabling vignette
    }
}
```

**Pros**: Simple to implement, direct control
**Cons**: Doesn't account for camera position (could be above ceiling with steep pitch)

### Technique 4: gl_FrontFacing Built-in (Not Available in Godot)

**Standard OpenGL approach**:
```glsl
void fragment() {
    if (!gl_FrontFacing) {
        // We're looking at back face, disable effects
    }
}
```

**Note**: Godot does NOT expose `gl_FrontFacing` in spatial shaders, but the shader is already using `cull_disabled`, so both faces render anyway.

**Source**: [OpenGL Backface Detection](https://community.khronos.org/t/how-to-check-for-backface-in-fragment-shader/59252)

---

## Recommended Solutions

### Option 1: View Direction Dot Product (RECOMMENDED)

**Best approach: Use VIEW and NORMAL to detect viewing direction**

**Implementation**:

```glsl
void fragment() {
    // Base PSX rendering
    vec4 color_base = COLOR * modulate_color;
    vec4 texture_color = texture(albedoTex, UV);
    ALBEDO = (color_base * texture_color).rgb;
    ALPHA = texture_color.a * color_base.a;

    // Ceiling fade system
    if (enable_ceiling_fade) {
        // NEW: Detect if camera is below ceiling looking up
        vec3 view_dir = normalize(VIEW);
        vec3 normal_dir = normalize(NORMAL);
        float view_dot_normal = dot(view_dir, normal_dir);

        // If dot product is negative, we're looking at ceiling from below
        // Disable vignette completely
        if (view_dot_normal < 0.0) {
            // Camera is below ceiling, render fully opaque
            // Skip all vignette calculations
        } else {
            // Camera is above ceiling, apply vignette as normal
            float fade = calculate_combined_fade();

            if (fade < wireframe_threshold) {
                // Wireframe rendering...
            } else {
                // Fade in based on distance...
            }
        }
    }
}
```

**Why this is best**:
- ✅ Automatic detection based on actual viewing geometry
- ✅ Works for any camera angle or position
- ✅ No external uniforms needed (self-contained)
- ✅ Handles edge cases (camera moving through ceiling)
- ✅ Standard shader technique used across industry

**Refinement: Smooth transition zone**
```glsl
// Instead of hard cutoff at 0.0, use a smooth transition
float viewing_from_below_factor = smoothstep(-0.2, 0.2, view_dot_normal);
// 0.0 = fully below (disable vignette)
// 1.0 = fully above (enable vignette)

if (viewing_from_below_factor < 0.1) {
    // Fully opaque, no vignette
} else {
    float fade = calculate_combined_fade();
    fade *= viewing_from_below_factor; // Scale by viewing angle
    // ... rest of vignette code
}
```

---

### Option 2: Camera World Position Uniform

**Pass camera world position and compare Y coordinates**

**Implementation**:

```glsl
// Add to uniforms (already have player_world_position)
uniform vec3 camera_world_position = vec3(0.0);

void fragment() {
    if (enable_ceiling_fade) {
        // Check if camera is below this fragment
        float camera_y = camera_world_position.y;
        float fragment_y = world_position.y;

        if (camera_y < fragment_y - 0.5) {
            // Camera is below ceiling by at least 0.5 units
            // Render fully opaque
        } else {
            // Apply vignette as normal
            float fade = calculate_combined_fade();
            // ...
        }
    }
}
```

**Pros**:
- ✅ Simple height comparison
- ✅ Easy to debug (can print camera Y and ceiling Y)
- ✅ Explicit control over threshold (0.5 unit buffer)

**Cons**:
- ❌ Requires passing camera position uniform every frame
- ❌ Doesn't handle angled ceilings or ramps
- ❌ Less flexible than dot product approach

---

### Option 3: Camera Pitch Angle Heuristic

**Use camera pitch as a simple heuristic**

**Implementation**:

```glsl
uniform float camera_pitch = -45.0; // Degrees

void fragment() {
    if (enable_ceiling_fade) {
        // Very steep pitch suggests looking up from below
        if (camera_pitch < -70.0) {
            // Likely viewing from below, reduce/disable vignette
        } else {
            // Normal vignette
            float fade = calculate_combined_fade();
            // ...
        }
    }
}
```

**Pros**:
- ✅ Very simple to implement
- ✅ Single uniform to pass

**Cons**:
- ❌ Unreliable (steep pitch doesn't always mean "below ceiling")
- ❌ Camera could be above ceiling with steep pitch
- ❌ Doesn't account for actual spatial relationship

---

## Implementation Plan

### Recommended Approach: Option 1 (View Direction Dot Product)

#### Step 1: Modify Fragment Shader

Edit `/home/andrew/projects/backrooms_power_crawl/shaders/psx_ceiling.gdshader`:

```glsl
void fragment() {
    // Base PSX rendering
    vec4 color_base = COLOR * modulate_color;
    vec4 texture_color = texture(albedoTex, UV);
    ALBEDO = (color_base * texture_color).rgb;
    ALPHA = texture_color.a * color_base.a;

    // Ceiling fade system
    if (enable_ceiling_fade) {
        // STEP 1: Check if we're viewing ceiling from below
        vec3 view_dir = normalize(VIEW);
        vec3 normal_dir = normalize(NORMAL);
        float view_dot_normal = dot(view_dir, normal_dir);

        // STEP 2: Create smooth transition factor
        // When view_dot_normal < 0, camera is below ceiling looking up
        // Use smoothstep for gradual transition
        float viewing_from_above = smoothstep(-0.1, 0.1, view_dot_normal);
        // viewing_from_above = 0.0 -> fully below (disable vignette)
        // viewing_from_above = 1.0 -> fully above (enable vignette)

        // STEP 3: Early exit if viewing from below
        if (viewing_from_above < 0.05) {
            // Fully opaque, no transparency or wireframe
            return;
        }

        // STEP 4: Apply vignette scaled by viewing angle
        float fade = calculate_combined_fade();
        fade = mix(0.0, fade, viewing_from_above);

        if (fade < wireframe_threshold) {
            // Wireframe rendering
            vec3 deltas = fwidth(barys);
            vec3 barys_s = smoothstep(
                deltas * wire_width - wire_smoothness,
                deltas * wire_width + wire_smoothness,
                barys
            );
            float wire_mix = min(barys_s.x, min(barys_s.y, barys_s.z));

            ALBEDO = mix(wireframe_color.rgb, ALBEDO, wire_mix);
            ALPHA = mix(wireframe_color.a, 0.0, wire_mix);

            if (ALPHA < 0.01) {
                discard;
            }
        } else {
            // Fade in based on distance
            ALPHA *= fade;
            if (ALPHA < 0.01) {
                discard;
            }
        }
    }
}
```

#### Step 2: Test in Various Camera Positions

**Test cases**:
1. Camera at Y=5.0, pitch=-45° (above ceiling, looking down) → Vignette should work
2. Camera at Y=1.5, pitch=-80° (below ceiling, looking up) → Ceiling should be opaque
3. Camera at Y=2.5, pitch=-30° (near ceiling height 3.0, looking slightly down) → Smooth transition
4. Camera moving from Y=5.0 to Y=1.0 → Vignette should fade out smoothly

#### Step 3: Fine-tune Transition Zone

Adjust `smoothstep(-0.1, 0.1, view_dot_normal)` parameters:
- Wider range `(-0.3, 0.3)` = smoother, more gradual transition
- Narrower range `(-0.05, 0.05)` = sharper cutoff at horizon line

#### Step 4: Optional Debug Visualization

**Add debug uniform to visualize dot product:**

```glsl
uniform bool debug_view_direction = false;

void fragment() {
    if (debug_view_direction) {
        float view_dot_normal = dot(normalize(VIEW), normalize(NORMAL));
        // Red = below, Green = above, Yellow = transition
        ALBEDO = vec3(
            1.0 - smoothstep(-0.1, 0.1, view_dot_normal), // Red when below
            smoothstep(-0.1, 0.1, view_dot_normal),        // Green when above
            0.0
        );
        return;
    }
    // ... normal rendering
}
```

---

## Expected Behavior

### After Fix

**Camera looking down from above (pitch near -10° to -45°)**:
- ✅ Vignette active
- ✅ Screen-space and world-space fading work
- ✅ Wireframe at edges, opaque near center/player
- ✅ Exactly as current behavior

**Camera looking up from below (pitch near -80°, inside room)**:
- ✅ Ceiling fully opaque
- ✅ No transparency or wireframe
- ✅ Full texture visibility
- ✅ Acts like a normal ceiling viewed from inside

**Camera at horizon (pitch ~= angle where camera is level with ceiling)**:
- ✅ Smooth transition between opaque and vignette
- ✅ No harsh popping or sudden changes
- ✅ Gradual fade as viewing angle changes

---

## Integration Points

### No TacticalCamera Changes Needed!

**The beauty of Option 1**: Shader handles everything automatically using built-in vectors.

No need to:
- ❌ Pass camera pitch as uniform
- ❌ Pass camera world position (beyond existing player position)
- ❌ Modify TacticalCamera script
- ❌ Add any update logic

**Self-contained in shader**:
- VIEW vector automatically updated per fragment
- NORMAL vector automatically updated per fragment
- Dot product calculation is fast and automatic

### Potential Future Enhancement

If we want to expose controls to designers:

```glsl
// Optional: Control transition zone
uniform float view_transition_threshold : hint_range(-1.0, 1.0) = 0.0;
uniform float view_transition_smoothness : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    float view_dot_normal = dot(normalize(VIEW), normalize(NORMAL));
    float viewing_from_above = smoothstep(
        view_transition_threshold - view_transition_smoothness,
        view_transition_threshold + view_transition_smoothness,
        view_dot_normal
    );
    // ... rest of code
}
```

---

## Alternative Approaches Considered

### Why Not Camera Pitch?

Camera pitch doesn't tell us spatial relationship:
- Camera could be at Y=10.0 with pitch=-80° (above ceiling, looking straight down)
- Camera could be at Y=1.0 with pitch=-80° (below ceiling, looking up)
- Same pitch, completely different viewing scenarios

### Why Not World Position Y Comparison?

Works well for flat ceilings, but:
- Requires passing camera position uniform (extra state management)
- Doesn't handle angled surfaces or ramps
- Less flexible than view direction approach
- More code to maintain (update uniform every frame)

### Why View Direction Dot Product Wins

- ✅ Automatic detection of actual viewing geometry
- ✅ Works for any surface orientation
- ✅ No external uniforms needed
- ✅ Standard graphics programming technique
- ✅ Handles edge cases naturally
- ✅ Fast computation (single dot product)

---

## Technical Deep Dive: Understanding VIEW and NORMAL

### Godot Spatial Shader Coordinate Spaces

**VIEW vector**:
- Provided in **view space** (camera coordinate system)
- Points from fragment to camera
- Normalized unit vector
- **Note**: Godot documentation has historically been confusing about VIEW direction
  - Some docs say "camera to fragment", but it's actually "fragment to camera"
  - See [Godot Issue #50449](https://github.com/godotengine/godot/issues/50449)

**NORMAL vector**:
- Surface normal in **view space** (camera coordinate system)
- Points perpendicular to surface
- For ceiling with normal Y+ in world space, transforms to camera view space
- Normalized unit vector

### Dot Product Interpretation

```
dot(VIEW, NORMAL) = |VIEW| * |NORMAL| * cos(angle)
```

Since both are normalized:
```
dot(VIEW, NORMAL) = cos(angle between VIEW and NORMAL)
```

**For horizontal ceiling (normal points up in world space)**:

| Camera Position | VIEW Direction | NORMAL Direction | Dot Product | Interpretation |
|----------------|---------------|-----------------|-------------|----------------|
| Above ceiling, looking down | Down | Up | Positive | Same hemisphere |
| Below ceiling, looking up | Up | Up | Negative | Opposite hemispheres |
| At ceiling level | Horizontal | Up | ~0.0 | Perpendicular |

**Visual diagram**:
```
Above ceiling:
    Camera
      ↓ VIEW (points down toward fragment)
    ━━━━━━━━━━ Ceiling
      ↑ NORMAL (points up toward camera)
    dot(VIEW, NORMAL) > 0

Below ceiling:
    ━━━━━━━━━━ Ceiling
      ↑ NORMAL (points up away from camera)
      ↑ VIEW (points up toward camera)
    Camera
    dot(VIEW, NORMAL) < 0
```

---

## Performance Considerations

### Computational Cost

**Added operations per fragment**:
```glsl
vec3 view_dir = normalize(VIEW);        // ~6 ops (sqrt + 3 divides)
vec3 normal_dir = normalize(NORMAL);    // ~6 ops
float dot_product = dot(view_dir, normal_dir);  // 3 muls + 2 adds
float smoothstep_result = smoothstep(-0.1, 0.1, dot_product);  // ~8 ops
```

**Total**: ~25 operations per fragment

**Context**: Existing shader already does:
- Texture sampling (expensive)
- Wireframe barycentric calculations (many ops)
- Two vignette calculations (distance, smoothstep, pow)
- Multiple alpha blending operations

**Verdict**: ✅ Negligible impact, well within budget for modern GPUs

### Early Exit Optimization

```glsl
if (viewing_from_above < 0.05) {
    return; // Skip all vignette calculations
}
```

When viewing from below, this **saves** performance by avoiding:
- `calculate_combined_fade()` (2 distance calculations, smoothsteps, pow)
- Wireframe barycentric smoothing
- Alpha blending logic

**Net result**: Likely performance neutral or slightly faster when inside rooms

---

## References

### GLSL/Shader Techniques
- [LearnOpenGL - Basic Lighting (View/Normal Dot Product)](https://learnopengl.com/Lighting/Basic-lighting)
- [Khronos Forums - Backface Detection in Fragment Shader](https://community.khronos.org/t/how-to-check-for-backface-in-fragment-shader/59252)
- [Harry Alisavakis - Shader Bits: View Direction and Normal Vectors](https://halisavakis.com/shader-bits-camera-distance-view-direction-and-normal-vectors/)

### Godot-Specific
- [Godot Spatial Shader Reference (VIEW built-in)](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)
- [Godot Issue #50449 - VIEW Direction Confusion](https://github.com/godotengine/godot/issues/50449)
- [Stack Overflow - Godot Camera Angle in Shader](https://stackoverflow.com/questions/69048732/how-to-determine-camera-angle-in-shader)

### GLSL Dot Product Math
- [GLSL Programming - Two-Sided Surfaces](https://en.wikibooks.org/wiki/GLSL_Programming/GLUT/Two-Sided_Surfaces)
- [Stack Overflow - Angle Between View Vector and Normal](https://stackoverflow.com/questions/59492385/angle-between-view-vector-and-normal)

---

## Next Steps

### Implementation Checklist

1. **Edit shader** (`psx_ceiling.gdshader`):
   - Add view direction dot product calculation
   - Add smooth transition factor
   - Add early exit for below-ceiling viewing
   - Scale fade by viewing angle

2. **Test in editor**:
   - Run game with controller
   - Move camera to various Y positions
   - Tilt camera up/down through full range
   - Verify smooth transitions

3. **Debug visualization** (optional):
   - Add debug uniform to shader
   - Visualize dot product as color
   - Identify exact transition zones

4. **Fine-tune parameters**:
   - Adjust smoothstep range for transition smoothness
   - Test with different ceiling heights
   - Validate at zoom extremes (near/far)

5. **Integration testing**:
   - Test with existing screen-space vignette
   - Test with existing world-space vignette
   - Ensure wireframe still works at edges when above ceiling
   - Verify performance impact is negligible

6. **Documentation**:
   - Update ARCHITECTURE.md with view direction detection
   - Document shader parameters for designers
   - Add comments explaining dot product logic

---

## Conclusion

**Recommended Solution**: Use VIEW/NORMAL dot product to detect viewing direction and disable ceiling vignette when camera is below ceiling looking up.

**Why it's the best choice**:
- Automatic detection based on actual geometry
- No external state management needed
- Works for any camera configuration
- Standard graphics programming technique
- Negligible performance impact
- Handles edge cases naturally

**Implementation complexity**: Low (single shader edit, ~15 lines of code)

**Expected results**: Seamless transition between tactical top-down view (vignette active) and inside-room view (ceiling fully opaque).

---

**Ready for implementation!**
