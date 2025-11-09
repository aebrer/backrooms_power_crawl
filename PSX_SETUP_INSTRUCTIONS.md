# PSX Shader Integration - Editor Tasks

## ✅ Completed (Automatically)

1. **Downloaded PSX shaders** from MenacingMecha's repository
   - Core shaders in `shaders/` directory
   - Post-process materials in `post_process/` directory

2. **Configured project settings** in `project.godot`:
   - Viewport resolution: 320x240 (low-res PSX look)
   - Window display: 1280x720 (upscaled for modern screens)
   - Added `precision_multiplier` global shader parameter (0.5 = wobbly vertices)
   - Texture filter: Nearest (pixelated look)

3. **Created PSX materials**:
   - `assets/materials/psx_floor.tres` - Brown floor material
   - `assets/materials/psx_wall.tres` - Yellow/beige Backrooms walls
   - `assets/materials/psx_ceiling.tres` - Off-white ceiling tiles

4. **Applied PSX materials to MeshLibrary**:
   - Converted `assets/grid_mesh_library.tres` to use external PSX shader materials
   - Floor tiles now use `psx_floor.tres`
   - Wall tiles now use `psx_wall.tres`
   - Automated via Python script (no manual editor work required)

5. **Added dithering post-process to game scene**:
   - Added `PostProcessDither` ColorRect node to `scenes/game_3d.tscn`
   - Full-screen overlay with `dither-banding_mat.tres`
   - Mouse filter set to "Ignore" (doesn't block input)

---

## 🎮 READY TO TEST!

**Phase 3: PSX Shader Integration is complete!** All tasks have been automated and are ready for testing in the Godot Editor

---

## 🎮 Testing the PSX Look

Once the above tasks are complete, run the game. You should see:

1. **Vertex Wobble**: Geometry "jiggles" slightly when camera moves (PS1 effect)
2. **Affine Texture Mapping**: Textures warp at oblique angles (no perspective correction)
3. **Pixelated Rendering**: 320x240 internal resolution upscaled to window size
4. **Color Banding**: Dithering simulates 15-bit color depth
5. **Nearest Neighbor Filtering**: Crisp pixel edges, no smooth blending

---

## ⚙️ Adjusting PSX Effect Intensity

### Reduce Vertex Wobble
In **Project Settings → Shader Globals → precision_multiplier**:
- `0.5` = Moderate wobble (default, authentic PS1)
- `0.7` = Subtle wobble (more playable)
- `1.0` = No wobble (disable effect)

### Adjust Dithering
Edit `post_process/dither-banding_mat.tres`:
- `col_depth`: Lower = more banding (8-12 for strong effect, 15-16 for subtle)
- `dither_banding`: true/false to toggle

### Change Resolution
In **project.godot** `[display]` section:
- `viewport_width/height`: Change internal resolution (320x240, 640x480, etc.)
- Lower = more pixelated, Higher = sharper but less PS1-like

---

## 🐛 Troubleshooting

**Issue**: Shaders not working / errors
- **Fix**: Ensure `shaders/psx_base.gdshaderinc` exists (core shader file)
- Check shader paths in material .tres files are correct

**Issue**: No vertex wobble visible
- **Fix**: Check `precision_multiplier` is set to 0.5 in Project Settings
- Wobble is most visible when camera is moving

**Issue**: Dithering not visible
- **Fix**: Ensure ColorRect with dither material is ABOVE other UI elements
- Check material is loaded correctly in Inspector

**Issue**: Performance issues
- **Fix**: Reduce viewport resolution to 240x180
- Disable shadows on lights (PSX didn't have realtime shadows)

---

## 📚 Next Steps (Phase 4)

After PSX shaders are working:
1. **Backrooms Textures**: Create yellow wallpaper and brown carpet textures
2. **Fluorescent Lighting**: Add flickering OmniLight3D nodes
3. **Volumetric Fog**: Add subtle yellow haze to environment
4. **Ambient Sound**: Add 60Hz electrical buzz loop

See `docs/2.5D_PSX_CONVERSION_PLAN.md` for full roadmap.

---

**Ready to test!** Complete the editor tasks above, then run the game to see the PSX aesthetic in action.
