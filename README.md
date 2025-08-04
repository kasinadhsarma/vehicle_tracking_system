# Vehicle Tracking System MVP

A comprehensive Flutter-based vehicle tracking system with real-time monitoring, fleet management, and advanced UI features.

## Features

### 🚗 Core Functionality
- **Real-time Vehicle Tracking**: Live GPS tracking and monitoring
- **Fleet Management**: Comprehensive vehicle and driver management
- **Interactive Dashboard**: Overview of fleet status, metrics, and activities
- **Live Map View**: Real-time vehicle positions with status indicators
- **Detailed Reports**: Analytics and reporting capabilities
- **Geofencing**: Location-based alerts and monitoring
- **Alert System**: Real-time notifications for important events

### 🎨 Enhanced UI/UX
- **Dark/Light Mode**: Seamless theme switching with system preference detection
- **Material 3 Design**: Modern, consistent design language
- **Responsive Layout**: Optimized for desktop and mobile platforms
- **Custom Components**: Reusable UI components with consistent styling
- **Animated Transitions**: Smooth animations and micro-interactions
- **Professional Dashboard**: Comprehensive fleet overview with metrics

### 🛠️ Technical Features
- **Cross-Platform**: Flutter support for Linux, Windows, macOS, iOS, and Android
- **State Management**: GetX for reactive programming and dependency injection
- **Theme Persistence**: Automatic theme preference saving
- **Modular Architecture**: Clean, scalable code structure
- **Custom Widgets**: Reusable component library

## Project Structure

```
lib/
├── app.dart                    # Main application entry point
├── main.dart                  # Application initialization
├── core/
│   ├── controllers/           # State management controllers
│   │   └── theme_controller.dart
│   ├── models/               # Data models
│   ├── services/             # Business logic services
│   ├── theme/                # Theme definitions
│   │   └── app_theme.dart
│   └── utils/                # Utility functions
├── features/                 # Feature modules
│   ├── alerts/              # Alert management
│   ├── auth/                # Authentication
│   ├── driver/              # Driver management
│   ├── geofence/            # Geofencing features
│   ├── manager/             # Manager dashboard
│   └── reports/             # Report generation
├── routes/                  # Navigation routing
│   └── app_routes.dart
└── shared/                  # Shared components
    └── widgets/
        └── custom_widgets.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or later)
- Dart SDK
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd vehicle_tracking_system
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on Linux Desktop**
   ```bash
   flutter run -d linux
   ```

4. **Run on other platforms**
   ```bash
   # Android
   flutter run -d android
   
   # iOS
   flutter run -d ios
   
   # Web
   flutter run -d web
   
   # Windows
   flutter run -d windows
   
   # macOS
   flutter run -d macos
   ```

### Platform-Specific Setup

#### Firebase Integration
- Firebase is automatically disabled for desktop platforms
- For mobile platforms, configure Firebase:
  1. Add your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
  2. Update Firebase configuration in `lib/firebase_options.dart`

#### Desktop Support
The application includes desktop-specific optimizations:
- Responsive navigation rail for larger screens
- Desktop-friendly UI components
- Platform-aware initialization

## Theme System

The application features a comprehensive theming system:

### Features
- **Automatic Detection**: Respects system theme preferences
- **Manual Toggle**: Easy switching between light and dark modes
- **Persistence**: Theme preferences are saved locally
- **Consistent Design**: Material 3 color schemes throughout

### Usage
```dart
// Get theme controller
final ThemeController themeController = Get.find<ThemeController>();

// Toggle theme
themeController.toggleTheme();

// Check current theme
bool isDark = themeController.isDarkMode;
```

## Custom Components

The application includes a library of custom widgets:

### Available Components
- **CustomCard**: Enhanced card with gradient and shadow options
- **CustomButton**: Versatile button with multiple variants
- **MetricCard**: Dashboard metric display cards
- **StatusChip**: Status indicators with color coding
- **LoadingButton**: Button with loading state support

### Usage Example
```dart
CustomButton(
  text: 'Action',
  icon: Icons.add,
  onPressed: () {},
  isOutlined: true,
)
```

## Architecture

### State Management
- **GetX**: Reactive state management with dependency injection
- **Controllers**: Centralized business logic and state
- **Reactive UI**: Automatic UI updates with Obx widgets

### Theme Management
- **ThemeController**: Centralized theme state management
- **SharedPreferences**: Local storage for theme persistence
- **Material 3**: Consistent design system implementation

## Development

### Hot Reload
During development, use Flutter's hot reload for rapid iteration:
```bash
# In the terminal running flutter run
r  # Hot reload
R  # Hot restart
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## Features Overview

### Dashboard
- Fleet overview with real-time metrics
- Active vehicle status indicators
- Recent activity timeline
- Quick action buttons
- System status monitoring

### Map View
- Real-time vehicle positions
- Interactive map controls
- Vehicle status filtering
- Geofence visualization

### Vehicle Management
- Comprehensive vehicle listings
- Status tracking and updates
- Detailed vehicle information
- Maintenance scheduling

### Reports & Analytics
- Fleet performance metrics
- Historical data analysis
- Exportable reports
- Custom date ranges

### Settings
- Theme customization
- Notification preferences
- Security settings
- Account management

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Email: support@vehicletracking.com
- Documentation: [docs.vehicletracking.com](https://docs.vehicletracking.com)
- Issues: GitHub Issues page

---

**Vehicle Tracking System MVP** - Built with ❤️ using Flutter
