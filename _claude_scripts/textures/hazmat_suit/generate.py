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

    # Draw helmet (circle at top)
    helmet_radius = 10
    helmet_top = 8
    helmet_center_y = helmet_top + helmet_radius

    # Helmet background (light gray)
    draw.ellipse(
        [center_x - helmet_radius, helmet_center_y - helmet_radius,
         center_x + helmet_radius, helmet_center_y + helmet_radius],
        fill=GRAY_HELMET
    )

    # Helmet shadow (right side)
    draw.arc(
        [center_x - helmet_radius, helmet_center_y - helmet_radius,
         center_x + helmet_radius, helmet_center_y + helmet_radius],
        start=315, end=135, fill=GRAY_DARK, width=4
    )

    # Visor (dark oval on helmet)
    visor_width = 12
    visor_height = 6
    draw.ellipse(
        [center_x - visor_width//2, helmet_center_y - 2,
         center_x + visor_width//2, helmet_center_y + visor_height - 2],
        fill=VISOR_DARK
    )

    # Neck/collar connection (small gray rectangle)
    collar_width = 14
    collar_height = 4
    collar_top = helmet_center_y + helmet_radius
    draw.rectangle(
        [center_x - collar_width//2, collar_top,
         center_x + collar_width//2, collar_top + collar_height],
        fill=GRAY_DARK
    )

    # Suit body (bulky rectangle)
    body_width = 28
    body_height = 32
    body_top = collar_top + collar_height
    draw.rectangle(
        [center_x - body_width//2, body_top,
         center_x + body_width//2, body_top + body_height],
        fill=YELLOW_SUIT
    )

    # Body shadow (right side)
    shadow_width = 8
    draw.rectangle(
        [center_x + body_width//2 - shadow_width, body_top,
         center_x + body_width//2, body_top + body_height],
        fill=YELLOW_DARK
    )

    # Arms (simple rectangles on sides)
    arm_width = 8
    arm_height = 26
    arm_top = body_top + 4

    # Left arm
    draw.rectangle(
        [center_x - body_width//2 - arm_width, arm_top,
         center_x - body_width//2, arm_top + arm_height],
        fill=YELLOW_SUIT
    )

    # Left arm shadow
    draw.rectangle(
        [center_x - body_width//2 - arm_width, arm_top,
         center_x - body_width//2 - arm_width + 3, arm_top + arm_height],
        fill=YELLOW_DARK
    )

    # Right arm
    draw.rectangle(
        [center_x + body_width//2, arm_top,
         center_x + body_width//2 + arm_width, arm_top + arm_height],
        fill=YELLOW_DARK  # Right arm is in shadow
    )

    # Oxygen tank (small gray rectangle on back/chest)
    tank_width = 10
    tank_height = 16
    tank_top = body_top + 8
    draw.rectangle(
        [center_x - tank_width//2, tank_top,
         center_x + tank_width//2, tank_top + tank_height],
        fill=GRAY_DARK
    )

    # Tank highlight
    draw.rectangle(
        [center_x - tank_width//2, tank_top,
         center_x - tank_width//2 + 2, tank_top + tank_height],
        fill=GRAY_HELMET
    )

    # Legs (simple trapezoid/rectangles)
    leg_width = 10
    leg_height = 12
    leg_top = body_top + body_height

    # Left leg
    draw.polygon(
        [(center_x - body_width//2 + 4, leg_top),
         (center_x - 2, leg_top),
         (center_x - 4, leg_top + leg_height),
         (center_x - body_width//2 + 2, leg_top + leg_height)],
        fill=YELLOW_SUIT
    )

    # Right leg
    draw.polygon(
        [(center_x + 2, leg_top),
         (center_x + body_width//2 - 4, leg_top),
         (center_x + body_width//2 - 2, leg_top + leg_height),
         (center_x + 4, leg_top + leg_height)],
        fill=YELLOW_DARK
    )

    # Add PSX grain
    add_grain(img, intensity=12)

    # Fill transparent background with solid color (make opaque)
    # Create new image with black background
    opaque_img = Image.new('RGB', (SIZE, SIZE), (0, 0, 0))
    opaque_img.paste(img, (0, 0), img)  # Paste with alpha as mask

    return opaque_img

def main():
    """Generate the hazmat suit sprite."""
    print("Generating 64x64 PSX-style hazmat suit sprite...")

    img = draw_hazmat_suit()

    output_path = 'output.png'
    img.save(output_path, 'PNG')

    print(f"✓ Generated hazmat suit sprite: {output_path}")
    print(f"  Size: {SIZE}x{SIZE} pixels")
    print(f"  Format: RGB (opaque)")

if __name__ == '__main__':
    main()
