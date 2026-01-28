#!/usr/bin/env python3
"""
Dark Overcast Sky Texture Generator
Generates a seamless 128x128 dark winter sky texture for PSX-style ceiling.
Uses toroidal 4D Perlin noise for perfect tiling.
"""

import numpy as np
from PIL import Image
from noise import pnoise2

# Constants
SIZE = 128
OUTPUT_PATH = "output.png"

# Dark winter sky color palette (hex -> RGB)
DARKEST = (14, 14, 18)        # #0e0e12 - near-black base
DARK_GRAY = (26, 26, 30)      # #1a1a1e - primary cloud dark
MID_DARK = (42, 42, 48)       # #2a2a30 - cloud mid-tone
CLOUD_EDGE = (48, 48, 56)     # #303038 - lighter cloud edges
LIGHTEST = (58, 58, 66)       # #3a3a42 - brightest cloud highlights

def toroidal_noise(x, y, size, scale, octaves=4, persistence=0.5, lacunarity=2.0):
    """
    Generate 4D Perlin noise that tiles seamlessly using toroidal mapping.

    Maps 2D coordinates to 4D space on a torus to ensure edges wrap perfectly.
    """
    # Normalize coordinates to [0, 1]
    nx = x / size
    ny = y / size

    # Map to 4D torus (two circles in 4D space)
    # This ensures the noise wraps seamlessly at texture boundaries
    angle_x = 2 * np.pi * nx
    angle_y = 2 * np.pi * ny

    # Radius of the torus in 4D space (affects noise correlation)
    radius = size / (2 * np.pi)

    # 4D coordinates on torus
    dx = radius * np.cos(angle_x)
    dy = radius * np.sin(angle_x)
    dz = radius * np.cos(angle_y)
    dw = radius * np.sin(angle_y)

    # Sample 4D Perlin noise (pnoise2 can handle 4D via additional params)
    # We'll layer multiple octaves manually for better control
    value = 0.0
    amplitude = 1.0
    frequency = scale
    max_value = 0.0

    for _ in range(octaves):
        # Sample noise at current frequency
        sample = pnoise2(
            dx * frequency / size,
            dy * frequency / size,
            octaves=1,
            persistence=persistence,
            lacunarity=lacunarity,
            base=int(dz * 1000) % 256  # Use dz/dw for variation
        )

        value += sample * amplitude
        max_value += amplitude

        amplitude *= persistence
        frequency *= lacunarity

    # Normalize to [0, 1]
    return value / max_value

def generate_dark_sky():
    """Generate dark overcast winter sky texture."""
    print("Generating dark overcast sky texture...")

    # Create base image array
    img_array = np.zeros((SIZE, SIZE, 3), dtype=np.uint8)

    # Generate base cloud layer (large-scale)
    print("  - Generating base cloud layer...")
    base_noise = np.zeros((SIZE, SIZE))
    for y in range(SIZE):
        for x in range(SIZE):
            base_noise[y, x] = toroidal_noise(x, y, SIZE, scale=2.0, octaves=3)

    # Normalize base noise to [0, 1]
    base_noise = (base_noise - base_noise.min()) / (base_noise.max() - base_noise.min())

    # Generate detail layer (smaller-scale cloud detail)
    print("  - Generating detail layer...")
    detail_noise = np.zeros((SIZE, SIZE))
    for y in range(SIZE):
        for x in range(SIZE):
            detail_noise[y, x] = toroidal_noise(x, y, SIZE, scale=4.0, octaves=4, persistence=0.6)

    # Normalize detail noise
    detail_noise = (detail_noise - detail_noise.min()) / (detail_noise.max() - detail_noise.min())

    # Generate turbulence layer (fine cloud edges)
    print("  - Generating turbulence layer...")
    turbulence = np.zeros((SIZE, SIZE))
    for y in range(SIZE):
        for x in range(SIZE):
            turbulence[y, x] = toroidal_noise(x, y, SIZE, scale=8.0, octaves=2, persistence=0.4)

    # Normalize turbulence
    turbulence = (turbulence - turbulence.min()) / (turbulence.max() - turbulence.min())

    # Combine layers with weights (keep it very dark overall)
    print("  - Combining layers...")
    combined = (base_noise * 0.6) + (detail_noise * 0.3) + (turbulence * 0.1)

    # Normalize combined
    combined = (combined - combined.min()) / (combined.max() - combined.min())

    # Apply dark bias - push most values toward darker end
    # Use power curve to darken: most pixels dark, few lighter
    combined = np.power(combined, 2.5)  # Darkens everything significantly

    # Map to dark color palette
    print("  - Mapping to color palette...")
    for y in range(SIZE):
        for x in range(SIZE):
            value = combined[y, x]

            # Map to grayscale palette (very dark)
            if value < 0.2:
                # Darkest areas (80% of image)
                color = np.array(DARKEST) + (np.array(DARK_GRAY) - np.array(DARKEST)) * (value / 0.2)
            elif value < 0.5:
                # Dark gray areas
                t = (value - 0.2) / 0.3
                color = np.array(DARK_GRAY) + (np.array(MID_DARK) - np.array(DARK_GRAY)) * t
            elif value < 0.75:
                # Mid-dark cloud edges
                t = (value - 0.5) / 0.25
                color = np.array(MID_DARK) + (np.array(CLOUD_EDGE) - np.array(MID_DARK)) * t
            else:
                # Lightest cloud highlights (very rare)
                t = (value - 0.75) / 0.25
                color = np.array(CLOUD_EDGE) + (np.array(LIGHTEST) - np.array(CLOUD_EDGE)) * t

            img_array[y, x] = color.astype(np.uint8)

    # Create PIL image
    img = Image.fromarray(img_array, mode='RGB')

    # Save output
    print(f"  - Saving to {OUTPUT_PATH}...")
    img.save(OUTPUT_PATH)
    print(f"✓ Dark sky texture generated successfully!")
    print(f"  Size: {SIZE}x{SIZE}")
    print(f"  Tiling: Seamless (toroidal 4D noise)")
    print(f"  Style: Dark overcast winter sky")

if __name__ == "__main__":
    generate_dark_sky()
