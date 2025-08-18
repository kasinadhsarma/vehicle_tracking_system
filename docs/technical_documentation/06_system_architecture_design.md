# 6. System Architecture & Design

## 6.1 Overview

This chapter presents the comprehensive system architecture and design decisions for the Vehicle Tracking System. The architecture is designed to support high scalability, real-time performance, and cross-platform consistency while maintaining cost-effectiveness and ease of maintenance.

## 6.2 High-Level System Architecture

### 6.2.1 Architectural Principles

**Design Principles:**
1. **Single Source of Truth**: Centralized data management with Firebase
2. **Real-Time First**: Architecture optimized for real-time data flow
3. **Mobile-First Design**: Primary focus on mobile user experience
4. **Cloud-Native Architecture**: Leveraging serverless and managed services
5. **Cross-Platform Consistency**: Unified codebase with Flutter framework

### 6.2.2 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                               Client Layer                                   │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────┤
│   Mobile App    │  Web Dashboard  │  Desktop App    │   External Clients      │
│   (Flutter)     │   (Flutter)     │   (Flutter)     │   (REST API)            │
│                 │                 │                 │                         │
│ • GPS Tracking  │ • Fleet Monitor │ • Admin Panel   │ • Third-party Apps      │
│ • Navigation    │ • Analytics     │ • System Config │ • Mobile Integrations   │
│ • Driver UI     │ • Reporting     │ • User Mgmt     │ • Web Integrations      │
└─────────────────┴─────────────────┴─────────────────┴─────────────────────────┘
                                        │
                              ┌─────────────────────┐
                              │    API Gateway      │
                              │  (Firebase Cloud)   │
                              │    Functions        │
                              └─────────────────────┘
                                        │
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Service Layer                                   │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────┤
│  Authentication │  Data Services  │  Geospatial     │  Communication          │
│  Service        │                 │  Services       │  Services               │
│                 │                 │                 │                         │
│ • Firebase Auth │ • Cloud Firestore│ • Google Maps  │ • FCM Notifications     │
│ • Multi-Role    │ • Realtime DB   │ • Directions API│ • WebSocket Connections │
│ • Session Mgmt  │ • Cloud Storage │ • Geocoding API │ • Email Services        │
└─────────────────┴─────────────────┴─────────────────┴─────────────────────────┘
                                        │
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Infrastructure Layer                              │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────┤
│  Data Storage   │  Processing     │  Monitoring     │  Security               │
│                 │                 │                 │                         │
│ • Firebase      │ • Cloud         │ • Error         │ • Identity & Access     │
│   Databases     │   Functions     │   Reporting     │   Management            │
│ • Cloud Storage │ • Scheduled     │ • Performance   │ • Data Encryption       │
│ • Backup Systems│   Tasks         │   Monitoring    │ • Network Security      │
└─────────────────┴─────────────────┴─────────────────┴─────────────────────────┘
```

### 6.2.3 Technology Stack

**Frontend Technologies:**
```yaml
Mobile/Web/Desktop: Flutter 3.x
Programming Language: Dart
State Management: Riverpod
Navigation: GoRouter
Local Storage: Hive/SharedPreferences
Maps: Google Maps Flutter Plugin
```

**Backend Technologies:**
```yaml
Backend-as-a-Service: Firebase
Authentication: Firebase Authentication
Database: Cloud Firestore + Realtime Database
Functions: Cloud Functions for Firebase
Storage: Firebase Cloud Storage
Messaging: Firebase Cloud Messaging (FCM)
```

**External Services:**
```yaml
Mapping: Google Maps Platform
Geocoding: Google Geocoding API
Directions: Google Directions API
Analytics: Firebase Analytics
Monitoring: Firebase Crashlytics
```

## 6.3 Detailed Component Architecture

### 6.3.1 Client Architecture (Flutter)

**Application Structure:**
```
lib/
├── core/
│   ├── config/          # App configuration
│   ├── constants/       # App constants
│   ├── models/          # Data models
│   ├── services/        # Core services
│   ├── utils/           # Utility functions
│   └── theme/           # UI theme
├── features/
│   ├── auth/            # Authentication
│   ├── dashboard/       # Dashboard screens
│   ├── live_tracking/   # Real-time tracking
│   ├── vehicles/        # Vehicle management
│   ├── driver/          # Driver features
│   ├── manager/         # Manager features
│   ├── reports/         # Reporting
│   ├── maps/            # Map features
│   ├── geofence/        # Geofencing
│   ├── alerts/          # Alert system
│   └── route_planning/  # Route optimization
├── shared/
│   ├── widgets/         # Reusable widgets
│   └── themes/          # Shared themes
└── routes/
    └── app_routes.dart  # Application routing
```

**State Management Architecture:**
```dart
// Provider-based State Management
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     View        │    │   ViewModel     │    │   Repository    │
│   (Widgets)     │───▶│  (Providers)    │───▶│   (Services)    │
│                 │    │                 │    │                 │
│ • UI Components │    │ • Business      │    │ • Data Sources  │
│ • User Input    │    │   Logic         │    │ • API Calls     │
│ • State Display │    │ • State Mgmt    │    │ • Local Storage │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 6.3.2 Backend Architecture (Firebase)

**Service-Oriented Architecture:**

**Authentication Service:**
```javascript
// Firebase Authentication Structure
{
  "providers": ["email", "google", "phone"],
  "customClaims": {
    "role": "driver|manager|admin",
    "permissions": ["read", "write", "admin"],
    "organizationId": "org_uuid"
  },
  "security": {
    "multiFactorAuth": true,
    "sessionTimeout": 3600
  }
}
```

**Data Services:**
```javascript
// Cloud Firestore Structure
{
  "organizations": {
    "orgId": {
      "name": "string",
      "settings": {},
      "createdAt": "timestamp"
    }
  },
  "vehicles": {
    "vehicleId": {
      "licensePlate": "string",
      "make": "string",
      "model": "string",
      "organizationId": "string",
      "driverId": "string",
      "status": "active|inactive|maintenance"
    }
  },
  "locations": {
    "locationId": {
      "vehicleId": "string",
      "latitude": "number",
      "longitude": "number",
      "timestamp": "timestamp",
      "speed": "number",
      "heading": "number"
    }
  }
}

// Firebase Realtime Database Structure (Real-time tracking)
{
  "live_tracking": {
    "vehicleId": {
      "location": {
        "lat": 0.0,
        "lng": 0.0,
        "timestamp": 0,
        "speed": 0,
        "heading": 0
      },
      "status": "moving|stopped|offline"
    }
  }
}
```

### 6.3.3 API Gateway Architecture

**Cloud Functions Structure:**
```typescript
// API Gateway Implementation
export const api = functions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  // Route handling
  switch (data.action) {
    case 'updateLocation':
      return await updateVehicleLocation(data, context);
    case 'getFleetStatus':
      return await getFleetStatus(data, context);
    case 'generateReport':
      return await generateReport(data, context);
    default:
      throw new functions.https.HttpsError('invalid-argument', 'Unknown action');
  }
});
```

**Microservice Functions:**
```
functions/
├── auth/
│   ├── userManagement.ts
│   └── roleManagement.ts
├── tracking/
│   ├── locationUpdates.ts
│   └── geofencing.ts
├── analytics/
│   ├── reportGeneration.ts
│   └── dataProcessing.ts
├── notifications/
│   ├── alertSystem.ts
│   └── pushNotifications.ts
└── integrations/
    ├── mapsIntegration.ts
    └── externalAPIs.ts
```

## 6.4 Data Architecture

### 6.4.1 Database Design

**Multi-Database Strategy:**

**Cloud Firestore (Primary Database):**
- User profiles and authentication data
- Vehicle information and metadata
- Historical tracking data and analytics
- Reports and generated documents
- System configuration and settings

**Realtime Database (Real-time Operations):**
- Live vehicle locations and status
- Real-time driver communications
- Active alerts and notifications
- Live dashboard data feeds

**Data Modeling Strategy:**

```typescript
// Core Data Models
interface Vehicle {
  id: string;
  organizationId: string;
  licensePlate: string;
  make: string;
  model: string;
  year: number;
  driverId?: string;
  status: 'active' | 'inactive' | 'maintenance';
  metadata: VehicleMetadata;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface LocationUpdate {
  id: string;
  vehicleId: string;
  latitude: number;
  longitude: number;
  accuracy: number;
  speed: number;
  heading: number;
  timestamp: Timestamp;
  address?: string;
}

interface Driver {
  id: string;
  organizationId: string;
  name: string;
  email: string;
  phone: string;
  licenseNumber: string;
  status: 'active' | 'inactive' | 'suspended';
  assignedVehicles: string[];
  createdAt: Timestamp;
}
```

### 6.4.2 Geospatial Data Optimization

**GeoHashing for Location Indexing:**
```typescript
// Geospatial Query Optimization
interface GeoPoint {
  latitude: number;
  longitude: number;
  geohash: string; // For efficient spatial queries
}

// Geofence Definition
interface Geofence {
  id: string;
  name: string;
  organizationId: string;
  type: 'circle' | 'polygon';
  coordinates: GeoPoint[];
  radius?: number; // For circular geofences
  alerts: GeofenceAlert[];
}
```

**Spatial Indexing Strategy:**
- GeoHash implementation for spatial queries
- Grid-based indexing for map tile optimization
- R-tree indexing for complex polygon geofences
- Distance-based queries for proximity searches

## 6.5 Real-Time Architecture

### 6.5.1 Real-Time Data Flow

**Location Update Pipeline:**
```
Mobile GPS → Local Processing → Network Layer → Firebase Functions → Database Update → Real-time Listeners → UI Update
```

**Detailed Flow Implementation:**
```typescript
// Real-time Location Service
class LocationService {
  private realtimeDB = firebase.database();
  private firestoreDB = firebase.firestore();

  async updateLocation(vehicleId: string, location: LocationData) {
    // Real-time update for live tracking
    await this.realtimeDB
      .ref(`live_tracking/${vehicleId}`)
      .set({
        ...location,
        lastUpdate: firebase.database.ServerValue.TIMESTAMP
      });

    // Historical data storage
    await this.firestoreDB
      .collection('location_history')
      .add({
        vehicleId,
        ...location,
        timestamp: firebase.firestore.FieldValue.serverTimestamp()
      });
  }

  subscribeToVehicleLocation(vehicleId: string, callback: (data: LocationData) => void) {
    return this.realtimeDB
      .ref(`live_tracking/${vehicleId}`)
      .on('value', (snapshot) => {
        callback(snapshot.val());
      });
  }
}
```

### 6.5.2 WebSocket and Streaming

**Real-Time Communication Architecture:**
```typescript
// WebSocket Service Implementation
class RealtimeService {
  private connection: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;

  connect() {
    this.connection = new WebSocket('wss://your-domain.com/realtime');
    
    this.connection.onopen = () => {
      this.reconnectAttempts = 0;
      this.subscribeToChannels();
    };

    this.connection.onmessage = (event) => {
      this.handleMessage(JSON.parse(event.data));
    };

    this.connection.onclose = () => {
      this.handleReconnection();
    };
  }

  private subscribeToChannels() {
    const subscriptions = [
      { channel: 'vehicle_locations', filter: { organizationId: this.orgId } },
      { channel: 'alerts', filter: { userId: this.userId } },
      { channel: 'system_notifications', filter: {} }
    ];

    subscriptions.forEach(sub => {
      this.send({ type: 'subscribe', ...sub });
    });
  }
}
```

## 6.6 Security Architecture

### 6.6.1 Authentication and Authorization

**Multi-Layer Security Model:**
```
User Authentication → Role-Based Access Control → Resource-Level Permissions → Data Encryption
```

**Firebase Security Rules:**
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Organization-based access control
    match /organizations/{orgId} {
      allow read, write: if isAuthenticated() && 
                        (resource.data.adminIds.hasAll([request.auth.uid]) ||
                         hasRole('admin'));
    }

    // Vehicle access control
    match /vehicles/{vehicleId} {
      allow read: if isAuthenticated() && 
                  (belongsToOrganization(resource.data.organizationId) ||
                   resource.data.driverId == request.auth.uid);
      allow write: if isAuthenticated() && 
                   hasRole('manager') && 
                   belongsToOrganization(resource.data.organizationId);
    }

    // Location data access
    match /locations/{locationId} {
      allow read: if isAuthenticated() && 
                  canAccessVehicle(resource.data.vehicleId);
      allow create: if isAuthenticated() && 
                    isDriverOfVehicle(resource.data.vehicleId);
    }

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function hasRole(role) {
      return request.auth.token.role == role;
    }

    function belongsToOrganization(orgId) {
      return request.auth.token.organizationId == orgId;
    }
  }
}
```

### 6.6.2 Data Protection

**Encryption Strategy:**
- **Data at Rest**: Firebase default encryption + application-level encryption for sensitive data
- **Data in Transit**: TLS 1.3 for all communications
- **Application Level**: AES-256 encryption for PII data
- **Key Management**: Firebase App Check + custom key rotation

**Privacy Implementation:**
```typescript
// Data Anonymization Service
class PrivacyService {
  async anonymizeLocationData(locationData: LocationData[]): Promise<AnonymizedLocationData[]> {
    return locationData.map(data => ({
      ...data,
      // Remove or hash personally identifiable information
      vehicleId: this.hashId(data.vehicleId),
      driverId: undefined, // Remove driver association
      timestamp: this.fuzzyTimestamp(data.timestamp),
      location: this.fuzzyLocation(data.latitude, data.longitude)
    }));
  }

  private hashId(id: string): string {
    return crypto.createHash('sha256').update(id).digest('hex').substring(0, 16);
  }

  private fuzzyLocation(lat: number, lng: number, precision: number = 0.01): GeoPoint {
    return {
      latitude: Math.round(lat / precision) * precision,
      longitude: Math.round(lng / precision) * precision
    };
  }
}
```

## 6.7 Performance Architecture

### 6.7.1 Caching Strategy

**Multi-Level Caching:**
```
Client Cache (Hive/SharedPreferences) → CDN Cache → Database Cache → Application Cache
```

**Implementation Strategy:**
```typescript
// Caching Service
class CacheService {
  private localCache = new Map<string, CacheItem>();
  private cacheTimeout = 5 * 60 * 1000; // 5 minutes

  async get<T>(key: string, fetcher: () => Promise<T>): Promise<T> {
    // Check local cache first
    const cached = this.localCache.get(key);
    if (cached && !this.isExpired(cached)) {
      return cached.data as T;
    }

    // Fetch from source and cache
    const data = await fetcher();
    this.set(key, data);
    return data;
  }

  set<T>(key: string, data: T, ttl?: number): void {
    this.localCache.set(key, {
      data,
      timestamp: Date.now(),
      ttl: ttl || this.cacheTimeout
    });
  }

  private isExpired(item: CacheItem): boolean {
    return Date.now() - item.timestamp > item.ttl;
  }
}
```

### 6.7.2 Scalability Design

**Horizontal Scaling Architecture:**
```
Load Balancer → Multiple App Instances → Shared Database Layer → CDN Distribution
```

**Auto-Scaling Configuration:**
```yaml
# Firebase Functions Auto-scaling
functions:
  memory: 512MB
  timeout: 60s
  minInstances: 2
  maxInstances: 100
  concurrency: 1000
  
  triggers:
    - https: true
    - database: 
        path: /live_tracking/{vehicleId}
        event: write
```

## 6.8 Integration Architecture

### 6.8.1 External Service Integration

**Google Maps Platform Integration:**
```typescript
// Maps Service Abstraction
interface MapsService {
  initializeMap(element: HTMLElement, options: MapOptions): Promise<Map>;
  addMarker(map: Map, position: LatLng, options: MarkerOptions): Marker;
  calculateRoute(origin: LatLng, destination: LatLng): Promise<Route>;
  geocodeAddress(address: string): Promise<LatLng>;
  reverseGeocode(position: LatLng): Promise<Address>;
}

class GoogleMapsService implements MapsService {
  private apiKey: string;
  private maps: typeof google.maps;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async initializeMap(element: HTMLElement, options: MapOptions): Promise<Map> {
    if (!this.maps) {
      await this.loadGoogleMapsAPI();
    }

    return new this.maps.Map(element, {
      zoom: options.zoom || 10,
      center: options.center,
      mapTypeId: options.mapType || 'roadmap',
      styles: options.customStyles
    });
  }

  async calculateRoute(origin: LatLng, destination: LatLng): Promise<Route> {
    const directionsService = new this.maps.DirectionsService();
    
    return new Promise((resolve, reject) => {
      directionsService.route({
        origin: origin,
        destination: destination,
        travelMode: this.maps.TravelMode.DRIVING,
        optimizeWaypoints: true
      }, (result, status) => {
        if (status === 'OK') {
          resolve(this.parseDirectionsResult(result));
        } else {
          reject(new Error(`Directions request failed: ${status}`));
        }
      });
    });
  }
}
```

### 6.8.2 API Design

**RESTful API Structure:**
```typescript
// API Route Definitions
const apiRoutes = {
  // Authentication
  'POST /auth/login': authController.login,
  'POST /auth/logout': authController.logout,
  'POST /auth/refresh': authController.refreshToken,

  // Vehicles
  'GET /vehicles': vehicleController.list,
  'POST /vehicles': vehicleController.create,
  'GET /vehicles/:id': vehicleController.get,
  'PUT /vehicles/:id': vehicleController.update,
  'DELETE /vehicles/:id': vehicleController.delete,

  // Tracking
  'POST /tracking/location': trackingController.updateLocation,
  'GET /tracking/vehicle/:id/current': trackingController.getCurrentLocation,
  'GET /tracking/vehicle/:id/history': trackingController.getLocationHistory,

  // Analytics
  'GET /analytics/dashboard': analyticsController.getDashboard,
  'POST /analytics/reports': analyticsController.generateReport,
  'GET /analytics/reports/:id': analyticsController.getReport,

  // Geofences
  'GET /geofences': geofenceController.list,
  'POST /geofences': geofenceController.create,
  'PUT /geofences/:id': geofenceController.update,
  'DELETE /geofences/:id': geofenceController.delete
};
```

**GraphQL Schema (Alternative):**
```graphql
type Vehicle {
  id: ID!
  licensePlate: String!
  make: String!
  model: String!
  year: Int!
  driver: Driver
  currentLocation: Location
  status: VehicleStatus!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Location {
  id: ID!
  latitude: Float!
  longitude: Float!
  accuracy: Float!
  speed: Float!
  heading: Float!
  address: String
  timestamp: DateTime!
}

type Query {
  vehicles(organizationId: ID!): [Vehicle!]!
  vehicle(id: ID!): Vehicle
  vehicleLocations(vehicleId: ID!, from: DateTime, to: DateTime): [Location!]!
  liveTracking(vehicleIds: [ID!]!): [Vehicle!]!
}

type Mutation {
  updateLocation(vehicleId: ID!, location: LocationInput!): Location!
  createGeofence(input: GeofenceInput!): Geofence!
  triggerAlert(vehicleId: ID!, alertType: AlertType!, message: String!): Alert!
}

type Subscription {
  vehicleLocationUpdated(vehicleId: ID!): Location!
  alertTriggered(organizationId: ID!): Alert!
  fleetStatusChanged(organizationId: ID!): FleetStatus!
}
```

This comprehensive system architecture provides a solid foundation for building a scalable, maintainable, and high-performance vehicle tracking system using modern cloud-native technologies and best practices.
