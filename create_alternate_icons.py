#!/usr/bin/env python3
"""
Create alternate app icons with different color schemes
"""

from PIL import Image, ImageDraw

def create_dumbbell_icon(bg_color, output_path):
    """Create a dumbbell icon with specified background color"""
    size = 1024
    img = Image.new('RGB', (size, size), color=bg_color)
    draw = ImageDraw.Draw(img)

    # Center coordinates
    cx, cy = size // 2, size // 2

    # Dumbbell bar (horizontal rectangle)
    bar_width = 400
    bar_height = 60
    bar_left = cx - bar_width // 2
    bar_top = cy - bar_height // 2
    draw.rounded_rectangle(
        [bar_left, bar_top, bar_left + bar_width, bar_top + bar_height],
        radius=20,
        fill='white'
    )

    # Left weight plate
    plate_width = 140
    plate_height = 200
    left_plate_x = bar_left - plate_width + 20
    left_plate_y = cy - plate_height // 2
    draw.rounded_rectangle(
        [left_plate_x, left_plate_y, left_plate_x + plate_width, left_plate_y + plate_height],
        radius=15,
        fill='white'
    )

    # Right weight plate
    right_plate_x = bar_left + bar_width - 20
    right_plate_y = cy - plate_height // 2
    draw.rounded_rectangle(
        [right_plate_x, right_plate_y, right_plate_x + plate_width, right_plate_y + plate_height],
        radius=15,
        fill='white'
    )

    # Add small accent circles on the plates
    circle_radius = 25
    # Left plate circles
    draw.ellipse(
        [left_plate_x + 35, cy - circle_radius, left_plate_x + 35 + circle_radius * 2, cy + circle_radius],
        fill=bg_color
    )
    # Right plate circles
    draw.ellipse(
        [right_plate_x + 80, cy - circle_radius, right_plate_x + 80 + circle_radius * 2, cy + circle_radius],
        fill=bg_color
    )

    img.save(output_path, 'PNG')
    print(f"✅ Created: {output_path}")

# Color schemes
icons = [
    ('app_icon.png', '#1976D2', 'Blue (Default)'),
    ('app_icon_red.png', '#D32F2F', 'Red'),
    ('app_icon_green.png', '#388E3C', 'Green'),
    ('app_icon_orange.png', '#F57C00', 'Orange'),
    ('app_icon_purple.png', '#7B1FA2', 'Purple'),
    ('app_icon_dark.png', '#212121', 'Dark'),
]

print("Creating alternate app icons...")
for filename, color, name in icons:
    create_dumbbell_icon(color, f'assets/icon/{filename}')

print(f"\n✅ Successfully created {len(icons)} app icon variations!")
