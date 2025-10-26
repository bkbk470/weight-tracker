#!/bin/bash

# Script to generate all alternate icon sets for iOS

echo "Generating alternate app icon sets..."

# Colors and their names
declare -a colors=("red" "green" "orange" "purple" "dark")

# Temporarily modify pubspec.yaml for each color variant
for color in "${colors[@]}"; do
    echo "Generating ${color} icon set..."

    # Create temporary pubspec
    cat > temp_icon_config.yaml <<EOF
flutter_launcher_icons:
  ios: true
  image_path: "assets/icon/app_icon_${color}.png"
  remove_alpha_ios: true
EOF

    # Generate icons
    flutter pub run flutter_launcher_icons -f temp_icon_config.yaml

    # Move generated icons to alternate icon set
    if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
        rm -rf "ios/Runner/Assets.xcassets/AppIcon-${color}.appiconset"
        cp -r "ios/Runner/Assets.xcassets/AppIcon.appiconset" "ios/Runner/Assets.xcassets/AppIcon-${color}.appiconset"
        echo "✅ Created AppIcon-${color}.appiconset"
    fi
done

# Regenerate the default (blue) icon
echo "Regenerating default blue icon..."
flutter pub run flutter_launcher_icons

# Cleanup
rm -f temp_icon_config.yaml

echo "✅ All icon sets generated successfully!"
