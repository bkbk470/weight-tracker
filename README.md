# FitTrack - Weight Tracker Flutter App

A complete Material Design 3 weightlifting tracking app built with Flutter, based on Figma design files.

## 🎯 Features v1.0.0

### Core Features
- **Beautiful Material Design 3 UI** - Modern, clean interface following Material 3 guidelines
- **User Authentication** - Sign in/Sign up screens with social login options
- **Onboarding Flow** - Welcome screens to introduce new users to the app
- **Dashboard** - Quick overview of workout stats, streak, and recent activities
- **Workout Tracking** - Active workout session with set tracking and rest timers
- **Progress Tracking** - Visual charts and graphs to track your fitness journey
- **Profile Management** - User profile with settings and preferences

### All Screens Included

#### 🔐 Authentication & Onboarding
1. **Login Screen** (`login_screen.dart`)
   - Sign In / Sign Up tabs
   - Email/Password authentication
   - Social login (Google, Apple)
   - Password visibility toggle
   - Form validation

2. **Welcome Screen** (`welcome_screen.dart`)
   - 4-slide onboarding flow
   - Progress indicators
   - Skip functionality
   - Beautiful illustrations

#### 🏠 Main App Screens
3. **Dashboard Screen** (`dashboard_screen.dart`)
   - Weekly stats overview
   - Quick action cards
   - Recent workouts list
   - Progress indicators
   - Workout streak display

4. **Workout Screen** (`workout_screen.dart`)
   - Pre-workout template selection
   - Real-time workout timer
   - Set tracking with weight/rep counters
   - Automatic rest timer with visual feedback
   - Add/remove exercises dynamically
   - Complete set tracking

5. **Progress Screen** (`progress_screen.dart`)
   - Time period selector (1M, 3M, 6M, 1Y)
   - Line charts for progress tracking
   - Bar charts for weekly activity
   - Achievement cards
   - Statistics grid
   - Recent achievements

6. **Profile Screen** (`profile_screen.dart`)
   - User information display
   - Statistics summary
   - Settings menu
   - Support options
   - Logout functionality

#### ⚙️ Settings & Utility Screens
7. **About Screen** (`about_screen.dart`)
   - App information
   - Version display
   - Feature highlights
   - Technology stack
   - Credits
   - Contact options
   - Legal links

8. **Edit Profile Screen** (`edit_profile_screen.dart`)
   - Update personal information
   - Profile picture upload
   - Physical stats (height, weight)
   - Unit system selection (Metric/Imperial)
   - Gender selection
   - Change password
   - Delete account

9. **Notifications Screen** (`notifications_screen.dart`)
   - Workout reminders
   - Rest timer alerts
   - Achievement notifications
   - Weekly reports toggle
   - Motivational messages
   - Custom reminder time

10. **Goals Screen** (`goals_screen.dart`)
    - Create fitness goals
    - Track progress
    - Active/completed goals
    - Goal categories (Strength, Frequency, Consistency)
    - Progress bars
    - Goal statistics

#### 🏋️ Workout Features
11. **Workout Builder Screen** (`workout_builder_screen.dart`)
    - Create custom workouts
    - Exercise library
    - Category filter (Chest, Back, Legs, etc.)
    - Reorderable exercise list
    - Set default sets/reps
    - Save workout templates

12. **Exercise Detail Screen** (`exercise_detail_screen.dart`)
    - Exercise-specific stats
    - Personal record display
    - Weight progression chart
    - Volume progression chart
    - Recent workout history
    - Time period filtering

## 📱 Screenshots Overview

The app includes 12 complete screens:
- Login/Sign Up
- Welcome/Onboarding (4 slides)
- Dashboard
- Active Workout
- Progress & Charts
- Profile
- About
- Edit Profile
- Notifications Settings
- Goals Management
- Workout Builder
- Exercise Details

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (recommended IDEs)

### Installation

1. Navigate to the project directory:
```bash
cd weight_tracker_flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Project Structure

```
lib/
├── main.dart                          # App entry point and navigation
├── screens/
│   ├── login_screen.dart             # Authentication
│   ├── welcome_screen.dart           # Onboarding
│   ├── dashboard_screen.dart         # Main dashboard
│   ├── workout_screen.dart           # Active workout tracking
│   ├── progress_screen.dart          # Progress charts
│   ├── profile_screen.dart           # User profile
│   ├── about_screen.dart             # App information
│   ├── edit_profile_screen.dart      # Profile editing
│   ├── notifications_screen.dart     # Notification settings
│   ├── goals_screen.dart             # Goals management
│   ├── workout_builder_screen.dart   # Custom workout creation
│   └── exercise_detail_screen.dart   # Exercise analytics
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  fl_chart: ^0.66.0              # Beautiful charts and graphs
```

## 🎨 Design System

The app uses Material Design 3 with:
- **Primary Color**: Cyan (#0891b2)
- **Secondary Color**: Green (#16a34a)
- **Typography**: Material 3 type scale
- **Components**: Cards, buttons, and navigation following Material 3 guidelines
- **Dark Mode**: Full dark theme support

## ✨ Key Features Implemented

### Authentication & Profile
- ✅ Tab-based sign in/sign up
- ✅ Social login buttons
- ✅ Profile editing with photo upload
- ✅ Account management

### Workout Tracking
- ✅ Real-time workout timer
- ✅ Set tracking with increment/decrement
- ✅ Visual rest timer with progress bar
- ✅ Exercise library with categories
- ✅ Custom workout builder
- ✅ Reorderable exercise lists

### Progress & Analytics
- ✅ Interactive line and bar charts
- ✅ Time period filtering
- ✅ Exercise-specific progress tracking
- ✅ Achievement system
- ✅ Weekly activity visualization

### Goals & Motivation
- ✅ Custom goal creation
- ✅ Progress tracking with visual indicators
- ✅ Active/completed goal separation
- ✅ Goal categories
- ✅ Overall progress calculation

### Settings & Customization
- ✅ Notification preferences
- ✅ Custom reminder times
- ✅ Unit system (Metric/Imperial)
- ✅ Theme support (Light/Dark)

## 🔄 Navigation Flow

```
Login → Welcome → Dashboard ⟷ Workout ⟷ Progress ⟷ Profile
                                  ↓         ↓          ↓
                           Workout Builder  Exercise  Settings
                                             Detail      ↓
                                                    About/Goals/
                                                    Notifications
```

## 🎯 Next Steps for Production

### Backend Integration
- [ ] Connect to a real backend API (Firebase, Supabase, or custom)
- [ ] Implement proper authentication with JWT tokens
- [ ] Store workout data in database
- [ ] Sync data across devices
- [ ] Cloud backup

### State Management
- [ ] Add Provider, Riverpod, or Bloc
- [ ] Implement proper data persistence (Hive, SQLite)
- [ ] Add offline support
- [ ] Implement data caching

### Additional Features
- [ ] Exercise video demonstrations
- [ ] Social features (share workouts, challenges)
- [ ] Export workout data (CSV, PDF)
- [ ] Import from other apps
- [ ] Apple Health / Google Fit integration
- [ ] Workout reminders and notifications
- [ ] Voice commands during workout
- [ ] Wearable device integration

### Testing & Quality
- [ ] Add unit tests
- [ ] Add widget tests
- [ ] Add integration tests
- [ ] Performance optimization
- [ ] Accessibility improvements

### Publishing
- [ ] App store screenshots
- [ ] Privacy policy and terms
- [ ] App store descriptions
- [ ] Beta testing
- [ ] Submit to App Store and Play Store

## 🐛 Known Issues

None currently. All screens are fully functional with mock data.

## 📄 License

This project is created for demonstration purposes based on Figma design files.

## 👏 Credits

- Design inspired by Material Design 3 guidelines
- Icons from Material Icons
- Charts powered by fl_chart
- Flutter framework by Google

## 📞 Support

For issues or questions:
- Check the code documentation
- Review the Flutter documentation
- Open an issue in the repository

---

**Made with ❤️ using Flutter**

Version: 1.0.0
# weight-tracker
