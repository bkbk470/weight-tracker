#!/bin/bash

echo "🔧 Fixing iOS Code Signing Issues"
echo "=================================="
echo ""

PROJECT_DIR="/Users/kb/Documents/testing_claude/weight_tracker_flutter"
cd "$PROJECT_DIR"

echo "📦 Step 1: Removing extended attributes..."
xattr -cr ios/ 2>/dev/null || true
xattr -cr build/ 2>/dev/null || true
echo "✅ Extended attributes removed"
echo ""

echo "🧹 Step 2: Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ Derived data cleaned"
echo ""

echo "🗑️  Step 3: Removing build folders..."
rm -rf ios/build
rm -rf build
echo "✅ Build folders removed"
echo ""

echo "🧹 Step 4: Flutter clean..."
flutter clean
echo "✅ Flutter cleaned"
echo ""

echo "📥 Step 5: Getting dependencies..."
flutter pub get
echo "✅ Dependencies retrieved"
echo ""

echo "🔄 Step 6: Reinstalling pods..."
cd ios
pod install
cd ..
echo "✅ Pods installed"
echo ""

echo "🎉 Cleanup complete!"
echo ""
echo "Next steps:"
echo ""
echo "Option A - Build for Simulator (no signing needed):"
echo "  flutter build ios --simulator"
echo "  flutter run"
echo ""
echo "Option B - Fix signing in Xcode then build:"
echo "  open ios/Runner.xcworkspace"
echo "  (Fix signing in Xcode as described)"
echo "  flutter build ios --release"
echo ""
echo "Option C - Build for device:"
echo "  Connect your iPhone"
echo "  flutter run --release"
