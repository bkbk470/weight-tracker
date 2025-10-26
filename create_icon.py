#!/usr/bin/env python3
"""
Simple script to create an iOS app icon for Weight Tracker app.
Creates a 1024x1024 PNG with a dumbbell icon.
"""

try:
    from PIL import Image, ImageDraw
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("PIL/Pillow not available. Install with: pip3 install Pillow")

def create_app_icon():
    if not PIL_AVAILABLE:
        print("Cannot create icon without Pillow library.")
        print("Please install: pip3 install Pillow")
        return False

    # Create 1024x1024 image (iOS App Store size)
    size = 1024
    img = Image.new('RGB', (size, size), color='#1976D2')  # Material blue
    draw = ImageDraw.Draw(img)

    # Draw a simple dumbbell icon
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
        fill='#1976D2'
    )
    # Right plate circles
    draw.ellipse(
        [right_plate_x + 80, cy - circle_radius, right_plate_x + 80 + circle_radius * 2, cy + circle_radius],
        fill='#1976D2'
    )

    # Save the icon
    output_path = 'assets/icon/app_icon.png'
    img.save(output_path, 'PNG')
    print(f"✅ App icon created successfully: {output_path}")
    print(f"   Size: {size}x{size}px")
    return True

if __name__ == '__main__':
    create_app_icon()
