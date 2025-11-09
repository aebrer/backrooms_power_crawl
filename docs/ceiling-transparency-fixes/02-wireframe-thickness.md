# Issue 2: Wireframe Lines Too Thick

## Problem

The current wireframe lines are too thick and obscure the underlying acoustic tile texture. The lines are intended to show structure and create a 90s VR/wireframe aesthetic, but at `wire_width = 8.0`, they cover too much of the screen and block visibility of the texture pattern beneath.

**Current State:**
- Wireframe lines use screen-space consistent thickness via `fwidth(barys)`
- Parameter: `wire_width = 8.0`
- Lines are anti-aliased with `wire_smoothness = 0.01`
- Result: Lines are too prominent, blocking the detailed acoustic tile texture

**Target Aesthetic:**
- Thin, crisp wireframe lines like 90s VR/CAD visualization
- Show triangle structure without obscuring the texture
- Maintain screen-space consistency (don't grow/shrink with distance)
- Clean, technical look with minimal aliasing

---

## Current Implementation

**Shader Location:** `/home/andrew/projects/backrooms_power_crawl/shaders/psx_ceiling.gdshader`

**Relevant Uniforms (Lines 28-32):**
```glsl
// Wireframe rendering
uniform vec4 wireframe_color : source_color = vec4(0.0, 1.0, 0.8, 0.5);
uniform float wire_width : hint_range(0.0, 40.0) = 8.0;
uniform float wire_smoothness : hint_range(0.0, 0.1) = 0.01;
uniform float wireframe_threshold : hint_range(0.0, 1.0) = 0.6;
```

**Wireframe Rendering (Lines 124-130):**
```glsl
// Wireframe rendering
vec3 deltas = fwidth(barys);
vec3 barys_s = smoothstep(
    deltas * wire_width - wire_smoothness,
    deltas * wire_width + wire_smoothness,
    barys
);
float wire_mix = min(barys_s.x, min(barys_s.y, barys_s.z));
```

**How It Works:**
1. **Barycentric coordinates** (`barys`): Each vertex gets (1,0,0), (0,1,0), or (0,0,1)
2. **Screen-space derivatives** (`fwidth(barys)`): Calculates how fast barycentric coords change per pixel
3. **Thickness calculation** (`deltas * wire_width`): Multiplies derivative by width parameter
4. **Anti-aliasing** (`smoothstep` with `wire_smoothness`): Creates smooth transition at edges
5. **Edge detection** (`min(barys_s.x, barys_s.y, barys_s.z)`): Closest edge determines wireframe alpha

This technique ensures lines remain constant thickness in screen-space regardless of triangle size or viewing distance.

---

## Research Findings

### Core Technique: Barycentric + fwidth()

**How fwidth() Enables Screen-Space Consistency:**

The `fwidth()` function is the key to constant-width lines. It calculates `abs(dFdx(p)) + abs(dFdy(p))`, which measures how fast a value changes across pixels in both X and Y directions.

**Why This Matters:**
- Without derivatives: A fixed barycentric threshold (e.g., 0.05) could span 1000 pixels, 5 pixels, or less than a pixel depending on triangle size
- With derivatives: Dividing thickness by `fwidth(barys)` converts "barycentric units" to "pixel units", making lines consistently sized

**The Pattern (from research):**
```glsl
float delta = fwidth(dist);
float alpha = smoothstep(thickness - delta, thickness, dist);
```

This creates lines that are `thickness` pixels wide, with smooth anti-aliasing over `delta` pixel width.

### Line Thickness Control Methods

**1. Direct Parameter Adjustment (Simplest)**

The current implementation already supports this via the `wire_width` uniform. The research suggests typical values for thin lines:

- **Ultra-thin (CAD/technical)**: 0.5 - 1.5 (barely visible structure lines)
- **Thin (90s VR aesthetic)**: 1.5 - 3.0 (visible but not dominant)
- **Medium (debugging/visibility)**: 3.0 - 6.0 (clear structure, some texture visible)
- **Thick (current)**: 6.0 - 10.0 (dominant lines, texture obscured)

**From glsl-solid-wireframe library:**
> "A thickness of 1.0 or 5.0 should map to the amount of barycentric-units that determine if a pixel is on, off, or between the line."

**2. Improved Anti-Aliasing**

The research shows a common pattern for smoother anti-aliasing:

```glsl
// Research-recommended pattern
vec3 deltas = fwidth(barys);
vec3 smoothed = smoothstep(vec3(0.0), deltas * wire_width, barys);
float edge_factor = min(smoothed.x, min(smoothed.y, smoothed.z));
```

This differs from the current implementation in two ways:
- Uses `smoothstep(0.0, deltas * wire_width, barys)` instead of `smoothstep(deltas * wire_width - smoothness, deltas * wire_width + smoothness, barys)`
- Simpler - the anti-aliasing is inherent in the fwidth derivative, no separate smoothness parameter needed

**3. Distance-Adaptive Thickness (Optional Enhancement)**

For very dense meshes or distant ceilings, research suggests scaling line width with distance:

```glsl
// Scale line width based on distance from camera
float view_dist = length(VIEW);
float adaptive_width = wire_width * mix(1.0, 0.3, smoothstep(5.0, 20.0, view_dist));

vec3 deltas = fwidth(barys);
vec3 barys_s = smoothstep(
    deltas * adaptive_width,
    deltas * adaptive_width + wire_smoothness,
    barys
);
```

**Benefits:**
- Lines stay visible at long distances (don't become sub-pixel)
- Lines fade out when mesh is very dense (prevent visual noise)
- Adds depth cue (thin = close, thicker = far)

**From research:**
> "A useful effect is to scale the line width as a function of depth, which adds a strong depth cue. Additionally, for very dense meshes, it's useful to fade out the wireframe as a function of distance since the shading of filled polygons becomes much more visible."

**4. Resolution-Aware Scaling (Advanced)**

For supporting different display resolutions (1080p vs 4K), lines can scale with viewport size:

```glsl
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
float resolution_scale = viewport_size.y / 1080.0;
float scaled_width = wire_width / resolution_scale;
```

This ensures 2-pixel lines on 1080p remain 2-pixel (not 4-pixel) on 4K displays.

### Avoiding Corner Artifacts

**Problem identified in research:**
> "Aliasing artifacts can appear in lines near triangle corners because the nearest edge suddenly changes in those regions."

**Solution:**
The current implementation correctly uses `min(barys_s.x, min(barys_s.y, barys_s.z))`, which:
- Evaluates each edge independently
- Takes minimum (closest edge)
- Avoids sudden discontinuities at corners

**Alternative approach (if artifacts appear):**
```glsl
// Blend derivatives separately, then take minimum
vec3 deltas = fwidth(barys);
vec3 smoothed_edges = smoothstep(vec3(0.0), deltas * wire_width, barys);
float edge_factor = min(smoothed_edges.x, min(smoothed_edges.y, smoothed_edges.z));
```

---

## Recommended Solutions

### Option 1: Simple Parameter Change (Immediate Fix)

**Change:**
```glsl
uniform float wire_width : hint_range(0.0, 40.0) = 2.0;  // Was 8.0
```

**Benefits:**
- Instant fix, no code changes
- Preserves all existing functionality
- Easy to tweak in-editor via material inspector

**Recommended Values:**
- **Start with:** `2.0` (thin 90s VR aesthetic)
- **If too thin:** `3.0` (slightly more visible)
- **If too thick:** `1.5` (ultra-minimal)

**Test Range:** 1.0 - 4.0

---

### Option 2: Simplified Anti-Aliasing (Code Improvement)

**Replace lines 124-130 with:**
```glsl
// Wireframe rendering (simplified pattern from research)
vec3 deltas = fwidth(barys);
vec3 barys_s = smoothstep(vec3(0.0), deltas * wire_width, barys);
float wire_mix = min(barys_s.x, min(barys_s.y, barys_s.z));
```

**Changes:**
- Remove `wire_smoothness` parameter (no longer needed)
- Simplify smoothstep range (0.0 to deltas * wire_width)
- Anti-aliasing is automatic via fwidth()

**Benefits:**
- Cleaner code, one less parameter to tune
- More standard implementation (matches research examples)
- Better anti-aliasing at very thin line widths

**Recommended `wire_width`:** Start at 2.5 (may need slight adjustment from Option 1 due to different smoothstep range)

---

### Option 3: Distance-Adaptive Lines (Enhancement)

**Add uniform:**
```glsl
uniform bool enable_adaptive_wireframe = false;
uniform float adaptive_near_width : hint_range(0.1, 10.0) = 2.0;
uniform float adaptive_far_width : hint_range(0.1, 10.0) = 4.0;
uniform float adaptive_near_distance : hint_range(1.0, 50.0) = 5.0;
uniform float adaptive_far_distance : hint_range(1.0, 50.0) = 20.0;
```

**Replace lines 124-130 with:**
```glsl
// Wireframe rendering with distance adaptation
float effective_width = wire_width;

if (enable_adaptive_wireframe) {
    // Calculate view-space distance
    float view_dist = length(VIEW);

    // Scale line width based on distance
    float dist_factor = smoothstep(
        adaptive_near_distance,
        adaptive_far_distance,
        view_dist
    );
    effective_width = mix(adaptive_near_width, adaptive_far_width, dist_factor);
}

vec3 deltas = fwidth(barys);
vec3 barys_s = smoothstep(
    deltas * effective_width - wire_smoothness,
    deltas * effective_width + wire_smoothness,
    barys
);
float wire_mix = min(barys_s.x, min(barys_s.y, barys_s.z));
```

**Benefits:**
- Lines stay visible at long distances
- Prevents visual noise when mesh is dense
- Adds subtle depth cue
- Optional (can be toggled off)

**Use Cases:**
- Large open areas with distant ceilings
- Very dense triangle meshes
- Cinematic depth-of-field effects

---

### Option 4: Resolution-Aware Scaling (Future-Proofing)

**Add uniform:**
```glsl
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
uniform bool enable_resolution_scaling = true;
```

**Modify wire_width calculation:**
```glsl
float effective_width = wire_width;

if (enable_resolution_scaling) {
    // Scale relative to 1080p baseline
    float resolution_scale = viewport_size.y / 1080.0;
    effective_width = effective_width / resolution_scale;
}

vec3 deltas = fwidth(barys);
vec3 barys_s = smoothstep(
    deltas * effective_width - wire_smoothness,
    deltas * effective_width + wire_smoothness,
    barys
);
float wire_mix = min(barys_s.x, min(barys_s.y, barys_s.z));
```

**Benefits:**
- Consistent line width on 1080p, 1440p, 4K displays
- Future-proof for high-DPI screens
- Automatic scaling, no manual adjustment needed

**Implementation Note:**
Would require passing viewport dimensions from GDScript:
```gdscript
# In ceiling material setup
material.set_shader_parameter("viewport_size", get_viewport().get_visible_rect().size)
```

---

## Implementation Plan

### Phase 1: Immediate Fix (Recommended First Step)

**Action:** Change `wire_width` default from 8.0 to 2.0

**File:** `/home/andrew/projects/backrooms_power_crawl/shaders/psx_ceiling.gdshader`
**Line 30:**
```glsl
uniform float wire_width : hint_range(0.0, 40.0) = 2.0;  // Changed from 8.0
```

**Testing:**
1. Load game and observe ceiling wireframe
2. Test range: 1.0 (ultra-thin) to 4.0 (moderate)
3. Verify texture is visible through wireframe
4. Check that lines are still crisp and anti-aliased

**Expected Result:**
- Wireframe shows triangle structure clearly
- Acoustic tile texture is prominently visible
- Lines are thin but not too faint (90s VR aesthetic)

---

### Phase 2: Simplified Anti-Aliasing (Optional Refinement)

**Action:** Replace current smoothstep pattern with research-recommended approach

**File:** `/home/andrew/projects/backrooms_power_crawl/shaders/psx_ceiling.gdshader`

**Changes:**
1. Remove `wire_smoothness` uniform (line 31)
2. Replace lines 124-130:
   ```glsl
   // Wireframe rendering (simplified)
   vec3 deltas = fwidth(barys);
   vec3 barys_s = smoothstep(vec3(0.0), deltas * wire_width, barys);
   float wire_mix = min(barys_s.x, min(barys_s.y, barys_s.z));
   ```

**Testing:**
1. Verify anti-aliasing is still smooth
2. Test at very thin widths (1.0 - 1.5)
3. Compare before/after at edges and corners

**Expected Result:**
- Cleaner code with one less parameter
- Similar or better anti-aliasing quality
- Slight adjustment to `wire_width` may be needed

---

### Phase 3: Distance-Adaptive Lines (Future Enhancement)

**Action:** Add distance-based line width scaling

**When to implement:**
- If wireframe becomes too dense at far distances
- If player feedback requests depth cues
- After Phase 1 is validated

**Testing:**
1. Test in large open areas with distant ceilings
2. Verify lines don't become sub-pixel at distance
3. Check that near lines aren't too thin
4. Ensure fade transition is smooth

---

## Visual Examples

### Expected Appearance at Different Settings

**wire_width = 1.0 (Ultra-Thin):**
- Lines barely visible, like technical CAD drawings
- Maximum texture visibility
- May be too subtle for gameplay readability
- Good for: Minimalist aesthetic, high-detail textures

**wire_width = 2.0 (Recommended Default):**
- Thin but clearly visible lines
- 90s VR/wireframe aesthetic achieved
- Texture pattern prominently visible
- Good balance of structure and detail
- **Target setting for this project**

**wire_width = 3.0 (Moderate):**
- More prominent structure lines
- Texture still clearly visible
- Good for debugging or visual clarity
- Slightly less "technical" look

**wire_width = 4.0 - 5.0 (Thick):**
- Structure dominates over texture
- Lines become visual feature, not accent
- Texture partially obscured
- Good for: Stylized look, less detail needed

**wire_width = 8.0 (Current - Too Thick):**
- Lines cover majority of screen space
- Texture barely visible between lines
- Structure completely dominates
- **This is the problem we're fixing**

### Edge Cases to Test

**Thin lines at distance:**
- Lines may become sub-pixel and disappear
- Consider distance-adaptive solution if this occurs

**Dense triangle meshes:**
- Too many thin lines can create moiré patterns
- Test with high-poly areas

**Corner artifacts:**
- Current min() approach should prevent discontinuities
- Verify smooth transitions at triangle corners

**Different viewing angles:**
- Lines should remain consistent thickness
- fwidth() should handle perspective correctly

---

## References

### Research Sources

1. **glsl-solid-wireframe library** (rreusser/GitHub)
   - https://github.com/rreusser/glsl-solid-wireframe
   - Comprehensive barycentric wireframe implementation
   - "Thickness of 1.0 or 5.0 should map to pixel units"

2. **Catlike Coding: Flat and Wireframe Shading**
   - https://catlikecoding.com/unity/tutorials/advanced-rendering/flat-and-wireframe-shading/
   - Detailed tutorial on barycentric coordinate setup
   - Explains smoothstep patterns and anti-aliasing

3. **Using fwidth for distance-based anti-aliasing** (numb3r23)
   - http://www.numb3r23.net/2015/08/17/using-fwidth-for-distance-based-anti-aliasing/
   - Core technique explanation
   - Pattern: `float aaf = fwidth(dst); float alpha = smoothstep(radius - aaf, radius, dst)`

4. **Made by Evan: Anti-Aliased Grid Shader**
   - https://madebyevan.com/shaders/grid/
   - Practical grid line implementation
   - Demonstrates thin line anti-aliasing

5. **GL_EXT_fragment_shader_barycentric: Wireframe** (Wunk)
   - https://wunkolo.github.io/post/2022/07/gl_ext_fragment_shader_barycentric-wireframe/
   - Advanced barycentric techniques
   - Screen-space derivative calculations

6. **Shader-Based Wireframe Drawing** (CGG Journal)
   - https://cgg-journal.com/2008-2/06/index.html
   - Distance attenuation for line width
   - LOD integration techniques

7. **WebGL Wireframes** (mattdesl/GitHub)
   - https://github.com/mattdesl/webgl-wireframes
   - Stylized wireframe rendering patterns
   - Various thickness control methods

### Key Concepts Referenced

- **fwidth()**: `abs(dFdx(p)) + abs(dFdy(p))` - screen-space derivative magnitude
- **Barycentric coordinates**: (1,0,0), (0,1,0), (0,0,1) per triangle vertex
- **smoothstep()**: Smooth Hermite interpolation for anti-aliasing
- **Screen-space consistency**: Lines remain constant pixel width regardless of 3D distance
- **Distance adaptation**: Scale line width with view distance for visibility/LOD

---

## Conclusion

The immediate fix is straightforward: **reduce `wire_width` from 8.0 to 2.0**. This single parameter change will achieve the thin, crisp 90s VR wireframe aesthetic while maintaining excellent texture visibility.

The research confirms our implementation technique is sound - using barycentric coordinates with `fwidth()` for screen-space consistency is the industry-standard approach. The only issue is the thickness parameter was set too high for the intended aesthetic.

**Recommended next steps:**
1. Test `wire_width = 2.0` immediately
2. Fine-tune between 1.5 - 3.0 based on visual preference
3. Consider simplified anti-aliasing (Phase 2) for cleaner code
4. Keep distance-adaptive option (Phase 3) for future if needed

The acoustic tile texture should become prominently visible while the wireframe structure remains clear and technical-looking.
