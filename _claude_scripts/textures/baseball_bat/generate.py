#!/usr/bin/env python3
"""
Generate a 64x64 pixel baseball bat texture with PSX-style aesthetics.

FIXES FROM PREVIOUS VERSION:
1. DIAGONAL orientation (45 degrees, bottom-left to top-right)
2. CORRECT COLOR GRADIENT: lighter barrel, darker handle
3. BETTER PROPORTIONS: elongated bat shape, not popsicle
4. CLEAR TAPE GRIP: distinct horizontal bands at handle
5. PSX GRAIN: visible noise and dithering
"""

from PIL import Image, ImageDraw
import random
import math

# Constants
SIZE = 64
OUTPUT_PATH = "output.png"

# Color palette - natural wood tones with PSX dithering
BARREL_BASE = (210, 180, 140)      # Lighter tan for hitting end
HANDLE_BASE = (139, 90, 43)        # Darker brown for grip end
TAPE_COLOR = (50, 50, 50)          # Dark grey athletic tape
HIGHLIGHT = (240, 220, 180)        # Wood highlight
SHADOW = (100, 60, 30)             # Deep shadow

def add_psx_grain(img, intensity=0.15):
    """Add PSX-style grain/dithering to the image."""
    pixels = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = pixels[x, y]
            if a > 0:  # Only on non-transparent pixels
                noise = random.uniform(-intensity, intensity)
                r = max(0, min(255, int(r * (1 + noise))))
                g = max(0, min(255, int(g * (1 + noise))))
                b = max(0, min(255, int(b * (1 + noise))))
                pixels[x, y] = (r, g, b, a)
    return img

def distance_to_line(px, py, x1, y1, x2, y2):
    """Calculate perpendicular distance from point to line segment."""
    # Vector from line start to point
    dx = px - x1
    dy = py - y1

    # Line direction vector
    lx = x2 - x1
    ly = y2 - y1

    # Project point onto line
    line_len_sq = lx*lx + ly*ly
    if line_len_sq == 0:
        return math.sqrt(dx*dx + dy*dy), 0

    t = max(0, min(1, (dx*lx + dy*ly) / line_len_sq))

    # Closest point on line
    closest_x = x1 + t * lx
    closest_y = y1 + t * ly

    # Distance to closest point
    dist_x = px - closest_x
    dist_y = py - closest_y

    return math.sqrt(dist_x*dist_x + dist_y*dist_y), t

def create_baseball_bat():
    """Generate the baseball bat texture."""
    # Create image with transparency
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    pixels = img.load()

    # Bat orientation: diagonal from bottom-left to top-right (45 degrees)
    # Start point (handle end - bottom left) - moved inward to prevent clipping
    start_x = 12
    start_y = SIZE - 12

    # End point (barrel end - top right) - moved inward to prevent clipping
    end_x = SIZE - 14
    end_y = 14

    # Bat dimensions along its length (slightly smaller to fit)
    HANDLE_WIDTH = 3.0      # Thin grip
    BARREL_WIDTH = 7.0      # Thick hitting end
    TAPER_START = 0.3       # Where taper begins (30% from handle)
    TAPER_END = 0.75        # Where barrel reaches full width

    # Process each pixel
    for y in range(SIZE):
        for x in range(SIZE):
            dist, t = distance_to_line(x, y, start_x, start_y, end_x, end_y)

            # Calculate width at this position along bat
            if t < TAPER_START:
                # Handle - constant thin width
                width = HANDLE_WIDTH
            elif t < TAPER_END:
                # Taper section - gradual widening
                taper_progress = (t - TAPER_START) / (TAPER_END - TAPER_START)
                width = HANDLE_WIDTH + (BARREL_WIDTH - HANDLE_WIDTH) * taper_progress
            else:
                # Barrel - constant thick width
                width = BARREL_WIDTH

            # Check if pixel is inside bat
            if dist <= width:
                # Base color gradient: LIGHTER at barrel, DARKER at handle
                # (FIXED: was backwards before!)
                barrel_amount = t  # 0 at handle, 1 at barrel

                r = int(HANDLE_BASE[0] + (BARREL_BASE[0] - HANDLE_BASE[0]) * barrel_amount)
                g = int(HANDLE_BASE[1] + (BARREL_BASE[1] - HANDLE_BASE[1]) * barrel_amount)
                b = int(HANDLE_BASE[2] + (BARREL_BASE[2] - HANDLE_BASE[2]) * barrel_amount)

                # Add cylindrical shading (darker at edges)
                edge_factor = dist / width  # 0 at center, 1 at edge
                shade = 1.0 - (edge_factor * 0.3)  # Darken edges by 30%

                r = int(r * shade)
                g = int(g * shade)
                b = int(b * shade)

                # Add subtle highlight on top edge
                if dist < width * 0.3:
                    highlight_strength = (1.0 - dist / (width * 0.3)) * 0.2
                    r = int(r + (HIGHLIGHT[0] - r) * highlight_strength)
                    g = int(g + (HIGHLIGHT[1] - g) * highlight_strength)
                    b = int(b + (HIGHLIGHT[2] - b) * highlight_strength)

                # Athletic tape grip at handle end (3-4 bands)
                # Tape wraps perpendicular to bat direction
                tape_zone = t < 0.25  # First 25% of bat
                if tape_zone:
                    # Create 4 tape bands
                    band_position = t / 0.25  # 0 to 1 within tape zone
                    band_index = band_position * 12  # 12 segments = 4 bands with gaps

                    # Every 3 segments: 2 segments tape, 1 segment gap
                    in_band = (int(band_index) % 3) < 2

                    if in_band:
                        # Tape color with slight texture
                        tape_shade = 1.0 - (edge_factor * 0.2)
                        r = int(TAPE_COLOR[0] * tape_shade)
                        g = int(TAPE_COLOR[1] * tape_shade)
                        b = int(TAPE_COLOR[2] * tape_shade)

                pixels[x, y] = (r, g, b, 255)

    # Add PSX grain
    img = add_psx_grain(img, intensity=0.18)

    # Add dithering pattern for PSX aesthetic
    pixels = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = pixels[x, y]
            if a > 0:
                # Checkerboard dither pattern
                if (x + y) % 2 == 0:
                    dither = -8
                else:
                    dither = 8

                r = max(0, min(255, r + dither))
                g = max(0, min(255, g + dither))
                b = max(0, min(255, b + dither))
                pixels[x, y] = (r, g, b, a)

    return img

def main():
    print("Generating baseball bat texture...")
    print("FIXES: Diagonal orientation, correct color gradient, better proportions, tape grip, PSX grain")

    bat = create_baseball_bat()
    bat.save(OUTPUT_PATH)

    print(f"✓ Baseball bat texture saved to {OUTPUT_PATH}")
    print(f"  Size: {SIZE}x{SIZE} pixels")
    print(f"  Orientation: Diagonal (45°, bottom-left to top-right)")
    print(f"  Colors: Lighter barrel → darker handle with tape grip")
    print(f"  Style: PSX low-res with grain and dithering")

if __name__ == "__main__":
    main()
