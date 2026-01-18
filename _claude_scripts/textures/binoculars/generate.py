#!/usr/bin/env python3
"""
PSX-style Binoculars Texture Generator
Generates a 64x64 military binoculars icon with PSX aesthetic
"""

from PIL import Image, ImageDraw
import numpy as np
import random

# Constants
SIZE = 64
OUTPUT_PATH = "output.png"

# Color palette (olive drab military colors)
OLIVE_DARK = (45, 51, 20)      # Dark olive
OLIVE_MED = (74, 83, 32)        # Medium olive
OLIVE_LIGHT = (89, 98, 42)      # Light olive
RUBBER_DARK = (35, 38, 18)      # Very dark for shadows
LENS_DARK = (20, 25, 35)        # Dark blue-grey for lens
LENS_REFLECT = (100, 130, 160)  # Blue reflection
LENS_SHINE = (180, 200, 220)    # Bright reflection spot
BRIDGE_COLOR = (40, 45, 22)     # Slightly different shade for bridge

def add_grain(img_array, intensity=0.15):
    """Add PSX-style film grain"""
    grain = np.random.normal(0, intensity, (SIZE, SIZE, 3))
    img_array[:, :, :3] = np.clip(img_array[:, :, :3] + grain * 255, 0, 255)
    return img_array

def add_dither(img_array, strength=8):
    """Add PSX-style dithering"""
    for y in range(SIZE):
        for x in range(SIZE):
            if img_array[y, x, 3] > 0:  # Only dither non-transparent pixels
                threshold = (x % 2 + y % 2) * strength
                for c in range(3):
                    if random.random() < 0.3:  # 30% of pixels get dithered
                        current_val = int(img_array[y, x, c])
                        dither_offset = random.randint(-threshold, threshold)
                        img_array[y, x, c] = np.clip(current_val + dither_offset, 0, 255)
    return img_array

def draw_circle_filled(img_array, cx, cy, radius, color):
    """Draw a filled circle with alpha"""
    for y in range(max(0, cy - radius), min(SIZE, cy + radius + 1)):
        for x in range(max(0, cx - radius), min(SIZE, cx + radius + 1)):
            dx = x - cx
            dy = y - cy
            if dx*dx + dy*dy <= radius*radius:
                img_array[y, x] = color

def draw_circle_outline(img_array, cx, cy, radius, color, thickness=1):
    """Draw a circle outline"""
    for y in range(max(0, cy - radius - thickness), min(SIZE, cy + radius + thickness + 1)):
        for x in range(max(0, cx - radius - thickness), min(SIZE, cx + radius + thickness + 1)):
            dx = x - cx
            dy = y - cy
            dist_sq = dx*dx + dy*dy
            if (radius - thickness)**2 <= dist_sq <= (radius + thickness)**2:
                img_array[y, x] = color

def draw_ellipse_filled(img_array, cx, cy, rx, ry, color, angle=0):
    """Draw a filled ellipse at given angle"""
    cos_a = np.cos(angle)
    sin_a = np.sin(angle)

    for y in range(max(0, cy - ry - 2), min(SIZE, cy + ry + 3)):
        for x in range(max(0, cx - rx - 2), min(SIZE, cx + rx + 3)):
            # Rotate point
            dx = x - cx
            dy = y - cy
            rx_point = dx * cos_a + dy * sin_a
            ry_point = -dx * sin_a + dy * cos_a

            # Check if inside ellipse
            if (rx_point/rx)**2 + (ry_point/ry)**2 <= 1:
                img_array[y, x] = color

def generate_binoculars():
    """Generate the binoculars texture"""
    # Create RGBA image
    img_array = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)

    # Binocular parameters (3/4 view) - SCALED UP for better icon presence
    barrel_radius = 15
    barrel_length = 42
    lens_radius = 12

    # Left barrel center (slightly offset for 3/4 view)
    left_cx = 22
    left_cy = 32

    # Right barrel center
    right_cx = 42
    right_cy = 32

    # === DRAW BARREL BODIES (cylinders in 3/4 view) ===

    # Left barrel body (elliptical to show perspective)
    draw_ellipse_filled(img_array, left_cx, left_cy, barrel_radius, barrel_length//2,
                       (*OLIVE_MED, 255), angle=np.pi/2)

    # Right barrel body
    draw_ellipse_filled(img_array, right_cx, right_cy, barrel_radius, barrel_length//2,
                       (*OLIVE_MED, 255), angle=np.pi/2)

    # Add shadow side to barrels (darker strip on left side) and highlights on right
    for y in range(SIZE):
        for x in range(SIZE):
            if img_array[y, x, 3] > 0:
                # Left barrel shadow
                if x < left_cx - 4 and abs(y - left_cy) < barrel_length//2:
                    img_array[y, x, :3] = OLIVE_DARK
                # Left barrel highlight (right side)
                elif x > left_cx + 4 and abs(y - left_cy) < barrel_length//2:
                    img_array[y, x, :3] = OLIVE_LIGHT
                # Right barrel shadow
                elif x < right_cx - 4 and abs(y - right_cy) < barrel_length//2:
                    img_array[y, x, :3] = OLIVE_DARK
                # Right barrel highlight (right side)
                elif x > right_cx + 4 and abs(y - right_cy) < barrel_length//2:
                    img_array[y, x, :3] = OLIVE_LIGHT

    # Add rubber texture bands (horizontal subtle lines)
    for band_y in range(4):
        y_pos = left_cy - barrel_length//2 + 8 + band_y * 8
        for x in range(left_cx - barrel_radius, left_cx + barrel_radius):
            if 0 <= y_pos < SIZE and 0 <= x < SIZE and img_array[y_pos, x, 3] > 0:
                # Darken slightly for texture
                img_array[y_pos, x, :3] = [max(0, c - 10) for c in img_array[y_pos, x, :3]]
        for x in range(right_cx - barrel_radius, right_cx + barrel_radius):
            if 0 <= y_pos < SIZE and 0 <= x < SIZE and img_array[y_pos, x, 3] > 0:
                img_array[y_pos, x, :3] = [max(0, c - 10) for c in img_array[y_pos, x, :3]]

    # === DRAW BRIDGE CONNECTING BARRELS ===
    bridge_width = right_cx - left_cx
    bridge_height = 8
    bridge_y = left_cy

    for y in range(bridge_y - bridge_height//2, bridge_y + bridge_height//2):
        for x in range(left_cx, right_cx + 1):
            if 0 <= y < SIZE and 0 <= x < SIZE:
                img_array[y, x] = (*BRIDGE_COLOR, 255)

    # Bridge shadow (top edge)
    for x in range(left_cx, right_cx + 1):
        y = bridge_y - bridge_height//2
        if 0 <= y < SIZE and 0 <= x < SIZE:
            img_array[y, x] = (*RUBBER_DARK, 255)

    # === DRAW LENSES (front of barrels) ===

    # Left lens base
    draw_circle_filled(img_array, left_cx, left_cy - barrel_length//2 + 2,
                      lens_radius, (*LENS_DARK, 255))

    # Right lens base
    draw_circle_filled(img_array, right_cx, right_cy - barrel_length//2 + 2,
                      lens_radius, (*LENS_DARK, 255))

    # Add glass reflection (blue tint)
    # Left lens reflection
    draw_circle_filled(img_array, left_cx, left_cy - barrel_length//2 + 2,
                      lens_radius - 2, (*LENS_REFLECT, 255))

    # Right lens reflection
    draw_circle_filled(img_array, right_cx, right_cy - barrel_length//2 + 2,
                      lens_radius - 2, (*LENS_REFLECT, 255))

    # Add bright reflection spots (top-left of each lens) - larger and brighter
    shine_offset_x = -4
    shine_offset_y = -4

    # Left lens shine (3x3 bright spot)
    for y in range(3):
        for x in range(3):
            px = left_cx + shine_offset_x + x
            py = left_cy - barrel_length//2 + 2 + shine_offset_y + y
            if 0 <= py < SIZE and 0 <= px < SIZE:
                # Center pixel brightest
                if x == 1 and y == 1:
                    img_array[py, px] = (255, 255, 255, 255)
                else:
                    img_array[py, px] = (*LENS_SHINE, 255)

    # Right lens shine (3x3 bright spot)
    for y in range(3):
        for x in range(3):
            px = right_cx + shine_offset_x + x
            py = right_cy - barrel_length//2 + 2 + shine_offset_y + y
            if 0 <= py < SIZE and 0 <= px < SIZE:
                # Center pixel brightest
                if x == 1 and y == 1:
                    img_array[py, px] = (255, 255, 255, 255)
                else:
                    img_array[py, px] = (*LENS_SHINE, 255)

    # Lens rims (darker outline)
    draw_circle_outline(img_array, left_cx, left_cy - barrel_length//2 + 2,
                       lens_radius, (*RUBBER_DARK, 255), thickness=1)
    draw_circle_outline(img_array, right_cx, right_cy - barrel_length//2 + 2,
                       lens_radius, (*RUBBER_DARK, 255), thickness=1)

    # === DRAW EYECUPS (back of barrels) ===
    eyecup_radius = 9

    # Left eyecup
    draw_circle_filled(img_array, left_cx, left_cy + barrel_length//2 - 2,
                      eyecup_radius, (*RUBBER_DARK, 255))
    draw_circle_filled(img_array, left_cx, left_cy + barrel_length//2 - 2,
                      eyecup_radius - 2, (*OLIVE_DARK, 255))

    # Right eyecup
    draw_circle_filled(img_array, right_cx, right_cy + barrel_length//2 - 2,
                      eyecup_radius, (*RUBBER_DARK, 255))
    draw_circle_filled(img_array, right_cx, right_cy + barrel_length//2 - 2,
                      eyecup_radius - 2, (*OLIVE_DARK, 255))

    # === ADD WEATHERING ===
    # Add random scratches and scuffs (more visible)
    random.seed(42)  # Consistent weathering pattern
    for _ in range(25):
        sx = random.randint(0, SIZE - 1)
        sy = random.randint(0, SIZE - 1)
        if img_array[sy, sx, 3] > 0:
            # Small scratch (brighter for visibility)
            length = random.randint(3, 7)
            angle = random.random() * 2 * np.pi
            for i in range(length):
                x = int(sx + i * np.cos(angle))
                y = int(sy + i * np.sin(angle))
                if 0 <= x < SIZE and 0 <= y < SIZE and img_array[y, x, 3] > 0:
                    # Mix of light scratches and dark scuffs
                    if random.random() < 0.6:
                        img_array[y, x, :3] = OLIVE_LIGHT
                    else:
                        img_array[y, x, :3] = RUBBER_DARK

    # Add a few prominent scuff marks on barrels
    for barrel_cx in [left_cx, right_cx]:
        for _ in range(3):
            scuff_x = barrel_cx + random.randint(-5, 5)
            scuff_y = random.randint(left_cy - 10, left_cy + 10)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    px, py = scuff_x + dx, scuff_y + dy
                    if 0 <= px < SIZE and 0 <= py < SIZE and img_array[py, px, 3] > 0:
                        img_array[py, px, :3] = [max(0, c - 20) for c in img_array[py, px, :3]]

    # === ADD PSX EFFECTS ===
    img_array = add_grain(img_array, intensity=0.06)
    img_array = add_dither(img_array, strength=3)

    return img_array

def main():
    """Generate and save the binoculars texture"""
    print("Generating PSX-style binoculars texture...")

    # Generate texture
    img_array = generate_binoculars()

    # Convert to PIL Image
    img = Image.fromarray(img_array.astype(np.uint8), 'RGBA')

    # Save
    img.save(OUTPUT_PATH)
    print(f"✓ Saved to {OUTPUT_PATH}")
    print(f"  Size: {SIZE}x{SIZE} pixels")
    print(f"  Style: PSX military aesthetic with grain and dithering")

if __name__ == "__main__":
    main()
