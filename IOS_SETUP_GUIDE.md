# iOS Setup Guide - From Scratch

## 🎯 Overview
Your Flutter project doesn't have iOS support yet. This guide will help you add it and prepare for TestFlight.

## 📋 Prerequisites

Before starting, make sure you have:

1. **Mac Computer** with macOS
2. **Xcode** installed (from App Store)
3. **CocoaPods** installed
4. **Flutter** SDK installed
5. **Apple Developer Account** (for TestFlight)

### Check Prerequisites

```bash
# Check if you have Xcode
xcode-select --version

# Check if you have CocoaPods
pod --version

# If CocoaPods not installed:
sudo gem install cocoapods

# Check Flutter
flutter doctor
```

## 🚀 Quick Setup (Automated)

### Option 1: Use Setup Script

```bash
# Navigate to project
cd /Users/kb/Documents/testing_claude/weight_tracker_flutter

# Make script executable
chmod +x setup_ios.sh

# Run setup script
./setup_ios.sh
```

## 🔧 Manual Setup (Step by Step)

### Step 1: Add iOS Platform

```bash
# Navigate to your project root
cd /Users/kb/Documents/testing_claude/weight_tracker_flutter

# Create iOS platform files
flutter create --platforms=ios .
```

**What this does:**
- Creates `ios` folder
- Generates Xcode project files
- Sets up basic iOS configuration
- Creates Podfile for dependencies

### Step 2: Install Dependencies

```bash
# Navigate to ios folder
cd ios

# Install CocoaPods dependencies
pod install

# This will create:
# - Pods folder
# - Runner.xcworkspace (use this, not .xcodeproj!)
# - Podfile.lock

# Return to project root
cd ..
```

### Step 3: Clean and Get Flutter Dependencies

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get
```

### Step 4: Configure Xcode Project

```bash
# Open Xcode workspace (NOT .xcodeproj!)
open ios/Runner.xcworkspace
```

In Xcode:

1. **Select Runner** in the left sidebar
2. **Go to Signing & Capabilities tab**
3. **Update the following:**

   - **Display Name**: `FitTrack`
   - **Bundle Identifier**: `com.yourcompany.fittrack`
     (Replace `yourcompany` with your company name)
   - **Version**: `1.0.0`
   - **Build**: `1`

4. **Enable Automatic Signing:**
   - Check "Automatically manage signing"
   - Select your Apple Developer Team
   - If you don't have a team, you'll need to add your Apple ID:
     - Xcode → Preferences → Accounts
     - Click "+" → Add Apple ID

### Step 5: Update Info.plist

The file is located at: `ios/Runner/Info.plist`

Add/update these keys:

```xml
<key>CFBundleDisplayName</key>
<string>FitTrack</string>

<key>CFBundleName</key>
<string>FitTrack</string>

<key>NSCameraUsageDescription</key>
<string>We need camera access to take profile photos</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select profile photos</string>
```

### Step 6: Test iOS Build

```bash
# Check if iOS simulator is available
flutter devices

# Run on iOS simulator
flutter run

# Or build release version
flutter build ios --release
```

## 📱 Testing Before TestFlight

### Test on Simulator

```bash
# List available simulators
xcrun simctl list devices

# Run app on simulator
flutter run
```

### Test on Real Device

1. **Connect iPhone/iPad via USB**
2. **Trust computer on device**
3. **In Xcode:**
   - Select your device from device dropdown
   - Click Run (▶️) button
4. **Or via command line:**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure After Setup

```
weight_tracker_flutter/
├── android/               (existing)
├── ios/                   (newly created)
│   ├── Flutter/
│   ├── Pods/             (after pod install)
│   ├── Runner/
│   │   ├── Assets.xcassets/
│   │   ├── Info.plist
│   │   ├── AppDelegate.swift
│   │   └── Runner-Bridging-Header.h
│   ├── Runner.xcodeproj/
│   ├── Runner.xcworkspace/  (USE THIS!)
│   ├── Podfile
│   └── Podfile.lock
├── lib/                  (existing)
├── pubspec.yaml          (existing)
└── setup_ios.sh          (new script)
```

## 🎨 Adding App Icons

After iOS setup, you need to add app icons:

### Option 1: Use Online Generator

1. Go to https://appicon.co or https://www.appicon.build
2. Upload a 1024x1024 PNG image
3. Download the generated icons
4. Replace contents of `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Option 2: Manual Creation

Create icons in these sizes:
- 1024x1024 (App Store)
- 180x180 (iPhone)
- 167x167 (iPad Pro)
- 152x152 (iPad)
- 120x120 (iPhone)
- And smaller sizes...

Place in: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## ⚙️ Important Configuration

### Update Deployment Target

In Xcode:
1. Select Runner → Build Settings
2. Search for "iOS Deployment Target"
3. Set to iOS 12.0 or higher

### Enable Required Capabilities

If your app uses:
- **Push Notifications**: Enable in Signing & Capabilities
- **Background Modes**: Enable if needed
- **App Groups**: Enable if sharing data

## 🐛 Common Issues

### Issue 1: "pod: command not found"
**Solution:**
```bash
sudo gem install cocoapods
```

### Issue 2: "No such file or directory - ios/Podfile"
**Solution:**
```bash
flutter create --platforms=ios .
cd ios
pod install
```

### Issue 3: "Failed to build iOS app"
**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### Issue 4: "Could not find Runner.xcworkspace"
**Solution:**
- Make sure you ran `pod install` in the ios folder
- The workspace is created by CocoaPods

### Issue 5: Signing errors in Xcode
**Solution:**
- Use automatic signing
- Add your Apple ID to Xcode Accounts
- Select your development team

## 📚 Next Steps

After successful iOS setup:

1. ✅ Test app on simulator
2. ✅ Test app on real device
3. ✅ Add app icons
4. ✅ Configure bundle identifier
5. ✅ Set up signing
6. ✅ Create App Store Connect app
7. ✅ Build for TestFlight

## 🎯 Quick Commands Reference

```bash
# Create iOS platform
flutter create --platforms=ios .

# Install pods
cd ios && pod install && cd ..

# Clean project
flutter clean

# Get dependencies
flutter pub get

# Run on simulator
flutter run

# Build release
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace

# Check available devices
flutter devices

# Check Flutter health
flutter doctor
```

## 📝 Checklist

- [ ] Xcode installed
- [ ] CocoaPods installed
- [ ] iOS platform created
- [ ] Pods installed successfully
- [ ] App runs on simulator
- [ ] Bundle ID configured
- [ ] Signing configured
- [ ] App icons added
- [ ] Info.plist updated
- [ ] Tested on real device (if available)

## 🆘 Getting Help

If you encounter issues:

1. **Check Flutter doctor:**
   ```bash
   flutter doctor -v
   ```

2. **Check Xcode issues:**
   - Open Xcode
   - Check for any error messages
   - Product → Clean Build Folder

3. **Reset setup:**
   ```bash
   rm -rf ios
   flutter clean
   flutter create --platforms=ios .
   cd ios && pod install && cd ..
   flutter pub get
   ```

## 💡 Tips

1. Always use `Runner.xcworkspace`, never `Runner.xcodeproj`
2. Run `pod install` after adding new dependencies
3. Keep Xcode and Flutter updated
4. Test on simulator first, then real device
5. Use automatic signing for easier setup

---

**Ready to proceed?** Run the setup script or follow the manual steps above!

Once iOS is set up, come back and I'll help you prepare for TestFlight submission. 🚀
