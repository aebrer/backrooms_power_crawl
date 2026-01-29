#!/usr/bin/env python3
"""
Vending Machine Sprite Generator
Generates a 64x64 PSX-style vending machine sprite with transparent background
"""

from PIL import Image, ImageDraw
import numpy as np

# Canvas size
SIZE = 64

# PSX-style limited palette
COLORS = {
    'body_dark': (45, 55, 65),        # Dark gray-blue (body shadow)
    'body_mid': (65, 75, 90),         # Mid gray-blue (main body)
    'body_light': (85, 95, 110),      # Light gray-blue (highlights)
    'metal_dark': (50, 50, 55),       # Dark metallic
    'metal_light': (100, 105, 115),   # Light metallic highlights
    'panel_bg': (30, 40, 50),         # Dark panel background
    'panel_glow': (60, 120, 180),     # Cyan-blue glow (display/coin slot)
    'accent_red': (180, 60, 60),      # Red button/item
    'accent_green': (60, 160, 70),    # Green button/item
    'accent_yellow': (200, 180, 60),  # Yellow accent
    'tray_dark': (35, 35, 40),        # Dispensing tray
}

# Create RGBA image
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
pixels = img.load()

# Machine dimensions (tall and narrow)
machine_left = 17
machine_right = 47
machine_width = machine_right - machine_left

# Machine structure (from top to bottom):
# - Top section (darker cap): y 4-8
# - PRODUCT DISPLAY WINDOW (60% of machine): y 8-42
# - Control panel (buttons/coin): y 42-50
# - Dispensing tray: y 50-58
# - Base: y 58-60

def draw_rect(x1, y1, x2, y2, color):
    """Draw a filled rectangle"""
    for y in range(y1, y2 + 1):
        for x in range(x1, x2 + 1):
            if 0 <= x < SIZE and 0 <= y < SIZE:
                pixels[x, y] = color + (255,)  # Add full alpha

def draw_pixel(x, y, color, alpha=255):
    """Draw a single pixel with optional alpha"""
    if 0 <= x < SIZE and 0 <= y < SIZE:
        pixels[x, y] = color + (alpha,)

# 1. Top cap (darker metallic)
draw_rect(machine_left, 4, machine_right, 8, COLORS['metal_dark'])
# Top highlight
for x in range(machine_left, machine_right):
    draw_pixel(x, 4, COLORS['metal_light'])

# 2. Main body
draw_rect(machine_left, 8, machine_right, 58, COLORS['body_mid'])

# Left edge shadow
for y in range(8, 58):
    draw_pixel(machine_left, y, COLORS['body_dark'])
    draw_pixel(machine_left + 1, y, COLORS['body_dark'])

# Right edge highlight
for y in range(8, 58):
    draw_pixel(machine_right, y, COLORS['body_light'])
    draw_pixel(machine_right - 1, y, COLORS['body_light'])

# 3. PRODUCT DISPLAY WINDOW (large, prominent, upper 60%)
display_top = 10
display_bottom = 42
display_left = machine_left + 3
display_right = machine_right - 3

# Window frame (darker border)
draw_rect(display_left, display_top, display_right, display_bottom, COLORS['metal_dark'])

# Glass area (lighter interior - brighter to show it's a window)
glass_left = display_left + 1
glass_right = display_right - 1
glass_top = display_top + 1
glass_bottom = display_bottom - 1
draw_rect(glass_left, glass_top, glass_right, glass_bottom, (50, 60, 75))  # Slightly lighter background

# Grid of product items (5 rows x 3 columns of colorful items)
item_colors = [COLORS['accent_red'], COLORS['accent_green'], COLORS['accent_yellow'],
               COLORS['panel_glow'], COLORS['accent_red']]
item_rows = 5
item_cols = 3
item_spacing_y = 6
item_spacing_x = 8
item_start_x = glass_left + 3
item_start_y = glass_top + 2

for row in range(item_rows):
    for col in range(item_cols):
        x = item_start_x + col * item_spacing_x
        y = item_start_y + row * item_spacing_y
        color = item_colors[(row + col) % len(item_colors)]
        # 3x3 pixel items (larger, more visible)
        for dy in range(3):
            for dx in range(3):
                draw_pixel(x + dx, y + dy, color)

# Glass reflection (diagonal highlight stripe)
for i in range(15):
    x = glass_left + 2 + i
    y = glass_top + 2 + i
    if x < glass_right - 1 and y < glass_bottom - 1:
        draw_pixel(x, y, COLORS['body_light'], 120)

# 4. Control panel (buttons and coin slot - SMALL section)
panel_top = 44
panel_bottom = 50
panel_left = machine_left + 4
panel_right = machine_right - 4

# Dark panel background
draw_rect(panel_left, panel_top, panel_right, panel_bottom, COLORS['panel_bg'])

# Small coin slot (horizontal)
coin_y = 46
for x in range(panel_left + 4, panel_right - 3):
    draw_pixel(x, coin_y, COLORS['panel_glow'])

# Two small buttons
draw_pixel(panel_left + 2, panel_top + 2, COLORS['accent_red'])
draw_pixel(panel_left + 2, panel_top + 3, COLORS['accent_red'])
draw_pixel(panel_right - 3, panel_top + 2, COLORS['accent_green'])
draw_pixel(panel_right - 3, panel_top + 3, COLORS['accent_green'])

# 5. Dispensing tray (dark inset at bottom - MORE PROMINENT)
tray_top = 52
tray_bottom = 57
tray_left = machine_left + 3
tray_right = machine_right - 3

# Tray frame (darker)
draw_rect(tray_left, tray_top, tray_right, tray_bottom, COLORS['metal_dark'])

# Tray opening (very dark - the actual dispensing slot)
tray_opening_top = tray_top + 1
tray_opening_bottom = tray_bottom - 1
draw_rect(tray_left + 1, tray_opening_top, tray_right - 1, tray_opening_bottom, COLORS['tray_dark'])

# Tray lip (slightly lighter edge at top to show depth)
for x in range(tray_left + 2, tray_right - 1):
    draw_pixel(x, tray_opening_top, COLORS['body_dark'])

# 6. Base (darker footer)
draw_rect(machine_left, 58, machine_right, 60, COLORS['metal_dark'])

# 7. Add some PSX-style weathering/noise (avoid the glass window)
np.random.seed(42)  # Consistent noise
for _ in range(60):  # Add random dark pixels for grungy look
    x = np.random.randint(machine_left + 2, machine_right - 1)
    y = np.random.randint(8, 58)
    # Skip the glass window area to keep it cleaner
    if y >= display_top and y <= display_bottom:
        continue
    # Only darken existing pixels (not transparent areas)
    if pixels[x, y][3] > 0:
        current = pixels[x, y]
        darkened = tuple(max(0, c - 15) for c in current[:3])
        draw_pixel(x, y, darkened, current[3])

# 8. Vertical edge highlights (PSX-style hard edges)
for y in range(8, 58):
    if pixels[machine_left + 2, y][3] > 0:
        draw_pixel(machine_left + 2, y, COLORS['body_light'], 180)

# Save the image
img.save('output.png')
print(f"✓ Vending machine sprite generated: output.png")
print(f"  Size: {img.size[0]}x{img.size[1]} pixels")
print(f"  Mode: {img.mode} (RGBA with transparency)")
