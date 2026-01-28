# Credits and Attributions

This project uses assets and code from various sources. All external content is properly credited below.

---

## Shaders

### VHS Post-Processing Shader
- **Source**: [Godot Shaders](https://godotshaders.com/shader/vhs-post-processing/)
- **Author**: LazarusOverlook
- **Original Game**: Room2Room (analog horror game)
- **Based On**: [FMS_Cat's VCR Distortion Shader](https://www.shadertoy.com/view/MdffD7) (ShaderToy, 2017)
- **License**: CC0 (Public Domain)
- **Location**: `post_process/vhs_post_process.gdshader`
- **Usage**: VHS tape artifacts (scanlines, tape crease, tracking errors, color shift)

### PSX Dithering Shader
- **Source**: [godot-psx-shaders-demo](https://github.com/WittyCognomen/godot-psx-shaders-demo/blob/master/shaders/psx_dither_post.shader)
- **Author**: WittyCognomen
- **Modifications**: Ported to Godot 4.x compatibility
- **License**: Not specified (assumed permissive for demo code)
- **Location**: `shaders/pp_band-dither.gdshader`
- **Usage**: PSX-style color quantization and dithering

---

## Textures

### RGBA Noise Texture (VHS Shader Dependency)
- **Source**: [GitHub Gist by atdr](https://gist.githubusercontent.com/atdr/1bd65e54a3f51cd9e2a28e4e9e189b01/raw/08d3409bba9206af9f6a24cdfd99b82cae5de095/rgba-noise-medium.png)
- **Author**: atdr
- **License**: Not specified (public gist)
- **Location**: `assets/textures/rgba-noise-medium.png`
- **Usage**: Required texture input for VHS post-processing shader

### PSX Dither Texture
- **Source**: Included with godot-psx-shaders-demo
- **Author**: WittyCognomen
- **License**: Not specified (assumed permissive for demo code)
- **Location**: `shaders/psxdither.png`
- **Usage**: Dithering pattern for PSX-style rendering

---

## Fonts

### Rubik Spray Paint
- **Source**: [Google Fonts](https://fonts.google.com/specimen/Rubik+Spray+Paint) / [GitHub](https://github.com/NaN-xyz/Rubik-Filtered)
- **Authors**: NaN (Rubik Filtered Project Authors)
- **License**: SIL Open Font License, Version 1.1
- **Location**: `assets/fonts/RubikSprayPaint/`
- **Usage**: Spraypaint/graffiti text rendered on floors and walls in-game

### IBM Plex Mono
- **Source**: [GitHub](https://github.com/IBM/plex)
- **Authors**: IBM Corp.
- **License**: SIL Open Font License, Version 1.1
- **Location**: `assets/fonts/IBMPlexMono/`
- **Usage**: Primary UI and game text font

### Noto Color Emoji
- **Source**: [Google Fonts](https://fonts.google.com/noto/specimen/Noto+Color+Emoji) / [GitHub](https://github.com/googlefonts/noto-emoji)
- **Authors**: Google Inc.
- **License**: SIL Open Font License, Version 1.1
- **Location**: `assets/fonts/NotoEmoji/`
- **Usage**: Emoji fallback for text rendering

---

## Level Design References

### Backrooms Lore and Aesthetics
- **Inspiration**: [The Backrooms Wiki](http://backrooms-wiki.wikidot.com/)
- **Level 0 Description**: Greyish-yellow wallpaper, buzzing fluorescent lights, moist carpet
- **License**: CC BY-SA 3.0 (creative commons share-alike)
- **Usage**: Visual aesthetic reference, not direct asset usage

---

## Game Engine

### Godot Engine
- **Version**: 4.x
- **License**: MIT License
- **Website**: [godotengine.org](https://godotengine.org/)

---

## Code and Design

### Original Work
- **Developer**: Drew Brereton (aebrer)
- **License**: To be determined (likely GPL-compatible for FOSS ethos)
- **AI Assistance**: Claude (Anthropic) via Claude Code

All code not listed above is original work created specifically for this project.

---

## Asset Generation Scripts

### Texture Generation System
- **Location**: `_claude_scripts/textures/`
- **Purpose**: Procedural texture generation using Python (PIL, NumPy, noise libraries)
- **Examples**: Backrooms wallpaper, carpet, ceiling tiles
- **License**: Original work (same as project)

---

## Future Additions

As new assets are added to the project, they will be documented here with proper attribution.

**Last Updated**: 2026-01-27
