# Issue 1: Wireframe Shows Triangle Diagonals Instead of Quad Grid

**Status**: Research Complete
**Priority**: High
**Affected Shader**: `/home/andrew/projects/backrooms_power_crawl/shaders/psx_ceiling.gdshader`

---

## Problem Statement

The current ceiling wireframe shader renders triangle edges instead of quad grid lines. Each GridMap tile consists of 2 triangles forming a quad, resulting in 5 visible lines per tile (4 quad edges + 1 diagonal) instead of the desired 4 quad edges.

**Current Visual**: ▦ (quad with diagonal slash)
**Desired Visual**: □ (clean quad outline)

**Root Cause**: The barycentric coordinate approach (lines 83-89, 118-133) detects all triangle edges uniformly, with no mechanism to distinguish or suppress the diagonal edge that bisects each quad.

---

## Current Implementation Analysis

### Barycentric Wireframe Technique

```gdscript
// vertex() shader (lines 83-90)
int index = VERTEX_ID % 3;
if (index == 0) {
    barys = vec3(1.0, 0.0, 0.0);
} else if (index == 1) {
    barys = vec3(0.0, 1.0, 0.0);
} else {
    barys = vec3(0.0, 0.0, 1.0);
}

// fragment() shader (lines 124-133)
vec3 deltas = fwidth(barys);
vec3 barys_s = smoothstep(
    deltas * wire_width - wire_smoothness,
    deltas * wire_width + wire_smoothness,
    barys
);
float wire_mix = min(barys_s.x, min(barys_s.y, barys_s.z));
```

**How It Works**:
- Each triangle vertex gets a unique barycentric coordinate (1,0,0), (0,1,0), or (0,0,1)
- Fragment shader uses `fwidth()` to detect coordinate transitions (edges)
- All three edges of every triangle are rendered with equal priority

**Why It Shows Diagonals**:
- GPU only understands triangles, not quads
- Each quad is two triangles, each with 3 edges
- Barycentric method has no concept of "quad topology" or "shared edges"
- The diagonal edge is indistinguishable from the outer quad edges

---

## Research Findings

I conducted extensive research into GLSL quad wireframe techniques. Here are the key findings:

### 1. GPU Fundamental Limitation

**Source**: Multiple Stack Overflow/GameDev.SE discussions
**Key Insight**: "GPUs only understand triangles. No amount of tweaking API configuration, clever use of degenerate triangles, or geometry shaders will change that fact."

This means any solution must work within the triangle-based rendering paradigm while suppressing the unwanted diagonal edges.

### 2. Common Approaches to Hiding Diagonals

#### A. Normal Discontinuity Filtering
**Technique**: Only render edges between triangles with different normals
**Source**: https://stackoverflow.com/questions/268428/direct3d-wireframe-without-diagonals

**Pros**:
- Works for 3D meshes with different faces
- Automatically hides coplanar edges

**Cons**:
- ❌ **Won't work for our use case**: All ceiling tiles are coplanar (same normal)
- Requires geometry shader or edge detection in fragment shader
- Not applicable to flat grids

#### B. Separate Line Index Buffer
**Technique**: Maintain a second index buffer for quad edges only
**Source**: https://stackoverflow.com/questions/23063/how-can-i-get-rid-of-the-diagonal-wires-in-wireframe-boxes

**Example**: For quad vertices 1,2,3,4, use indices: `1,2,2,3,3,4,4,1`

**Pros**:
- Clean separation of filled geometry vs wireframe
- Perfect control over which edges render
- Industry-standard solution for wireframe rendering

**Cons**:
- ❌ **Not viable in Godot shaders**: Requires CPU-side geometry manipulation
- Would require custom mesh generation instead of GridMap
- Can't be implemented purely in shader code

#### C. Edge Flag Approach (Legacy OpenGL)
**Technique**: `glEdgeFlag()` to mark which edges should render
**Source**: https://gamedev.stackexchange.com/questions/67002/

**Cons**:
- ❌ **Not available in modern OpenGL/GLSL**: Legacy API only
- Not supported in Godot 4.x spatial shaders

### 3. UV-Based Grid Rendering (VIABLE SOLUTION)

**Technique**: Use UV coordinates and `fract()`/`mod()` to create grid patterns
**Sources**:
- https://thebookofshaders.com/09/ (Pattern generation)
- https://godotshaders.com/shader/infinite-ground-grid/ (Godot implementation)
- https://www.lighthouse3d.com/tutorials/glsl-tutorial/texture-coordinates/

**How It Works**:

```glsl
// Pseudo-code from research
vec2 grid_uv = UV * grid_scale;  // Scale UVs to grid frequency
vec2 grid_cell = fract(grid_uv);  // Get position within each cell [0-1]

// Detect edges by checking if we're near 0 or 1 in either axis
float grid_line_x = step(grid_cell.x, line_width) + step(1.0 - line_width, grid_cell.x);
float grid_line_y = step(grid_cell.y, line_width) + step(1.0 - line_width, grid_cell.y);
float grid = max(grid_line_x, grid_line_y);
```

**Example from "Infinite Ground Grid" shader**:

```glsl
float grid(vec2 pos, float unit, float thickness){
    vec2 threshold = fwidth(pos) * thickness * .5 / unit;
    vec2 posWrapped = pos / unit;
    vec2 line = step(fract(-posWrapped), threshold) +
                step(fract(posWrapped), threshold);
    return max(line.x, line.y);
}
```

**Pros**:
- ✅ **Topology-independent**: Works on any mesh, regardless of triangle layout
- ✅ **No diagonal artifacts**: Grid is defined by UV space, not mesh edges
- ✅ **Shader-only solution**: No CPU-side mesh changes required
- ✅ **Perspective-correct**: Can use `fwidth()` for consistent line thickness
- ✅ **Already works in Godot 4.x**: Proven technique (see GodotShaders.com)

**Cons**:
- Requires proper UV mapping on GridMap tiles (1 quad = 0-1 UV range)
- Line thickness affected by UV scale (need to account for this)
- Slightly different aesthetic than barycentric wireframe (more "grid-like")

---

## Recommended Solutions

Based on research, here are the viable approaches ranked by feasibility:

### **SOLUTION 1: UV-Based Grid Rendering** ⭐ RECOMMENDED

**Approach**: Replace barycentric coordinate wireframe with UV-based grid pattern

**Rationale**:
- Only shader-based solution that inherently avoids diagonals
- Grid is defined by UV topology, not triangle edges
- Proven to work in Godot 4.x (Infinite Ground Grid shader)
- Requires minimal changes to existing shader code

**Trade-offs**:
- Different visual style: "grid lines" vs "triangle edges"
- Requires GridMap tiles to have proper UV mapping (likely already correct)
- May need tuning to match current wireframe aesthetic

**Risk Level**: Low (established technique with working examples)

---

### **SOLUTION 2: Hybrid UV + Barycentric Masking**

**Approach**: Use UV coordinates to detect which barycentric edges to suppress

**Concept**:
```glsl
// In fragment shader:
// 1. Detect if we're near a UV cell boundary (quad edge)
vec2 uv_fract = fract(UV * grid_scale);
float near_uv_edge = step(uv_fract.x, 0.1) + step(uv_fract.y, 0.1) +
                     step(0.9, uv_fract.x) + step(0.9, uv_fract.y);

// 2. Use barycentric to detect triangle edges
float triangle_edge = [current barycentric calculation];

// 3. Only show edges that align with UV boundaries
float quad_edge = triangle_edge * near_uv_edge;
```

**Pros**:
- Preserves barycentric edge quality/smoothness
- Suppresses diagonals by masking against UV grid

**Cons**:
- More complex shader code
- Requires precise UV mapping
- May have artifacts at UV discontinuities

**Risk Level**: Medium (untested, may require iteration)

---

### **SOLUTION 3: World-Space Grid (Alternative)**

**Approach**: Generate grid based on world position rather than mesh topology

**Concept**:
```glsl
// Use world position to create grid independent of mesh
vec2 world_xz = world_position.xz;
vec2 grid_cell = fract(world_xz);  // 1-unit world grid
float grid = [edge detection on grid_cell];
```

**Pros**:
- Completely mesh-independent
- Perfect alignment with world grid units
- No UV or triangle topology concerns

**Cons**:
- Different fade behavior (world-space vs screen-space)
- Less control over individual tile rendering
- May not align with GridMap tile boundaries

**Risk Level**: Medium (requires rethinking fade system)

---

## Implementation Plan: Solution 1 (UV-Based Grid)

### Step 1: Verify UV Mapping

**Verify that GridMap tiles have correct UVs**:
- Each quad tile should map to UV range [0-1] x [0-1]
- Diagonals should not affect UV layout
- Check in Godot Editor: Select GridMap tile mesh, view UV mapping

**Expected**: PlaneMesh used by GridMap should have standard 0-1 UV mapping per quad

---

### Step 2: Replace Barycentric with UV Grid

**Current code to replace** (lines 83-90 vertex shader):
```gdscript
// Remove barycentric calculation
// int index = VERTEX_ID % 3;
// if (index == 0) { barys = vec3(1.0, 0.0, 0.0); }
// ...
```

**New vertex shader code**:
```gdscript
varying vec2 grid_uv;  // New varying for grid calculation

void vertex() {
    // ... existing code ...

    // Pass scaled UV for grid calculation
    grid_uv = UV * uv_scale;  // Use existing uv_scale uniform

    // ... existing code ...
}
```

---

### Step 3: Implement Grid Pattern in Fragment Shader

**Current code to replace** (lines 123-133 fragment shader):
```gdscript
// Replace barycentric wireframe rendering
if (fade < wireframe_threshold) {
    // [CURRENT BARYCENTRIC CODE]
}
```

**New fragment shader code**:
```gdscript
if (fade < wireframe_threshold) {
    // UV-based grid rendering
    vec2 grid_cell = fract(grid_uv);  // Position within grid cell [0-1]

    // Calculate distance from cell edges using fwidth for perspective correction
    vec2 grid_deltas = fwidth(grid_uv);
    float line_threshold = wire_width * 0.01;  // Convert to UV space

    // Detect proximity to edges (near 0 or near 1)
    vec2 edge_dist = min(grid_cell, 1.0 - grid_cell);
    vec2 edge_smooth = smoothstep(
        grid_deltas * line_threshold - wire_smoothness,
        grid_deltas * line_threshold + wire_smoothness,
        edge_dist
    );

    // Combine X and Y edge detection
    float wire_mix = min(edge_smooth.x, edge_smooth.y);

    // Apply wireframe color (same as before)
    ALBEDO = mix(wireframe_color.rgb, ALBEDO, wire_mix);
    ALPHA = mix(wireframe_color.a, 0.0, wire_mix);

    if (ALPHA < 0.01) {
        discard;
    }
}
```

---

### Step 4: Tuning Parameters

**Adjust uniforms to match previous wireframe aesthetic**:

```gdscript
// May need to adjust wire_width interpretation
// Barycentric: wire_width in screen-space pixels
// UV-based: wire_width in UV-space units

// Option A: Keep uniform the same, adjust calculation
float line_threshold = wire_width * 0.005;  // Tune multiplier

// Option B: Add separate grid_scale uniform for fine control
uniform float grid_scale : hint_range(0.1, 10.0) = 1.0;
```

**Testing checklist**:
- [ ] Grid lines appear at quad boundaries only (no diagonals)
- [ ] Line thickness matches previous wireframe
- [ ] Smoothness/anti-aliasing comparable to barycentric
- [ ] Fade transitions work correctly
- [ ] Performance is acceptable (should be faster than barycentric)

---

### Expected Visual Result

**Before (Barycentric)**:
```
┌─────┬─────┐
│  ╱  │  ╱  │  <- Diagonal visible in each quad
├─────┼─────┤
│  ╱  │  ╱  │
└─────┴─────┘
```

**After (UV Grid)**:
```
┌─────┬─────┐
│     │     │  <- Clean grid, no diagonals
├─────┼─────┤
│     │     │
└─────┴─────┘
```

---

### Potential Issues & Solutions

#### Issue 1: UV Mapping Incorrect
**Symptom**: Grid doesn't align with tile boundaries
**Solution**: Verify GridMap MeshLibrary UV mapping, may need to adjust grid_uv calculation

#### Issue 2: Line Thickness Wrong
**Symptom**: Lines too thin/thick compared to barycentric
**Solution**: Adjust `line_threshold` multiplier or add `grid_scale` uniform for tuning

#### Issue 3: Artifacts at UV Seams
**Symptom**: Missing lines or double lines at tile boundaries
**Solution**: Use `fract()` wrapping or adjust edge detection threshold

#### Issue 4: Performance Regression
**Symptom**: Shader runs slower than barycentric
**Solution**: UV-based should be faster (fewer varying interpolations), but profile if needed

---

## Alternative Quick Test: Godot's Infinite Grid Shader

Before implementing full solution, we could test the concept by adapting the Infinite Ground Grid shader:

**Source**: https://godotshaders.com/shader/infinite-ground-grid/

**Quick Prototype**:
1. Copy grid calculation function from Infinite Grid shader
2. Replace barycentric wireframe section with grid function
3. Use `world_position.xz` or `UV` as input
4. Test visual result to confirm no diagonals

This would validate the approach before committing to full implementation.

---

## References

### Academic/Tutorial Sources
- **The Book of Shaders - Patterns**: https://thebookofshaders.com/09/
  (Fundamental GLSL pattern generation with `fract()` and `mod()`)

- **GLSL Tutorial - Texture Coordinates**: https://www.lighthouse3d.com/tutorials/glsl-tutorial/texture-coordinates/
  (Grid line generation using fractional UV thresholds)

### Godot-Specific Resources
- **Wireframe Shader (Godot 4.0)**: https://godotshaders.com/shader/wireframe-shader-godot-4-0/
  (Current barycentric approach we're using)

- **Infinite Ground Grid**: https://godotshaders.com/shader/infinite-ground-grid/
  (UV-based grid pattern without triangle artifacts)

- **Godot 4.x Spatial Shader Reference**: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
  (Official documentation for spatial shader capabilities)

### Stack Overflow / GameDev Discussions
- **Wireframe shader: How to display quads and not triangles?**: https://stackoverflow.com/questions/49350004/
  (Unity-specific, but discusses general approaches)

- **How can I draw a quad in wireframe without rendering the interior bisecting edge?**: https://gamedev.stackexchange.com/questions/67002/
  (OpenGL discussion of line buffer approach)

- **webgl: Quad wireframe remove the diagonal line**: https://stackoverflow.com/questions/41867830/
  (WebGL approach to diagonal suppression)

- **How can I get rid of the diagonal wires in wireframe boxes?**: https://gamedev.stackexchange.com/questions/23063/
  (Discussion of separate line index buffer technique)

- **Understanding generalized barycentric coordinates**: https://www.gamedev.net/forums/topic/667334-understanding-generalized-barycentric-coordinates/
  (Academic discussion of quad-based barycentric systems)

### Technical Papers
- **Barycentric Quad Rasterization**: https://jcgt.org/published/0011/03/04/paper.pdf
  (Academic approach to quad rendering with generalized barycentric coordinates - complex, not practical for our use case)

---

## Decision Matrix

| Solution | Complexity | Risk | Performance | Visual Quality | Godot Support |
|----------|-----------|------|-------------|----------------|---------------|
| **UV Grid** | Low | Low | Better | Good | ✅ Native |
| **Hybrid UV+Bary** | Medium | Medium | Same | Excellent | ✅ Native |
| **World Grid** | Medium | Medium | Same | Good | ✅ Native |
| **Line Buffer** | High | N/A | Best | Perfect | ❌ Not viable |
| **Normal Filter** | Low | N/A | Same | N/A | ❌ Won't work |

**Recommendation**: Implement **Solution 1 (UV Grid)** first. It has the lowest risk and complexity while solving the core problem. If visual quality isn't satisfactory, iterate to Solution 2 (Hybrid).

---

## Next Steps

1. **Verify UV Mapping**: Check GridMap tile UVs in Godot Editor
2. **Prototype UV Grid**: Implement Solution 1 in test shader
3. **Visual Comparison**: Compare against current barycentric wireframe
4. **Performance Test**: Ensure no regression in shader performance
5. **Tune Parameters**: Adjust line thickness and smoothness to match aesthetic
6. **Document Final Solution**: Update this document with results and final implementation

---

**Document Created**: 2025-11-09
**Research Conducted By**: Claude (Sonnet 4.5)
**Status**: Ready for Implementation
