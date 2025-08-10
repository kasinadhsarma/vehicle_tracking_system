# Vehicle Tracking System - Development Guide

## Table of Contents
1. [Development Environment Setup](#development-environment-setup)
2. [Project Architecture](#project-architecture)
3. [Code Organization](#code-organization)
4. [Development Workflow](#development-workflow)
5. [API Integration](#api-integration)
6. [Testing Strategy](#testing-strategy)
7. [Performance Optimization](#performance-optimization)
8. [Security Implementation](#security-implementation)
9. [Deployment Pipeline](#deployment-pipeline)
10. [Maintenance Guidelines](#maintenance-guidelines)

---

## Development Environment Setup

### 1.1 Prerequisites

**System Requirements:**
- **Operating System**: Windows 10+, macOS 10.14+, or Ubuntu 18.04+
- **RAM**: Minimum 8GB, Recommended 16GB+
- **Storage**: 10GB free space for development tools
- **Network**: Stable internet connection for API access

**Required Software:**
```bash
# Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
flutter doctor

# Android Studio (for Android development)
# Download from: https://developer.android.com/studio

# Xcode (for iOS development - macOS only)
# Download from Mac App Store

# VS Code with Flutter extension
# Download from: https://code.visualstudio.com/
```

**Development Tools:**
```bash
# Firebase CLI
npm install -g firebase-tools

# Git (version control)
git --version

# Chrome (for web debugging)
# Download from: https://www.google.com/chrome/
```

### 1.2 Project Setup

**Clone Repository:**
```bash
git clone <repository-url>
cd vehicle_tracking_system
```

**Install Dependencies:**
```bash
flutter pub get
```

**Environment Configuration:**
```bash
# Copy environment template
cp .env.example .env

# Edit configuration file
nano .env
```

**Environment Variables:**
```env
# Firebase Configuration
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# Google Maps Configuration
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Development Settings
DEBUG_MODE=true
LOG_LEVEL=debug
API_BASE_URL=https://api.example.com

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
ENABLE_PERFORMANCE_MONITORING=true
```

### 1.3 IDE Configuration

**VS Code Settings:**
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalLibraries": false,
  "dart.debugSdkLibraries": false,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "dart.lineLength": 80,
  "files.associations": {
    "*.dart": "dart"
  }
}
```

**Recommended Extensions:**
- Flutter
- Dart
- GitLens
- Error Lens
- Bracket Pair Colorizer
- Material Icon Theme

---

## Project Architecture

### 2.1 Clean Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Widgets   │  │ Controllers │  │        Screens          │  │
│  │             │  │   (GetX)    │  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                     Domain Layer                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Models    │  │  Use Cases  │  │     Repositories        │  │
│  │             │  │             │  │    (Interfaces)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Data Sources│  │ Repositories│  │       Services          │  │
│  │ (Firebase)  │  │(Impl)       │  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Folder Structure

```
lib/
├── app.dart                    # Main application widget
├── main.dart                  # Application entry point
├── core/                      # Core functionality
│   ├── config/               # Configuration files
│   │   ├── app_config.dart
│   │   └── maps_config.dart
│   ├── constants/            # Application constants
│   │   ├── app_colors.dart
│   │   ├── app_constants.dart
│   │   └── api_endpoints.dart
│   ├── controllers/          # Global controllers
│   │   ├── theme_controller.dart
│   │   └── auth_controller.dart
│   ├── models/              # Data models
│   │   ├── user_model.dart
│   │   ├── vehicle_model.dart
│   │   └── location_model.dart
│   ├── services/            # Core services
│   │   ├── api_service.dart
│   │   ├── storage_service.dart
│   │   └── notification_service.dart
│   ├── theme/               # Theme configuration
│   │   └── app_theme.dart
│   └── utils/               # Utility functions
│       ├── validators.dart
│       ├── formatters.dart
│       └── helpers.dart
├── features/                # Feature modules
│   ├── auth/               # Authentication feature
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   ├── dashboard/          # Dashboard feature
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   ├── tracking/           # Vehicle tracking feature
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── views/
│   └── reports/            # Reporting feature
│       ├── controllers/
│       ├── models/
│       ├── services/
│       └── views/
├── routes/                 # Navigation routing
│   └── app_routes.dart
└── shared/                 # Shared components
    ├── widgets/           # Reusable widgets
    │   ├── custom_button.dart
    │   ├── loading_widget.dart
    │   └── error_widget.dart
    ├── mixins/            # Reusable mixins
    └── extensions/        # Dart extensions
```

### 2.3 Dependency Injection

**Service Locator Setup:**
```dart
// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core services
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<StorageService>(() => StorageService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  
  // Repositories
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(apiService: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(apiService: sl()),
  );
  
  // Use cases
  sl.registerLazySingleton<GetVehiclesUseCase>(
    () => GetVehiclesUseCase(repository: sl()),
  );
  sl.registerLazySingleton<UpdateLocationUseCase>(
    () => UpdateLocationUseCase(repository: sl()),
  );
  
  // Controllers
  sl.registerFactory<VehicleController>(
    () => VehicleController(getVehiclesUseCase: sl()),
  );
}
```

**GetX Dependency Injection:**
```dart
// lib/core/di/bindings.dart
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core controllers
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    
    // Services
    Get.lazyPut<LocationService>(() => LocationService());
    Get.lazyPut<FirebaseService>(() => FirebaseService());
    Get.lazyPut<GoogleMapsService>(() => GoogleMapsService());
  }
}

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<VehicleController>(() => VehicleController());
  }
}
```

---

## Code Organization

### 3.1 Coding Standards

**Dart Style Guide:**
```dart
// Use descriptive names
final String vehicleRegistrationNumber = 'ABC-123';
final List<Vehicle> activeVehicles = [];

// Follow naming conventions
class VehicleTrackingService {} // PascalCase for classes
void updateVehicleLocation() {} // camelCase for methods
const int maxRetryAttempts = 3; // camelCase for constants

// Use proper documentation
/// Updates the vehicle location in real-time database
/// 
/// [vehicleId] The unique identifier for the vehicle
/// [position] The new GPS coordinates
/// [timestamp] When the location was recorded
/// 
/// Returns [Future<bool>] indicating success or failure
/// 
/// Throws [LocationUpdateException] if update fails
Future<bool> updateVehicleLocation({
  required String vehicleId,
  required LatLng position,
  required DateTime timestamp,
}) async {
  try {
    // Implementation
    return true;
  } catch (e) {
    throw LocationUpdateException('Failed to update location: $e');
  }
}
```

**Widget Organization:**
```dart
// lib/shared/widgets/vehicle_card.dart
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.showStatus = true,
  });

  final Vehicle vehicle;
  final VoidCallback? onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildDetails(),
              if (showStatus) ...[
                const SizedBox(height: 8),
                _buildStatus(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.directions_car,
          color: vehicle.isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            vehicle.registrationNumber,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (vehicle.isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Driver: ${vehicle.driverName ?? 'Unassigned'}'),
        Text('Model: ${vehicle.model}'),
        Text('Last Update: ${_formatLastUpdate()}'),
      ],
    );
  }

  Widget _buildStatus() {
    return Row(
      children: [
        Icon(
          Icons.speed,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text('${vehicle.currentSpeed.toStringAsFixed(1)} km/h'),
        const SizedBox(width: 16),
        Icon(
          Icons.location_on,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            vehicle.currentLocation ?? 'Location unavailable',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatLastUpdate() {
    if (vehicle.lastUpdate == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(vehicle.lastUpdate!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
```

### 3.2 State Management with GetX

**Controller Pattern:**
```dart
// lib/features/dashboard/controllers/dashboard_controller.dart
class DashboardController extends GetxController {
  // Observable variables
  final RxList<Vehicle> vehicles = <Vehicle>[].obs;
  final RxList<Alert> alerts = <Alert>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DashboardMetrics> metrics = DashboardMetrics.empty().obs;

  // Services
  final VehicleService _vehicleService = Get.find<VehicleService>();
  final AlertService _alertService = Get.find<AlertService>();
  final AnalyticsService _analyticsService = Get.find<AnalyticsService>();

  // Streams
  StreamSubscription<List<Vehicle>>? _vehicleSubscription;
  StreamSubscription<List<Alert>>? _alertSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupRealTimeListeners();
  }

  @override
  void onClose() {
    _vehicleSubscription?.cancel();
    _alertSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initializeData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load initial data
      await Future.wait([
        loadVehicles(),
        loadAlerts(),
        loadMetrics(),
      ]);
    } catch (e) {
      errorMessage.value = 'Failed to load dashboard data: $e';
      _logError('Dashboard initialization failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  void _setupRealTimeListeners() {
    // Listen to vehicle updates
    _vehicleSubscription = _vehicleService.getVehicleStream().listen(
      (vehicleList) {
        vehicles.assignAll(vehicleList);
        _updateMetrics();
      },
      onError: (error) {
        _logError('Vehicle stream error', error);
      },
    );

    // Listen to alert updates
    _alertSubscription = _alertService.getAlertStream().listen(
      (alertList) {
        alerts.assignAll(alertList);
        _checkCriticalAlerts(alertList);
      },
      onError: (error) {
        _logError('Alert stream error', error);
      },
    );
  }

  Future<void> loadVehicles() async {
    try {
      final vehicleList = await _vehicleService.getVehicles();
      vehicles.assignAll(vehicleList);
    } catch (e) {
      throw Exception('Failed to load vehicles: $e');
    }
  }

  Future<void> loadAlerts() async {
    try {
      final alertList = await _alertService.getActiveAlerts();
      alerts.assignAll(alertList);
    } catch (e) {
      throw Exception('Failed to load alerts: $e');
    }
  }

  Future<void> loadMetrics() async {
    try {
      final dashboardMetrics = await _analyticsService.getDashboardMetrics();
      metrics.value = dashboardMetrics;
    } catch (e) {
      throw Exception('Failed to load metrics: $e');
    }
  }

  void _updateMetrics() {
    final activeVehicles = vehicles.where((v) => v.isActive).length;
    final totalDistance = vehicles.fold<double>(
      0,
      (sum, vehicle) => sum + vehicle.todayDistance,
    );
    
    metrics.value = metrics.value.copyWith(
      activeVehicles: activeVehicles,
      totalDistance: totalDistance,
      lastUpdated: DateTime.now(),
    );
  }

  void _checkCriticalAlerts(List<Alert> alertList) {
    final criticalAlerts = alertList.where((alert) => alert.isCritical);
    
    if (criticalAlerts.isNotEmpty) {
      Get.snackbar(
        'Critical Alert',
        '${criticalAlerts.length} critical alert(s) require attention',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> refreshData() async {
    await _initializeData();
    
    Get.snackbar(
      'Refreshed',
      'Dashboard data has been updated',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _logError(String message, dynamic error) {
    print('DashboardController Error: $message - $error');
    
    // Log to analytics/crashlytics
    _analyticsService.logError(
      message,
      error,
      additionalData: {
        'controller': 'DashboardController',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
```

**Using Controllers in Views:**
```dart
// lib/features/dashboard/views/dashboard_page.dart
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricsSection(controller),
                const SizedBox(height: 24),
                _buildVehiclesSection(controller),
                const SizedBox(height: 24),
                _buildAlertsSection(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMetricsSection(DashboardController controller) {
    return Obx(() {
      final metrics = controller.metrics.value;
      
      return Row(
        children: [
          Expanded(
            child: MetricCard(
              title: 'Active Vehicles',
              value: metrics.activeVehicles.toString(),
              subtitle: 'out of ${controller.vehicles.length}',
              icon: Icons.directions_car,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              title: 'Total Distance',
              value: '${metrics.totalDistance.toStringAsFixed(1)} km',
              subtitle: 'today',
              icon: Icons.route,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              title: 'Active Alerts',
              value: controller.alerts.length.toString(),
              subtitle: 'require attention',
              icon: Icons.warning,
              color: Colors.orange,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildVehiclesSection(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Vehicles',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Get.toNamed('/vehicles'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.vehicles.isEmpty) {
            return const Center(
              child: Text('No vehicles available'),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(controller.vehicles.length, 5),
            itemBuilder: (context, index) {
              final vehicle = controller.vehicles[index];
              return VehicleCard(
                vehicle: vehicle,
                onTap: () => Get.toNamed('/vehicle/${vehicle.id}'),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildAlertsSection(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Alerts',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Get.toNamed('/alerts'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.alerts.isEmpty) {
            return const Center(
              child: Text('No active alerts'),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(controller.alerts.length, 3),
            itemBuilder: (context, index) {
              final alert = controller.alerts[index];
              return AlertCard(
                alert: alert,
                onTap: () => Get.toNamed('/alert/${alert.id}'),
              );
            },
          );
        }),
      ],
    );
  }
}
```

### 3.3 Model Classes

**Base Model:**
```dart
// lib/core/models/base_model.dart
abstract class BaseModel {
  const BaseModel();

  Map<String, dynamic> toMap();
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseModel && other.runtimeType == runtimeType;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}
```

**Vehicle Model:**
```dart
// lib/core/models/vehicle_model.dart
class Vehicle extends BaseModel {
  const Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.model,
    required this.year,
    this.driverId,
    this.driverName,
    this.isActive = false,
    this.currentSpeed = 0.0,
    this.currentLocation,
    this.lastUpdate,
    this.todayDistance = 0.0,
    this.fuelLevel,
    this.batteryLevel,
    this.engineStatus = EngineStatus.off,
  });

  final String id;
  final String registrationNumber;
  final String model;
  final int year;
  final String? driverId;
  final String? driverName;
  final bool isActive;
  final double currentSpeed;
  final String? currentLocation;
  final DateTime? lastUpdate;
  final double todayDistance;
  final double? fuelLevel;
  final double? batteryLevel;
  final EngineStatus engineStatus;

  Vehicle copyWith({
    String? id,
    String? registrationNumber,
    String? model,
    int? year,
    String? driverId,
    String? driverName,
    bool? isActive,
    double? currentSpeed,
    String? currentLocation,
    DateTime? lastUpdate,
    double? todayDistance,
    double? fuelLevel,
    double? batteryLevel,
    EngineStatus? engineStatus,
  }) {
    return Vehicle(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      model: model ?? this.model,
      year: year ?? this.year,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      isActive: isActive ?? this.isActive,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      todayDistance: todayDistance ?? this.todayDistance,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      engineStatus: engineStatus ?? this.engineStatus,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registrationNumber': registrationNumber,
      'model': model,
      'year': year,
      'driverId': driverId,
      'driverName': driverName,
      'isActive': isActive,
      'currentSpeed': currentSpeed,
      'currentLocation': currentLocation,
      'lastUpdate': lastUpdate?.millisecondsSinceEpoch,
      'todayDistance': todayDistance,
      'fuelLevel': fuelLevel,
      'batteryLevel': batteryLevel,
      'engineStatus': engineStatus.name,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      model: map['model'] ?? '',
      year: map['year']?.toInt() ?? 0,
      driverId: map['driverId'],
      driverName: map['driverName'],
      isActive: map['isActive'] ?? false,
      currentSpeed: map['currentSpeed']?.toDouble() ?? 0.0,
      currentLocation: map['currentLocation'],
      lastUpdate: map['lastUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdate'])
          : null,
      todayDistance: map['todayDistance']?.toDouble() ?? 0.0,
      fuelLevel: map['fuelLevel']?.toDouble(),
      batteryLevel: map['batteryLevel']?.toDouble(),
      engineStatus: EngineStatus.values.firstWhere(
        (e) => e.name == map['engineStatus'],
        orElse: () => EngineStatus.off,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Vehicle.fromJson(String source) =>
      Vehicle.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Vehicle(id: $id, registrationNumber: $registrationNumber, model: $model, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Vehicle &&
        other.id == id &&
        other.registrationNumber == registrationNumber &&
        other.model == model &&
        other.year == year &&
        other.driverId == driverId &&
        other.driverName == driverName &&
        other.isActive == isActive &&
        other.currentSpeed == currentSpeed &&
        other.currentLocation == currentLocation &&
        other.lastUpdate == lastUpdate &&
        other.todayDistance == todayDistance &&
        other.fuelLevel == fuelLevel &&
        other.batteryLevel == batteryLevel &&
        other.engineStatus == engineStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        registrationNumber.hashCode ^
        model.hashCode ^
        year.hashCode ^
        driverId.hashCode ^
        driverName.hashCode ^
        isActive.hashCode ^
        currentSpeed.hashCode ^
        currentLocation.hashCode ^
        lastUpdate.hashCode ^
        todayDistance.hashCode ^
        fuelLevel.hashCode ^
        batteryLevel.hashCode ^
        engineStatus.hashCode;
  }
}

enum EngineStatus {
  off,
  idle,
  running,
  maintenance,
}
```

---

## Development Workflow

### 4.1 Git Workflow

**Branch Strategy:**
```
main (production)
├── develop (development)
│   ├── feature/vehicle-tracking
│   ├── feature/dashboard-ui
│   ├── feature/geofencing
│   └── hotfix/location-bug
└── release/v1.0.0
```

**Commit Message Convention:**
```
feat: add vehicle real-time tracking
fix: resolve location update issue
docs: update API documentation
style: format code according to style guide
refactor: restructure vehicle service
test: add unit tests for location service
chore: update dependencies
```

**Pull Request Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings introduced
```

### 4.2 Development Process

**Feature Development Workflow:**
1. **Create Feature Branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/new-feature-name
   ```

2. **Development**
   - Write failing tests first (TDD approach)
   - Implement feature
   - Ensure tests pass
   - Update documentation

3. **Code Review**
   ```bash
   git add .
   git commit -m "feat: implement new feature"
   git push origin feature/new-feature-name
   # Create pull request
   ```

4. **Testing**
   ```bash
   # Run all tests
   flutter test
   
   # Run integration tests
   flutter drive --target=test_driver/app.dart
   
   # Check code coverage
   flutter test --coverage
   ```

5. **Merge to Develop**
   - After approval, merge to develop branch
   - Delete feature branch

### 4.3 Code Quality Tools

**Static Analysis:**
```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    # Error rules
    avoid_empty_else: true
    avoid_print: true
    avoid_relative_lib_imports: true
    avoid_returning_null_for_future: true
    avoid_slow_async_io: true
    avoid_types_as_parameter_names: true
    cancel_subscriptions: true
    close_sinks: true
    comment_references: true
    control_flow_in_finally: true
    empty_statements: true
    hash_and_equals: true
    invariant_booleans: true
    iterable_contains_unrelated_type: true
    list_remove_unrelated_type: true
    literal_only_boolean_expressions: true
    no_adjacent_strings_in_list: true
    no_duplicate_case_values: true
    prefer_void_to_null: true
    test_types_in_equals: true
    throw_in_finally: true
    unnecessary_statements: true
    unrelated_type_equality_checks: true
    valid_regexps: true
    
    # Style rules
    always_declare_return_types: true
    always_put_control_body_on_new_line: true
    always_require_non_null_named_parameters: true
    annotate_overrides: true
    avoid_annotating_with_dynamic: true
    avoid_as: true
    avoid_bool_literals_in_conditional_expressions: true
    avoid_catches_without_on_clauses: true
    avoid_catching_errors: true
    avoid_double_and_int_checks: true
    avoid_field_initializers_in_const_classes: true
    avoid_function_literals_in_foreach_calls: true
    avoid_implementing_value_types: true
    avoid_init_to_null: true
    avoid_null_checks_in_equality_operators: true
    avoid_positional_boolean_parameters: true
    avoid_private_typedef_functions: true
    avoid_redundant_argument_values: true
    avoid_renaming_method_parameters: true
    avoid_return_types_on_setters: true
    avoid_returning_null: true
    avoid_returning_null_for_void: true
    avoid_setters_without_getters: true
    avoid_shadowing_type_parameters: true
    avoid_single_cascade_in_expression_statements: true
    avoid_unnecessary_containers: true
    avoid_unused_constructor_parameters: true
    avoid_void_async: true
    await_only_futures: true
    camel_case_extensions: true
    camel_case_types: true
    cascade_invocations: true
    constant_identifier_names: true
    curly_braces_in_flow_control_structures: true
    directives_ordering: true
    empty_catches: true
    empty_constructor_bodies: true
    file_names: true
    flutter_style_todos: true
    implementation_imports: true
    join_return_with_assignment: true
    library_names: true
    library_prefixes: true
    lines_longer_than_80_chars: true
    non_constant_identifier_names: true
    null_closures: true
    omit_local_variable_types: true
    one_member_abstracts: true
    only_throw_errors: true
    overridden_fields: true
    package_api_docs: true
    package_names: true
    package_prefixed_library_names: true
    parameter_assignments: true
    prefer_adjacent_string_concatenation: true
    prefer_asserts_in_initializer_lists: true
    prefer_collection_literals: true
    prefer_conditional_assignment: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_constructors_over_static_methods: true
    prefer_contains: true
    prefer_equal_for_default_values: true
    prefer_expression_function_bodies: true
    prefer_final_fields: true
    prefer_final_in_for_each: true
    prefer_final_locals: true
    prefer_for_elements_to_map_fromIterable: true
    prefer_foreach: true
    prefer_function_declarations_over_variables: true
    prefer_generic_function_type_aliases: true
    prefer_if_elements_to_conditional_expressions: true
    prefer_if_null_operators: true
    prefer_initializing_formals: true
    prefer_inlined_adds: true
    prefer_int_literals: true
    prefer_interpolation_to_compose_strings: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    prefer_is_not_operator: true
    prefer_iterable_whereType: true
    prefer_mixin: true
    prefer_null_aware_operators: true
    prefer_relative_imports: true
    prefer_single_quotes: true
    prefer_spread_collections: true
    prefer_typing_uninitialized_variables: true
    provide_deprecation_message: true
    public_member_api_docs: true
    recursive_getters: true
    slash_for_doc_comments: true
    sort_child_properties_last: true
    sort_constructors_first: true
    sort_pub_dependencies: true
    sort_unnamed_constructors_first: true
    type_annotate_public_apis: true
    type_init_formals: true
    unawaited_futures: true
    unnecessary_await_in_return: true
    unnecessary_brace_in_string_interps: true
    unnecessary_const: true
    unnecessary_getters_setters: true
    unnecessary_lambdas: true
    unnecessary_new: true
    unnecessary_null_aware_assignments: true
    unnecessary_null_in_if_null_operators: true
    unnecessary_overrides: true
    unnecessary_parenthesis: true
    unnecessary_raw_strings: true
    unnecessary_string_escapes: true
    unnecessary_string_interpolations: true
    unnecessary_this: true
    use_full_hex_values_for_flutter_colors: true
    use_function_type_syntax_for_parameters: true
    use_rethrow_when_possible: true
    use_setters_to_change_properties: true
    use_string_buffers: true
    use_to_and_as_if_applicable: true
    valid_regexps: true
    void_checks: true
```

**Pre-commit Hooks:**
```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running pre-commit checks..."

# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi

echo "Pre-commit checks passed!"
```

---

## API Integration

### 5.1 Firebase Integration

**Firebase Service:**
```dart
// lib/core/services/firebase_service.dart
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore operations
  static Future<void> createDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(data);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to create document: $e',
      );
    }
  }

  static Future<DocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to get document: $e',
      );
    }
  }

  static Stream<QuerySnapshot> getCollectionStream({
    required String collection,
    Query Function(CollectionReference)? queryBuilder,
  }) {
    try {
      CollectionReference ref = _firestore.collection(collection);
      Query query = queryBuilder?.call(ref) ?? ref;
      return query.snapshots();
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to get collection stream: $e',
      );
    }
  }

  static Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to update document: $e',
      );
    }
  }

  static Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to delete document: $e',
      );
    }
  }

  // Realtime Database operations
  static Future<void> setRealtimeData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _database.ref(path).set(data);
    } catch (e) {
      throw FirebaseException(
        plugin: 'database',
        message: 'Failed to set realtime data: $e',
      );
    }
  }

  static Future<void> updateRealtimeData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _database.ref(path).update(data);
    } catch (e) {
      throw FirebaseException(
        plugin: 'database',
        message: 'Failed to update realtime data: $e',
      );
    }
  }

  static Stream<DatabaseEvent> getRealtimeDataStream(String path) {
    try {
      return _database.ref(path).onValue;
    } catch (e) {
      throw FirebaseException(
        plugin: 'database',
        message: 'Failed to get realtime data stream: $e',
      );
    }
  }

  static Future<DataSnapshot> getRealtimeData(String path) async {
    try {
      return await _database.ref(path).get();
    } catch (e) {
      throw FirebaseException(
        plugin: 'database',
        message: 'Failed to get realtime data: $e',
      );
    }
  }

  // Error handling
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
```

### 5.2 Google Maps Integration

**Google Maps Service:**
```dart
// lib/core/services/google_maps_service.dart
class GoogleMapsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Geocoding
  static Future<List<Placemark>> getPlacemarks({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        '/geocode/json',
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': _apiKey,
        },
      );

      if (response.data['status'] == 'OK') {
        final results = response.data['results'] as List;
        return results.map((result) => Placemark.fromMap(result)).toList();
      } else {
        throw Exception('Geocoding failed: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Failed to get placemarks: $e');
    }
  }

  static Future<List<Location>> getLocationsFromAddress(String address) async {
    try {
      final response = await _dio.get(
        '/geocode/json',
        queryParameters: {
          'address': address,
          'key': _apiKey,
        },
      );

      if (response.data['status'] == 'OK') {
        final results = response.data['results'] as List;
        return results.map((result) {
          final location = result['geometry']['location'];
          return Location(
            latitude: location['lat'].toDouble(),
            longitude: location['lng'].toDouble(),
          );
        }).toList();
      } else {
        throw Exception('Geocoding failed: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Failed to get locations from address: $e');
    }
  }

  // Directions
  static Future<DirectionsResult> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    TravelMode travelMode = TravelMode.driving,
    bool optimizeWaypoints = false,
  }) async {
    try {
      final waypointsParam = waypoints?.isNotEmpty == true
          ? waypoints!.map((wp) => '${wp.latitude},${wp.longitude}').join('|')
          : null;

      final response = await _dio.get(
        '/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          if (waypointsParam != null) 'waypoints': waypointsParam,
          'mode': travelMode.name,
          'optimize': optimizeWaypoints,
          'key': _apiKey,
        },
      );

      if (response.data['status'] == 'OK') {
        return DirectionsResult.fromMap(response.data);
      } else {
        throw Exception('Directions failed: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Failed to get directions: $e');
    }
  }

  // Distance Matrix
  static Future<DistanceMatrixResult> getDistanceMatrix({
    required List<LatLng> origins,
    required List<LatLng> destinations,
    TravelMode travelMode = TravelMode.driving,
    DistanceMatrixUnit unit = DistanceMatrixUnit.metric,
  }) async {
    try {
      final originsParam = origins
          .map((origin) => '${origin.latitude},${origin.longitude}')
          .join('|');
      
      final destinationsParam = destinations
          .map((dest) => '${dest.latitude},${dest.longitude}')
          .join('|');

      final response = await _dio.get(
        '/distancematrix/json',
        queryParameters: {
          'origins': originsParam,
          'destinations': destinationsParam,
          'mode': travelMode.name,
          'units': unit.name,
          'key': _apiKey,
        },
      );

      if (response.data['status'] == 'OK') {
        return DistanceMatrixResult.fromMap(response.data);
      } else {
        throw Exception('Distance matrix failed: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Failed to get distance matrix: $e');
    }
  }

  // Places
  static Future<List<PlaceSearchResult>> searchPlaces({
    required String query,
    LatLng? location,
    double? radius,
    String? type,
  }) async {
    try {
      final response = await _dio.get(
        '/place/textsearch/json',
        queryParameters: {
          'query': query,
          if (location != null) 'location': '${location.latitude},${location.longitude}',
          if (radius != null) 'radius': radius.toInt(),
          if (type != null) 'type': type,
          'key': _apiKey,
        },
      );

      if (response.data['status'] == 'OK') {
        final results = response.data['results'] as List;
        return results.map((result) => PlaceSearchResult.fromMap(result)).toList();
      } else {
        throw Exception('Place search failed: ${response.data['status']}');
      }
    } catch (e) {
      throw Exception('Failed to search places: $e');
    }
  }

  // Route optimization
  static Future<OptimizedRoute> optimizeRoute({
    required LatLng start,
    required LatLng end,
    required List<LatLng> waypoints,
  }) async {
    try {
      final directionsResult = await getDirections(
        origin: start,
        destination: end,
        waypoints: waypoints,
        optimizeWaypoints: true,
      );

      return OptimizedRoute(
        route: directionsResult.routes.first,
        optimizedOrder: directionsResult.routes.first.waypointOrder,
        totalDistance: directionsResult.routes.first.legs
            .fold(0, (sum, leg) => sum + leg.distance.value),
        totalDuration: directionsResult.routes.first.legs
            .fold(0, (sum, leg) => sum + leg.duration.value),
      );
    } catch (e) {
      throw Exception('Failed to optimize route: $e');
    }
  }
}

enum TravelMode { driving, walking, bicycling, transit }
enum DistanceMatrixUnit { metric, imperial }
```

### 5.3 Location Service

**Location Service:**
```dart
// lib/core/services/location_service.dart
class LocationService {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // meters
    timeLimit: Duration(seconds: 30),
  );

  static StreamSubscription<Position>? _positionSubscription;
  static final StreamController<Position> _positionController = 
      StreamController<Position>.broadcast();

  // Check permissions
  static Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position
  static Future<Position> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw LocationServiceException('Location permission denied');
    }

    final isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      throw LocationServiceException('Location services are disabled');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      throw LocationServiceException('Failed to get current position: $e');
    }
  }

  // Start location tracking
  static Future<void> startLocationTracking() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw LocationServiceException('Location permission denied');
    }

    final isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      throw LocationServiceException('Location services are disabled');
    }

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (position) {
          _positionController.add(position);
          _handleLocationUpdate(position);
        },
        onError: (error) {
          print('Location tracking error: $error');
        },
      );
    } catch (e) {
      throw LocationServiceException('Failed to start location tracking: $e');
    }
  }

  // Stop location tracking
  static Future<void> stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Get location stream
  static Stream<Position> get positionStream => _positionController.stream;

  // Calculate distance between two points
  static double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Calculate bearing between two points
  static double calculateBearing({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Handle location updates
  static void _handleLocationUpdate(Position position) {
    // Update Firebase with new location
    final vehicleId = Get.find<AuthController>().currentUser?.uid;
    if (vehicleId != null) {
      FirebaseService.updateRealtimeData(
        path: 'locations/$vehicleId',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'heading': position.heading,
          'speed': position.speed,
          'speedAccuracy': position.speedAccuracy,
          'timestamp': ServerValue.timestamp,
        },
      ).catchError((error) {
        print('Failed to update location: $error');
      });
    }

    // Check geofences
    _checkGeofences(position);
    
    // Analyze driving behavior
    _analyzeDrivingBehavior(position);
  }

  // Check geofences
  static void _checkGeofences(Position position) {
    // Implementation for geofence checking
    final geofenceService = Get.find<GeofenceService>();
    geofenceService.checkGeofences(
      LatLng(position.latitude, position.longitude),
    );
  }

  // Analyze driving behavior
  static void _analyzeDrivingBehavior(Position position) {
    // Implementation for driving behavior analysis
    final behaviorService = Get.find<DriverBehaviorService>();
    behaviorService.analyzePosition(position);
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

class LocationServiceException implements Exception {
  final String message;
  
  const LocationServiceException(this.message);
  
  @override
  String toString() => 'LocationServiceException: $message';
}
```

---

This development guide provides comprehensive information for developers working on the Vehicle Tracking System. It covers everything from environment setup to advanced implementation patterns, ensuring consistent and maintainable code across the project.