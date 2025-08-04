vehicle_tracking_system/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart
│   │   ├── services/
│   │   │   ├── firebase_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── geofence_service.dart
│   │   │   └── auth_service.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   └── formatters.dart
│   │   └── models/
│   │       ├── user_model.dart
│   │       ├── location_model.dart
│   │       ├── trip_model.dart
│   │       ├── alert_model.dart
│   │       └── geofence_model.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── views/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── role_selector_screen.dart
│   │   │   └── controllers/
│   │   │       └── auth_controller.dart
│   │   ├── driver/
│   │   │   ├── views/
│   │   │   │   ├── driver_home_screen.dart
│   │   │   │   ├── live_tracking_screen.dart
│   │   │   │   └── profile_screen.dart
│   │   │   └── controllers/
│   │   │       ├── driver_tracking_controller.dart
│   │   │       └── trip_controller.dart
│   │   ├── manager/
│   │   │   ├── views/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   ├── vehicle_detail_screen.dart
│   │   │   │   └── map_overview_screen.dart
│   │   │   └── controllers/
│   │   │       └── fleet_controller.dart
│   │   ├── geofence/
│   │   │   ├── views/
│   │   │   │   └── geofence_editor_screen.dart
│   │   │   └── controllers/
│   │   │       └── geofence_controller.dart
│   │   ├── alerts/
│   │   │   ├── views/
│   │   │   │   └── alerts_screen.dart
│   │   │   └── controllers/
│   │   │       └── alert_controller.dart
│   │   └── reports/
│   │       ├── views/
│   │       │   └── reports_screen.dart
│   │       └── controllers/
│   │           └── report_controller.dart
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── custom_app_bar.dart
│   │   │   ├── drawer_menu.dart
│   │   │   └── location_status_widget.dart
│   │   └── themes/
│   │       └── app_theme.dart
│   └── routes/
│       └── app_routes.dart
├── test/
│   ├── auth/
│   ├── driver/
│   ├── manager/
│   └── core/
├── web/
│   ├── index.html
│   └── manifest.json
├── pubspec.yaml
├── .gitignore
├── README.md
└── analysis_options.yaml
