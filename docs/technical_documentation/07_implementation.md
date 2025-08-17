# 7. Implementation

## 7.1 Overview

This chapter details the implementation of the Vehicle Tracking System, covering the development process, key code implementations, technical challenges encountered, and solutions adopted. The implementation follows the architectural decisions outlined in the previous chapter and demonstrates the practical application of Flutter, Firebase, and associated technologies.

## 7.2 Development Environment Setup

### 7.2.1 Development Tools and Environment

**Required Software Stack:**
```bash
# Development Environment Setup
Flutter SDK: 3.16.0 or later
Dart SDK: 3.2.0 or later
Android Studio: 2023.1 or later
VS Code: 1.80 or later
Git: 2.40 or later
Node.js: 18.x or later (for Firebase Functions)
Firebase CLI: 12.x or later
```

**IDE Configuration:**
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalLibraries": true,
  "dart.debugSdkLibraries": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "files.associations": {
    "*.dart": "dart"
  }
}

// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Debug",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": ["--flavor", "development"]
    },
    {
      "name": "Flutter Profile",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "flutterMode": "profile"
    }
  ]
}
```

### 7.2.2 Project Structure Implementation

**Flutter Project Structure:**
```
lib/
├── app.dart                 # Main application widget
├── main.dart               # Application entry point
├── firebase_options.dart   # Firebase configuration
├── core/
│   ├── config/
│   │   ├── app_config.dart           # Application configuration
│   │   ├── environment_config.dart   # Environment-specific config
│   │   └── route_config.dart         # Routing configuration
│   ├── constants/
│   │   ├── app_constants.dart        # Application constants
│   │   ├── api_constants.dart        # API endpoints
│   │   └── asset_constants.dart      # Asset paths
│   ├── controllers/
│   │   ├── auth_controller.dart      # Authentication logic
│   │   ├── location_controller.dart  # Location management
│   │   └── data_controller.dart      # Data synchronization
│   ├── models/
│   │   ├── user_model.dart          # User data model
│   │   ├── vehicle_model.dart       # Vehicle data model
│   │   ├── location_model.dart      # Location data model
│   │   └── base_model.dart          # Base model class
│   ├── services/
│   │   ├── firebase_service.dart    # Firebase integration
│   │   ├── location_service.dart    # GPS and location services
│   │   ├── notification_service.dart # Push notifications
│   │   ├── storage_service.dart     # Local storage
│   │   └── network_service.dart     # Network operations
│   ├── utils/
│   │   ├── date_utils.dart          # Date/time utilities
│   │   ├── validation_utils.dart    # Input validation
│   │   ├── permission_utils.dart    # Permission handling
│   │   └── geo_utils.dart           # Geospatial calculations
│   └── theme/
│       ├── app_theme.dart           # Application theme
│       ├── colors.dart              # Color palette
│       └── text_styles.dart         # Typography
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── widgets/
│   │   │   ├── login_form.dart
│   │   │   └── auth_button.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   ├── dashboard/
│   │   ├── screens/
│   │   │   ├── manager_dashboard.dart
│   │   │   └── driver_dashboard.dart
│   │   ├── widgets/
│   │   │   ├── dashboard_card.dart
│   │   │   ├── fleet_overview.dart
│   │   │   └── quick_stats.dart
│   │   └── providers/
│   │       └── dashboard_provider.dart
│   └── [other features...]
├── shared/
│   ├── widgets/
│   │   ├── custom_app_bar.dart
│   │   ├── loading_widget.dart
│   │   ├── error_widget.dart
│   │   └── map_widget.dart
│   └── themes/
│       └── widget_themes.dart
└── routes/
    └── app_routes.dart
```

## 7.3 Core Implementation Details

### 7.3.1 Application Bootstrap

**Main Application Entry Point:**
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('app_storage');
  await Hive.openBox('location_cache');
  
  // Initialize core services
  await FirebaseService.instance.initialize();
  await LocationService.instance.initialize();
  await NotificationService.instance.initialize();
  
  runApp(
    const ProviderScope(
      child: VehicleTrackingApp(),
    ),
  );
}
```

**Application Widget:**
```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/route_config.dart';
import 'core/theme/app_theme.dart';
import 'core/controllers/auth_controller.dart';

class VehicleTrackingApp extends ConsumerWidget {
  const VehicleTrackingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Vehicle Tracking System',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Prevent system font scaling
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
```

### 7.3.2 Authentication Implementation

**Firebase Authentication Service:**
```dart
// lib/core/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseDatabase _realtimeDB;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseDatabase get realtimeDB => _realtimeDB;

  Future<void> initialize() async {
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _realtimeDB = FirebaseDatabase.instance;

    // Configure Firestore settings
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Configure Realtime Database
    _realtimeDB.setPersistenceEnabled(true);
  }

  // Authentication methods
  Future<UserCredential?> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user's last login time
      if (credential.user != null) {
        await _updateUserLastLogin(credential.user!.uid);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email, 
    String password, 
    Map<String, dynamic> userData,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserProfile(credential.user!.uid, userData);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User profile management
  Future<void> _createUserProfile(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  Future<void> _updateUserLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
```

**Authentication Controller:**
```dart
// lib/core/controllers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/firebase_service.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState.initial()) {
    _initializeAuthListener();
  }

  final FirebaseService _firebaseService = FirebaseService.instance;

  void _initializeAuthListener() {
    _firebaseService.auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final userModel = await _getUserProfile(user.uid);
        state = AuthState.authenticated(userModel);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = const AuthState.loading();
    
    try {
      await _firebaseService.signInWithEmailAndPassword(email, password);
      // State will be updated by auth listener
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String organizationId,
  }) async {
    state = const AuthState.loading();
    
    try {
      final userData = {
        'name': name,
        'email': email,
        'role': role,
        'organizationId': organizationId,
      };
      
      await _firebaseService.createUserWithEmailAndPassword(
        email, 
        password, 
        userData,
      );
      
      // State will be updated by auth listener
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
  }

  Future<UserModel> _getUserProfile(String uid) async {
    final doc = await _firebaseService.firestore
        .collection('users')
        .doc(uid)
        .get();
    
    return UserModel.fromFirestore(doc);
  }
}

// Auth State Management
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(UserModel user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}
```

### 7.3.3 Real-Time Location Tracking Implementation

**Location Service:**
```dart
// lib/core/services/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/location_model.dart';
import 'firebase_service.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  
  LocationService._();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUpdateTimer;
  final FirebaseService _firebaseService = FirebaseService.instance;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Minimum distance (in meters) before update
    timeLimit: Duration(seconds: 30),
  );

  Future<void> initialize() async {
    await _checkLocationPermissions();
  }

  Future<bool> _checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Check background location permission for continuous tracking
    final backgroundStatus = await Permission.locationAlways.status;
    if (backgroundStatus.isDenied) {
      await Permission.locationAlways.request();
    }

    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw LocationServiceDisabledException();
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    );
  }

  Future<void> startTracking(String vehicleId) async {
    if (!await _checkLocationPermissions()) {
      throw Exception('Location permissions not granted');
    }

    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();

    // Start location stream
    _positionStreamSubscription = getLocationStream().listen(
      (Position position) {
        _handleLocationUpdate(vehicleId, position);
      },
      onError: (error) {
        print('Location stream error: $error');
        _handleLocationError(error);
      },
    );

    // Fallback timer for location updates
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        final position = await getCurrentLocation();
        if (position != null) {
          _handleLocationUpdate(vehicleId, position);
        }
      },
    );
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _positionStreamSubscription = null;
    _locationUpdateTimer = null;
  }

  void _handleLocationUpdate(String vehicleId, Position position) async {
    final locationModel = LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleId: vehicleId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      timestamp: DateTime.now(),
    );

    // Update real-time location
    await _updateRealtimeLocation(vehicleId, locationModel);
    
    // Store historical location
    await _storeHistoricalLocation(locationModel);
  }

  Future<void> _updateRealtimeLocation(String vehicleId, LocationModel location) async {
    try {
      await _firebaseService.realtimeDB
          .ref('live_tracking/$vehicleId')
          .set({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'speed': location.speed,
        'heading': location.heading,
        'accuracy': location.accuracy,
        'timestamp': ServerValue.timestamp,
        'lastUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating real-time location: $e');
    }
  }

  Future<void> _storeHistoricalLocation(LocationModel location) async {
    try {
      await _firebaseService.firestore
          .collection('location_history')
          .add(location.toFirestore());
    } catch (e) {
      print('Error storing historical location: $e');
    }
  }

  void _handleLocationError(dynamic error) {
    // Implement error handling and retry logic
    print('Location tracking error: $error');
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
```

### 7.3.4 Map Integration Implementation

**Map Widget:**
```dart
// lib/shared/widgets/map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/vehicle_model.dart';
import '../../core/models/location_model.dart';
import '../../features/maps/providers/map_provider.dart';

class MapWidget extends ConsumerStatefulWidget {
  final List<VehicleModel> vehicles;
  final Function(String vehicleId)? onVehicleSelected;
  final LatLng? initialLocation;
  final double initialZoom;

  const MapWidget({
    super.key,
    required this.vehicles,
    this.onVehicleSelected,
    this.initialLocation,
    this.initialZoom = 10.0,
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: widget.initialLocation ?? const LatLng(37.7749, -122.4194),
            zoom: widget.initialZoom,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: mapState.mapType,
          trafficEnabled: mapState.trafficEnabled,
          onCameraMove: (CameraPosition position) {
            ref.read(mapProvider.notifier).updateCameraPosition(position);
          },
        ),
        _buildMapControls(),
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    ref.read(mapProvider.notifier).setMapController(controller);
    _setCustomMapStyle();
  }

  void _initializeMarkers() {
    final Set<Marker> markers = {};

    for (final vehicle in widget.vehicles) {
      if (vehicle.currentLocation != null) {
        markers.add(_createVehicleMarker(vehicle));
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Marker _createVehicleMarker(VehicleModel vehicle) {
    return Marker(
      markerId: MarkerId(vehicle.id),
      position: LatLng(
        vehicle.currentLocation!.latitude,
        vehicle.currentLocation!.longitude,
      ),
      infoWindow: InfoWindow(
        title: vehicle.licensePlate,
        snippet: '${vehicle.make} ${vehicle.model}',
        onTap: () {
          widget.onVehicleSelected?.call(vehicle.id);
        },
      ),
      icon: _getVehicleMarkerIcon(vehicle),
      rotation: vehicle.currentLocation?.heading ?? 0.0,
      onTap: () {
        _showVehicleDetails(vehicle);
      },
    );
  }

  BitmapDescriptor _getVehicleMarkerIcon(VehicleModel vehicle) {
    switch (vehicle.status) {
      case VehicleStatus.moving:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case VehicleStatus.stopped:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case VehicleStatus.offline:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _showVehicleDetails(VehicleModel vehicle) {
    showModalBottomSheet(
      context: context,
      builder: (context) => VehicleDetailsSheet(vehicle: vehicle),
    );
  }

  void _setCustomMapStyle() async {
    if (_mapController != null) {
      final String mapStyle = await DefaultAssetBundle.of(context)
          .loadString('assets/map_styles/standard_style.json');
      _mapController!.setMapStyle(mapStyle);
    }
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: _centerOnUserLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _toggleMapType,
            child: const Icon(Icons.layers),
          ),
        ],
      ),
    );
  }

  void _centerOnUserLocation() async {
    if (_mapController != null) {
      final position = await LocationService.instance.getCurrentLocation();
      if (position != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    }
  }

  void _toggleMapType() {
    ref.read(mapProvider.notifier).toggleMapType();
  }
}
```

### 7.3.5 Dashboard Implementation

**Manager Dashboard:**
```dart
// lib/features/dashboard/screens/manager_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/vehicle_model.dart';
import '../../../shared/widgets/map_widget.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/fleet_overview.dart';
import '../widgets/quick_stats.dart';
import '../providers/dashboard_provider.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.map), text: 'Live Map'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(data),
            _buildMapTab(data),
            _buildAnalyticsTab(data),
            _buildSettingsTab(data),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(DashboardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuickStats(stats: data.quickStats),
          const SizedBox(height: 16),
          FleetOverview(vehicles: data.vehicles),
          const SizedBox(height: 16),
          _buildRecentActivities(data.recentActivities),
        ],
      ),
    );
  }

  Widget _buildMapTab(DashboardData data) {
    return MapWidget(
      vehicles: data.vehicles,
      onVehicleSelected: (vehicleId) {
        _showVehicleDetails(vehicleId, data.vehicles);
      },
    );
  }

  Widget _buildAnalyticsTab(DashboardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DashboardCard(
            title: 'Fleet Performance',
            child: _buildPerformanceChart(data.performanceData),
          ),
          const SizedBox(height: 16),
          DashboardCard(
            title: 'Driver Scores',
            child: _buildDriverScoreChart(data.driverScores),
          ),
          const SizedBox(height: 16),
          DashboardCard(
            title: 'Fuel Efficiency',
            child: _buildFuelEfficiencyChart(data.fuelData),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(DashboardData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Manage Users'),
          onTap: () => _navigateToUserManagement(),
        ),
        ListTile(
          leading: const Icon(Icons.directions_car),
          title: const Text('Manage Vehicles'),
          onTap: () => _navigateToVehicleManagement(),
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Geofences'),
          onTap: () => _navigateToGeofenceManagement(),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Alert Settings'),
          onTap: () => _navigateToAlertSettings(),
        ),
      ],
    );
  }

  Widget _buildRecentActivities(List<ActivityModel> activities) {
    return DashboardCard(
      title: 'Recent Activities',
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
            ),
            title: Text(activity.title),
            subtitle: Text(activity.description),
            trailing: Text(
              _formatTime(activity.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        },
      ),
    );
  }

  void _showVehicleDetails(String vehicleId, List<VehicleModel> vehicles) {
    final vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => VehicleDetailsSheet(
          vehicle: vehicle,
          scrollController: scrollController,
        ),
      ),
    );
  }

  // Helper methods and navigation methods...
}
```

### 7.3.6 Data Models Implementation

**Vehicle Model:**
```dart
// lib/core/models/vehicle_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'location_model.dart';

part 'vehicle_model.freezed.dart';
part 'vehicle_model.g.dart';

@freezed
class VehicleModel with _$VehicleModel {
  const factory VehicleModel({
    required String id,
    required String organizationId,
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    String? driverId,
    String? driverName,
    required VehicleStatus status,
    LocationModel? currentLocation,
    VehicleMetadata? metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _VehicleModel;

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelFromJson(json);

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    });
  }

  const VehicleModel._();

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['updatedAt'] = Timestamp.fromDate(updatedAt);
    return json;
  }

  bool get isActive => status == VehicleStatus.moving || status == VehicleStatus.stopped;
  bool get isOnline => currentLocation != null && 
      DateTime.now().difference(currentLocation!.timestamp).inMinutes < 5;
}

@freezed
class VehicleMetadata with _$VehicleMetadata {
  const factory VehicleMetadata({
    String? vin,
    String? color,
    String? fuelType,
    double? fuelCapacity,
    double? odometer,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    DateTime? insuranceExpiryDate,
    DateTime? registrationExpiryDate,
  }) = _VehicleMetadata;

  factory VehicleMetadata.fromJson(Map<String, dynamic> json) =>
      _$VehicleMetadataFromJson(json);
}

enum VehicleStatus {
  @JsonValue('active')
  active,
  @JsonValue('moving')
  moving,
  @JsonValue('stopped')
  stopped,
  @JsonValue('offline')
  offline,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('inactive')
  inactive,
}
```

This implementation demonstrates the practical application of the architectural decisions, showcasing real-world Flutter and Firebase integration patterns, state management with Riverpod, and comprehensive error handling strategies.
