#!/bin/bash

echo "🚀 Setting up iOS for FitTrack Weight Tracker"
echo "=============================================="
echo ""

# Step 1: Create iOS platform
echo "📱 Step 1: Creating iOS platform files..."
flutter create --platforms=ios .

if [ $? -eq 0 ]; then
    echo "✅ iOS platform files created successfully"
else
    echo "❌ Failed to create iOS platform files"
    exit 1
fi

echo ""

# Step 2: Install CocoaPods dependencies
echo "📦 Step 2: Installing CocoaPods dependencies..."
cd ios
pod install

if [ $? -eq 0 ]; then
    echo "✅ CocoaPods dependencies installed successfully"
else
    echo "❌ Failed to install CocoaPods dependencies"
    echo "💡 Try running: sudo gem install cocoapods"
    exit 1
fi

cd ..
echo ""

# Step 3: Clean and get dependencies
echo "🧹 Step 3: Cleaning and getting dependencies..."
flutter clean
flutter pub get

echo ""

# Step 4: Verify setup
echo "✅ iOS Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode (NOT .xcodeproj)"
echo "2. Update Bundle Identifier to: com.yourcompany.fittrack"
echo "3. Select your Apple Developer Team"
echo "4. Run: flutter run to test on simulator/device"
echo ""
echo "To open in Xcode, run:"
echo "  open ios/Runner.xcworkspace"
