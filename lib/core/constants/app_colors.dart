import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Secondary Colors
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF388E3C);
  static const Color secondaryLight = Color(0xFF81C784);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF424242);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F3F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // Vehicle Status Colors
  static const Color vehicleMoving = Color(0xFF4CAF50);
  static const Color vehicleIdle = Color(0xFFFF9800);
  static const Color vehicleOffline = Color(0xFF9E9E9E);
  static const Color vehicleAlert = Color(0xFFF44336);

  // Map Colors
  static const Color routeColor = Color(0xFF2196F3);
  static const Color geofenceColor = Color(0xFF9C27B0);
  static const Color currentLocation = Color(0xFF4CAF50);
}

class AppConstants {
  // App Information
  static const String appName = 'Vehicle Tracking System';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.vehicletracking.com';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Google API Configuration
  static const String googleMapsApiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';
  static const String googlePlacesApiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';
  static const String googleDirectionsApiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';

  // Location Settings
  static const double locationAccuracy = 10.0;
  static const int locationUpdateInterval = 5000; // milliseconds
  static const int locationFastestInterval = 2000; // milliseconds
  static const double locationDistanceFilter = 5.0; // meters

  // Geofence Settings
  static const double defaultGeofenceRadius = 100.0; // meters
  static const int geofenceTransitionDuration = 5000; // milliseconds

  // Driver Behavior Thresholds
  static const double harshBrakingThreshold = -0.3; // g-force
  static const double harshAccelerationThreshold = 0.4; // g-force
  static const double harshCorneringThreshold = 0.4; // g-force
  static const double speedingThreshold = 10.0; // km/h over limit

  // Notification Settings
  static const String notificationChannelId = 'vehicle_tracking_channel';
  static const String notificationChannelName = 'Vehicle Tracking';
  static const String notificationChannelDescription =
      'Notifications for vehicle tracking events';

  // Database Collections
  static const String usersCollection = 'users';
  static const String vehiclesCollection = 'vehicles';
  static const String tripsCollection = 'trips';
  static const String locationsCollection = 'locations';
  static const String geofencesCollection = 'geofences';
  static const String alertsCollection = 'alerts';
  static const String organizationsCollection = 'organizations';

  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyOrganizationId = 'organization_id';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyLocationPermissionGranted =
      'location_permission_granted';
  static const String keyNotificationPermissionGranted =
      'notification_permission_granted';

  // User Roles
  static const String roleDriver = 'driver';
  static const String roleManager = 'manager';
  static const String roleAdmin = 'admin';
  static const String roleConsumer = 'consumer';

  // Trip Status
  static const String tripStatusActive = 'active';
  static const String tripStatusCompleted = 'completed';
  static const String tripStatusPaused = 'paused';

  // Vehicle Status
  static const String vehicleStatusMoving = 'moving';
  static const String vehicleStatusIdle = 'idle';
  static const String vehicleStatusOffline = 'offline';

  // Alert Types
  static const String alertTypeGeofence = 'geofence';
  static const String alertTypeSpeeding = 'speeding';
  static const String alertTypeHarshBraking = 'harsh_braking';
  static const String alertTypeHarshAcceleration = 'harsh_acceleration';
  static const String alertTypeHarshCornering = 'harsh_cornering';
  static const String alertTypeDeviceOffline = 'device_offline';
}

class AppStrings {
  // General
  static const String appTitle = 'Vehicle Tracking System';
  static const String loading = 'Loading...';
  static const String pleaseWait = 'Please wait...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String confirm = 'Confirm';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String retry = 'Retry';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String view = 'View';
  static const String add = 'Add';
  static const String remove = 'Remove';
  static const String update = 'Update';

  // Authentication
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String loginSuccessful = 'Login successful';
  static const String loginFailed = 'Login failed';
  static const String invalidEmailOrPassword = 'Invalid email or password';
  static const String emailRequired = 'Email is required';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 6 characters';

  // Navigation
  static const String dashboard = 'Dashboard';
  static const String liveTracking = 'Live Tracking';
  static const String history = 'History';
  static const String reports = 'Reports';
  static const String geofences = 'Geofences';
  static const String alerts = 'Alerts';
  static const String settings = 'Settings';
  static const String profile = 'Profile';

  // Vehicle Tracking
  static const String vehicles = 'Vehicles';
  static const String drivers = 'Drivers';
  static const String currentLocation = 'Current Location';
  static const String lastUpdated = 'Last Updated';
  static const String speed = 'Speed';
  static const String direction = 'Direction';
  static const String status = 'Status';
  static const String startTrip = 'Start Trip';
  static const String endTrip = 'End Trip';
  static const String pauseTrip = 'Pause Trip';
  static const String resumeTrip = 'Resume Trip';

  // Permissions
  static const String locationPermissionRequired =
      'Location permission is required';
  static const String locationPermissionDenied = 'Location permission denied';
  static const String locationPermissionPermanentlyDenied =
      'Location permission permanently denied';
  static const String notificationPermissionRequired =
      'Notification permission is required';
  static const String backgroundLocationRequired =
      'Background location permission is required for tracking';

  // Errors
  static const String networkError = 'Network error occurred';
  static const String serverError = 'Server error occurred';
  static const String unknownError = 'An unknown error occurred';
  static const String noInternetConnection = 'No internet connection';
  static const String locationServiceDisabled = 'Location service is disabled';
  static const String gpsNotAvailable = 'GPS is not available';
}
