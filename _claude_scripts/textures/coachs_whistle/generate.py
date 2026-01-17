#!/usr/bin/env python3
"""
Coach's Whistle Texture Generator
Generates a 64x64 PSX-style whistle icon - classic horizontal pea whistle design.
"""

import numpy as np
from PIL import Image, ImageDraw
import sys
import os

# Output configuration
SIZE = 64
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "output.png")

# PSX-style color palette
COLORS = {
    'bg': (0, 0, 0, 0),  # Transparent
    'chrome_darkest': (40, 45, 50, 255),
    'chrome_dark': (80, 85, 90, 255),
    'chrome_mid': (140, 145, 150, 255),
    'chrome_light': (200, 205, 210, 255),
    'chrome_highlight': (255, 255, 255, 255),
    'lanyard_dark': (140, 20, 20, 255),
    'lanyard_mid': (200, 30, 30, 255),
    'lanyard_light': (230, 80, 80, 255),
}

def add_psx_grain(img_array, intensity=6):
    """Add subtle PSX-style grain to the image"""
    noise = np.random.randint(-intensity, intensity + 1, (SIZE, SIZE, 4), dtype=np.int16)
    noise[:, :, 3] = 0  # Don't affect alpha channel

    result = img_array.astype(np.int16) + noise
    result = np.clip(result, 0, 255)
    return result.astype(np.uint8)

def draw_whistle_body(img_array):
    """Draw the classic horizontal pea whistle shape"""
    # Whistle positioned horizontally across center
    # Fills ~60-70% of canvas

    # Main tube dimensions
    tube_center_x = SIZE // 2
    tube_center_y = SIZE // 2 + 2  # Slightly down to accommodate lanyard
    tube_length = 40
    tube_radius = 6  # Diameter of 12 pixels

    # Pea chamber dimensions (bulge on right side)
    chamber_x = tube_center_x + 16
    chamber_radius = 9  # Larger bulbous chamber

    # Mouthpiece dimensions (flat on left side)
    mouth_x = tube_center_x - 20
    mouth_width = 4
    mouth_height = 10

    # Draw main tube body (horizontal cylinder)
    for x in range(tube_center_x - 18, tube_center_x + 14):
        for y in range(tube_center_y - tube_radius, tube_center_y + tube_radius + 1):
            dy = y - tube_center_y
            # Cylindrical shading
            brightness = 1.0 - abs(dy) / tube_radius * 0.6

            if dy < -2:
                color = COLORS['chrome_highlight']  # Top highlight
            elif dy < 0:
                color = COLORS['chrome_light']
            elif dy < 2:
                color = COLORS['chrome_mid']
            else:
                color = COLORS['chrome_dark']  # Bottom shadow

            if 0 <= y < SIZE and 0 <= x < SIZE:
                img_array[y, x] = color

    # Draw pea chamber bulge (round chamber on right)
    for y in range(chamber_radius * 2 + 1):
        for x in range(chamber_radius * 2 + 1):
            dy = y - chamber_radius
            dx = x - chamber_radius
            dist = np.sqrt(dx**2 + dy**2)

            if dist <= chamber_radius:
                px = chamber_x - chamber_radius + x
                py = tube_center_y - chamber_radius + y

                if 0 <= py < SIZE and 0 <= px < SIZE:
                    # Spherical shading
                    if dy < -4:
                        color = COLORS['chrome_highlight']
                    elif dy < -1:
                        color = COLORS['chrome_light']
                    elif dy < 3:
                        color = COLORS['chrome_mid']
                    else:
                        color = COLORS['chrome_dark']

                    img_array[py, px] = color

    # Add pea chamber opening (dark circle indicating depth)
    opening_radius = 3
    for y in range(opening_radius * 2 + 1):
        for x in range(opening_radius * 2 + 1):
            dy = y - opening_radius
            dx = x - opening_radius
            dist = np.sqrt(dx**2 + dy**2)

            if dist <= opening_radius:
                px = chamber_x - opening_radius + x
                py = tube_center_y - opening_radius + y

                if 0 <= py < SIZE and 0 <= px < SIZE:
                    img_array[py, px] = COLORS['chrome_darkest']

    # Draw mouthpiece (flat rectangular end on left)
    mouth_y1 = tube_center_y - mouth_height // 2
    mouth_y2 = tube_center_y + mouth_height // 2

    for y in range(mouth_y1, mouth_y2 + 1):
        for x in range(mouth_x, mouth_x + mouth_width):
            if 0 <= y < SIZE and 0 <= x < SIZE:
                dy = y - tube_center_y
                # Shading for flat mouthpiece
                if abs(dy) < 2:
                    color = COLORS['chrome_light']
                elif abs(dy) < 4:
                    color = COLORS['chrome_mid']
                else:
                    color = COLORS['chrome_dark']

                img_array[y, x] = color

    # Add lanyard ring (small loop on top of tube)
    ring_x = tube_center_x + 4
    ring_y = tube_center_y - tube_radius - 3
    ring_radius = 3

    # Draw ring outline (hollow circle)
    for y in range(ring_radius * 2 + 1):
        for x in range(ring_radius * 2 + 1):
            dy = y - ring_radius
            dx = x - ring_radius
            dist = np.sqrt(dx**2 + dy**2)

            if ring_radius - 1 <= dist <= ring_radius:
                px = ring_x - ring_radius + x
                py = ring_y - ring_radius + y

                if 0 <= py < SIZE and 0 <= px < SIZE:
                    img_array[py, px] = COLORS['chrome_mid']

    return ring_x, ring_y

def draw_lanyard(img_array, ring_x, ring_y):
    """Draw the red lanyard cord"""
    # Lanyard curves up and to the right from the ring
    # Using Bezier-like curve points

    points = []
    num_points = 30

    # Start at ring, curve upward and right
    start_x, start_y = ring_x, ring_y
    end_x, end_y = ring_x + 20, ring_y - 16

    # Control point for curve
    ctrl_x, ctrl_y = ring_x + 8, ring_y - 12

    # Generate quadratic bezier curve points
    for i in range(num_points):
        t = i / (num_points - 1)
        # Quadratic Bezier formula: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
        x = (1-t)**2 * start_x + 2*(1-t)*t * ctrl_x + t**2 * end_x
        y = (1-t)**2 * start_y + 2*(1-t)*t * ctrl_y + t**2 * end_y
        points.append((int(x), int(y)))

    # Draw lanyard cord (thick line with shading)
    for i in range(len(points) - 1):
        x1, y1 = points[i]
        x2, y2 = points[i + 1]

        # Draw thick cord (3 pixels wide)
        for offset in [(-1, 0), (0, 0), (1, 0), (0, -1), (0, 1)]:
            ox, oy = offset

            # Bresenham-ish line drawing
            dx = abs(x2 - x1)
            dy = abs(y2 - y1)
            sx = 1 if x1 < x2 else -1
            sy = 1 if y1 < y2 else -1
            err = dx - dy

            x, y = x1, y1
            steps = 0
            max_steps = 100

            while steps < max_steps:
                px, py = x + ox, y + oy
                if 0 <= py < SIZE and 0 <= px < SIZE:
                    # Color based on offset for shading
                    if ox == -1 or oy == -1:
                        color = COLORS['lanyard_light']  # Highlight side
                    elif ox == 1 or oy == 1:
                        color = COLORS['lanyard_dark']  # Shadow side
                    else:
                        color = COLORS['lanyard_mid']  # Center

                    img_array[py, px] = color

                if x == x2 and y == y2:
                    break

                e2 = 2 * err
                if e2 > -dy:
                    err -= dy
                    x += sx
                if e2 < dx:
                    err += dx
                    y += sy

                steps += 1

def generate_whistle():
    """Generate the complete whistle texture"""
    # Create base image with transparency
    img_array = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    img_array[:, :] = COLORS['bg']

    # Draw whistle body and get ring position
    ring_x, ring_y = draw_whistle_body(img_array)

    # Draw lanyard attached to ring
    draw_lanyard(img_array, ring_x, ring_y)

    # Add PSX grain
    img_array = add_psx_grain(img_array, intensity=6)

    # Convert to image
    final_img = Image.fromarray(img_array, 'RGBA')

    return final_img

def main():
    """Main execution"""
    print("Generating Coach's Whistle texture...")
    print(f"Output size: {SIZE}x{SIZE} pixels")
    print(f"Output path: {OUTPUT_PATH}")

    # Generate texture
    whistle_img = generate_whistle()

    # Save output
    whistle_img.save(OUTPUT_PATH, 'PNG')

    print(f"✓ Texture generated successfully: {OUTPUT_PATH}")
    print(f"  File size: {os.path.getsize(OUTPUT_PATH)} bytes")

if __name__ == "__main__":
    main()
