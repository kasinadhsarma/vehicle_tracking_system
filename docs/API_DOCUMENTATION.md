# Vehicle Tracking System - API Documentation

## Table of Contents
1. [API Overview](#api-overview)
2. [Authentication](#authentication)
3. [Vehicle Management](#vehicle-management)
4. [Location Tracking](#location-tracking)
5. [Geofencing](#geofencing)
6. [Driver Management](#driver-management)
7. [Alerts & Notifications](#alerts--notifications)
8. [Reports & Analytics](#reports--analytics)
9. [Real-time Data](#real-time-data)
10. [Error Handling](#error-handling)
11. [Rate Limiting](#rate-limiting)
12. [SDK Examples](#sdk-examples)

---

## API Overview

### Base URL
```
Production: https://api.vehicletracking.com/v1
Development: https://dev-api.vehicletracking.com/v1
```

### API Versioning
The API uses URL versioning. The current version is `v1`.

### Content Type
All API requests and responses use JSON format:
```
Content-Type: application/json
```

### Response Format
All API responses follow a consistent structure:

**Success Response:**
```json
{
  "success": true,
  "data": {
    // Response data
  },
  "message": "Operation completed successfully",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

## Authentication

### Overview
The API uses Firebase Authentication with JWT tokens. All protected endpoints require a valid Bearer token.

### Authentication Header
```
Authorization: Bearer <firebase_jwt_token>
```

### Login
**Endpoint:** `POST /auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "uid": "firebase_user_id",
      "email": "user@example.com",
      "role": "manager",
      "displayName": "John Doe",
      "emailVerified": true
    },
    "token": "firebase_jwt_token",
    "refreshToken": "firebase_refresh_token",
    "expiresIn": 3600
  }
}
```

### Register
**Endpoint:** `POST /auth/register`

**Request Body:**
```json
{
  "email": "newuser@example.com",
  "password": "securePassword123",
  "displayName": "Jane Smith",
  "role": "driver",
  "phoneNumber": "+1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "uid": "firebase_user_id",
      "email": "newuser@example.com",
      "role": "driver",
      "displayName": "Jane Smith",
      "emailVerified": false
    },
    "message": "Verification email sent"
  }
}
```

### Refresh Token
**Endpoint:** `POST /auth/refresh`

**Request Body:**
```json
{
  "refreshToken": "firebase_refresh_token"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "new_firebase_jwt_token",
    "expiresIn": 3600
  }
}
```

### Logout
**Endpoint:** `POST /auth/logout`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully logged out"
}
```

---

## Vehicle Management

### Get All Vehicles
**Endpoint:** `GET /vehicles`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)
- `status` (optional): Filter by status (active, inactive, maintenance)
- `search` (optional): Search by registration number or model

**Example Request:**
```
GET /vehicles?page=1&limit=10&status=active&search=ABC
```

**Response:**
```json
{
  "success": true,
  "data": {
    "vehicles": [
      {
        "id": "vehicle_id_1",
        "registrationNumber": "ABC-123",
        "model": "Toyota Camry",
        "year": 2022,
        "status": "active",
        "driverId": "driver_id_1",
        "driverName": "John Driver",
        "currentLocation": {
          "latitude": 37.7749,
          "longitude": -122.4194,
          "address": "San Francisco, CA",
          "timestamp": "2024-01-15T10:30:00Z"
        },
        "currentSpeed": 45.5,
        "engineStatus": "running",
        "fuelLevel": 75.5,
        "batteryLevel": 98.2,
        "odometer": 15420.5,
        "lastUpdate": "2024-01-15T10:30:00Z",
        "createdAt": "2024-01-01T00:00:00Z",
        "updatedAt": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 48,
      "itemsPerPage": 10,
      "hasNextPage": true,
      "hasPreviousPage": false
    }
  }
}
```

### Get Vehicle by ID
**Endpoint:** `GET /vehicles/{vehicleId}`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "vehicle": {
      "id": "vehicle_id_1",
      "registrationNumber": "ABC-123",
      "model": "Toyota Camry",
      "year": 2022,
      "status": "active",
      "driverId": "driver_id_1",
      "driverName": "John Driver",
      "currentLocation": {
        "latitude": 37.7749,
        "longitude": -122.4194,
        "address": "San Francisco, CA",
        "timestamp": "2024-01-15T10:30:00Z"
      },
      "specifications": {
        "make": "Toyota",
        "model": "Camry",
        "year": 2022,
        "color": "White",
        "engineType": "Hybrid",
        "fuelType": "Gasoline",
        "transmission": "Automatic"
      },
      "maintenance": {
        "lastService": "2024-01-01T00:00:00Z",
        "nextService": "2024-04-01T00:00:00Z",
        "mileageAtLastService": 14500.0
      },
      "insurance": {
        "provider": "ABC Insurance",
        "policyNumber": "POL123456",
        "expiryDate": "2024-12-31T23:59:59Z"
      }
    }
  }
}
```

### Create Vehicle
**Endpoint:** `POST /vehicles`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "registrationNumber": "XYZ-789",
  "make": "Honda",
  "model": "Civic",
  "year": 2023,
  "color": "Blue",
  "engineType": "Gasoline",
  "fuelType": "Gasoline",
  "transmission": "Manual",
  "driverId": "driver_id_2",
  "specifications": {
    "engineCapacity": "1.5L",
    "seatingCapacity": 5,
    "fuelTankCapacity": 50.0
  },
  "insurance": {
    "provider": "XYZ Insurance",
    "policyNumber": "POL789012",
    "expiryDate": "2024-12-31T23:59:59Z"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "vehicle": {
      "id": "vehicle_id_new",
      "registrationNumber": "XYZ-789",
      "make": "Honda",
      "model": "Civic",
      "year": 2023,
      "status": "inactive",
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  },
  "message": "Vehicle created successfully"
}
```

### Update Vehicle
**Endpoint:** `PUT /vehicles/{vehicleId}`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "status": "maintenance",
  "driverId": "new_driver_id",
  "specifications": {
    "color": "Red"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "vehicle": {
      "id": "vehicle_id_1",
      "status": "maintenance",
      "driverId": "new_driver_id",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  },
  "message": "Vehicle updated successfully"
}
```

### Delete Vehicle
**Endpoint:** `DELETE /vehicles/{vehicleId}`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Vehicle deleted successfully"
}
```

---

## Location Tracking

### Update Vehicle Location
**Endpoint:** `POST /vehicles/{vehicleId}/location`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "accuracy": 5.0,
  "altitude": 10.5,
  "heading": 180.0,
  "speed": 45.5,
  "speedAccuracy": 2.0,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "location": {
      "vehicleId": "vehicle_id_1",
      "latitude": 37.7749,
      "longitude": -122.4194,
      "address": "San Francisco, CA",
      "timestamp": "2024-01-15T10:30:00Z"
    }
  },
  "message": "Location updated successfully"
}
```

### Get Vehicle Location History
**Endpoint:** `GET /vehicles/{vehicleId}/location/history`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `startDate`: Start date (ISO 8601 format)
- `endDate`: End date (ISO 8601 format)
- `limit` (optional): Number of records (default: 100, max: 1000)
- `interval` (optional): Time interval (1m, 5m, 15m, 1h) for data aggregation

**Example Request:**
```
GET /vehicles/vehicle_id_1/location/history?startDate=2024-01-15T00:00:00Z&endDate=2024-01-15T23:59:59Z&limit=500&interval=5m
```

**Response:**
```json
{
  "success": true,
  "data": {
    "locations": [
      {
        "latitude": 37.7749,
        "longitude": -122.4194,
        "speed": 45.5,
        "heading": 180.0,
        "accuracy": 5.0,
        "timestamp": "2024-01-15T10:30:00Z"
      },
      {
        "latitude": 37.7750,
        "longitude": -122.4195,
        "speed": 50.0,
        "heading": 185.0,
        "accuracy": 4.0,
        "timestamp": "2024-01-15T10:35:00Z"
      }
    ],
    "summary": {
      "totalPoints": 288,
      "totalDistance": 125.5,
      "averageSpeed": 42.3,
      "maxSpeed": 65.0,
      "duration": 1440
    }
  }
}
```

### Get Real-time Vehicle Locations
**Endpoint:** `GET /vehicles/locations/realtime`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `vehicleIds` (optional): Comma-separated list of vehicle IDs
- `bounds` (optional): Geographic bounds (lat1,lng1,lat2,lng2)

**Example Request:**
```
GET /vehicles/locations/realtime?vehicleIds=vehicle_1,vehicle_2&bounds=37.7,122.4,37.8,122.5
```

**Response:**
```json
{
  "success": true,
  "data": {
    "locations": {
      "vehicle_id_1": {
        "latitude": 37.7749,
        "longitude": -122.4194,
        "speed": 45.5,
        "heading": 180.0,
        "status": "moving",
        "timestamp": "2024-01-15T10:30:00Z"
      },
      "vehicle_id_2": {
        "latitude": 37.7850,
        "longitude": -122.4094,
        "speed": 0.0,
        "heading": 0.0,
        "status": "idle",
        "timestamp": "2024-01-15T10:29:45Z"
      }
    },
    "lastUpdated": "2024-01-15T10:30:00Z"
  }
}
```

---

## Geofencing

### Get All Geofences
**Endpoint:** `GET /geofences`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `active` (optional): Filter by active status (true/false)
- `type` (optional): Filter by type (circle, polygon)

**Response:**
```json
{
  "success": true,
  "data": {
    "geofences": [
      {
        "id": "geofence_id_1",
        "name": "Warehouse Zone",
        "description": "Main warehouse delivery area",
        "type": "circle",
        "active": true,
        "geometry": {
          "center": {
            "latitude": 37.7749,
            "longitude": -122.4194
          },
          "radius": 500
        },
        "rules": {
          "alertOnEntry": true,
          "alertOnExit": true,
          "allowedVehicles": ["vehicle_id_1", "vehicle_id_2"],
          "timeRestrictions": {
            "enabled": true,
            "allowedHours": {
              "start": "08:00",
              "end": "18:00"
            },
            "allowedDays": [1, 2, 3, 4, 5]
          }
        },
        "createdAt": "2024-01-01T00:00:00Z",
        "updatedAt": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

### Create Geofence
**Endpoint:** `POST /geofences`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body (Circle):**
```json
{
  "name": "Customer Site A",
  "description": "Customer delivery location",
  "type": "circle",
  "active": true,
  "geometry": {
    "center": {
      "latitude": 37.7849,
      "longitude": -122.4094
    },
    "radius": 200
  },
  "rules": {
    "alertOnEntry": true,
    "alertOnExit": false,
    "allowedVehicles": ["vehicle_id_1"],
    "speedLimit": 25.0
  }
}
```

**Request Body (Polygon):**
```json
{
  "name": "Restricted Area",
  "description": "No entry zone",
  "type": "polygon",
  "active": true,
  "geometry": {
    "coordinates": [
      [
        {"latitude": 37.7749, "longitude": -122.4194},
        {"latitude": 37.7759, "longitude": -122.4194},
        {"latitude": 37.7759, "longitude": -122.4184},
        {"latitude": 37.7749, "longitude": -122.4184},
        {"latitude": 37.7749, "longitude": -122.4194}
      ]
    ]
  },
  "rules": {
    "alertOnEntry": true,
    "alertOnExit": true,
    "restrictedVehicles": ["all"]
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "geofence": {
      "id": "geofence_id_new",
      "name": "Customer Site A",
      "type": "circle",
      "active": true,
      "createdAt": "2024-01-15T10:30:00Z"
    }
  },
  "message": "Geofence created successfully"
}
```

### Update Geofence
**Endpoint:** `PUT /geofences/{geofenceId}`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "active": false,
  "rules": {
    "alertOnEntry": false,
    "speedLimit": 30.0
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "geofence": {
      "id": "geofence_id_1",
      "active": false,
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  },
  "message": "Geofence updated successfully"
}
```

### Delete Geofence
**Endpoint:** `DELETE /geofences/{geofenceId}`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Geofence deleted successfully"
}
```

### Check Geofence Violations
**Endpoint:** `POST /geofences/check`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "vehicleId": "vehicle_id_1",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "violations": [
      {
        "geofenceId": "geofence_id_1",
        "geofenceName": "Restricted Area",
        "violationType": "entry",
        "vehicleId": "vehicle_id_1",
        "location": {
          "latitude": 37.7749,
          "longitude": -122.4194
        },
        "timestamp": "2024-01-15T10:30:00Z",
        "severity": "high"
      }
    ]
  }
}
```

---

## Driver Management

### Get All Drivers
**Endpoint:** `GET /drivers`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `status` (optional): Filter by status (active, inactive)
- `search` (optional): Search by name or license number

**Response:**
```json
{
  "success": true,
  "data": {
    "drivers": [
      {
        "id": "driver_id_1",
        "userId": "firebase_user_id",
        "firstName": "John",
        "lastName": "Driver",
        "email": "john.driver@example.com",
        "phoneNumber": "+1234567890",
        "licenseNumber": "DL123456789",
        "licenseExpiry": "2025-12-31T23:59:59Z",
        "status": "active",
        "currentVehicleId": "vehicle_id_1",
        "rating": 4.8,
        "totalTrips": 245,
        "totalDistance": 15420.5,
        "joinDate": "2023-01-01T00:00:00Z",
        "lastActive": "2024-01-15T10:30:00Z",
        "emergencyContact": {
          "name": "Jane Driver",
          "phoneNumber": "+1234567891",
          "relationship": "Spouse"
        }
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 25,
      "itemsPerPage": 20
    }
  }
}
```

### Get Driver by ID
**Endpoint:** `GET /drivers/{driverId}`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": "driver_id_1",
      "userId": "firebase_user_id",
      "firstName": "John",
      "lastName": "Driver",
      "email": "john.driver@example.com",
      "phoneNumber": "+1234567890",
      "licenseNumber": "DL123456789",
      "licenseExpiry": "2025-12-31T23:59:59Z",
      "status": "active",
      "currentVehicleId": "vehicle_id_1",
      "rating": 4.8,
      "totalTrips": 245,
      "totalDistance": 15420.5,
      "averageSpeed": 42.3,
      "fuelEfficiency": 12.5,
      "safetyScore": 92,
      "violations": {
        "speeding": 3,
        "harshBraking": 1,
        "rapidAcceleration": 2
      },
      "performance": {
        "onTimeDeliveries": 98.5,
        "customerRating": 4.7,
        "fuelEfficiencyRank": 15
      }
    }
  }
}
```

### Create Driver
**Endpoint:** `POST /drivers`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "jane.smith@example.com",
  "phoneNumber": "+1234567892",
  "licenseNumber": "DL987654321",
  "licenseExpiry": "2026-06-30T23:59:59Z",
  "emergencyContact": {
    "name": "John Smith",
    "phoneNumber": "+1234567893",
    "relationship": "Spouse"
  },
  "address": {
    "street": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zipCode": "94102",
    "country": "USA"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": "driver_id_new",
      "firstName": "Jane",
      "lastName": "Smith",
      "email": "jane.smith@example.com",
      "status": "inactive",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  },
  "message": "Driver created successfully. Invitation email sent."
}
```

### Update Driver
**Endpoint:** `PUT /drivers/{driverId}`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "status": "active",
  "currentVehicleId": "vehicle_id_2",
  "phoneNumber": "+1234567894"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": "driver_id_1",
      "status": "active",
      "currentVehicleId": "vehicle_id_2",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  },
  "message": "Driver updated successfully"
}
```

### Get Driver Performance
**Endpoint:** `GET /drivers/{driverId}/performance`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `startDate`: Start date for performance analysis
- `endDate`: End date for performance analysis
- `metrics` (optional): Comma-separated list of metrics to include

**Response:**
```json
{
  "success": true,
  "data": {
    "performance": {
      "period": {
        "startDate": "2024-01-01T00:00:00Z",
        "endDate": "2024-01-15T23:59:59Z"
      },
      "driving": {
        "totalDistance": 1250.5,
        "totalDrivingTime": 45.5,
        "averageSpeed": 38.2,
        "maxSpeed": 75.0,
        "idleTime": 2.5,
        "fuelEfficiency": 13.2
      },
      "safety": {
        "safetyScore": 88,
        "speedingViolations": 2,
        "harshBrakingEvents": 1,
        "rapidAccelerationEvents": 0,
        "sharpTurnEvents": 3
      },
      "productivity": {
        "tripsCompleted": 15,
        "onTimeDeliveries": 14,
        "averageDeliveryTime": 25.5,
        "customerRating": 4.6
      },
      "trends": {
        "safetyScoreTrend": "improving",
        "fuelEfficiencyTrend": "stable",
        "productivityTrend": "improving"
      }
    }
  }
}
```

---

## Alerts & Notifications

### Get All Alerts
**Endpoint:** `GET /alerts`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `status` (optional): Filter by status (active, acknowledged, resolved)
- `severity` (optional): Filter by severity (low, medium, high, critical)
- `type` (optional): Filter by alert type
- `vehicleId` (optional): Filter by vehicle ID
- `startDate` (optional): Start date filter
- `endDate` (optional): End date filter

**Response:**
```json
{
  "success": true,
  "data": {
    "alerts": [
      {
        "id": "alert_id_1",
        "type": "speed_violation",
        "severity": "high",
        "status": "active",
        "title": "Speed Limit Exceeded",
        "message": "Vehicle ABC-123 exceeded speed limit by 15 km/h",
        "vehicleId": "vehicle_id_1",
        "vehicleRegistration": "ABC-123",
        "driverId": "driver_id_1",
        "driverName": "John Driver",
        "location": {
          "latitude": 37.7749,
          "longitude": -122.4194,
          "address": "Highway 101, San Francisco, CA"
        },
        "data": {
          "currentSpeed": 85.0,
          "speedLimit": 70.0,
          "violation": 15.0
        },
        "timestamp": "2024-01-15T10:30:00Z",
        "acknowledgedBy": null,
        "acknowledgedAt": null,
        "resolvedAt": null
      }
    ],
    "summary": {
      "total": 25,
      "active": 8,
      "acknowledged": 12,
      "resolved": 5,
      "critical": 1,
      "high": 7,
      "medium": 12,
      "low": 5
    }
  }
}
```

### Create Alert
**Endpoint:** `POST /alerts`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "type": "geofence_violation",
  "severity": "medium",
  "title": "Geofence Entry",
  "message": "Vehicle entered restricted area",
  "vehicleId": "vehicle_id_1",
  "driverId": "driver_id_1",
  "location": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "data": {
    "geofenceId": "geofence_id_1",
    "geofenceName": "Restricted Zone",
    "violationType": "entry"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "alert": {
      "id": "alert_id_new",
      "type": "geofence_violation",
      "severity": "medium",
      "status": "active",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  },
  "message": "Alert created successfully"
}
```

### Acknowledge Alert
**Endpoint:** `POST /alerts/{alertId}/acknowledge`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "notes": "Contacted driver, issue resolved"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "alert": {
      "id": "alert_id_1",
      "status": "acknowledged",
      "acknowledgedBy": "manager_user_id",
      "acknowledgedAt": "2024-01-15T10:35:00Z",
      "notes": "Contacted driver, issue resolved"
    }
  },
  "message": "Alert acknowledged successfully"
}
```

### Resolve Alert
**Endpoint:** `POST /alerts/{alertId}/resolve`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "resolution": "Driver counseled on speed limits",
  "preventiveMeasures": "Additional training scheduled"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "alert": {
      "id": "alert_id_1",
      "status": "resolved",
      "resolvedAt": "2024-01-15T10:40:00Z",
      "resolution": "Driver counseled on speed limits"
    }
  },
  "message": "Alert resolved successfully"
}
```

### Send Notification
**Endpoint:** `POST /notifications/send`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "recipients": ["user_id_1", "user_id_2"],
  "title": "Maintenance Reminder",
  "message": "Vehicle ABC-123 is due for maintenance",
  "type": "maintenance",
  "priority": "medium",
  "channels": ["push", "email"],
  "data": {
    "vehicleId": "vehicle_id_1",
    "maintenanceType": "oil_change",
    "dueDate": "2024-01-20T00:00:00Z"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "notification": {
      "id": "notification_id_1",
      "status": "sent",
      "sentAt": "2024-01-15T10:30:00Z",
      "deliveryStatus": {
        "push": "delivered",
        "email": "pending"
      }
    }
  },
  "message": "Notification sent successfully"
}
```

---

## Reports & Analytics

### Generate Report
**Endpoint:** `POST /reports/generate`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "type": "fleet_summary",
  "format": "pdf",
  "parameters": {
    "startDate": "2024-01-01T00:00:00Z",
    "endDate": "2024-01-15T23:59:59Z",
    "vehicleIds": ["vehicle_id_1", "vehicle_id_2"],
    "includeCharts": true,
    "includeDetails": true
  },
  "delivery": {
    "method": "email",
    "recipients": ["manager@example.com"]
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "report": {
      "id": "report_id_1",
      "type": "fleet_summary",
      "status": "generating",
      "estimatedCompletion": "2024-01-15T10:35:00Z",
      "downloadUrl": null
    }
  },
  "message": "Report generation started"
}
```

### Get Report Status
**Endpoint:** `GET /reports/{reportId}/status`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "report": {
      "id": "report_id_1",
      "type": "fleet_summary",
      "status": "completed",
      "progress": 100,
      "generatedAt": "2024-01-15T10:33:00Z",
      "downloadUrl": "https://api.vehicletracking.com/v1/reports/report_id_1/download",
      "expiresAt": "2024-01-22T10:33:00Z",
      "fileSize": 2048576,
      "format": "pdf"
    }
  }
}
```

### Download Report
**Endpoint:** `GET /reports/{reportId}/download`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
Binary file download with appropriate headers:
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="fleet_summary_2024-01-15.pdf"
Content-Length: 2048576
```

### Get Analytics Dashboard
**Endpoint:** `GET /analytics/dashboard`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `period` (optional): Time period (today, week, month, quarter, year)
- `vehicleIds` (optional): Comma-separated list of vehicle IDs

**Response:**
```json
{
  "success": true,
  "data": {
    "dashboard": {
      "period": {
        "startDate": "2024-01-01T00:00:00Z",
        "endDate": "2024-01-15T23:59:59Z"
      },
      "fleet": {
        "totalVehicles": 50,
        "activeVehicles": 48,
        "idleVehicles": 12,
        "maintenanceVehicles": 2,
        "offlineVehicles": 0
      },
      "performance": {
        "totalDistance": 15420.5,
        "totalFuelConsumed": 1250.8,
        "averageFuelEfficiency": 12.3,
        "totalDrivingTime": 850.5,
        "averageSpeed": 42.1
      },
      "safety": {
        "totalAlerts": 25,
        "criticalAlerts": 2,
        "speedingViolations": 8,
        "harshBrakingEvents": 5,
        "geofenceViolations": 3,
        "averageSafetyScore": 87.5
      },
      "trends": {
        "distanceTrend": "increasing",
        "fuelEfficiencyTrend": "stable",
        "safetyTrend": "improving",
        "utilizationTrend": "increasing"
      },
      "charts": {
        "dailyDistance": [
          {"date": "2024-01-01", "distance": 1250.5},
          {"date": "2024-01-02", "distance": 1180.2}
        ],
        "fuelConsumption": [
          {"date": "2024-01-01", "fuel": 95.2},
          {"date": "2024-01-02", "fuel": 88.7}
        ],
        "alertsByType": [
          {"type": "speeding", "count": 8},
          {"type": "harsh_braking", "count": 5}
        ]
      }
    }
  }
}
```

---

## Real-time Data

### WebSocket Connection
**Endpoint:** `wss://api.vehicletracking.com/v1/ws`

**Authentication:**
Send authentication message immediately after connection:
```json
{
  "type": "auth",
  "token": "firebase_jwt_token"
}
```

**Subscribe to Vehicle Locations:**
```json
{
  "type": "subscribe",
  "channel": "vehicle_locations",
  "vehicleIds": ["vehicle_id_1", "vehicle_id_2"]
}
```

**Location Update Message:**
```json
{
  "type": "location_update",
  "vehicleId": "vehicle_id_1",
  "data": {
    "latitude": 37.7749,
    "longitude": -122.4194,
    "speed": 45.5,
    "heading": 180.0,
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

**Subscribe to Alerts:**
```json
{
  "type": "subscribe",
  "channel": "alerts"
}
```

**Alert Message:**
```json
{
  "type": "alert",
  "data": {
    "id": "alert_id_new",
    "type": "speed_violation",
    "severity": "high",
    "vehicleId": "vehicle_id_1",
    "message": "Speed limit exceeded",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

---

## Error Handling

### Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Request validation failed |
| `AUTHENTICATION_ERROR` | Authentication failed |
| `AUTHORIZATION_ERROR` | Insufficient permissions |
| `NOT_FOUND` | Resource not found |
| `CONFLICT` | Resource conflict |
| `RATE_LIMIT_EXCEEDED` | Rate limit exceeded |
| `INTERNAL_ERROR` | Internal server error |
| `SERVICE_UNAVAILABLE` | Service temporarily unavailable |

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": {
      "field": "email",
      "reason": "Invalid email format",
      "value": "invalid-email"
    }
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "requestId": "req_123456789"
}
```

### HTTP Status Codes

| Status | Description |
|--------|-------------|
| `200` | Success |
| `201` | Created |
| `400` | Bad Request |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not Found |
| `409` | Conflict |
| `422` | Unprocessable Entity |
| `429` | Too Many Requests |
| `500` | Internal Server Error |
| `503` | Service Unavailable |

---

## Rate Limiting

### Rate Limits

| Endpoint Category | Limit | Window |
|------------------|-------|---------|
| Authentication | 10 requests | 1 minute |
| Location Updates | 1000 requests | 1 minute |
| General API | 100 requests | 1 minute |
| Report Generation | 5 requests | 1 hour |
| WebSocket Connections | 10 connections | 1 minute |

### Rate Limit Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248600
X-RateLimit-Window: 60
```

### Rate Limit Exceeded Response
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Try again in 30 seconds.",
    "details": {
      "limit": 100,
      "window": 60,
      "retryAfter": 30
    }
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

## SDK Examples

### JavaScript/TypeScript SDK

**Installation:**
```bash
npm install @vehicletracking/sdk
```

**Basic Usage:**
```typescript
import { VehicleTrackingSDK } from '@vehicletracking/sdk';

const sdk = new VehicleTrackingSDK({
  apiKey: 'your_api_key',
  baseUrl: 'https://api.vehicletracking.com/v1'
});

// Authenticate
await sdk.auth.login('user@example.com', 'password');

// Get vehicles
const vehicles = await sdk.vehicles.getAll();

// Update location
await sdk.locations.update('vehicle_id', {
  latitude: 37.7749,
  longitude: -122.4194,
  timestamp: new Date()
});

// Subscribe to real-time updates
sdk.realtime.subscribe('vehicle_locations', (data) => {
  console.log('Location update:', data);
});
```

### Flutter/Dart SDK

**Installation:**
```yaml
dependencies:
  vehicle_tracking_sdk: ^1.0.0
```

**Basic Usage:**
```dart
import 'package:vehicle_tracking_sdk/vehicle_tracking_sdk.dart';

final sdk = VehicleTrackingSDK(
  apiKey: 'your_api_key',
  baseUrl: 'https://api.vehicletracking.com/v1',
);

// Authenticate
await sdk.auth.login('user@example.com', 'password');

// Get vehicles
final vehicles = await sdk.vehicles.getAll();

// Update location
await sdk.locations.update('vehicle_id', LocationUpdate(
  latitude: 37.7749,
  longitude: -122.4194,
  timestamp: DateTime.now(),
));

// Listen to real-time updates
sdk.realtime.vehicleLocations.listen((update) {
  print('Location update: ${update.vehicleId}');
});
```

### Python SDK

**Installation:**
```bash
pip install vehicle-tracking-sdk
```

**Basic Usage:**
```python
from vehicle_tracking_sdk import VehicleTrackingSDK

sdk = VehicleTrackingSDK(
    api_key='your_api_key',
    base_url='https://api.vehicletracking.com/v1'
)

# Authenticate
await sdk.auth.login('user@example.com', 'password')

# Get vehicles
vehicles = await sdk.vehicles.get_all()

# Update location
await sdk.locations.update('vehicle_id', {
    'latitude': 37.7749,
    'longitude': -122.4194,
    'timestamp': datetime.now().isoformat()
})

# Subscribe to real-time updates
@sdk.realtime.on('vehicle_locations')
def handle_location_update(data):
    print(f"Location update: {data['vehicleId']}")
```

---

This API documentation provides comprehensive information for integrating with the Vehicle Tracking System. For additional support or questions, please contact our developer support team.