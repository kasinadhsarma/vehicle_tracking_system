import 'dart:collection';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

/// Advanced pathfinding service using DFS, BFS, and A* algorithms
class PathfindingService {
  static final PathfindingService _instance = PathfindingService._internal();
  factory PathfindingService() => _instance;
  PathfindingService._internal();

  // Vadodara road network graph - major intersections and connections
  static final Map<String, LatLng> _vadodaraNodes = {
    'railway_station': const LatLng(22.3072, 73.1812),
    'ms_university': const LatLng(22.3511, 73.1350),
    'parul_university': const LatLng(22.2586, 73.3565), // Parul University, Waghodia
    'sayajigunj': const LatLng(22.3178, 73.1562),
    'makarpura': const LatLng(22.2587, 73.2137),
    'kapurai': const LatLng(22.2847, 73.2090),
    'old_city': const LatLng(22.2995, 73.2080),
    'alkapuri': const LatLng(22.3264, 73.1673),
    'gotri': const LatLng(22.3430, 73.2089),
    'harni': const LatLng(22.2725, 73.1848),
    'productivity_road': const LatLng(22.3200, 73.1900),
    'vasna': const LatLng(22.2900, 73.1750),
    'karelibaug': const LatLng(22.3100, 73.2000),
    'race_course': const LatLng(22.3300, 73.1800),
    'nizampura': const LatLng(22.2800, 73.1900),
    'manjalpur': const LatLng(22.2950, 73.1650),
    'subhanpura': const LatLng(22.3350, 73.1750),
    'waghodia_road': const LatLng(22.2750, 73.1650),
    'akota': const LatLng(22.3050, 73.1950),
    'sama': const LatLng(22.3400, 73.1650),
    'tandalja': const LatLng(22.3250, 73.1950),
    'limbayat': const LatLng(22.2650, 73.3200), // Near Parul University
    'atladra': const LatLng(22.2780, 73.2850), // Connecting point to Parul
  };

  // Road network connections (adjacency list)
  static final Map<String, List<String>> _roadNetwork = {
    'railway_station': ['sayajigunj', 'old_city', 'manjalpur', 'productivity_road'],
    'ms_university': ['sayajigunj', 'subhanpura', 'sama', 'alkapuri'],
    'parul_university': ['limbayat', 'atladra', 'waghodia_road'], // Parul University connections
    'sayajigunj': ['railway_station', 'ms_university', 'alkapuri', 'race_course'],
    'makarpura': ['kapurai', 'gotri', 'harni', 'old_city'],
    'kapurai': ['makarpura', 'karelibaug', 'akota', 'harni'],
    'old_city': ['railway_station', 'makarpura', 'nizampura', 'vasna'],
    'alkapuri': ['sayajigunj', 'ms_university', 'race_course', 'tandalja'],
    'gotri': ['makarpura', 'karelibaug', 'sama', 'subhanpura'],
    'harni': ['makarpura', 'kapurai', 'waghodia_road', 'vasna'],
    'productivity_road': ['railway_station', 'akota', 'tandalja', 'race_course'],
    'vasna': ['old_city', 'harni', 'manjalpur', 'nizampura'],
    'karelibaug': ['kapurai', 'gotri', 'akota', 'tandalja'],
    'race_course': ['sayajigunj', 'alkapuri', 'productivity_road', 'subhanpura'],
    'nizampura': ['old_city', 'vasna', 'manjalpur', 'waghodia_road'],
    'manjalpur': ['railway_station', 'vasna', 'nizampura', 'waghodia_road'],
    'subhanpura': ['ms_university', 'gotri', 'race_course', 'sama'],
    'waghodia_road': ['harni', 'nizampura', 'manjalpur', 'akota', 'parul_university', 'atladra'],
    'akota': ['kapurai', 'karelibaug', 'productivity_road', 'waghodia_road'],
    'sama': ['ms_university', 'gotri', 'subhanpura', 'tandalja'],
    'tandalja': ['alkapuri', 'karelibaug', 'productivity_road', 'sama'],
    'limbayat': ['parul_university', 'atladra'], // Near Parul University
    'atladra': ['parul_university', 'limbayat', 'waghodia_road', 'makarpura'], // Connecting point
  };

  // Traffic conditions (1.0 = normal, >1.0 = congested, <1.0 = fast)
  static final Map<String, double> _trafficConditions = {
    'sayajigunj-alkapuri': 1.5, // Heavy traffic
    'railway_station-old_city': 1.3,
    'makarpura-gotri': 1.2,
    'ms_university-sama': 0.8, // Fast route
    'race_course-subhanpura': 0.9,
    'productivity_road-akota': 1.1,
  };

  /// Find route using Depth-First Search (DFS)
  /// Good for: Exploring all possible paths, finding alternative routes
  static RouteResult? findRouteDFS(String start, String end) {
    if (!_vadodaraNodes.containsKey(start) || !_vadodaraNodes.containsKey(end)) {
      return null;
    }

    final visited = <String>{};
    final path = <String>[];
    final List<String> finalPath = [];

    bool dfsHelper(String current) {
      visited.add(current);
      path.add(current);

      if (current == end) {
        finalPath.addAll(path);
        return true;
      }

      final neighbors = _roadNetwork[current] ?? [];
      // Sort neighbors by distance for more intelligent exploration
      neighbors.sort((a, b) => _getDistance(current, a).compareTo(_getDistance(current, b)));

      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          if (dfsHelper(neighbor)) {
            return true;
          }
        }
      }

      path.removeLast();
      return false;
    }

    final found = dfsHelper(start);
    if (!found || finalPath.isEmpty) return null;

    return RouteResult(
      path: finalPath,
      coordinates: finalPath.map((node) => _vadodaraNodes[node]!).toList(),
      algorithm: 'DFS',
      distance: _calculatePathDistance(finalPath),
      estimatedTime: _calculatePathTime(finalPath),
      routeType: 'Alternative Path',
      color: Colors.orange,
    );
  }

  /// Find route using Breadth-First Search (BFS)
  /// Good for: Finding shortest path (minimum hops), exploring nearby areas
  static RouteResult? findRouteBFS(String start, String end) {
    if (!_vadodaraNodes.containsKey(start) || !_vadodaraNodes.containsKey(end)) {
      return null;
    }

    final queue = Queue<String>();
    final visited = <String>{};
    final parent = <String, String>{};

    queue.add(start);
    visited.add(start);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      if (current == end) {
        // Reconstruct path
        final path = <String>[];
        String? node = end;
        while (node != null) {
          path.insert(0, node);
          node = parent[node];
        }

        return RouteResult(
          path: path,
          coordinates: path.map((node) => _vadodaraNodes[node]!).toList(),
          algorithm: 'BFS',
          distance: _calculatePathDistance(path),
          estimatedTime: _calculatePathTime(path),
          routeType: 'Shortest Hops',
          color: Colors.blue,
        );
      }

      final neighbors = _roadNetwork[current] ?? [];
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          parent[neighbor] = current;
          queue.add(neighbor);
        }
      }
    }

    return null; // No path found
  }

  /// Find route using A* algorithm
  /// Good for: Optimal pathfinding with heuristics, real-world navigation
  static RouteResult? findRouteAStar(String start, String end) {
    if (!_vadodaraNodes.containsKey(start) || !_vadodaraNodes.containsKey(end)) {
      return null;
    }

    final openSet = <String>{start};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{start: 0.0};
    final fScore = <String, double>{start: _heuristic(start, end)};

    while (openSet.isNotEmpty) {
      // Find node with lowest fScore
      String current = openSet.first;
      for (final node in openSet) {
        if ((fScore[node] ?? double.infinity) < (fScore[current] ?? double.infinity)) {
          current = node;
        }
      }

      if (current == end) {
        // Reconstruct path
        final path = <String>[];
        String? node = end;
        while (node != null) {
          path.insert(0, node);
          node = cameFrom[node];
        }

        return RouteResult(
          path: path,
          coordinates: path.map((node) => _vadodaraNodes[node]!).toList(),
          algorithm: 'A*',
          distance: _calculatePathDistance(path),
          estimatedTime: _calculatePathTime(path),
          routeType: 'Optimal Route',
          color: Colors.green,
        );
      }

      openSet.remove(current);
      final neighbors = _roadNetwork[current] ?? [];

      for (final neighbor in neighbors) {
        final tentativeGScore = (gScore[current] ?? double.infinity) + 
                               _getDistance(current, neighbor) * 
                               _getTrafficMultiplier(current, neighbor);

        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = tentativeGScore + _heuristic(neighbor, end);

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }

    return null; // No path found
  }

  /// Find multiple routes using different algorithms
  static List<RouteResult> findMultipleRoutes(String start, String end) {
    final routes = <RouteResult>[];

    // Try all three algorithms
    final dfsRoute = findRouteDFS(start, end);
    if (dfsRoute != null) routes.add(dfsRoute);

    final bfsRoute = findRouteBFS(start, end);
    if (bfsRoute != null) routes.add(bfsRoute);

    final astarRoute = findRouteAStar(start, end);
    if (astarRoute != null) routes.add(astarRoute);

    // Remove duplicate routes and sort by estimated time
    final uniqueRoutes = _removeDuplicateRoutes(routes);
    uniqueRoutes.sort((a, b) => a.estimatedTime.compareTo(b.estimatedTime));

    return uniqueRoutes;
  }

  /// Get nearest node to a coordinate
  static String getNearestNode(LatLng coordinate) {
    String nearestNode = _vadodaraNodes.keys.first;
    double minDistance = double.infinity;

    for (final entry in _vadodaraNodes.entries) {
      final distance = _calculateDistance(coordinate, entry.value);
      if (distance < minDistance) {
        minDistance = distance;
        nearestNode = entry.key;
      }
    }

    return nearestNode;
  }

  /// Generate random routes for vehicle simulation
  static RouteResult generateRandomRoute() {
    final nodes = _vadodaraNodes.keys.toList();
    nodes.shuffle();
    
    final start = nodes[0];
    final end = nodes[1];
    
    // Prefer A* for random routes as it's most realistic
    return findRouteAStar(start, end) ?? 
           findRouteBFS(start, end) ?? 
           RouteResult(
             path: [start, end],
             coordinates: [_vadodaraNodes[start]!, _vadodaraNodes[end]!],
             algorithm: 'Direct',
             distance: _getDistance(start, end),
             estimatedTime: _getDistance(start, end) * 2, // Rough estimate
             routeType: 'Direct Route',
             color: Colors.grey,
           );
  }

  // Helper methods
  static double _heuristic(String a, String b) {
    return _getDistance(a, b);
  }

  static double _getDistance(String a, String b) {
    final coordA = _vadodaraNodes[a];
    final coordB = _vadodaraNodes[b];
    if (coordA == null || coordB == null) return double.infinity;
    return _calculateDistance(coordA, coordB);
  }

  static double _calculateDistance(LatLng a, LatLng b) {
    const double earthRadius = 6371; // km
    final dLat = (b.latitude - a.latitude) * (math.pi / 180);
    final dLon = (b.longitude - a.longitude) * (math.pi / 180);
    final lat1 = a.latitude * (math.pi / 180);
    final lat2 = b.latitude * (math.pi / 180);

    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));

    return earthRadius * c;
  }

  static double _calculatePathDistance(List<String> path) {
    double totalDistance = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      totalDistance += _getDistance(path[i], path[i + 1]);
    }
    return totalDistance;
  }

  static double _calculatePathTime(List<String> path) {
    double totalTime = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      final distance = _getDistance(path[i], path[i + 1]);
      final trafficMultiplier = _getTrafficMultiplier(path[i], path[i + 1]);
      totalTime += distance * trafficMultiplier * 2; // Rough time estimate in minutes
    }
    return totalTime;
  }

  static double _getTrafficMultiplier(String from, String to) {
    final key1 = '$from-$to';
    final key2 = '$to-$from';
    return _trafficConditions[key1] ?? _trafficConditions[key2] ?? 1.0;
  }

  static List<RouteResult> _removeDuplicateRoutes(List<RouteResult> routes) {
    final uniqueRoutes = <RouteResult>[];
    final seenPaths = <String>{};

    for (final route in routes) {
      final pathKey = route.path.join('-');
      if (!seenPaths.contains(pathKey)) {
        seenPaths.add(pathKey);
        uniqueRoutes.add(route);
      }
    }

    return uniqueRoutes;
  }

  /// Get predefined demo routes for specific scenarios
  static List<Map<String, String>> getPredefinedRoutes() {
    return [
      {
        'name': 'Railway Station → Parul University',
        'description': 'Major route from city center to university',
        'start': 'railway_station',
        'end': 'parul_university',
        'category': 'educational',
      },
      {
        'name': 'MS University → Alkapuri',
        'description': 'University to commercial area',
        'start': 'ms_university',
        'end': 'alkapuri',
        'category': 'commercial',
      },
      {
        'name': 'Sayajigunj → Gotri',
        'description': 'Central to residential area',
        'start': 'sayajigunj',
        'end': 'gotri',
        'category': 'residential',
      },
      {
        'name': 'Makarpura → Race Course',
        'description': 'Industrial to entertainment zone',
        'start': 'makarpura',
        'end': 'race_course',
        'category': 'mixed',
      },
      {
        'name': 'Old City → Subhanpura',
        'description': 'Heritage area to modern suburb',
        'start': 'old_city',
        'end': 'subhanpura',
        'category': 'mixed',
      },
      {
        'name': 'Harni → Tandalja',
        'description': 'Cross-city route',
        'start': 'harni',
        'end': 'tandalja',
        'category': 'cross_city',
      },
    ];
  }

  /// Calculate route for a specific predefined scenario
  static List<RouteResult> calculatePredefinedRoute(String routeName) {
    final routes = getPredefinedRoutes();
    final selectedRoute = routes.firstWhere(
      (route) => route['name'] == routeName,
      orElse: () => routes.first,
    );
    
    final start = selectedRoute['start']!;
    final end = selectedRoute['end']!;
    
    return findMultipleRoutes(start, end);
  }

  /// Get all available nodes for UI
  static Map<String, LatLng> getAllNodes() => Map.from(_vadodaraNodes);

  /// Get road network for visualization
  static Map<String, List<String>> getRoadNetwork() => Map.from(_roadNetwork);
}

/// Result of pathfinding operation
class RouteResult {
  final List<String> path;
  final List<LatLng> coordinates;
  final String algorithm;
  final double distance;
  final double estimatedTime;
  final String routeType;
  final Color color;

  RouteResult({
    required this.path,
    required this.coordinates,
    required this.algorithm,
    required this.distance,
    required this.estimatedTime,
    required this.routeType,
    required this.color,
  });

  @override
  String toString() {
    return '$algorithm: ${path.join(' → ')} (${distance.toStringAsFixed(1)}km, ${estimatedTime.toStringAsFixed(1)}min)';
  }
}
