# Sổ Chi Thu - Personal Expense Tracker

A personal expense tracking application built with Flutter to help you manage your finances effectively and save more.

## 📋 Description

"No Money No Me" is a mobile application that helps users track and manage their daily expenses. With a user-friendly interface and diverse features, the app supports recording transactions, viewing detailed reports, and analyzing financial trends.

## ✨ Key Features

- 🔐 **User Authentication**: Secure login and account registration
- 💰 **Transaction Management**: Add, edit, delete income and expense transactions
- 📅 **Expense Calendar**: View expenses by day/month/year
- 📊 **Detailed Reports**: Statistics and visual charts about finances
- ⚙️ **Settings**: Customize the app according to personal needs
- 🛠️ **Utility Tools**: Additional features to support financial management

## 🛠️ Technologies Used

- **Framework**: Flutter
- **Language**: Dart
- **Backend**: Firebase (Authentication, Firestore)
- **State Management**: Provider
- **UI Components**: Material Design
- **Additional Libraries**:
  - `intl`: Internationalization support
  - `table_calendar`: Calendar widget for expense tracking
  - `flutter_localizations`: Localization support

## 📱 Supported Platforms

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## 🚀 System Requirements

- Flutter SDK: >= 3.10.7
- Dart SDK: >= 3.10.7
- Android Studio / VS Code with Flutter extension
- Firebase account (for authentication and database)

## 📦 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/no-money-no-me.git
   cd no-money-no-me
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android/iOS/Web apps to the project
   - Download configuration files and place them in the appropriate directories:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
     - `web/firebase-config.js`

4. **Run the application:**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # Main application entry point
├── auth_screen.dart          # Authentication screen
├── home_screen.dart          # Home screen
├── transaction_form.dart     # Form for adding/editing transactions
├── calendar_tab.dart         # Calendar tab for expenses
├── report_tab.dart           # Reports tab
├── settings_tab.dart         # Settings tab
├── utilities_tab.dart        # Utilities tab
├── models.dart               # Data model definitions
└── utils.dart                # Utility functions
```

## 🔧 Running on Different Platforms

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Web
```bash
flutter run -d web
```

### Desktop
```bash
flutter run -d windows  # or linux, macos
```

## 🧪 Testing

Run the available tests:
```bash
flutter test
```

## 📱 Build Release

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```