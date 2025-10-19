# iOS Setup - Quick Reference

## 🚀 One-Command Setup

```bash
cd /Users/kb/Documents/testing_claude/weight_tracker_flutter
chmod +x setup_ios.sh
./setup_ios.sh
```

## 📝 Manual Setup (3 Commands)

```bash
# 1. Create iOS files
flutter create --platforms=ios .

# 2. Install dependencies
cd ios && pod install && cd ..

# 3. Test
flutter run
```

## ✅ Verify Setup

```bash
# Check if iOS folder exists
ls ios/

# Should see:
# - Runner/
# - Runner.xcworkspace/
# - Podfile
# - Pods/
```

## 🔧 After Setup

1. **Open in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure:**
   - Bundle ID: `com.yourcompany.fittrack`
   - Team: Select your Apple Developer account
   - Enable automatic signing

3. **Test:**
   ```bash
   flutter run
   ```

## 🐛 If Issues

```bash
# Reset and try again
rm -rf ios
flutter clean
flutter create --platforms=ios .
cd ios && pod install && cd ..
flutter pub get
```

## 📚 Full Guide

See `IOS_SETUP_GUIDE.md` for complete documentation.

---

**Need help?** Check the full setup guide!
