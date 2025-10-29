#!/usr/bin/env python3
"""
Generate a lifting plate app icon
"""
from PIL import Image, ImageDraw, ImageFont
import math

def create_plate_icon(size=1024, bg_color=(41, 98, 255), plate_color=(50, 50, 60)):
    """Create a weight plate icon"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size // 2

    # Background circle (slightly larger for depth)
    outer_radius = int(size * 0.48)
    draw.ellipse(
        [(center - outer_radius, center - outer_radius),
         (center + outer_radius, center + outer_radius)],
        fill=bg_color
    )

    # Main plate body
    plate_radius = int(size * 0.42)
    draw.ellipse(
        [(center - plate_radius, center - plate_radius),
         (center + plate_radius, center + plate_radius)],
        fill=plate_color
    )

    # Inner rim (lighter)
    rim_radius = int(size * 0.38)
    draw.ellipse(
        [(center - rim_radius, center - rim_radius),
         (center + rim_radius, center + rim_radius)],
        fill=(70, 70, 80)
    )

    # Center hole
    hole_radius = int(size * 0.15)
    draw.ellipse(
        [(center - hole_radius, center - hole_radius),
         (center + hole_radius, center + hole_radius)],
        fill=(30, 30, 35)
    )

    # Inner hole highlight
    hole_inner = int(size * 0.12)
    draw.ellipse(
        [(center - hole_inner, center - hole_inner),
         (center + hole_inner, center + hole_inner)],
        fill=(40, 40, 45)
    )

    # Add grip holes (small circles around the plate)
    num_holes = 8
    grip_radius = int(size * 0.02)
    grip_distance = int(size * 0.35)

    for i in range(num_holes):
        angle = (i * 2 * math.pi) / num_holes
        x = center + int(grip_distance * math.cos(angle))
        y = center + int(grip_distance * math.sin(angle))

        draw.ellipse(
            [(x - grip_radius, y - grip_radius),
             (x + grip_radius, y + grip_radius)],
            fill=(40, 40, 45)
        )

    # Add weight text "45"
    try:
        # Try to use a bold font
        font_size = int(size * 0.15)
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()

    text = "45"

    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    text_x = center - text_width // 2
    text_y = center - text_height // 2 - int(size * 0.02)

    # Draw text with slight shadow for depth
    shadow_offset = int(size * 0.005)
    draw.text((text_x + shadow_offset, text_y + shadow_offset), text,
              fill=(20, 20, 25, 200), font=font)
    draw.text((text_x, text_y), text, fill=(200, 200, 210, 255), font=font)

    # Add "LBS" text below
    try:
        font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(size * 0.06))
    except:
        font_small = ImageFont.load_default()

    lbs_text = "LBS"
    bbox_lbs = draw.textbbox((0, 0), lbs_text, font=font_small)
    lbs_width = bbox_lbs[2] - bbox_lbs[0]
    lbs_x = center - lbs_width // 2
    lbs_y = center + int(size * 0.08)

    draw.text((lbs_x, lbs_y), lbs_text, fill=(160, 160, 170, 255), font=font_small)

    return img

def create_colored_variants(base_img, colors):
    """Create colored variants of the icon"""
    icons = {}

    for name, color in colors.items():
        # Create a copy
        img = base_img.copy()

        # Replace the blue background with the new color
        pixels = img.load()
        width, height = img.size

        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[x, y]
                # If it's the blue background color (roughly)
                if 30 < r < 60 and 80 < g < 120 and 240 < b < 255:
                    pixels[x, y] = (color[0], color[1], color[2], a)

        icons[name] = img

    return icons

# Generate the main icon
print("Generating lifting plate icon...")
main_icon = create_plate_icon(size=1024, bg_color=(41, 98, 255))

# Save main icon
main_icon.save('assets/icon/app_icon.png')
print("✓ Saved app_icon.png")

# Generate colored variants
colors = {
    'red': (220, 53, 69),
    'green': (40, 167, 69),
    'orange': (253, 126, 20),
    'purple': (111, 66, 193),
    'dark': (52, 58, 64)
}

print("Generating colored variants...")
colored_icons = create_colored_variants(main_icon, colors)

for name, icon in colored_icons.items():
    icon.save(f'assets/icon/app_icon_{name}.png')
    print(f"✓ Saved app_icon_{name}.png")

print("\n✓ All icons generated successfully!")
print("\nNext steps:")
print("1. Run: flutter pub run flutter_launcher_icons")
print("2. Rebuild your app to see the new icon")
