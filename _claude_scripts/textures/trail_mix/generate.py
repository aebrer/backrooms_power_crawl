#!/usr/bin/env python3
"""
PSX-style Trail Mix Bag Texture Generator
Generates a 64x64 pixel texture of a crinkled ziploc bag with trail mix
"""

import numpy as np
from PIL import Image, ImageDraw
import random

# Constants
SIZE = 64
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

# PSX-style limited color palette
PALETTE = {
    # Bag plastic (semi-transparent grey-blue)
    'bag_light': (220, 225, 230, 180),
    'bag_dark': (180, 185, 195, 200),
    'bag_crinkle': (160, 165, 175, 220),
    'ziplock_seal': (120, 140, 160, 255),  # Darker blue-grey for ziplock line

    # Trail mix components
    'peanut_light': (210, 180, 140, 255),
    'peanut_dark': (160, 130, 90, 255),
    'raisin': (60, 40, 30, 255),
    'candy_red': (200, 40, 40, 255),
    'candy_yellow': (220, 200, 40, 255),
    'candy_blue': (40, 80, 180, 255),
    'seed_light': (200, 195, 190, 255),
    'seed_dark': (100, 95, 90, 255),
}

def create_base_image():
    """Create transparent base image"""
    return Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

def draw_bag_shape(draw, img_array):
    """Draw the ziploc bag shape with hourglass pinch at ziplock seal"""
    # Bag bounds (rounded rectangle, slightly irregular)
    bag_left = 12
    bag_right = 52
    bag_top = 8
    bag_bottom = 56

    # Ziplock seal position (near top of bag)
    ziplock_y = 14

    # Draw bag outline with hourglass shape - pinched at ziplock seal
    for y in range(bag_top, bag_bottom):
        # Hourglass shape: narrowest at ziplock_y, wider above and below
        if y < ziplock_y:
            # Above the seal: flare outward toward the top (gathered plastic)
            # Distance from seal line
            dist_from_seal = ziplock_y - y
            # Maximum pinch happens at seal line (0 distance)
            # Gradually widen as we go up (flaring out)
            pinch_factor = 1.0 - (dist_from_seal / (ziplock_y - bag_top)) * 0.5  # 0.5 to 1.0
            pinch_amount = int(8 * pinch_factor)  # Max 8 pixels narrower at seal
            current_left = bag_left + pinch_amount
            current_right = bag_right - pinch_amount
        else:
            # Below the seal: gradually widen back to full width (filled with trail mix)
            # Distance from seal line
            dist_from_seal = y - ziplock_y
            # Maximum pinch at seal line, then gradually widen
            max_pinch_distance = 10  # Widen over 10 pixels
            if dist_from_seal < max_pinch_distance:
                pinch_factor = 1.0 - (dist_from_seal / max_pinch_distance)
                pinch_amount = int(8 * pinch_factor)  # Max 8 pixels at seal, 0 at distance
            else:
                pinch_amount = 0  # Full width
            current_left = bag_left + pinch_amount
            current_right = bag_right - pinch_amount

        for x in range(current_left, current_right):
            # Create rounded corners
            corner_radius = 4
            in_corner = False

            # Top-left corner
            if x < current_left + corner_radius and y < bag_top + corner_radius:
                dx = (current_left + corner_radius) - x
                dy = (bag_top + corner_radius) - y
                if dx*dx + dy*dy > corner_radius*corner_radius:
                    in_corner = True

            # Top-right corner
            if x > current_right - corner_radius and y < bag_top + corner_radius:
                dx = x - (current_right - corner_radius)
                dy = (bag_top + corner_radius) - y
                if dx*dx + dy*dy > corner_radius*corner_radius:
                    in_corner = True

            # Bottom corners
            if x < current_left + corner_radius and y > bag_bottom - corner_radius:
                dx = (current_left + corner_radius) - x
                dy = y - (bag_bottom - corner_radius)
                if dx*dx + dy*dy > corner_radius*corner_radius:
                    in_corner = True

            if x > current_right - corner_radius and y > bag_bottom - corner_radius:
                dx = x - (current_right - corner_radius)
                dy = y - (bag_bottom - corner_radius)
                if dx*dx + dy*dy > corner_radius*corner_radius:
                    in_corner = True

            if not in_corner:
                # Vary bag color slightly for plastic look
                if random.random() < 0.3:
                    color = PALETTE['bag_dark']
                else:
                    color = PALETTE['bag_light']
                img_array[y, x] = color

def draw_ziplock_seal(img_array):
    """Draw the ziplock seal line near top of bag"""
    ziplock_y = 14  # Position of seal line
    bag_left = 12
    bag_right = 52

    # Draw the main seal line (2-3 pixels thick for visibility)
    for y in range(ziplock_y - 1, ziplock_y + 2):
        for x in range(bag_left, bag_right):
            img_array[y, x] = PALETTE['ziplock_seal']

    # Add slight ridge/highlight above and below for 3D effect
    for x in range(bag_left, bag_right):
        if random.random() < 0.7:
            # Lighter line above
            img_array[ziplock_y - 2, x] = PALETTE['bag_light']
            # Darker line below
            img_array[ziplock_y + 2, x] = PALETTE['bag_crinkle']

def add_crinkles(img_array):
    """Add crinkle/wrinkle lines to bag"""
    # Vertical crinkles (only below ziplock seal)
    for i in range(3):
        x = 18 + i * 10
        for y in range(16, 54):  # Start below ziplock seal at y=14
            if random.random() < 0.6:
                img_array[y, x] = PALETTE['bag_crinkle']
                # Add adjacent pixels for line width
                if x + 1 < SIZE:
                    img_array[y, x + 1] = PALETTE['bag_crinkle']

    # Diagonal crinkles (only below ziplock seal)
    for i in range(2):
        start_x = 15 + i * 15
        for offset in range(25):
            x = start_x + offset
            y = 17 + offset  # Start below ziplock seal
            if 0 <= x < SIZE and 0 <= y < SIZE and random.random() < 0.4:
                img_array[y, x] = PALETTE['bag_crinkle']

def draw_trail_mix_pieces(img_array):
    """Draw trail mix components inside bag"""
    # Define bag interior bounds
    interior_left = 15
    interior_right = 49
    interior_top = 20  # Leave space at top (partially full)
    interior_bottom = 53

    # Draw peanuts (largest pieces)
    for _ in range(8):
        cx = random.randint(interior_left + 3, interior_right - 3)
        cy = random.randint(interior_top, interior_bottom - 3)

        # Oval shape for peanut
        for dy in range(-3, 4):
            for dx in range(-2, 3):
                dist = (dx/2.5)**2 + (dy/3.5)**2
                if dist <= 1:
                    x, y = cx + dx, cy + dy
                    if interior_left <= x < interior_right and interior_top <= y < interior_bottom:
                        if random.random() < 0.5:
                            img_array[y, x] = PALETTE['peanut_light']
                        else:
                            img_array[y, x] = PALETTE['peanut_dark']

    # Draw raisins (small dark pieces)
    for _ in range(12):
        cx = random.randint(interior_left + 1, interior_right - 1)
        cy = random.randint(interior_top, interior_bottom - 1)

        # Small irregular shape
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if random.random() < 0.7:
                    x, y = cx + dx, cy + dy
                    if interior_left <= x < interior_right and interior_top <= y < interior_bottom:
                        img_array[y, x] = PALETTE['raisin']

    # Draw M&Ms (colorful candy pieces)
    candy_colors = ['candy_red', 'candy_yellow', 'candy_blue']
    for _ in range(10):
        cx = random.randint(interior_left + 2, interior_right - 2)
        cy = random.randint(interior_top, interior_bottom - 2)
        color_name = random.choice(candy_colors)

        # Small circular shape
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                dist = dx*dx + dy*dy
                if dist <= 4:  # Radius of 2
                    x, y = cx + dx, cy + dy
                    if interior_left <= x < interior_right and interior_top <= y < interior_bottom:
                        img_array[y, x] = PALETTE[color_name]

    # Draw sunflower seeds (small striped pieces)
    for _ in range(15):
        cx = random.randint(interior_left + 1, interior_right - 1)
        cy = random.randint(interior_top, interior_bottom - 1)

        # Tiny seed shape with stripe
        for dy in range(-1, 2):
            for dx in range(-1, 1):
                x, y = cx + dx, cy + dy
                if interior_left <= x < interior_right and interior_top <= y < interior_bottom:
                    if dx == 0:
                        img_array[y, x] = PALETTE['seed_dark']  # Stripe
                    else:
                        img_array[y, x] = PALETTE['seed_light']

def add_psx_grain(img_array):
    """Add PSX-style grain/noise to non-transparent pixels"""
    for y in range(SIZE):
        for x in range(SIZE):
            if img_array[y, x, 3] > 0:  # Non-transparent pixel
                # Add random noise
                if random.random() < 0.15:
                    noise = random.randint(-15, 15)
                    for c in range(3):  # RGB channels
                        val = int(img_array[y, x, c]) + noise
                        img_array[y, x, c] = np.clip(val, 0, 255)

def apply_dithering(img_array):
    """Apply simple ordered dithering for PSX look"""
    # Bayer 2x2 matrix
    bayer = np.array([[0, 2],
                      [3, 1]]) / 4.0

    for y in range(SIZE):
        for x in range(SIZE):
            if img_array[y, x, 3] > 0:  # Non-transparent
                threshold = bayer[y % 2, x % 2] * 30
                for c in range(3):
                    if img_array[y, x, c] < threshold:
                        img_array[y, x, c] = max(0, img_array[y, x, c] - 10)

def generate_texture():
    """Main generation function"""
    print("Generating PSX-style trail mix texture...")

    # Create base image
    img = create_base_image()
    img_array = np.array(img, dtype=np.uint8)
    draw = ImageDraw.Draw(img)

    # Build the texture in layers
    print("  - Drawing bag shape...")
    draw_bag_shape(draw, img_array)

    print("  - Drawing trail mix pieces...")
    draw_trail_mix_pieces(img_array)

    print("  - Drawing ziplock seal...")
    draw_ziplock_seal(img_array)

    print("  - Adding crinkles...")
    add_crinkles(img_array)

    print("  - Applying PSX grain...")
    add_psx_grain(img_array)

    print("  - Applying dithering...")
    apply_dithering(img_array)

    # Convert back to image
    final_img = Image.fromarray(img_array, 'RGBA')

    # Save
    output_path = "output.png"
    final_img.save(output_path)
    print(f"✓ Texture saved to {output_path}")
    print(f"  Size: {SIZE}x{SIZE} pixels")

    return final_img

if __name__ == "__main__":
    generate_texture()
