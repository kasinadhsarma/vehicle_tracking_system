# 12. Installation & Setup Guide

## 12.1 Overview

This comprehensive installation and setup guide provides step-by-step instructions for deploying the Vehicle Tracking System across different environments. The guide covers development setup, staging deployment, and production configuration, ensuring a smooth installation process for developers, system administrators, and end users.

## 12.2 System Requirements

### 12.2.1 Development Environment Requirements

**Software Requirements:**
```bash
# Core Development Tools
Flutter SDK: 3.16.0 or later
Dart SDK: 3.2.0 or later
Git: 2.40.0 or later

# IDE Options
Android Studio: 2023.1 (Hedgehog) or later
VS Code: 1.80 or later with Flutter extensions
IntelliJ IDEA: 2023.2 or later

# Mobile Development
Android SDK: API Level 21+ (Android 5.0)
iOS SDK: iOS 11.0+ (Xcode 12.0+)

# Backend Development
Node.js: 18.x LTS or later
npm: 9.x or later
Firebase CLI: 12.x or later

# Additional Tools
Java JDK: 17 or later
Python: 3.8+ (for build scripts)
Docker: 20.10+ (optional, for containerization)
```

**Hardware Requirements:**
```
Minimum Development Machine:
├── CPU: Intel i5 / AMD Ryzen 5 (4 cores)
├── RAM: 8GB (16GB recommended)
├── Storage: 50GB free space (SSD recommended)
├── Network: Stable internet connection
└── Mobile Device: For testing (Android 5.0+ or iOS 11.0+)

Recommended Development Machine:
├── CPU: Intel i7 / AMD Ryzen 7 (8 cores)
├── RAM: 16GB or more
├── Storage: 100GB+ free space (NVMe SSD)
├── Network: High-speed internet (50+ Mbps)
└── Multiple Devices: Android and iOS for testing
```

### 12.2.2 Production Environment Requirements

**Server Specifications:**
```
Firebase Hosting Requirements:
├── CDN: Global content delivery network
├── SSL: Automatic HTTPS certificates
├── Bandwidth: Pay-per-use, no limits
└── Storage: Up to 10GB included

Cloud Functions Requirements:
├── Memory: 128MB - 8GB per function
├── CPU: Allocated automatically based on memory
├── Timeout: Up to 540 seconds
├── Concurrent Executions: 3,000 default (configurable)
└── Network: Outbound internet access

Database Requirements:
├── Firestore: NoSQL document database
├── Realtime Database: JSON tree structure
├── Storage: Cloud Storage for Firebase
└── Authentication: Firebase Authentication service
```

## 12.3 Development Environment Setup

### 12.3.1 Flutter Development Setup

**Step 1: Install Flutter SDK**
```bash
# Download and install Flutter (macOS/Linux)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"

# Verify installation
flutter --version
flutter doctor

# Install dependencies
flutter doctor --android-licenses

# For Windows, download from https://flutter.dev/docs/get-started/install/windows
```

**Step 2: IDE Configuration**

*VS Code Setup:*
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalLibraries": true,
  "dart.debugSdkLibraries": true,
  "dart.analysisExcludedFolders": [
    "build/**",
    ".dart_tool/**",
    "ios/**",
    "android/**"
  ],
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
      "name": "Flutter Development",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": ["--flavor", "development", "--target", "lib/main.dart"]
    },
    {
      "name": "Flutter Staging",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": ["--flavor", "staging", "--target", "lib/main_staging.dart"]
    },
    {
      "name": "Flutter Production",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": ["--flavor", "production", "--target", "lib/main_production.dart"]
    }
  ]
}
```

*Android Studio Setup:*
```bash
# Install required plugins
Flutter Plugin
Dart Plugin

# Configure SDK paths
File > Settings > Languages & Frameworks > Flutter
Set Flutter SDK path: /path/to/flutter
Set Dart SDK path: /path/to/flutter/bin/cache/dart-sdk
```

**Step 3: Project Clone and Setup**
```bash
# Clone the repository
git clone https://github.com/yourusername/vehicle_tracking_system.git
cd vehicle_tracking_system

# Install Flutter dependencies
flutter pub get

# Generate code (if using code generation)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run code analysis
flutter analyze

# Run tests
flutter test

# Check for any issues
flutter doctor
```

### 12.3.2 Firebase Setup

**Step 1: Create Firebase Project**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project directory
cd vehicle_tracking_system
firebase init

# Select services:
# - Functions
# - Firestore
# - Realtime Database
# - Storage
# - Hosting
# - Authentication
```

**Step 2: Configure Firebase Project**
```bash
# Generate Firebase configuration files
firebase apps:sdkconfig

# For Flutter web
firebase apps:sdkconfig web > web/firebase-config.js

# For Flutter mobile apps, download config files:
# - google-services.json (Android)
# - GoogleService-Info.plist (iOS)
```

**Step 3: Environment Configuration**
```dart
// lib/core/config/firebase_config.dart
class FirebaseConfig {
  static const String developmentProjectId = 'vts-dev-12345';
  static const String stagingProjectId = 'vts-staging-67890';
  static const String productionProjectId = 'vts-prod-11111';
  
  static String get projectId {
    switch (Environment.current) {
      case Environment.development:
        return developmentProjectId;
      case Environment.staging:
        return stagingProjectId;
      case Environment.production:
        return productionProjectId;
    }
  }
}
```

**Firebase Security Rules:**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Organization-based access control
    match /organizations/{orgId} {
      allow read, write: if request.auth != null && 
        (resource.data.adminIds.hasAll([request.auth.uid]) ||
         request.auth.token.organizationId == orgId);
    }
    
    // Vehicle access based on organization membership
    match /vehicles/{vehicleId} {
      allow read: if request.auth != null && 
        (belongsToOrganization(resource.data.organizationId) ||
         resource.data.driverId == request.auth.uid);
      allow write: if request.auth != null && 
        hasRole('manager', 'admin') && 
        belongsToOrganization(resource.data.organizationId);
    }
    
    // Location data access
    match /location_history/{locationId} {
      allow read: if request.auth != null && 
        canAccessVehicle(resource.data.vehicleId);
      allow create: if request.auth != null && 
        isDriverOfVehicle(resource.data.vehicleId);
    }
    
    // Helper functions
    function belongsToOrganization(orgId) {
      return request.auth.token.organizationId == orgId;
    }
    
    function hasRole(role) {
      return request.auth.token.role in [role];
    }
    
    function canAccessVehicle(vehicleId) {
      return get(/databases/$(database)/documents/vehicles/$(vehicleId)).data.organizationId == request.auth.token.organizationId ||
             get(/databases/$(database)/documents/vehicles/$(vehicleId)).data.driverId == request.auth.uid;
    }
  }
}

// database.rules (Realtime Database)
{
  "rules": {
    "live_tracking": {
      "$vehicleId": {
        ".read": "auth != null && (auth.token.organizationId == root.child('vehicles').child($vehicleId).child('organizationId').val() || root.child('vehicles').child($vehicleId).child('driverId').val() == auth.uid)",
        ".write": "auth != null && root.child('vehicles').child($vehicleId).child('driverId').val() == auth.uid"
      }
    }
  }
}

// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images
    match /profile_images/{userId}/{filename} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Vehicle images
    match /vehicle_images/{orgId}/{vehicleId}/{filename} {
      allow read, write: if request.auth != null && 
        request.auth.token.organizationId == orgId &&
        hasRole(['manager', 'admin']);
    }
    
    // Report files
    match /reports/{orgId}/{filename} {
      allow read: if request.auth != null && 
        request.auth.token.organizationId == orgId;
    }
  }
}
```

### 12.3.3 Google Maps API Setup

**Step 1: Enable APIs**
```bash
# Enable required Google Maps APIs in Google Cloud Console:
# - Maps JavaScript API
# - Places API
# - Directions API
# - Geocoding API
# - Distance Matrix API
# - Roads API

# Create API credentials and restrict by:
# - HTTP referrers (for web)
# - Android/iOS apps (for mobile)
```

**Step 2: Configure API Keys**
```yaml
# android/app/src/main/AndroidManifest.xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_ANDROID_API_KEY" />
</application>

# ios/Runner/Info.plist
<dict>
    <key>GOOGLE_MAPS_API_KEY</key>
    <string>YOUR_IOS_API_KEY</string>
</dict>

# web/index.html
<script>
  window.googleMapsApiKey = 'YOUR_WEB_API_KEY';
</script>
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_API_KEY&libraries=places"></script>
```

## 12.4 Build and Deployment

### 12.4.1 Mobile App Build Process

**Android Build:**
```bash
# Debug build
flutter build apk --debug --flavor development

# Release build
flutter build apk --release --flavor production

# App Bundle (recommended for Play Store)
flutter build appbundle --release --flavor production

# Install on device
flutter install --flavor development
```

**iOS Build:**
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Or build from command line
flutter build ios --release --flavor production

# For TestFlight/App Store
flutter build ipa --release --flavor production
```

**Build Configuration:**
```yaml
# android/app/build.gradle
android {
    defaultConfig {
        applicationId "com.yourcompany.vehicletracking"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        debug {
            applicationIdSuffix ".debug"
            versionNameSuffix "-debug"
        }
        release {
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    flavorDimensions "environment"
    productFlavors {
        development {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
        }
        production {
            dimension "environment"
        }
    }
}
```

### 12.4.2 Web Application Deployment

**Build for Web:**
```bash
# Development build
flutter build web --dart-define=ENVIRONMENT=development

# Production build
flutter build web --release --dart-define=ENVIRONMENT=production

# Build with specific target
flutter build web --release --target lib/main_production.dart
```

**Firebase Hosting Deployment:**
```bash
# Configure hosting
firebase init hosting

# Deploy to staging
firebase deploy --only hosting:staging

# Deploy to production
firebase deploy --only hosting:production

# Deploy with specific project
firebase deploy --project production --only hosting
```

**Hosting Configuration:**
```json
// firebase.json
{
  "hosting": [
    {
      "target": "production",
      "public": "build/web",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ],
      "headers": [
        {
          "source": "**/*.@(js|css|html|json|ico|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot)",
          "headers": [
            {
              "key": "Cache-Control",
              "value": "max-age=31536000"
            }
          ]
        }
      ]
    },
    {
      "target": "staging",
      "public": "build/web",
      "site": "vts-staging"
    }
  ]
}
```

### 12.4.3 Cloud Functions Deployment

**Functions Structure:**
```typescript
// functions/src/index.ts
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

// Vehicle location update handler
export const updateVehicleLocation = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const { vehicleId, latitude, longitude, speed, heading, timestamp } = data;
  
  try {
    // Update realtime database
    await admin.database().ref(`live_tracking/${vehicleId}`).set({
      latitude,
      longitude,
      speed,
      heading,
      timestamp: admin.database.ServerValue.TIMESTAMP,
      lastUpdate: new Date().toISOString(),
    });

    // Store in Firestore for history
    await admin.firestore().collection('location_history').add({
      vehicleId,
      latitude,
      longitude,
      speed,
      heading,
      timestamp: admin.firestore.Timestamp.fromDate(new Date(timestamp)),
      userId: context.auth.uid,
    });

    return { success: true };
  } catch (error) {
    console.error('Error updating location:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update location');
  }
});

// Generate reports function
export const generateReport = functions.https.onCall(async (data, context) => {
  // Implementation for report generation
  // ...
});

// Geofence monitoring
export const monitorGeofences = functions.database
  .ref('live_tracking/{vehicleId}')
  .onUpdate(async (change, context) => {
    // Geofence violation detection logic
    // ...
  });
```

**Deploy Functions:**
```bash
# Install dependencies
cd functions
npm install

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:updateVehicleLocation

# Set environment variables
firebase functions:config:set maps.api_key="YOUR_API_KEY"
firebase functions:config:set app.environment="production"
```

## 12.5 Production Deployment Guide

### 12.5.1 Pre-deployment Checklist

**Security Configuration:**
```bash
# 1. Update Firebase Security Rules
firebase deploy --only firestore:rules
firebase deploy --only database:rules
firebase deploy --only storage:rules

# 2. Configure API restrictions
# - Restrict API keys by domain/app
# - Enable only required APIs
# - Set up quotas and limits

# 3. Enable monitoring and logging
# - Firebase Performance Monitoring
# - Firebase Crashlytics
# - Google Cloud Logging
```

**Performance Optimization:**
```bash
# 1. Enable compression
# 2. Configure CDN
# 3. Optimize images and assets
# 4. Minify JavaScript and CSS
# 5. Enable HTTP/2 and HTTPS
```

### 12.5.2 Database Migration

**Data Migration Script:**
```typescript
// scripts/migrate-data.ts
import * as admin from 'firebase-admin';

const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://your-project.firebaseio.com'
});

async function migrateVehicleData() {
  const firestore = admin.firestore();
  const batch = firestore.batch();
  
  try {
    // Example migration: Add new field to existing documents
    const vehicles = await firestore.collection('vehicles').get();
    
    vehicles.forEach(doc => {
      const vehicleRef = firestore.collection('vehicles').doc(doc.id);
      batch.update(vehicleRef, {
        status: 'active', // Add default status
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });
    
    await batch.commit();
    console.log('Migration completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
  }
}

migrateVehicleData();
```

### 12.5.3 Monitoring and Alerting Setup

**Firebase Monitoring Configuration:**
```javascript
// Enable Performance Monitoring
import { getPerformance } from 'firebase/performance';
const perf = getPerformance(app);

// Custom traces
const trace = perf.trace('location_update');
trace.start();
// ... perform location update
trace.stop();

// Enable Crashlytics
import { getApp } from 'firebase/app';
import { getFunctions } from 'firebase/functions';
import { getCrashlytics } from 'firebase/crashlytics';

const crashlytics = getCrashlytics(getApp());
crashlytics.log('App started successfully');
```

**Alerting Configuration:**
```yaml
# monitoring/alerts.yaml
alertPolicy:
  displayName: "Vehicle Tracking System Alerts"
  conditions:
    - displayName: "High Error Rate"
      conditionThreshold:
        filter: 'resource.type="cloud_function"'
        comparison: COMPARISON_GREATER_THAN
        thresholdValue: 0.05
    - displayName: "High Response Time"
      conditionThreshold:
        filter: 'resource.type="https_lb_rule"'
        comparison: COMPARISON_GREATER_THAN
        thresholdValue: 1000
  notificationChannels:
    - "projects/your-project/notificationChannels/your-channel-id"
```

## 12.6 User Setup and Onboarding

### 12.6.1 Admin User Creation

**Initial Admin Setup:**
```bash
# Create admin user via Firebase Console or CLI
firebase auth:import admin-users.json --project your-project-id

# Or create programmatically
node scripts/create-admin.js
```

```typescript
// scripts/create-admin.ts
import * as admin from 'firebase-admin';

async function createAdminUser(email: string, password: string, organizationId: string) {
  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      emailVerified: true,
    });

    // Set custom claims
    await admin.auth().setCustomUserClaims(userRecord.uid, {
      role: 'admin',
      organizationId,
    });

    // Create user profile
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      name: 'System Administrator',
      email,
      role: 'admin',
      organizationId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
    });

    console.log('Admin user created successfully:', userRecord.uid);
  } catch (error) {
    console.error('Error creating admin user:', error);
  }
}
```

### 12.6.2 Organization Setup

**Organization Creation Script:**
```typescript
// scripts/setup-organization.ts
async function createOrganization(orgData: {
  name: string;
  adminEmail: string;
  settings: any;
}) {
  const firestore = admin.firestore();
  
  try {
    // Create organization document
    const orgRef = await firestore.collection('organizations').add({
      name: orgData.name,
      settings: orgData.settings,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
    });

    // Create initial admin user
    await createAdminUser(orgData.adminEmail, 'temp-password', orgRef.id);

    console.log('Organization created:', orgRef.id);
    return orgRef.id;
  } catch (error) {
    console.error('Error creating organization:', error);
    throw error;
  }
}
```

### 12.6.3 Mobile App Distribution

**Android Distribution:**
```bash
# Google Play Console
# 1. Upload AAB file
# 2. Configure store listing
# 3. Set up release management
# 4. Submit for review

# Internal testing
./gradlew bundleRelease
# Upload to Play Console internal testing track
```

**iOS Distribution:**
```bash
# App Store Connect
# 1. Archive app in Xcode
# 2. Upload to App Store Connect
# 3. Configure app information
# 4. Submit for review

# TestFlight
# Upload build and invite testers
```

## 12.7 Troubleshooting Guide

### 12.7.1 Common Issues and Solutions

**Build Issues:**
```bash
# Flutter doctor issues
flutter doctor --android-licenses
flutter clean && flutter pub get
flutter upgrade

# Gradle build failures
cd android && ./gradlew clean
flutter build apk --no-shrink

# iOS build issues
cd ios && pod install
flutter build ios --no-codesign
```

**Firebase Connection Issues:**
```dart
// Check Firebase initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  runApp(MyApp());
}
```

**Location Permission Issues:**
```dart
// Handle location permissions properly
Future<bool> checkLocationPermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();
  
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Show settings dialog
    await openAppSettings();
    return false;
  }
  
  return permission == LocationPermission.whileInUse || 
         permission == LocationPermission.always;
}
```

### 12.7.2 Performance Optimization

**Mobile App Optimization:**
```dart
// Optimize location updates
const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 10, // Only update if moved 10 meters
  timeLimit: Duration(seconds: 30),
);

// Optimize map rendering
GoogleMap(
  onMapCreated: (controller) => _mapController = controller,
  liteModeEnabled: true, // For better performance
  trafficEnabled: false, // Disable if not needed
  buildingsEnabled: false, // Reduce rendering complexity
  myLocationButtonEnabled: false, // Custom implementation
);

// Optimize Firebase queries
Query query = FirebaseFirestore.instance
    .collection('vehicles')
    .where('organizationId', isEqualTo: orgId)
    .limit(20); // Limit results
```

## 12.8 Backup and Recovery

### 12.8.1 Data Backup Strategy

**Automated Backup Setup:**
```bash
# Schedule Firestore exports
gcloud firestore export gs://your-backup-bucket/firestore-backups/$(date +%Y%m%d)

# Automate with Cloud Scheduler
gcloud scheduler jobs create http firestore-backup \
    --schedule="0 2 * * *" \
    --uri="https://your-region-your-project.cloudfunctions.net/exportFirestore"
```

**Backup Function:**
```typescript
// functions/src/backup.ts
import { firestore } from 'firebase-admin';

export const exportFirestore = functions.pubsub
  .schedule('0 2 * * *') // Daily at 2 AM
  .onRun(async (context) => {
    const client = new firestore.v1.FirestoreAdminClient();
    const projectId = process.env.GOOGLE_CLOUD_PROJECT;
    const databaseName = client.databasePath(projectId, '(default)');
    
    return client.exportDocuments({
      name: databaseName,
      outputUriPrefix: `gs://${projectId}-backups/firestore-${Date.now()}`,
      collectionIds: [], // Export all collections
    });
  });
```

### 12.8.2 Disaster Recovery Plan

**Recovery Procedures:**
```bash
# Restore from backup
gcloud firestore import gs://your-backup-bucket/firestore-backups/20231201

# Database rollback
firebase database:set / backup-data.json --project your-project

# Application rollback
firebase hosting:rollback --project your-project
```

This comprehensive installation and setup guide ensures smooth deployment and operation of the Vehicle Tracking System across all environments and platforms.
