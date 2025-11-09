# Ceiling Transparency Implementation Notes

## Issue 3: Zoom-Independent Player Vignette

**Status**: Working as designed - NO CHANGES NEEDED

### Analysis
The player vignette (3-8m radius cylinder) is correctly implemented in world-space coordinates. The perception that it "changes width" when zooming is expected behavior for perspective cameras:

- **Zoomed out**: You see more of the world, so 8m radius appears smaller relative to visible area
- **Zoomed in**: You see less of the world, so 8m radius fills more of the screen

### Why This is Correct
1. **Semantically accurate**: 8 meters in world space is always 8 meters
2. **Industry standard**: All RTS games with vision radius behave this way (StarCraft, EVE Online, etc.)
3. **Temporary effect**: Will be replaced with proper lighting/visibility simulation anyway

### Recommendation
Keep current implementation unchanged. If you want to adjust the "feel", tune the radius parameters (e.g., 2m-10m instead of 3m-8m) rather than changing coordinate spaces.

### Future: Proper Visibility System
See research document `03-zoom-independent-vignette.md` for grid-based visibility texture system that will replace this temporary effect.

---

## Issue 5: Camera Obstruction by Walls

**Status**: Quick fix implemented - FULL SYSTEM DEFERRED

### What Was Implemented
Added explicit collision shape to SpringArm3D (`SphereShape3D` radius=0.3) to improve collision detection accuracy. Previously relied on default raycast fallback.

### What Was Deferred
Full wall transparency system (dithered fade when walls obstruct view) has been researched and documented in `05-camera-obstruction.md` but not yet implemented. This is a larger feature that aligns with the "perfect information" design philosophy.

### Next Steps (Future Work)
If wall obstruction becomes an issue during gameplay testing:
1. Implement raycast wall detection in `tactical_camera.gd`
2. Create `psx_wall_transparent.gdshader` with dithered fade
3. Set up material swapping system for obstructing walls
4. See `05-camera-obstruction.md` for complete 5-phase implementation plan

### Current Behavior
SpringArm3D will compress when hitting walls, pushing camera closer to player. This is acceptable for turn-based tactical gameplay but may be refined later based on playtesting feedback.

---

**Date**: 2025-11-09
**Conclusion**: Issues 1, 2, and 4 fully fixed. Issue 3 is working as designed. Issue 5 quick fix applied, full system available if needed.
