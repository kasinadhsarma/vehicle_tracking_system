# 11. Source Code Structure

## 11.1 Overview

This chapter provides a comprehensive analysis of the Vehicle Tracking System's source code architecture, file organization, module structure, and development patterns. The codebase follows modern Flutter/Dart best practices with a clean architecture approach, emphasizing maintainability, scalability, and testability.

## 11.2 Project Architecture Overview

### 11.2.1 High-Level Structure

**Root Directory Organization:**
```
vehicle_tracking_system/
├── android/                    # Android-specific platform code
├── ios/                       # iOS-specific platform code
├── web/                       # Web-specific platform code
├── linux/                     # Linux desktop platform code
├── macos/                     # macOS desktop platform code
├── windows/                   # Windows desktop platform code
├── lib/                       # Main Dart application code
├── test/                      # Unit and integration tests
├── assets/                    # Static assets (images, fonts, etc.)
├── docs/                      # Project documentation
├── pubspec.yaml              # Project dependencies and metadata
├── analysis_options.yaml    # Dart analyzer configuration
└── README.md                 # Project overview and setup
```

### 11.2.2 Core Architecture Principles

**Clean Architecture Implementation:**
```yaml
Architecture Layers:
├── Presentation Layer (UI):
│   ├── Pages/Screens
│   ├── Widgets
│   ├── State Management
│   └── Navigation
├── Domain Layer (Business Logic):
│   ├── Entities
│   ├── Use Cases
│   ├── Repositories (Abstract)
│   └── Services (Abstract)
├── Data Layer (External):
│   ├── Repositories (Concrete)
│   ├── Data Sources
│   ├── Models
│   └── Services (Concrete)
└── Core Layer (Shared):
    ├── Constants
    ├── Utils
    ├── Extensions
    └── Configuration
```

## 11.3 Main Application Structure (`lib/` Directory)

### 11.3.1 Core Application Files

**Primary Application Entry Points:**
```dart
// lib/main.dart - Application entry point
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_config.dart';
import 'core/services/dependency_injection.dart';
import 'routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await DependencyInjection.init();
  runApp(VehicleTrackingApp());
}

class VehicleTrackingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vehicle Tracking System',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRoutes.router,
    );
  }
}
```

**Alternative Application Implementations:**
```yaml
Application Variants:
├── lib/app.dart:
│   ├── Full-featured application
│   ├── Complete state management
│   ├── All features enabled
│   └── Production configuration
├── lib/app_simple.dart:
│   ├── Simplified feature set
│   ├── Basic functionality only
│   ├── Educational/demo version
│   └── Minimal dependencies
├── lib/app_clean.dart:
│   ├── Clean architecture reference
│   ├── Best practices implementation
│   ├── Development template
│   └── Testing-focused structure
└── lib/app_backup.dart:
    ├── Backup implementation
    ├── Legacy code preservation
    ├── Migration reference
    └── Rollback capability
```

### 11.3.2 Core Module Structure

**Core Configuration and Utilities:**
```yaml
lib/core/
├── config/
│   ├── app_config.dart           # Application configuration
│   ├── environment_config.dart   # Environment variables
│   ├── firebase_config.dart      # Firebase settings
│   └── api_endpoints.dart        # API endpoint definitions
├── constants/
│   ├── app_constants.dart        # Global constants
│   ├── asset_constants.dart      # Asset path constants
│   ├── color_constants.dart      # Color definitions
│   ├── string_constants.dart     # Text strings
│   └── dimension_constants.dart  # UI dimensions
├── controllers/
│   ├── base_controller.dart      # Base controller class
│   ├── app_controller.dart       # Global app state
│   ├── network_controller.dart   # Network state management
│   └── permission_controller.dart # Device permissions
├── models/
│   ├── base_model.dart          # Base model interface
│   ├── api_response.dart        # API response wrapper
│   ├── error_model.dart         # Error handling model
│   └── result_model.dart        # Result wrapper
├── services/
│   ├── dependency_injection.dart # DI container setup
│   ├── database_service.dart    # Local database service
│   ├── network_service.dart     # HTTP client service
│   ├── location_service.dart    # GPS/location service
│   ├── notification_service.dart # Push notifications
│   └── storage_service.dart     # Local storage service
├── theme/
│   ├── app_theme.dart          # Theme configuration
│   ├── app_colors.dart         # Color scheme
│   ├── app_text_styles.dart    # Typography
│   └── app_decorations.dart    # UI decorations
└── utils/
    ├── date_utils.dart         # Date/time utilities
    ├── format_utils.dart       # Data formatting
    ├── validation_utils.dart   # Input validation
    ├── permission_utils.dart   # Permission helpers
    ├── location_utils.dart     # Location calculations
    └── network_utils.dart      # Network helpers
```

## 11.4 Feature-Based Module Organization

### 11.4.1 Authentication Module

**Authentication Feature Structure:**
```yaml
lib/features/auth/
├── data/
│   ├── models/
│   │   ├── user_model.dart          # User data model
│   │   ├── login_request.dart       # Login request DTO
│   │   ├── register_request.dart    # Registration DTO
│   │   └── auth_response.dart       # Auth response DTO
│   ├── repositories/
│   │   └── auth_repository_impl.dart # Auth repository implementation
│   └── datasources/
│       ├── auth_remote_datasource.dart # Firebase Auth
│       └── auth_local_datasource.dart  # Local storage
├── domain/
│   ├── entities/
│   │   ├── user.dart               # User entity
│   │   └── auth_token.dart         # Token entity
│   ├── repositories/
│   │   └── auth_repository.dart    # Auth repository interface
│   └── usecases/
│       ├── login_usecase.dart      # Login business logic
│       ├── register_usecase.dart   # Registration logic
│       ├── logout_usecase.dart     # Logout logic
│       └── refresh_token_usecase.dart # Token refresh
├── presentation/
│   ├── controllers/
│   │   ├── auth_controller.dart    # Auth state management
│   │   ├── login_controller.dart   # Login form controller
│   │   └── register_controller.dart # Register form controller
│   ├── pages/
│   │   ├── login_page.dart         # Login screen
│   │   ├── register_page.dart      # Registration screen
│   │   ├── forgot_password_page.dart # Password recovery
│   │   └── profile_page.dart       # User profile
│   └── widgets/
│       ├── auth_form_field.dart    # Custom form fields
│       ├── auth_button.dart        # Auth-specific buttons
│       ├── social_login_buttons.dart # Social auth widgets
│       └── password_strength_indicator.dart
└── tests/
    ├── unit/
    ├── widget/
    └── integration/
```

### 11.4.2 Vehicle Management Module

**Vehicle Management Feature Structure:**
```yaml
lib/features/vehicles/
├── data/
│   ├── models/
│   │   ├── vehicle_model.dart       # Vehicle data model
│   │   ├── vehicle_type_model.dart  # Vehicle type DTO
│   │   ├── vehicle_status_model.dart # Status model
│   │   └── maintenance_model.dart   # Maintenance record
│   ├── repositories/
│   │   └── vehicle_repository_impl.dart
│   └── datasources/
│       ├── vehicle_remote_datasource.dart # Firebase data
│       └── vehicle_local_datasource.dart  # SQLite cache
├── domain/
│   ├── entities/
│   │   ├── vehicle.dart            # Vehicle entity
│   │   ├── vehicle_type.dart       # Vehicle type entity
│   │   ├── vehicle_status.dart     # Status entity
│   │   └── maintenance_record.dart # Maintenance entity
│   ├── repositories/
│   │   └── vehicle_repository.dart # Repository interface
│   └── usecases/
│       ├── add_vehicle_usecase.dart     # Add vehicle
│       ├── update_vehicle_usecase.dart  # Update vehicle
│       ├── delete_vehicle_usecase.dart  # Delete vehicle
│       ├── get_vehicles_usecase.dart    # Fetch vehicles
│       └── schedule_maintenance_usecase.dart
├── presentation/
│   ├── controllers/
│   │   ├── vehicle_controller.dart      # Vehicle state
│   │   ├── vehicle_list_controller.dart # List management
│   │   └── vehicle_form_controller.dart # Form handling
│   ├── pages/
│   │   ├── vehicle_list_page.dart      # Vehicle list screen
│   │   ├── vehicle_detail_page.dart    # Vehicle details
│   │   ├── add_vehicle_page.dart       # Add vehicle form
│   │   ├── edit_vehicle_page.dart      # Edit vehicle form
│   │   └── vehicle_maintenance_page.dart
│   └── widgets/
│       ├── vehicle_card.dart           # Vehicle list item
│       ├── vehicle_info_widget.dart    # Info display
│       ├── vehicle_status_indicator.dart
│       ├── vehicle_form_fields.dart    # Form components
│       └── maintenance_schedule_widget.dart
└── tests/
```

### 11.4.3 Live Tracking Module

**Real-time Tracking Feature Structure:**
```yaml
lib/features/live_tracking/
├── data/
│   ├── models/
│   │   ├── location_model.dart     # GPS location model
│   │   ├── tracking_session.dart  # Tracking session DTO
│   │   ├── route_model.dart       # Route data model
│   │   └── speed_data_model.dart  # Speed tracking data
│   ├── repositories/
│   │   └── tracking_repository_impl.dart
│   └── datasources/
│       ├── location_datasource.dart    # GPS data source
│       ├── firebase_tracking_datasource.dart
│       └── local_tracking_datasource.dart
├── domain/
│   ├── entities/
│   │   ├── location.dart          # Location entity
│   │   ├── tracking_session.dart  # Session entity
│   │   ├── route.dart            # Route entity
│   │   └── journey.dart          # Journey entity
│   ├── repositories/
│   │   └── tracking_repository.dart
│   └── usecases/
│       ├── start_tracking_usecase.dart  # Start tracking
│       ├── stop_tracking_usecase.dart   # Stop tracking
│       ├── update_location_usecase.dart # Location update
│       ├── get_live_locations_usecase.dart
│       └── calculate_route_usecase.dart
├── presentation/
│   ├── controllers/
│   │   ├── tracking_controller.dart     # Tracking state
│   │   ├── map_controller.dart         # Map interactions
│   │   └── location_controller.dart    # Location management
│   ├── pages/
│   │   ├── live_tracking_page.dart     # Main tracking screen
│   │   ├── route_history_page.dart     # Route history
│   │   ├── tracking_settings_page.dart # Settings screen
│   │   └── journey_details_page.dart   # Journey analysis
│   └── widgets/
│       ├── tracking_map_widget.dart    # Map component
│       ├── vehicle_marker_widget.dart  # Map markers
│       ├── tracking_controls.dart      # Control buttons
│       ├── speed_indicator.dart        # Speed display
│       ├── route_info_panel.dart       # Route information
│       └── journey_stats_widget.dart   # Statistics display
└── tests/
```

### 11.4.4 Dashboard Module

**Dashboard and Analytics Feature:**
```yaml
lib/features/dashboard/
├── data/
│   ├── models/
│   │   ├── dashboard_stats.dart    # Statistics model
│   │   ├── chart_data_model.dart   # Chart data DTO
│   │   ├── kpi_model.dart         # KPI metrics model
│   │   └── alert_model.dart       # Alert/notification model
│   ├── repositories/
│   │   └── dashboard_repository_impl.dart
│   └── datasources/
│       ├── analytics_datasource.dart   # Analytics API
│       └── dashboard_cache_datasource.dart
├── domain/
│   ├── entities/
│   │   ├── dashboard_data.dart     # Dashboard entity
│   │   ├── chart_data.dart        # Chart entity
│   │   ├── metric.dart            # Metric entity
│   │   └── alert.dart             # Alert entity
│   ├── repositories/
│   │   └── dashboard_repository.dart
│   └── usecases/
│       ├── get_dashboard_data_usecase.dart
│       ├── generate_report_usecase.dart
│       ├── export_data_usecase.dart
│       └── calculate_metrics_usecase.dart
├── presentation/
│   ├── controllers/
│   │   ├── dashboard_controller.dart   # Dashboard state
│   │   ├── charts_controller.dart     # Chart management
│   │   └── analytics_controller.dart  # Analytics logic
│   ├── pages/
│   │   ├── dashboard_page.dart        # Main dashboard
│   │   ├── analytics_page.dart        # Detailed analytics
│   │   ├── reports_page.dart          # Reports section
│   │   └── kpi_details_page.dart      # KPI details
│   └── widgets/
│       ├── dashboard_card.dart        # Info cards
│       ├── chart_widget.dart          # Chart components
│       ├── metric_display.dart        # Metric widgets
│       ├── alert_list_widget.dart     # Alert display
│       ├── quick_stats_widget.dart    # Quick statistics
│       └── data_export_widget.dart    # Export functionality
└── tests/
```

## 11.5 Maps and Navigation Module

### 11.5.1 Map Integration Structure

**Maps Feature Organization:**
```yaml
lib/features/maps/
├── data/
│   ├── models/
│   │   ├── map_marker_model.dart   # Map marker data
│   │   ├── polygon_model.dart      # Geofence polygon
│   │   ├── polyline_model.dart     # Route polyline
│   │   └── place_model.dart        # Google Places data
│   ├── repositories/
│   │   └── maps_repository_impl.dart
│   └── datasources/
│       ├── google_maps_datasource.dart  # Google Maps API
│       ├── directions_datasource.dart   # Directions API
│       └── places_datasource.dart       # Places API
├── domain/
│   ├── entities/
│   │   ├── map_marker.dart         # Marker entity
│   │   ├── route.dart             # Route entity
│   │   ├── place.dart             # Place entity
│   │   └── map_bounds.dart        # Map bounds entity
│   ├── repositories/
│   │   └── maps_repository.dart
│   └── usecases/
│       ├── load_map_usecase.dart       # Map initialization
│       ├── add_markers_usecase.dart    # Marker management
│       ├── calculate_route_usecase.dart # Route calculation
│       ├── search_places_usecase.dart  # Place search
│       └── geocode_address_usecase.dart # Geocoding
├── presentation/
│   ├── controllers/
│   │   ├── map_controller.dart         # Map state management
│   │   ├── marker_controller.dart      # Marker management
│   │   └── directions_controller.dart  # Navigation logic
│   ├── pages/
│   │   ├── map_page.dart              # Full-screen map
│   │   ├── route_planner_page.dart    # Route planning
│   │   └── place_picker_page.dart     # Place selection
│   └── widgets/
│       ├── google_map_widget.dart     # Map component
│       ├── map_controls.dart          # Map controls
│       ├── marker_info_window.dart    # Marker popups
│       ├── route_panel.dart           # Route information
│       └── place_search_widget.dart   # Place search
└── tests/
```

## 11.6 Supporting Infrastructure

### 11.6.1 Routing and Navigation

**Application Routing Structure:**
```dart
// lib/routes/app_routes.dart
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/vehicles/presentation/pages/vehicle_list_page.dart';
import '../features/live_tracking/presentation/pages/live_tracking_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static const String tracking = '/tracking';
  static const String maps = '/maps';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: vehicles,
        builder: (context, state) => const VehicleListPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => VehicleDetailPage(
              vehicleId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: tracking,
        builder: (context, state) => const LiveTrackingPage(),
      ),
    ],
  );
}
```

### 11.6.2 Shared Widgets and Themes

**Shared Component Structure:**
```yaml
lib/shared/
├── widgets/
│   ├── common/
│   │   ├── app_bar_widget.dart      # Custom app bar
│   │   ├── bottom_nav_widget.dart   # Bottom navigation
│   │   ├── drawer_widget.dart       # Navigation drawer
│   │   ├── loading_widget.dart      # Loading indicators
│   │   ├── error_widget.dart        # Error displays
│   │   └── empty_state_widget.dart  # Empty state
│   ├── forms/
│   │   ├── custom_text_field.dart   # Text input fields
│   │   ├── custom_dropdown.dart     # Dropdown selectors
│   │   ├── custom_date_picker.dart  # Date selection
│   │   ├── custom_button.dart       # Button components
│   │   └── form_validator.dart      # Form validation
│   ├── cards/
│   │   ├── info_card.dart          # Information cards
│   │   ├── stat_card.dart          # Statistics cards
│   │   ├── vehicle_card.dart       # Vehicle display cards
│   │   └── alert_card.dart         # Alert/notification cards
│   └── dialogs/
│       ├── confirmation_dialog.dart # Confirmation prompts
│       ├── info_dialog.dart        # Information dialogs
│       ├── error_dialog.dart       # Error notifications
│       └── custom_bottom_sheet.dart # Bottom sheets
└── themes/
    ├── light_theme.dart            # Light theme configuration
    ├── dark_theme.dart             # Dark theme configuration
    ├── theme_extensions.dart       # Theme extensions
    └── custom_colors.dart          # Custom color definitions
```

## 11.7 Testing Structure

### 11.7.1 Test Organization

**Comprehensive Testing Structure:**
```yaml
test/
├── unit/
│   ├── core/
│   │   ├── utils/
│   │   │   ├── date_utils_test.dart
│   │   │   ├── validation_utils_test.dart
│   │   │   └── location_utils_test.dart
│   │   └── services/
│   │       ├── database_service_test.dart
│   │       ├── network_service_test.dart
│   │       └── location_service_test.dart
│   ├── auth/
│   │   ├── repositories/
│   │   │   └── auth_repository_test.dart
│   │   ├── usecases/
│   │   │   ├── login_usecase_test.dart
│   │   │   └── register_usecase_test.dart
│   │   └── controllers/
│   │       └── auth_controller_test.dart
│   ├── vehicles/
│   │   ├── repositories/
│   │   ├── usecases/
│   │   └── controllers/
│   ├── tracking/
│   │   ├── repositories/
│   │   ├── usecases/
│   │   └── controllers/
│   └── dashboard/
├── widget/
│   ├── auth/
│   │   ├── login_page_test.dart
│   │   └── register_page_test.dart
│   ├── vehicles/
│   │   ├── vehicle_list_test.dart
│   │   └── vehicle_card_test.dart
│   ├── tracking/
│   │   ├── tracking_map_test.dart
│   │   └── tracking_controls_test.dart
│   └── shared/
│       ├── common_widgets_test.dart
│       └── form_widgets_test.dart
├── integration/
│   ├── app_test.dart
│   ├── auth_flow_test.dart
│   ├── vehicle_management_test.dart
│   ├── tracking_flow_test.dart
│   └── dashboard_test.dart
├── mocks/
│   ├── mock_auth_repository.dart
│   ├── mock_vehicle_repository.dart
│   ├── mock_tracking_repository.dart
│   └── mock_services.dart
└── fixtures/
    ├── auth_fixtures.dart
    ├── vehicle_fixtures.dart
    ├── location_fixtures.dart
    └── test_data.json
```

## 11.8 Configuration and Asset Management

### 11.8.1 Configuration Files

**Project Configuration Structure:**
```yaml
Configuration Files:
├── pubspec.yaml:
│   ├── Project metadata
│   ├── Dependencies management
│   ├── Asset declarations
│   ├── Platform configurations
│   └── Build settings
├── analysis_options.yaml:
│   ├── Dart analyzer rules
│   ├── Linting preferences
│   ├── Code quality standards
│   └── Custom rule configurations
├── firebase_options.dart:
│   ├── Firebase project configuration
│   ├── Platform-specific settings
│   ├── API keys management
│   └── Service initialization
└── Platform-specific configs:
    ├── android/app/build.gradle
    ├── ios/Runner/Info.plist
    ├── web/index.html
    └── Platform permissions
```

### 11.8.2 Asset Organization

**Asset Management Structure:**
```yaml
assets/
├── images/
│   ├── logos/
│   │   ├── app_logo.png
│   │   ├── company_logo.png
│   │   └── splash_logo.png
│   ├── icons/
│   │   ├── vehicle_icons/
│   │   ├── map_markers/
│   │   └── ui_icons/
│   ├── backgrounds/
│   │   ├── login_background.jpg
│   │   ├── dashboard_bg.png
│   │   └── map_overlays/
│   └── illustrations/
│       ├── empty_states/
│       ├── onboarding/
│       └── error_illustrations/
├── fonts/
│   ├── Roboto/
│   ├── OpenSans/
│   └── CustomFont/
├── flags/
│   ├── country flags for localization
│   └── regional indicators
└── data/
    ├── sample_data.json
    ├── test_fixtures.json
    └── configuration_templates/
```

## 11.9 Code Quality and Standards

### 11.9.1 Coding Standards Implementation

**Code Quality Framework:**
```dart
// Example of standardized code structure
// lib/features/vehicles/presentation/controllers/vehicle_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_vehicles_usecase.dart';
import '../../../../core/controllers/base_controller.dart';
import '../../../../core/utils/result.dart';

/// Controller for managing vehicle-related operations and state
/// 
/// This controller handles:
/// - Vehicle list management
/// - CRUD operations
/// - State management for vehicle-related UI
/// - Error handling and loading states
class VehicleController extends BaseController {
  // Private members
  final GetVehiclesUseCase _getVehiclesUseCase;
  final RxList<Vehicle> _vehicles = <Vehicle>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Constructor with dependency injection
  VehicleController({
    required GetVehiclesUseCase getVehiclesUseCase,
  }) : _getVehiclesUseCase = getVehiclesUseCase;

  // Getters
  List<Vehicle> get vehicles => _vehicles.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value.isNotEmpty;
  bool get isEmpty => _vehicles.isEmpty && !_isLoading.value;

  // Public methods
  @override
  void onInit() {
    super.onInit();
    loadVehicles();
  }

  /// Loads vehicles from the repository
  Future<void> loadVehicles() async {
    try {
      setLoading(true);
      clearError();
      
      final result = await _getVehiclesUseCase.execute();
      
      result.when(
        success: (vehicles) {
          _vehicles.assignAll(vehicles);
        },
        failure: (error) {
          setError(error.message);
        },
      );
    } catch (e) {
      setError('An unexpected error occurred');
      logError('VehicleController.loadVehicles', e);
    } finally {
      setLoading(false);
    }
  }

  /// Refreshes the vehicle list
  Future<void> refreshVehicles() async {
    await loadVehicles();
  }

  /// Adds a new vehicle
  Future<bool> addVehicle(Vehicle vehicle) async {
    // Implementation details...
    return true;
  }

  // Private helper methods
  void setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void setError(String error) {
    _errorMessage.value = error;
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
```

### 11.9.2 Documentation Standards

**Code Documentation Framework:**
```dart
/// Comprehensive documentation example
/// 
/// This class represents a vehicle entity in the tracking system.
/// 
/// The Vehicle class contains all necessary information about a tracked
/// vehicle including identification, location, status, and metadata.
/// 
/// Example usage:
/// ```dart
/// final vehicle = Vehicle(
///   id: 'VEH001',
///   licensePlate: 'ABC123',
///   type: VehicleType.car,
///   driver: driverEntity,
/// );
/// 
/// // Update location
/// vehicle.updateLocation(newLocation);
/// 
/// // Check if vehicle is active
/// if (vehicle.isActive) {
///   // Perform tracking operations
/// }
/// ```
/// 
/// See also:
/// - [VehicleType] for available vehicle types
/// - [Location] for location data structure
/// - [Driver] for driver information
class Vehicle extends Equatable {
  /// Unique identifier for the vehicle
  /// 
  /// This ID is generated by the system and should be unique across
  /// all vehicles in the fleet. It's used for database operations
  /// and API requests.
  final String id;

  /// Vehicle license plate number
  /// 
  /// Must be unique within the system and follow the format
  /// requirements of the operating region.
  final String licensePlate;

  /// Current location of the vehicle
  /// 
  /// This field is updated in real-time through GPS tracking.
  /// May be null if location is not available.
  final Location? currentLocation;

  /// Vehicle operational status
  /// 
  /// Indicates whether the vehicle is active, inactive, or under
  /// maintenance. Affects tracking behavior and availability.
  final VehicleStatus status;

  /// Timestamp of last location update
  /// 
  /// Used to determine data freshness and connection status.
  /// Updated automatically when [currentLocation] changes.
  final DateTime? lastUpdate;

  // Constructor and methods...
}
```

## 11.10 Build and Deployment Structure

### 11.10.1 Build Configuration

**Build System Organization:**
```yaml
Build Configuration:
├── CI/CD Pipeline:
│   ├── .github/workflows/
│   │   ├── ci.yml              # Continuous Integration
│   │   ├── cd.yml              # Continuous Deployment
│   │   ├── test.yml            # Automated Testing
│   │   └── release.yml         # Release Management
│   ├── Build Scripts:
│   │   ├── build_android.sh    # Android build script
│   │   ├── build_ios.sh        # iOS build script
│   │   ├── build_web.sh        # Web build script
│   │   └── deploy.sh           # Deployment script
│   └── Configuration:
│       ├── staging.env         # Staging environment
│       ├── production.env      # Production environment
│       └── development.env     # Development environment
├── Platform Builds:
│   ├── Android:
│   │   ├── Debug builds
│   │   ├── Release builds
│   │   ├── Signed APK/AAB
│   │   └── Play Store deployment
│   ├── iOS:
│   │   ├── Debug builds
│   │   ├── Release builds
│   │   ├── Ad Hoc distribution
│   │   └── App Store deployment
│   ├── Web:
│   │   ├── Development build
│   │   ├── Production build
│   │   ├── PWA configuration
│   │   └── Hosting deployment
│   └── Desktop:
│       ├── Windows executable
│       ├── macOS application
│       └── Linux AppImage
└── Quality Assurance:
    ├── Automated tests
    ├── Code coverage reports
    ├── Performance benchmarks
    └── Security scans
```

The Vehicle Tracking System's source code structure demonstrates a well-organized, scalable, and maintainable architecture that follows Flutter and Dart best practices. The modular approach enables efficient development, testing, and deployment while ensuring code quality and long-term maintainability.
