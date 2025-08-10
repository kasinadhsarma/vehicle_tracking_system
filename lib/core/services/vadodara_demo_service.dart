import 'dart:math' as math;
import 'dart:math' show Random;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Demo service for simulating realistic vehicle movement in Vadodara, Gujarat
class VadodaraDemoService {
  static final VadodaraDemoService _instance = VadodaraDemoService._internal();
  factory VadodaraDemoService() => _instance;
  VadodaraDemoService._internal();

  // Vadodara city boundaries
  static const double _vadodaraMinLat = 22.2000;
  static const double _vadodaraMaxLat = 22.4000;
  static const double _vadodaraMinLng = 73.0500;
  static const double _vadodaraMaxLng = 73.3000;

  // Track current waypoint index for each vehicle
  static final Map<String, int> _vehicleWaypointIndex = {};

  // Important locations in Vadodara
  static const Map<String, LatLng> _vadodaraLandmarks = {
    'railway_station': LatLng(22.3072, 73.1812),
    'ms_university': LatLng(22.3511, 73.1350),
    'sayajigunj': LatLng(22.3178, 73.1562),
    'makarpura': LatLng(22.2587, 73.2137),
    'kapurai': LatLng(22.2847, 73.2090),
    'old_city': LatLng(22.2995, 73.2080),
    'alkapuri': LatLng(22.3264, 73.1673),
    'gotri': LatLng(22.3430, 73.2089),
    'harni': LatLng(22.2725, 73.1848),
    'productivity_road': LatLng(22.3200, 73.1900),
    'vasna': LatLng(22.2900, 73.1750),
    'karelibaug': LatLng(22.3100, 73.2000),
    'race_course': LatLng(22.3300, 73.1800),
    'nizampura': LatLng(22.2800, 73.1900),
  };

  // Predefined routes with more waypoints for smoother movement
  static const Map<String, List<LatLng>> _demoRoutes = {
    'city_center_route': [
      LatLng(22.3072, 73.1812), // Railway Station
      LatLng(22.3080, 73.1800),
      LatLng(22.3090, 73.1780),
      LatLng(22.3100, 73.1750),
      LatLng(22.3120, 73.1720),
      LatLng(22.3140, 73.1690),
      LatLng(22.3150, 73.1680),
      LatLng(22.3160, 73.1650),
      LatLng(22.3170, 73.1620),
      LatLng(22.3178, 73.1562), // Sayajigunj
      LatLng(22.3185, 73.1580),
      LatLng(22.3200, 73.1600),
      LatLng(22.3220, 73.1620),
      LatLng(22.3240, 73.1640),
      LatLng(22.3264, 73.1673), // Alkapuri
      LatLng(22.3250, 73.1690),
      LatLng(22.3230, 73.1720),
      LatLng(22.3200, 73.1750),
      LatLng(22.3180, 73.1780),
      LatLng(22.3150, 73.1800),
      LatLng(22.3120, 73.1820),
      LatLng(22.3100, 73.1830),
      LatLng(22.3080, 73.1820),
    ],
    'industrial_route': [
      LatLng(22.2587, 73.2137), // Makarpura
      LatLng(22.2600, 73.2120),
      LatLng(22.2620, 73.2110),
      LatLng(22.2650, 73.2100),
      LatLng(22.2680, 73.2080),
      LatLng(22.2720, 73.2070),
      LatLng(22.2750, 73.2050),
      LatLng(22.2780, 73.2060),
      LatLng(22.2820, 73.2080),
      LatLng(22.2847, 73.2090), // Kapurai
      LatLng(22.2870, 73.2070),
      LatLng(22.2900, 73.2050),
      LatLng(22.2930, 73.2060),
      LatLng(22.2960, 73.2070),
      LatLng(22.2995, 73.2080), // Old City
      LatLng(22.2970, 73.2100),
      LatLng(22.2940, 73.2120),
      LatLng(22.2900, 73.2130),
      LatLng(22.2850, 73.2140),
      LatLng(22.2800, 73.2150),
      LatLng(22.2750, 73.2160),
      LatLng(22.2700, 73.2150),
      LatLng(22.2650, 73.2140),
      LatLng(22.2620, 73.2140),
    ],
    'university_route': [
      LatLng(22.3511, 73.1350), // MS University
      LatLng(22.3500, 73.1370),
      LatLng(22.3480, 73.1380),
      LatLng(22.3450, 73.1400),
      LatLng(22.3430, 73.1430),
      LatLng(22.3420, 73.1460),
      LatLng(22.3400, 73.1500),
      LatLng(22.3380, 73.1530),
      LatLng(22.3360, 73.1560),
      LatLng(22.3350, 73.1600),
      LatLng(22.3330, 73.1630),
      LatLng(22.3320, 73.1660),
      LatLng(22.3300, 73.1700),
      LatLng(22.3280, 73.1750),
      LatLng(22.3250, 73.1800),
      LatLng(22.3220, 73.1850),
      LatLng(22.3200, 73.1900), // Productivity Road
      LatLng(22.3230, 73.1880),
      LatLng(22.3260, 73.1850),
      LatLng(22.3300, 73.1820),
      LatLng(22.3340, 73.1780),
      LatLng(22.3380, 73.1740),
      LatLng(22.3420, 73.1700),
      LatLng(22.3460, 73.1650),
      LatLng(22.3490, 73.1600),
      LatLng(22.3500, 73.1550),
      LatLng(22.3510, 73.1500),
      LatLng(22.3515, 73.1450),
      LatLng(22.3518, 73.1400),
    ],
    'suburb_route': [
      LatLng(22.3430, 73.2089), // Gotri
      LatLng(22.3420, 73.2070),
      LatLng(22.3400, 73.2050),
      LatLng(22.3380, 73.2030),
      LatLng(22.3350, 73.2000),
      LatLng(22.3320, 73.1980),
      LatLng(22.3300, 73.1960),
      LatLng(22.3280, 73.1940),
      LatLng(22.3250, 73.1920),
      LatLng(22.3220, 73.1910),
      LatLng(22.3180, 73.1890),
      LatLng(22.3150, 73.1870),
      LatLng(22.3120, 73.1860),
      LatLng(22.3080, 73.1850),
      LatLng(22.3040, 73.1845),
      LatLng(22.3000, 73.1840),
      LatLng(22.2950, 73.1845),
      LatLng(22.2900, 73.1847),
      LatLng(22.2850, 73.1848),
      LatLng(22.2800, 73.1849),
      LatLng(22.2750, 73.1848),
      LatLng(22.2725, 73.1848), // Harni
      LatLng(22.2750, 73.1860),
      LatLng(22.2780, 73.1880),
      LatLng(22.2820, 73.1900),
      LatLng(22.2860, 73.1920),
      LatLng(22.2900, 73.1940),
      LatLng(22.2950, 73.1960),
      LatLng(22.3000, 73.1980),
      LatLng(22.3050, 73.2000),
      LatLng(22.3100, 73.2020),
      LatLng(22.3150, 73.2040),
      LatLng(22.3200, 73.2050),
      LatLng(22.3250, 73.2060),
      LatLng(22.3300, 73.2070),
      LatLng(22.3350, 73.2075),
      LatLng(22.3400, 73.2080),
      LatLng(22.3425, 73.2085),
    ],
    'express_route': [
      LatLng(22.2587, 73.2137), // Makarpura (Start)
      LatLng(22.2620, 73.2100),
      LatLng(22.2650, 73.2070),
      LatLng(22.2680, 73.2040),
      LatLng(22.2700, 73.2000),
      LatLng(22.2730, 73.1960),
      LatLng(22.2770, 73.1920),
      LatLng(22.2820, 73.1880),
      LatLng(22.2850, 73.1850),
      LatLng(22.2900, 73.1820),
      LatLng(22.2950, 73.1780),
      LatLng(22.3000, 73.1750),
      LatLng(22.3050, 73.1720),
      LatLng(22.3100, 73.1690),
      LatLng(22.3150, 73.1660),
      LatLng(22.3200, 73.1640),
      LatLng(22.3240, 73.1650),
      LatLng(22.3264, 73.1673), // Alkapuri (End)
      LatLng(22.3240, 73.1700),
      LatLng(22.3200, 73.1730),
      LatLng(22.3150, 73.1760),
      LatLng(22.3100, 73.1790),
      LatLng(22.3050, 73.1820),
      LatLng(22.3000, 73.1850),
      LatLng(22.2950, 73.1880),
      LatLng(22.2900, 73.1920),
      LatLng(22.2850, 73.1960),
      LatLng(22.2800, 73.2000),
      LatLng(22.2750, 73.2040),
      LatLng(22.2700, 73.2080),
      LatLng(22.2650, 73.2100),
      LatLng(22.2620, 73.2120),
    ],
  };

  /// Initialize demo vehicles with realistic Vadodara data including popular ride services
  static List<Map<String, dynamic>> getVadodaraVehicles() {
    return [
      // Ola Vehicles
      {
        'id': 'OLA-VDR-001',
        'driverId': 'driver_001',
        'driverName': 'Rajesh Patel',
        'name': 'Ola Prime Sedan',
        'type': 'ola_prime',
        'service': 'Ola',
        'vehicleModel': 'Maruti Dzire',
        'color': '#FFD700', // Gold
        'route': 'city_center_route',
        'startLocation': _vadodaraLandmarks['railway_station'],
        'currentSpeed': 35.0,
        'maxSpeed': 80.0,
        'fuelLevel': 85.5,
        'rating': 4.8,
        'totalTrips': 1247,
        'status': 'available',
      },
      {
        'id': 'OLA-VDR-002',
        'driverId': 'driver_002',
        'driverName': 'Priya Sharma',
        'name': 'Ola Micro',
        'type': 'ola_micro',
        'service': 'Ola',
        'vehicleModel': 'Maruti Alto',
        'color': '#4CAF50', // Green
        'route': 'university_route',
        'startLocation': _vadodaraLandmarks['ms_university'],
        'currentSpeed': 25.0,
        'maxSpeed': 60.0,
        'fuelLevel': 72.3,
        'rating': 4.5,
        'totalTrips': 892,
        'status': 'busy',
      },
      
      // Uber Vehicles
      {
        'id': 'UBR-GJ-003',
        'driverId': 'driver_003',
        'driverName': 'Amit Shah',
        'name': 'Uber Go',
        'type': 'uber_go',
        'service': 'Uber',
        'vehicleModel': 'Hyundai i10',
        'color': '#000000', // Black
        'route': 'suburb_route',
        'startLocation': _vadodaraLandmarks['sayajigunj'],
        'currentSpeed': 30.0,
        'maxSpeed': 70.0,
        'fuelLevel': 68.2,
        'rating': 4.6,
        'totalTrips': 1089,
        'status': 'available',
      },
      {
        'id': 'UBR-GJ-004',
        'driverId': 'driver_004',
        'driverName': 'Neha Patel',
        'name': 'Uber Premier',
        'type': 'uber_premier',
        'service': 'Uber',
        'vehicleModel': 'Toyota Innova',
        'color': '#1E88E5', // Blue
        'route': 'express_route',
        'startLocation': _vadodaraLandmarks['alkapuri'],
        'currentSpeed': 40.0,
        'maxSpeed': 90.0,
        'fuelLevel': 91.8,
        'rating': 4.9,
        'totalTrips': 743,
        'status': 'available',
      },
      
      // Auto Rickshaws
      {
        'id': 'AUTO-VDR-005',
        'driverId': 'driver_005',
        'driverName': 'Vikram Singh',
        'name': 'City Auto',
        'type': 'auto_rickshaw',
        'service': 'Local',
        'vehicleModel': 'Bajaj Auto',
        'color': '#FF9800', // Orange
        'route': 'city_center_route',
        'startLocation': _vadodaraLandmarks['old_city'],
        'currentSpeed': 20.0,
        'maxSpeed': 45.0,
        'fuelLevel': 76.9,
        'rating': 4.2,
        'totalTrips': 2156,
        'status': 'available',
      },
      
      // GSRTC Buses
      {
        'id': 'GSRTC-001',
        'driverId': 'driver_006',
        'driverName': 'Mahesh Kumar',
        'name': 'GSRTC City Bus',
        'type': 'public_bus',
        'service': 'GSRTC',
        'vehicleModel': 'Ashok Leyland',
        'color': '#2196F3', // Blue
        'route': 'industrial_route',
        'startLocation': _vadodaraLandmarks['makarpura'],
        'currentSpeed': 25.0,
        'maxSpeed': 50.0,
        'fuelLevel': 85.0,
        'rating': 4.0,
        'totalTrips': 156,
        'status': 'on_route',
        'capacity': 45,
        'currentPassengers': 32,
      },
      
      // Delivery Services
      {
        'id': 'ZOMATO-007',
        'driverId': 'driver_007',
        'driverName': 'Rohit Joshi',
        'name': 'Zomato Delivery',
        'type': 'delivery_bike',
        'service': 'Zomato',
        'vehicleModel': 'Honda Activa',
        'color': '#E23744', // Red
        'route': 'suburb_route',
        'startLocation': _vadodaraLandmarks['gotri'],
        'currentSpeed': 35.0,
        'maxSpeed': 60.0,
        'fuelLevel': 82.4,
        'rating': 4.7,
        'totalTrips': 1523,
        'status': 'delivering',
      },
      {
        'id': 'SWIGGY-008',
        'driverId': 'driver_008',
        'driverName': 'Kiran Pandya',
        'name': 'Swiggy Delivery',
        'type': 'delivery_bike',
        'service': 'Swiggy',
        'vehicleModel': 'TVS Jupiter',
        'color': '#FF6B35', // Orange-Red
        'route': 'university_route',
        'startLocation': _vadodaraLandmarks['productivity_road'],
        'currentSpeed': 30.0,
        'maxSpeed': 55.0,
        'fuelLevel': 71.2,
        'rating': 4.4,
        'totalTrips': 967,
        'status': 'available',
      },
      
      // Corporate Fleet
      {
        'id': 'CORP-VDR-009',
        'driverId': 'driver_009',
        'driverName': 'Sanjay Patel',
        'name': 'Corporate Shuttle',
        'type': 'corporate_bus',
        'service': 'Corporate',
        'vehicleModel': 'Force Traveller',
        'color': '#9C27B0', // Purple
        'route': 'express_route',
        'startLocation': _vadodaraLandmarks['kapurai'],
        'currentSpeed': 40.0,
        'maxSpeed': 80.0,
        'fuelLevel': 89.7,
        'rating': 4.3,
        'totalTrips': 245,
        'status': 'scheduled',
        'capacity': 26,
        'currentPassengers': 18,
      },
      
      // Emergency Services
      {
        'id': 'AMB-VDR-010',
        'driverId': 'driver_010',
        'driverName': 'Dr. Kavita Shah',
        'name': 'Emergency Ambulance',
        'type': 'ambulance',
        'service': 'Emergency',
        'vehicleModel': 'Mahindra Bolero',
        'color': '#FFFFFF', // White
        'route': 'city_center_route',
        'startLocation': _vadodaraLandmarks['harni'],
        'currentSpeed': 45.0,
        'maxSpeed': 100.0,
        'fuelLevel': 95.3,
        'rating': 5.0,
        'totalTrips': 89,
        'status': 'standby',
        'priority': 'high',
      },
      
      // Additional vehicles (11-17) for expanded fleet
      {
        'id': 'OLA-VDR-011',
        'driverId': 'driver_011',
        'driverName': 'Snehal Patel',
        'name': 'Ola Auto',
        'type': 'ola_auto',
        'service': 'Ola',
        'vehicleModel': 'Bajaj Auto Rickshaw',
        'color': '#FFD700', // Gold
        'route': 'local_route',
        'startLocation': _vadodaraLandmarks['alkapuri'],
        'currentSpeed': 22.0,
        'maxSpeed': 45.0,
        'fuelLevel': 78.2,
        'rating': 4.2,
        'totalTrips': 3456,
        'status': 'available',
      },
      
      {
        'id': 'UBR-GJ-012',
        'driverId': 'driver_012',
        'driverName': 'Kiran Desai',
        'name': 'Uber XL',
        'type': 'uber_xl',
        'service': 'Uber',
        'vehicleModel': 'Toyota Innova',
        'color': '#000000', // Black
        'route': 'suburb_route',
        'startLocation': _vadodaraLandmarks['gotri'],
        'currentSpeed': 38.0,
        'maxSpeed': 90.0,
        'fuelLevel': 82.7,
        'rating': 4.7,
        'totalTrips': 1876,
        'status': 'busy',
        'capacity': 7,
        'currentPassengers': 4,
      },
      
      {
        'id': 'AMAZON-013',
        'driverId': 'driver_013',
        'driverName': 'Rahul Modi',
        'name': 'Amazon Prime',
        'type': 'delivery_van',
        'service': 'Amazon',
        'vehicleModel': 'Tata Ace',
        'color': '#FF9900', // Orange
        'route': 'industrial_route',
        'startLocation': _vadodaraLandmarks['makarpura'],
        'currentSpeed': 32.0,
        'maxSpeed': 65.0,
        'fuelLevel': 71.4,
        'rating': 4.8,
        'totalTrips': 2345,
        'status': 'delivering',
        'packagesCount': 67,
      },
      
      {
        'id': 'FLIPKART-014',
        'driverId': 'driver_014',
        'driverName': 'Hardik Joshi',
        'name': 'Flipkart Express',
        'type': 'delivery_van',
        'service': 'Flipkart',
        'vehicleModel': 'Mahindra Bolero Pickup',
        'color': '#047BD2', // Blue
        'route': 'suburb_route',
        'startLocation': _vadodaraLandmarks['vasna'],
        'currentSpeed': 28.0,
        'maxSpeed': 70.0,
        'fuelLevel': 65.8,
        'rating': 4.6,
        'totalTrips': 1987,
        'status': 'loading',
        'packagesCount': 43,
      },
      
      {
        'id': 'BLINKIT-015',
        'driverId': 'driver_015',
        'driverName': 'Arjun Chauhan',
        'name': 'Blinkit Quick',
        'type': 'delivery_bike',
        'service': 'Blinkit',
        'vehicleModel': 'Hero Splendor',
        'color': '#FFFF00', // Yellow
        'route': 'local_route',
        'startLocation': _vadodaraLandmarks['karelibaug'],
        'currentSpeed': 26.0,
        'maxSpeed': 50.0,
        'fuelLevel': 88.5,
        'rating': 4.4,
        'totalTrips': 1234,
        'status': 'available',
      },
      
      {
        'id': 'FIRE-016',
        'driverId': 'driver_016',
        'driverName': 'Captain Ravi Singh',
        'name': 'Fire Engine',
        'type': 'fire_truck',
        'service': 'Emergency',
        'vehicleModel': 'Tata 1613 Fire Tender',
        'color': '#DC143C', // Crimson Red
        'route': 'city_center_route',
        'startLocation': _vadodaraLandmarks['race_course'],
        'currentSpeed': 0.0,
        'maxSpeed': 80.0,
        'fuelLevel': 98.7,
        'rating': 5.0,
        'totalTrips': 45,
        'status': 'standby',
        'priority': 'critical',
      },
      
      {
        'id': 'SCHOOL-017',
        'driverId': 'driver_017',
        'driverName': 'Mahesh Yadav',
        'name': 'School Bus',
        'type': 'bus',
        'service': 'School',
        'vehicleModel': 'Eicher Skyline Pro',
        'color': '#FFD700', // Golden Yellow
        'route': 'university_route',
        'startLocation': _vadodaraLandmarks['nizampura'],
        'currentSpeed': 25.0,
        'maxSpeed': 60.0,
        'fuelLevel': 72.6,
        'rating': 4.0,
        'totalTrips': 567,
        'status': 'on_route',
        'capacity': 40,
        'currentPassengers': 32,
      },
    ];
  }

  /// Get a random location within Vadodara bounds
  static LatLng getRandomVadodaraLocation() {
    final random = Random();
    final lat = _vadodaraMinLat + 
        (random.nextDouble() * (_vadodaraMaxLat - _vadodaraMinLat));
    final lng = _vadodaraMinLng + 
        (random.nextDouble() * (_vadodaraMaxLng - _vadodaraMinLng));
    return LatLng(lat, lng);
  }

  /// Get next position for a vehicle on its route using waypoint-based movement
  static LatLng getNextPositionOnRoute(
    String routeName, 
    LatLng currentPosition, 
    double speed,
  ) {
    final route = _demoRoutes[routeName];
    if (route == null || route.isEmpty) {
      return getRandomVadodaraLocation();
    }

    // Get or initialize waypoint index for this vehicle
    final vehicleKey = '${routeName}_${currentPosition.latitude.toStringAsFixed(4)}_${currentPosition.longitude.toStringAsFixed(4)}';
    int waypointIndex = _vehicleWaypointIndex[vehicleKey] ?? 0;

    // Get current target waypoint
    final targetWaypoint = route[waypointIndex];
    
    // Calculate distance to current target
    final distanceToTarget = _calculateDistance(currentPosition, targetWaypoint);
    
    // If close to target (within 50 meters), move to next waypoint
    if (distanceToTarget < 0.05) { // 50 meters
      waypointIndex = (waypointIndex + 1) % route.length;
      _vehicleWaypointIndex[vehicleKey] = waypointIndex;
      return route[waypointIndex];
    }

    // Move towards current target waypoint
    final bearing = _calculateBearing(currentPosition, targetWaypoint);
    final moveDistance = (speed / 3600.0) * 3.0; // Convert km/h to km per 3 seconds
    
    return _moveAlongBearing(currentPosition, bearing, moveDistance);
  }

  /// Calculate bearing from point A to point B
  static double _calculateBearing(LatLng from, LatLng to) {
    final lat1Rad = from.latitude * (math.pi / 180);
    final lat2Rad = to.latitude * (math.pi / 180);
    final deltaLngRad = (to.longitude - from.longitude) * (math.pi / 180);
    
    final x = math.sin(deltaLngRad) * math.cos(lat2Rad);
    final y = math.cos(lat1Rad) * math.sin(lat2Rad) - 
              math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);
    
    final bearingRad = math.atan2(x, y);
    return (bearingRad * (180 / math.pi) + 360) % 360;
  }

  /// Move from a point along a bearing for a specific distance
  static LatLng _moveAlongBearing(LatLng start, double bearing, double distanceKm) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    
    final lat1Rad = start.latitude * (math.pi / 180);
    final lng1Rad = start.longitude * (math.pi / 180);
    final bearingRad = bearing * (math.pi / 180);
    
    final lat2Rad = math.asin(
      math.sin(lat1Rad) * math.cos(distanceKm / earthRadius) +
      math.cos(lat1Rad) * math.sin(distanceKm / earthRadius) * math.cos(bearingRad)
    );
    
    final lng2Rad = lng1Rad + math.atan2(
      math.sin(bearingRad) * math.sin(distanceKm / earthRadius) * math.cos(lat1Rad),
      math.cos(distanceKm / earthRadius) - math.sin(lat1Rad) * math.sin(lat2Rad)
    );
    
    final newLat = lat2Rad * (180 / math.pi);
    final newLng = lng2Rad * (180 / math.pi);
    
    return LatLng(
      newLat.clamp(_vadodaraMinLat, _vadodaraMaxLat),
      newLng.clamp(_vadodaraMinLng, _vadodaraMaxLng),
    );
  }

  /// Calculate distance between two points in kilometers
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    
    final lat1Rad = point1.latitude * (math.pi / 180);
    final lat2Rad = point2.latitude * (math.pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);
    
    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Generate realistic speed based on vehicle type and location
  static double generateRealisticSpeed(String vehicleType, LatLng location) {
    final random = Random();
    
    // Enhanced speed ranges by vehicle type including ride-sharing services
    Map<String, Map<String, double>> speedRanges = {
      // Ride-sharing services
      'ola_prime': {'min': 25.0, 'max': 80.0},
      'ola_micro': {'min': 20.0, 'max': 65.0},
      'uber_go': {'min': 22.0, 'max': 70.0},
      'uber_premier': {'min': 30.0, 'max': 90.0},
      
      // Traditional vehicles
      'auto_rickshaw': {'min': 15.0, 'max': 45.0},
      'public_bus': {'min': 15.0, 'max': 50.0},
      'corporate_bus': {'min': 25.0, 'max': 80.0},
      
      // Delivery services
      'delivery_bike': {'min': 20.0, 'max': 60.0},
      
      // Emergency services
      'ambulance': {'min': 40.0, 'max': 100.0},
      
      // Legacy types
      'bus': {'min': 15.0, 'max': 45.0},
      'van': {'min': 25.0, 'max': 70.0},
      'truck': {'min': 20.0, 'max': 60.0},
      'taxi': {'min': 20.0, 'max': 80.0},
    };
    
    final range = speedRanges[vehicleType] ?? {'min': 20.0, 'max': 60.0};
    final baseSpeed = range['min']! + 
        (random.nextDouble() * (range['max']! - range['min']!));
    
    // Adjust speed based on area and time of day
    double areaFactor = 1.0;
    double timeFactor = _getTimeOfDayFactor();
    
    if (_isInCityCenter(location)) {
      areaFactor = 0.6; // Much slower in city center
    } else if (_isOnHighway(location)) {
      areaFactor = 1.2; // Faster on highways
    } else if (_isInResidentialArea(location)) {
      areaFactor = 0.8; // Moderate in residential areas
    }
    
    // Emergency vehicles have priority
    if (vehicleType == 'ambulance') {
      areaFactor = math.min(areaFactor * 1.5, 2.0);
    }
    
    // Delivery bikes are more agile in traffic
    if (vehicleType == 'delivery_bike') {
      areaFactor = math.max(areaFactor, 0.8);
    }
    
    final finalSpeed = (baseSpeed * areaFactor * timeFactor).clamp(5.0, 120.0);
    
    // Add some randomness for realistic variation
    final variation = (random.nextDouble() - 0.5) * 0.2; // ±10% variation
    return (finalSpeed * (1 + variation)).clamp(5.0, 120.0);
  }

  /// Get time of day factor affecting traffic speed
  static double _getTimeOfDayFactor() {
    final hour = DateTime.now().hour;
    
    // Rush hours: 8-10 AM and 6-8 PM
    if ((hour >= 8 && hour <= 10) || (hour >= 18 && hour <= 20)) {
      return 0.6; // 40% slower during rush hours
    }
    
    // Late night: 11 PM - 5 AM
    if (hour >= 23 || hour <= 5) {
      return 1.3; // 30% faster during night
    }
    
    // Normal hours
    return 1.0;
  }

  /// Check if location is in city center
  static bool _isInCityCenter(LatLng location) {
    const cityCenter = LatLng(22.3072, 73.1812); // Railway Station
    return _calculateDistance(location, cityCenter) < 2.5; // Within 2.5km
  }

  /// Check if location is on highway
  static bool _isOnHighway(LatLng location) {
    // Productivity Road and Makarpura areas (industrial/highway zones)
    return (location.latitude > 22.315 && location.longitude > 73.18) ||
           (location.latitude < 22.270 && location.longitude > 73.20);
  }

  /// Check if location is in residential area
  static bool _isInResidentialArea(LatLng location) {
    // Alkapuri, Gotri, Harni areas
    return ((location.latitude >= 22.320 && location.latitude <= 22.350) &&
            (location.longitude >= 73.160 && location.longitude <= 73.210)) ||
           ((location.latitude >= 22.270 && location.latitude <= 22.290) &&
            (location.longitude >= 73.180 && location.longitude <= 73.200));
  }

  /// Get vehicle status based on speed and time
  static String getVehicleStatus(double speed, DateTime lastUpdate) {
    final now = DateTime.now();
    final timeDiff = now.difference(lastUpdate).inMinutes;
    
    if (timeDiff > 30) return 'offline';
    if (speed < 5) return 'idle';
    if (speed > 5) return 'active';
    return 'unknown';
  }

  /// Generate realistic fuel consumption
  static double simulateFuelConsumption(
    double currentFuel, 
    double speed, 
    String vehicleType,
  ) {
    // Fuel consumption rate per minute based on speed and vehicle type
    Map<String, double> baseConsumption = {
      'bus': 0.08,
      'van': 0.05,
      'truck': 0.12,
      'taxi': 0.04,
    };
    
    final baseFuelRate = baseConsumption[vehicleType] ?? 0.06;
    final speedFactor = speed > 40 ? 1.5 : 1.0; // Higher consumption at high speed
    final consumption = baseFuelRate * speedFactor;
    
    return (currentFuel - consumption).clamp(0.0, 100.0);
  }
}
