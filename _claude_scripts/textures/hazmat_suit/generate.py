#!/usr/bin/env python3
"""
Generate a 64x64 PSX-style hazmat suit billboard sprite.

Async Research Institute yellow Class A hazmat suit:
- Yellow suit body (bulky/baggy)
- Gray helmet with dark visor
- Front-facing silhouette view
- Simple PSX geometric aesthetic with grain
"""

from PIL import Image, ImageDraw
import random

# Dimensions
SIZE = 64

# Color palette (PSX-style muted colors)
YELLOW_SUIT = (200, 180, 80)       # Muted yellow for suit
YELLOW_DARK = (150, 130, 50)       # Darker yellow for shadows
GRAY_HELMET = (180, 180, 180)      # Light gray helmet
GRAY_DARK = (120, 120, 120)        # Dark gray for helmet shadows
VISOR_DARK = (60, 60, 60)          # Dark visor
BACKGROUND = (0, 0, 0, 0)          # Transparent background (will fill with opaque if needed)

def add_grain(img, intensity=15):
    """Add PSX-style grain/noise to the image."""
    pixels = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = pixels[x, y]
            if a > 0:  # Only add grain to non-transparent pixels
                noise = random.randint(-intensity, intensity)
                r = max(0, min(255, r + noise))
                g = max(0, min(255, g + noise))
                b = max(0, min(255, b + noise))
                pixels[x, y] = (r, g, b, a)

def draw_hazmat_suit():
    """Draw a front-facing hazmat suit sprite."""
    # Create RGBA image with transparent background
    img = Image.new('RGBA', (SIZE, SIZE), BACKGROUND)
    draw = ImageDraw.Draw(img)

    # Center position
    center_x = SIZE // 2

    # Draw LARGER industrial helmet (more bulky and intimidating)
    helmet_width = 20
    helmet_height = 18
    helmet_top = 6
    helmet_bottom = helmet_top + helmet_height

    # Helmet body (angular, not circular - industrial look)
    draw.ellipse(
        [center_x - helmet_width//2, helmet_top,
         center_x + helmet_width//2, helmet_bottom],
        fill=GRAY_HELMET
    )

    # Helmet shadow/shading (right side)
    draw.ellipse(
        [center_x + 2, helmet_top,
         center_x + helmet_width//2, helmet_bottom],
        fill=GRAY_DARK
    )

    # LARGE, PROMINENT VISOR (intimidating, not friendly)
    visor_width = 16
    visor_height = 8
    visor_top = helmet_top + 5
    draw.ellipse(
        [center_x - visor_width//2, visor_top,
         center_x + visor_width//2, visor_top + visor_height],
        fill=VISOR_DARK
    )

    # Visor reflection (small highlight to show it's glass/plastic)
    draw.ellipse(
        [center_x - visor_width//2 + 2, visor_top + 1,
         center_x - visor_width//2 + 5, visor_top + 3],
        fill=(100, 100, 100)
    )

    # Breathing apparatus/filters (side of helmet)
    filter_width = 4
    filter_height = 6
    filter_y = helmet_top + 8

    # Left filter
    draw.rectangle(
        [center_x - helmet_width//2 - 2, filter_y,
         center_x - helmet_width//2 + filter_width - 2, filter_y + filter_height],
        fill=GRAY_DARK
    )

    # Right filter
    draw.rectangle(
        [center_x + helmet_width//2 - filter_width + 2, filter_y,
         center_x + helmet_width//2 + 2, filter_y + filter_height],
        fill=GRAY_DARK
    )

    # Neck seal (thick collar connection)
    collar_width = 22
    collar_height = 5
    collar_top = helmet_bottom - 1
    draw.rectangle(
        [center_x - collar_width//2, collar_top,
         center_x + collar_width//2, collar_top + collar_height],
        fill=GRAY_DARK
    )

    # Suit body (BULKIER, more cumbersome looking)
    body_width = 32
    body_height = 30
    body_top = collar_top + collar_height
    draw.rectangle(
        [center_x - body_width//2, body_top,
         center_x + body_width//2, body_top + body_height],
        fill=YELLOW_SUIT
    )

    # Body shadow (right side) - deeper shadow for bulkiness
    shadow_width = 10
    draw.rectangle(
        [center_x + body_width//2 - shadow_width, body_top,
         center_x + body_width//2, body_top + body_height],
        fill=YELLOW_DARK
    )

    # Center seam/zipper line (industrial detail)
    draw.line(
        [(center_x, body_top), (center_x, body_top + body_height)],
        fill=YELLOW_DARK, width=2
    )

    # Arms (bulkier, more protective)
    arm_width = 10
    arm_height = 28
    arm_top = body_top + 2

    # Left arm (baggy protective sleeve)
    draw.rectangle(
        [center_x - body_width//2 - arm_width, arm_top,
         center_x - body_width//2, arm_top + arm_height],
        fill=YELLOW_SUIT
    )

    # Left arm shadow/fold
    draw.rectangle(
        [center_x - body_width//2 - arm_width, arm_top,
         center_x - body_width//2 - arm_width + 4, arm_top + arm_height],
        fill=YELLOW_DARK
    )

    # Right arm (fully shadowed)
    draw.rectangle(
        [center_x + body_width//2, arm_top,
         center_x + body_width//2 + arm_width, arm_top + arm_height],
        fill=YELLOW_DARK
    )

    # Gloves (gray/dark, industrial)
    glove_height = 6
    glove_top = arm_top + arm_height

    # Left glove
    draw.rectangle(
        [center_x - body_width//2 - arm_width, glove_top,
         center_x - body_width//2, glove_top + glove_height],
        fill=GRAY_DARK
    )

    # Right glove
    draw.rectangle(
        [center_x + body_width//2, glove_top,
         center_x + body_width//2 + arm_width, glove_top + glove_height],
        fill=(80, 80, 80)  # Darker in shadow
    )

    # EQUIPMENT STRAPS (crossing over chest)
    strap_width = 4
    # Left strap (diagonal from left shoulder to right hip)
    draw.line(
        [(center_x - body_width//2 + 4, body_top + 2),
         (center_x + body_width//2 - 8, body_top + body_height - 4)],
        fill=GRAY_DARK, width=strap_width
    )

    # Right strap (diagonal from right shoulder to left hip)
    draw.line(
        [(center_x + body_width//2 - 4, body_top + 2),
         (center_x - body_width//2 + 8, body_top + body_height - 4)],
        fill=GRAY_DARK, width=strap_width
    )

    # OXYGEN TANK (larger, more prominent on chest/back)
    tank_width = 12
    tank_height = 20
    tank_top = body_top + 6
    draw.rectangle(
        [center_x - tank_width//2, tank_top,
         center_x + tank_width//2, tank_top + tank_height],
        fill=GRAY_DARK
    )

    # Tank cylinder highlights (to show it's cylindrical)
    draw.rectangle(
        [center_x - tank_width//2 + 1, tank_top,
         center_x - tank_width//2 + 3, tank_top + tank_height],
        fill=GRAY_HELMET
    )

    # Breathing hose (connecting helmet to tank)
    hose_width = 3
    draw.line(
        [(center_x - 4, collar_top + collar_height),
         (center_x - 2, tank_top + 2)],
        fill=GRAY_DARK, width=hose_width
    )

    # Tank valve/regulator (top of tank)
    draw.rectangle(
        [center_x - 3, tank_top - 2,
         center_x + 3, tank_top + 2],
        fill=(80, 80, 80)
    )

    # Legs (bulkier, protective pants)
    leg_width = 12
    leg_height = 10
    leg_top = body_top + body_height

    # Left leg (baggy protective pants)
    draw.polygon(
        [(center_x - body_width//2 + 6, leg_top),
         (center_x - 1, leg_top),
         (center_x - 3, leg_top + leg_height),
         (center_x - body_width//2 + 4, leg_top + leg_height)],
        fill=YELLOW_SUIT
    )

    # Right leg (shadowed)
    draw.polygon(
        [(center_x + 1, leg_top),
         (center_x + body_width//2 - 6, leg_top),
         (center_x + body_width//2 - 4, leg_top + leg_height),
         (center_x + 3, leg_top + leg_height)],
        fill=YELLOW_DARK
    )

    # Boots (gray/dark industrial footwear)
    boot_height = 4
    boot_top = leg_top + leg_height

    # Left boot
    draw.rectangle(
        [center_x - body_width//2 + 4, boot_top,
         center_x - 3, boot_top + boot_height],
        fill=GRAY_DARK
    )

    # Right boot
    draw.rectangle(
        [center_x + 3, boot_top,
         center_x + body_width//2 - 4, boot_top + boot_height],
        fill=(80, 80, 80)  # Darker in shadow
    )

    # Add PSX grain
    add_grain(img, intensity=12)

    return img

def main():
    """Generate the hazmat suit sprite."""
    print("Generating 64x64 PSX-style hazmat suit sprite...")

    img = draw_hazmat_suit()

    output_path = 'output.png'
    img.save(output_path, 'PNG')

    print(f"✓ Generated hazmat suit sprite: {output_path}")
    print(f"  Size: {SIZE}x{SIZE} pixels")
    print(f"  Format: RGBA (transparent background)")

if __name__ == '__main__':
    main()
