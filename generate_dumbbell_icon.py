#!/usr/bin/env python3
"""
Generate a simple white dumbbell icon on black background for app icon.
"""

from PIL import Image, ImageDraw

def create_dumbbell_icon(size=1024, output_path='assets/icon/app_icon.png'):
    """Create a simple white dumbbell on black background."""

    # Create black background
    img = Image.new('RGB', (size, size), color='black')
    draw = ImageDraw.Draw(img)

    # Calculate dimensions
    center_x = size // 2
    center_y = size // 2

    # Dumbbell proportions
    bar_width = int(size * 0.5)  # 50% of icon width
    bar_height = int(size * 0.08)  # 8% thickness for bar

    weight_width = int(size * 0.15)  # 15% for weight plate width
    weight_height = int(size * 0.35)  # 35% for weight plate height

    # Draw center bar (horizontal)
    bar_left = center_x - bar_width // 2
    bar_top = center_y - bar_height // 2
    bar_right = center_x + bar_width // 2
    bar_bottom = center_y + bar_height // 2

    draw.rounded_rectangle(
        [bar_left, bar_top, bar_right, bar_bottom],
        radius=bar_height // 2,
        fill='white'
    )

    # Draw left weight plates
    left_weight_right = bar_left
    left_weight_left = left_weight_right - weight_width
    weight_top = center_y - weight_height // 2
    weight_bottom = center_y + weight_height // 2

    draw.rounded_rectangle(
        [left_weight_left, weight_top, left_weight_right, weight_bottom],
        radius=int(size * 0.02),
        fill='white'
    )

    # Draw right weight plates
    right_weight_left = bar_right
    right_weight_right = right_weight_left + weight_width

    draw.rounded_rectangle(
        [right_weight_left, weight_top, right_weight_right, weight_bottom],
        radius=int(size * 0.02),
        fill='white'
    )

    # Save the image
    img.save(output_path)
    print(f'✓ Created {output_path}')
    return output_path

if __name__ == '__main__':
    # Generate the icon
    create_dumbbell_icon()
    print('\n✓ Icon generation complete!')
    print('\nNext steps:')
    print('1. Run: flutter pub run flutter_launcher_icons')
    print('2. Rebuild your app to see the new icon')
