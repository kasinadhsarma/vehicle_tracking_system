import 'package:flutter/material.dart';
import '../live_tracking/live_tracking_widget.dart';

/// Simple map page that uses the live tracking widget
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveTrackingWidget(
      showControls: true,
      showStats: true,
    );
  }
}
