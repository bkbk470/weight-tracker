#!/bin/bash

echo "🚀 Preparing for TestFlight Build"
echo "=================================="
echo ""

PROJECT_DIR="/Users/kb/Documents/testing_claude/weight_tracker_flutter"
cd "$PROJECT_DIR"

echo "⚠️  This script requires sudo access to remove extended attributes"
echo "You may be prompted for your password."
echo ""

# Step 1: Remove extended attributes (the main issue)
echo "🧹 Step 1: Removing extended attributes from all files..."
sudo xattr -cr .
if [ $? -eq 0 ]; then
    echo "✅ Extended attributes removed"
else
    echo "❌ Failed to remove extended attributes"
    echo "Try running: sudo xattr -cr ."
    exit 1
fi
echo ""

# Step 2: Clean derived data
echo "🗑️  Step 2: Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ Derived data cleaned"
echo ""

# Step 3: Clean build folders
echo "🗑️  Step 3: Cleaning build folders..."
rm -rf build
rm -rf ios/build
rm -rf ios/DerivedData
echo "✅ Build folders cleaned"
echo ""

# Step 4: Flutter clean
echo "🧹 Step 4: Flutter clean..."
flutter clean
echo "✅ Flutter cleaned"
echo ""

# Step 5: Get dependencies
echo "📥 Step 5: Getting Flutter dependencies..."
flutter pub get
echo "✅ Dependencies retrieved"
echo ""

# Step 6: Reinstall pods
echo "🔄 Step 6: Reinstalling CocoaPods..."
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
POD_EXIT=$?
cd ..

if [ $POD_EXIT -eq 0 ]; then
    echo "✅ Pods installed successfully"
else
    echo "❌ Pod install failed"
    exit 1
fi
echo ""

echo "🎉 Cleanup Complete!"
echo ""
echo "═══════════════════════════════════════════"
echo "Next Steps for TestFlight:"
echo "═══════════════════════════════════════════"
echo ""
echo "1. Open Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Configure Signing:"
echo "   - Select 'Runner' target"
echo "   - Go to 'Signing & Capabilities'"
echo "   - Enable 'Automatically manage signing'"
echo "   - Select your Apple Developer Team"
echo "   - Set Bundle ID: com.yourcompany.fittrack"
echo ""
echo "3. Select Build Target:"
echo "   - Choose 'Any iOS Device (arm64)'"
echo ""
echo "4. Clean Build Folder:"
echo "   - Menu: Product → Clean Build Folder (⌘⇧K)"
echo ""
echo "5. Create Archive:"
echo "   - Menu: Product → Archive"
echo "   - Wait 5-15 minutes"
echo ""
echo "6. Distribute to TestFlight:"
echo "   - In Organizer, click 'Distribute App'"
echo "   - Choose 'App Store Connect'"
echo "   - Follow the wizard"
echo ""
echo "Opening Xcode now..."
sleep 2
open ios/Runner.xcworkspace
