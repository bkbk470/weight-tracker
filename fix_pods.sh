#!/bin/bash

echo "🔧 Fixing CocoaPods Sync Issue"
echo "================================"
echo ""

PROJECT_DIR="/Users/kb/Documents/testing_claude/weight_tracker_flutter"

cd "$PROJECT_DIR"

echo "📦 Step 1: Cleaning iOS build artifacts..."
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/build
echo "✅ iOS artifacts cleaned"
echo ""

echo "🧹 Step 2: Cleaning Flutter..."
flutter clean
echo "✅ Flutter cleaned"
echo ""

echo "📥 Step 3: Getting Flutter dependencies..."
flutter pub get
echo "✅ Flutter dependencies retrieved"
echo ""

echo "🔄 Step 4: Updating CocoaPods repo..."
cd ios
pod repo update
echo "✅ CocoaPods repo updated"
echo ""

echo "📦 Step 5: Installing pods..."
pod install --verbose
POD_EXIT_CODE=$?

if [ $POD_EXIT_CODE -eq 0 ]; then
    echo "✅ Pods installed successfully"
else
    echo "❌ Pod install failed with exit code $POD_EXIT_CODE"
    echo ""
    echo "Trying alternative approach..."
    echo ""
    
    echo "Deintegrating pods..."
    pod deintegrate
    
    echo "Reinstalling..."
    pod install --repo-update --verbose
fi

cd ..
echo ""

echo "🎉 Done!"
echo ""
echo "Next steps:"
echo "1. Try: flutter run"
echo "2. Or: flutter build ios --release"
echo "3. Or: open ios/Runner.xcworkspace"
