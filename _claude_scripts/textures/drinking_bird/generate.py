#!/usr/bin/env python3
"""
Drinking Bird Texture Generator

Generates a 32x32 pixel art texture of a drinking bird novelty toy.
The classic desk toy with a glass bulb head containing red fluid,
balanced on a pivot that dips into water.
"""

from PIL import Image, ImageDraw
import numpy as np

# Output settings
SIZE = 32
OUTPUT_PATH = "output.png"

# Color palette (limited for pixel art aesthetic)
COLORS = {
    'transparent': (0, 0, 0, 0),
    'red_fluid': (220, 40, 40, 255),      # Red fluid in head
    'red_dark': (150, 20, 20, 255),       # Darker red for shading
    'glass_light': (200, 220, 240, 255),  # Light glass reflection
    'glass_edge': (100, 120, 140, 255),   # Glass outline/edge
    'glass_clear': (220, 230, 240, 180),  # Semi-transparent glass
    'metal_dark': (60, 60, 70, 255),      # Dark metal for pivot
    'metal_light': (120, 120, 130, 255),  # Light metal highlight
    'base_dark': (80, 80, 90, 255),       # Dark base
    'base_light': (140, 140, 150, 255),   # Light base highlight
    'beak': (255, 200, 50, 255),          # Yellow beak
}

def create_drinking_bird():
    """Generate the drinking bird pixel art texture."""

    # Create image with transparency
    img = Image.new('RGBA', (SIZE, SIZE), COLORS['transparent'])
    pixels = img.load()

    # Draw from bottom to top (base -> body -> head)

    # === BASE/STAND (bottom) ===
    # Simple rectangular base
    for y in range(28, 32):
        for x in range(10, 22):
            if y == 28 or x == 10 or x == 21:
                pixels[x, y] = COLORS['base_dark']  # Outline
            else:
                pixels[x, y] = COLORS['base_light']  # Fill

    # === PIVOT/FULCRUM (middle support) ===
    # Vertical support post
    for y in range(18, 28):
        x = 15
        pixels[x, y] = COLORS['metal_dark']
        pixels[x + 1, y] = COLORS['metal_light']  # Highlight

    # Pivot point (horizontal bar)
    for x in range(13, 19):
        pixels[x, 18] = COLORS['metal_dark']
    pixels[14, 17] = COLORS['metal_light']  # Highlight

    # === LOWER BULB (body/counterweight) ===
    # Small round bulb at bottom of bird
    lower_bulb_center_x = 16
    lower_bulb_center_y = 14
    lower_bulb_radius = 3

    for dy in range(-lower_bulb_radius, lower_bulb_radius + 1):
        for dx in range(-lower_bulb_radius, lower_bulb_radius + 1):
            if dx*dx + dy*dy <= lower_bulb_radius*lower_bulb_radius:
                x = lower_bulb_center_x + dx
                y = lower_bulb_center_y + dy

                # Glass edge
                if dx*dx + dy*dy >= (lower_bulb_radius - 1)*(lower_bulb_radius - 1):
                    pixels[x, y] = COLORS['glass_edge']
                # Red fluid inside
                elif y > lower_bulb_center_y - 1:
                    pixels[x, y] = COLORS['red_fluid']
                # Glass highlight
                else:
                    pixels[x, y] = COLORS['glass_clear']

    # === CONNECTING TUBE (glass tube connecting bulbs) ===
    # Thin vertical glass tube
    for y in range(8, 14):
        pixels[16, y] = COLORS['glass_edge']
        pixels[17, y] = COLORS['glass_clear']

    # === UPPER BULB (head) ===
    # Larger round bulb at top
    head_center_x = 16
    head_center_y = 5
    head_radius = 4

    for dy in range(-head_radius, head_radius + 1):
        for dx in range(-head_radius, head_radius + 1):
            if dx*dx + dy*dy <= head_radius*head_radius:
                x = head_center_x + dx
                y = head_center_y + dy

                if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
                    continue

                # Glass edge outline
                if dx*dx + dy*dy >= (head_radius - 1)*(head_radius - 1):
                    pixels[x, y] = COLORS['glass_edge']
                # Red fluid filling the head
                elif y > head_center_y - 2:
                    # Darker red at bottom for depth
                    if y > head_center_y:
                        pixels[x, y] = COLORS['red_dark']
                    else:
                        pixels[x, y] = COLORS['red_fluid']
                # Glass highlight at top
                else:
                    pixels[x, y] = COLORS['glass_light']

    # === BEAK ===
    # Small triangular beak pointing left
    beak_pixels = [
        (11, 5),  # Tip
        (12, 4), (12, 5), (12, 6),  # Middle
        (13, 5),  # Base
    ]
    for x, y in beak_pixels:
        pixels[x, y] = COLORS['beak']

    # Add dark outline to beak tip
    pixels[11, 5] = (200, 150, 30, 255)  # Darker yellow

    # === LEGS/WIRES (thin lines from tube to base) ===
    # Simple straight lines representing the wire legs
    # Left leg
    for y in range(14, 18):
        pixels[14, y] = COLORS['metal_dark']

    # Right leg
    for y in range(14, 18):
        pixels[18, y] = COLORS['metal_dark']

    # === FINAL TOUCHES ===
    # Add a few highlight pixels for glass shine on head
    pixels[head_center_x - 2, head_center_y - 2] = COLORS['glass_light']
    pixels[head_center_x - 1, head_center_y - 3] = COLORS['glass_light']

    return img

def main():
    """Generate and save the drinking bird texture."""
    print(f"Generating {SIZE}x{SIZE} drinking bird texture...")

    img = create_drinking_bird()

    # Save the image
    img.save(OUTPUT_PATH, 'PNG')
    print(f"✓ Saved texture to {OUTPUT_PATH}")

    # Verify output
    import os
    file_size = os.path.getsize(OUTPUT_PATH)
    print(f"  File size: {file_size} bytes")
    print(f"  Dimensions: {img.size}")
    print(f"  Mode: {img.mode}")

if __name__ == '__main__':
    main()
