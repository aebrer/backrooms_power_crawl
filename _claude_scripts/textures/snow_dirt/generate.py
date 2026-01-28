#!/usr/bin/env python3
"""
Snowy Dirt Ground Texture Generator
Generates a 128x128 tileable texture with dark dirt, snow patches, and dead grass.
"""

import numpy as np
from PIL import Image
from opensimplex import OpenSimplex

SIZE = 128

# Color palette - ITERATION 3: Dramatic contrast
DIRT_DARK = np.array([42, 26, 16])   # #2a1a10 - Darker dirt
DIRT_LIGHT = np.array([74, 58, 42])  # #4a3a2a - Medium-dark dirt
SNOW_DARK = np.array([235, 240, 250])  # #ebf0fa - Bright snow
SNOW_LIGHT = np.array([240, 245, 255])  # #f0f5ff - Pure white snow
GRASS_YELLOW = np.array([138, 122, 64])  # #8a7a40 - MUCH brighter yellow-brown
GRASS_GREEN = np.array([106, 98, 56])   # #6a6238 - Lighter dead grass

def generate_tileable_noise(noise_gen, scale, octaves=1):
    """Generate tileable noise using 4D toroidal mapping for guaranteed seamless tiling."""
    noise = np.zeros((SIZE, SIZE))

    for octave in range(octaves):
        freq = 2 ** octave
        amp = 1.0 / (2 ** octave)

        for y in range(SIZE):
            for x in range(SIZE):
                # Map to 4D torus coordinates for perfect tiling
                # This GUARANTEES seamless edges by mapping 2D plane to 4D torus
                nx = x / SIZE
                ny = y / SIZE

                # 4D coordinates on torus surface
                s = np.cos(nx * 2 * np.pi)
                t = np.sin(nx * 2 * np.pi)
                u = np.cos(ny * 2 * np.pi)
                v = np.sin(ny * 2 * np.pi)

                noise[y, x] += noise_gen.noise4(
                    s * scale * freq,
                    t * scale * freq,
                    u * scale * freq,
                    v * scale * freq
                ) * amp

    return noise

def main():
    # Initialize noise generators with different seeds
    dirt_noise = OpenSimplex(seed=42)
    snow_noise = OpenSimplex(seed=123)
    detail_noise = OpenSimplex(seed=789)

    # Create base dirt layer with multi-octave noise
    print("Generating dirt base...")
    dirt_variation = generate_tileable_noise(dirt_noise, scale=0.05, octaves=3)
    dirt_variation = (dirt_variation + 1) / 2  # Normalize to 0-1

    # Initialize image array
    img_array = np.zeros((SIZE, SIZE, 3), dtype=np.uint8)

    # Apply dirt colors with variation
    for y in range(SIZE):
        for x in range(SIZE):
            t = dirt_variation[y, x]
            color = DIRT_DARK * (1 - t) + DIRT_LIGHT * t
            img_array[y, x] = color.astype(np.uint8)

    # Generate snow patches using noise threshold - DRAMATIC visibility
    print("Adding snow patches...")
    snow_layer = generate_tileable_noise(snow_noise, scale=0.03, octaves=2)  # LARGER patches (lower frequency)
    snow_layer = (snow_layer + 1) / 2  # Normalize to 0-1

    # Apply snow where noise is above threshold - MUCH MORE COVERAGE (35-40%)
    snow_threshold = 0.38  # Was 0.45, now 0.38 for ~35-40% coverage
    for y in range(SIZE):
        for x in range(SIZE):
            if snow_layer[y, x] > snow_threshold:
                # Blend snow based on how far above threshold
                snow_strength = (snow_layer[y, x] - snow_threshold) / (1 - snow_threshold)
                snow_strength = np.clip(snow_strength, 0, 1)

                # Vary snow color - pure white to bright
                t = snow_strength * 0.5  # Less variation, stay bright
                snow_color = SNOW_DARK * (1 - t) + SNOW_LIGHT * t

                # Blend with underlying dirt - STRONG blend for stark contrast
                blend_factor = snow_strength * 0.98  # Near-total replacement for pure white
                img_array[y, x] = (img_array[y, x] * (1 - blend_factor) +
                                   snow_color * blend_factor).astype(np.uint8)

    # Add fine detail noise for texture
    print("Adding surface detail...")
    detail = generate_tileable_noise(detail_noise, scale=0.15, octaves=2)
    detail = (detail + 1) / 2

    for y in range(SIZE):
        for x in range(SIZE):
            detail_factor = (detail[y, x] - 0.5) * 0.15  # Small variation
            img_array[y, x] = np.clip(img_array[y, x] * (1 + detail_factor), 0, 255).astype(np.uint8)

    # Add small pebbles/rocks for texture detail
    print("Adding pebbles...")
    np.random.seed(789)
    num_pebbles = 40

    for _ in range(num_pebbles):
        cx = np.random.randint(0, SIZE)
        cy = np.random.randint(0, SIZE)

        # Small dark spots for pebbles (1-2px radius)
        radius = np.random.randint(1, 3)
        pebble_color = DIRT_DARK * 0.6  # Darker than dirt

        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if dx*dx + dy*dy <= radius*radius:
                    px = (cx + dx) % SIZE
                    py = (cy + dy) % SIZE

                    # Only add pebbles on dirt, not snow
                    if np.sum(img_array[py, px]) < 180:  # If not bright (not snow)
                        blend = 0.6
                        img_array[py, px] = (img_array[py, px] * (1 - blend) +
                                           pebble_color * blend).astype(np.uint8)

    # Scatter dead grass/pine needles using modulo wrapping - HIGHLY VISIBLE
    print("Scattering dead grass...")
    np.random.seed(456)
    num_grass_bits = 120  # Was 80, now 120 for much more grass

    for _ in range(num_grass_bits):
        # Random center position
        cx = np.random.randint(0, SIZE)
        cy = np.random.randint(0, SIZE)

        # Random grass type (favor yellow for visibility)
        grass_color = GRASS_YELLOW if np.random.random() > 0.3 else GRASS_GREEN

        # Draw THICKER line segments (4-6 pixels) for grass/needle appearance
        length = np.random.randint(4, 7)  # Was 2-5, now 4-7 for longer grass
        angle = np.random.random() * 2 * np.pi
        thickness = np.random.randint(2, 4)  # 2-3px wide lines

        for i in range(length):
            # Calculate offset along line
            dx = int(np.cos(angle) * i)
            dy = int(np.sin(angle) * i)

            # Draw with thickness (offset perpendicular to line)
            perp_angle = angle + np.pi / 2
            for t in range(thickness):
                offset_x = int(np.cos(perp_angle) * (t - thickness/2))
                offset_y = int(np.sin(perp_angle) * (t - thickness/2))

                # Apply with modulo wrapping for seamless tiling
                px = (cx + dx + offset_x) % SIZE
                py = (cy + dy + offset_y) % SIZE

                # Strong blend for high visibility
                blend = 0.85  # Was 0.75, now 0.85 for VERY visible grass
                img_array[py, px] = (img_array[py, px] * (1 - blend) +
                                     grass_color * blend).astype(np.uint8)

    # Save output
    print("Saving output.png...")
    img = Image.fromarray(img_array, mode='RGB')
    img.save('output.png')
    print("✓ Texture generated successfully!")
    print(f"  - Size: {SIZE}x{SIZE} pixels")
    print(f"  - Tileable: Yes (seamless wrapping)")
    print(f"  - Style: PSX/retro with dark dirt, snow patches, dead grass")

if __name__ == '__main__':
    main()
