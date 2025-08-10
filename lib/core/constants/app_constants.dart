class AppConstants {
  // User roles
  static const String roleDriver = 'driver';
  static const String roleManager = 'manager';
  static const String roleAdmin = 'admin';

  // API endpoints
  static const String baseUrl = 'https://your-api-domain.com/api';
  static const String authEndpoint = '/auth';
  static const String trackingEndpoint = '/tracking';
  static const String vehiclesEndpoint = '/vehicles';
  static const String geofenceEndpoint = '/geofences';

  // Local storage keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';

  // Map settings
  static const double defaultZoom = 15.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 20.0;

  // Tracking settings
  static const int locationUpdateInterval = 30; // seconds
  static const int maxLocationHistory = 100;
  static const double geofenceRadiusDefault = 100.0; // meters

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int phoneNumberLength = 10;

  // Demo/Mock data
  static const List<Map<String, dynamic>> mockVehicles = [
    {
      'id': 'VH-001',
      'driver': 'John Smith',
      'status': 'Active',
      'lat': 40.7128,
      'lng': -74.0060,
    },
    {
      'id': 'VH-002',
      'driver': 'Jane Doe',
      'status': 'Idle',
      'lat': 40.7589,
      'lng': -73.9851,
    },
    {
      'id': 'VH-003',
      'driver': 'Mike Johnson',
      'status': 'Active',
      'lat': 40.7282,
      'lng': -73.7949,
    },
  ];
}
