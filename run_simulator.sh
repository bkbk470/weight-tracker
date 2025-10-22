#!/bin/bash

echo "🎯 Building for iOS Simulator (No Signing Required)"
echo "===================================================="
echo ""

PROJECT_DIR="/Users/kb/Documents/testing_claude/weight_tracker_flutter"
cd "$PROJECT_DIR"

echo "🧹 Step 1: Cleaning project..."
flutter clean
rm -rf build
rm -rf ios/build
rm -rf ios/DerivedData
echo "✅ Project cleaned"
echo ""

echo "📥 Step 2: Getting dependencies...."
flutter pub get
echo "✅ Dependencies retrieved"
echo ""

echo "📱 Step 3: Checking available devices..."
flutter devices
echo ""

echo "🔨 Step 4: Building for simulator..."
flutter build ios --simulator --debug

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🎉 Ready to run!"
    echo ""
    echo "To run the app, execute:"
    echo "  flutter run"
    echo ""
    echo "Or specify a simulator:"
    echo "  flutter run -d 'iPhone 15 Pro'"
else
    echo "❌ Build failed"
    echo ""
    echo "Trying alternative approach..."
    echo "Running directly (will build automatically):"
    flutter run
fi
