import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';
import '../config/google_api_config.dart';
import '../constants/app_colors.dart';

class PDFService {
  static PDFService? _instance;
  static PDFService get instance => _instance ??= PDFService._();
  
  PDFService._();

  // Generate Trip Report PDF
  Future<Uint8List> generateTripReport({
    required TripModel trip,
    required List<LocationModel> locations,
    required VehicleModel vehicle,
    required UserModel driver,
    String? logoPath,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    // Load logo if provided
    pw.ImageProvider? logo;
    if (logoPath != null) {
      try {
        final logoFile = File(logoPath);
        if (await logoFile.exists()) {
          logo = pw.MemoryImage(await logoFile.readAsBytes());
        }
      } catch (e) {
        debugPrint('Error loading logo: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildTripReportHeader(logo),
        build: (context) => [
          _buildTripSummary(trip, vehicle, driver, dateFormat),
          pw.SizedBox(height: 20),
          _buildTripDetails(trip, dateFormat),
          pw.SizedBox(height: 20),
          _buildLocationTable(locations, dateFormat),
          pw.SizedBox(height: 20),
          _buildTripStatistics(trip, locations),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  // Generate Vehicle Document PDF
  Future<Uint8List> generateVehicleDocument({
    required VehicleModel vehicle,
    required UserModel driver,
    String? logoPath,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    pw.ImageProvider? logo;
    if (logoPath != null) {
      try {
        final logoFile = File(logoPath);
        if (await logoFile.exists()) {
          logo = pw.MemoryImage(await logoFile.readAsBytes());
        }
      } catch (e) {
        debugPrint('Error loading logo: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildVehicleDocumentHeader(logo),
            pw.SizedBox(height: 30),
            _buildVehicleInfo(vehicle, dateFormat),
            pw.SizedBox(height: 20),
            _buildDriverInfo(driver),
            pw.SizedBox(height: 30),
            _buildVehicleSpecs(vehicle),
            pw.Spacer(),
            _buildDocumentFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // Generate Fleet Summary Report
  Future<Uint8List> generateFleetSummary({
    required List<VehicleModel> vehicles,
    required Map<String, List<TripModel>> vehicleTrips,
    required DateTime startDate,
    required DateTime endDate,
    String? logoPath,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    pw.ImageProvider? logo;
    if (logoPath != null) {
      try {
        final logoFile = File(logoPath);
        if (await logoFile.exists()) {
          logo = pw.MemoryImage(await logoFile.readAsBytes());
        }
      } catch (e) {
        debugPrint('Error loading logo: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildFleetReportHeader(logo, startDate, endDate, dateFormat),
        build: (context) => [
          _buildFleetOverview(vehicles, vehicleTrips),
          pw.SizedBox(height: 20),
          _buildVehiclePerformanceTable(vehicles, vehicleTrips),
          pw.SizedBox(height: 20),
          _buildFleetStatistics(vehicles, vehicleTrips),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  // Generate Driver Performance Report
  Future<Uint8List> generateDriverReport({
    required UserModel driver,
    required List<TripModel> trips,
    required DateTime startDate,
    required DateTime endDate,
    String? logoPath,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    pw.ImageProvider? logo;
    if (logoPath != null) {
      try {
        final logoFile = File(logoPath);
        if (await logoFile.exists()) {
          logo = pw.MemoryImage(await logoFile.readAsBytes());
        }
      } catch (e) {
        debugPrint('Error loading logo: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildDriverReportHeader(logo, driver),
        build: (context) => [
          _buildDriverSummary(driver, trips, startDate, endDate, dateFormat),
          pw.SizedBox(height: 20),
          _buildDriverTripsTable(trips, dateFormat),
          pw.SizedBox(height: 20),
          _buildDriverPerformanceMetrics(trips),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  // Header builders
  pw.Widget _buildTripReportHeader(pw.ImageProvider? logo) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Image(logo, width: 40, height: 40),
                pw.SizedBox(width: 10),
              ],
              pw.Text(
                'Vehicle Tracking System',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.Text(
            'Trip Report',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVehicleDocumentHeader(pw.ImageProvider? logo) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Image(logo, width: 40, height: 40),
                pw.SizedBox(width: 10),
              ],
              pw.Text(
                'Vehicle Tracking System',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.Text(
            'Vehicle Document',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFleetReportHeader(
    pw.ImageProvider? logo, 
    DateTime startDate, 
    DateTime endDate, 
    DateFormat dateFormat
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  if (logo != null) ...[
                    pw.Image(logo, width: 40, height: 40),
                    pw.SizedBox(width: 10),
                  ],
                  pw.Text(
                    'Vehicle Tracking System',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ],
              ),
              pw.Text(
                'Fleet Summary Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDriverReportHeader(pw.ImageProvider? logo, UserModel driver) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Image(logo, width: 40, height: 40),
                pw.SizedBox(width: 10),
              ],
              pw.Text(
                'Vehicle Tracking System',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Driver Performance Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Driver: ${driver.name}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Content builders
  pw.Widget _buildTripSummary(
    TripModel trip, 
    VehicleModel vehicle, 
    UserModel driver, 
    DateFormat dateFormat
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trip Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Trip ID: ${trip.id}'),
                  pw.Text('Vehicle: ${vehicle.licensePlate}'),
                  pw.Text('Driver: ${driver.name}'),
                  pw.Text('Phone: ${driver.phone}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Start: ${dateFormat.format(trip.startTime)}'),
                  if (trip.endTime != null)
                    pw.Text('End: ${dateFormat.format(trip.endTime!)}'),
                  pw.Text('Distance: ${(trip.totalDistance ?? 0.0).toStringAsFixed(2)} km'),
                  pw.Text('Duration: ${trip.duration?.inMinutes ?? 0} min'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTripDetails(TripModel trip, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trip Details',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (trip.startLocationString != null)
            pw.Text('Start Location: ${trip.startLocationString}'),
          if (trip.endLocationString != null)
            pw.Text('End Location: ${trip.endLocationString}'),
          pw.Text('Max Speed: ${trip.maxSpeed.toStringAsFixed(2)} km/h'),
          pw.Text('Average Speed: ${trip.averageSpeed.toStringAsFixed(2)} km/h'),
          pw.Text('Fuel Efficiency: ${trip.fuelEfficiency.toStringAsFixed(2)} km/l'),
          if (trip.route.isNotEmpty)
            pw.Text('Route Points: ${trip.route.length}'),
        ],
      ),
    );
  }

  pw.Widget _buildLocationTable(List<LocationModel> locations, DateFormat dateFormat) {
    if (locations.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        child: pw.Text('No location data available'),
      );
    }

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Location History',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Location', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Speed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...locations.take(20).map((location) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(dateFormat.format(location.timestamp)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${(location.speed ?? 0.0).toStringAsFixed(1)} km/h'),
                  ),
                ],
              )),
            ],
          ),
          if (locations.length > 20)
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('... and ${locations.length - 20} more locations'),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildTripStatistics(TripModel trip, List<LocationModel> locations) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trip Statistics',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Distance: ${(trip.totalDistance ?? 0.0).toStringAsFixed(2)} km'),
                  pw.Text('Total Duration: ${trip.duration?.inHours ?? 0}h ${(trip.duration?.inMinutes ?? 0) % 60}m'),
                  pw.Text('Data Points: ${locations.length}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Max Speed: ${trip.maxSpeed.toStringAsFixed(2)} km/h'),
                  pw.Text('Avg Speed: ${trip.averageSpeed.toStringAsFixed(2)} km/h'),
                  pw.Text('Fuel Used: ${(trip.totalDistance / trip.fuelEfficiency).toStringAsFixed(2)} L'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVehicleInfo(VehicleModel vehicle, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vehicle Information',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('License Plate: ${vehicle.licensePlate}'),
                  pw.Text('Make: ${vehicle.make}'),
                  pw.Text('Model: ${vehicle.model}'),
                  pw.Text('Year: ${vehicle.year}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('VIN: ${vehicle.vin ?? 'N/A'}'),
                  pw.Text('Color: ${vehicle.color ?? 'N/A'}'),
                  pw.Text('Type: ${vehicle.type}'),
                  pw.Text('Status: ${vehicle.status}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDriverInfo(UserModel driver) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Driver Information',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Name: ${driver.name}'),
                  pw.Text('Phone: ${driver.phone}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Email: ${driver.email}'),
                  pw.Text('Role: ${driver.role}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVehicleSpecs(VehicleModel vehicle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vehicle Specifications',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Engine: ${vehicle.engineDetails ?? 'Not specified'}'),
          pw.Text('Fuel Type: ${vehicle.fuelType ?? 'Not specified'}'),
          pw.Text('Capacity: ${vehicle.capacity ?? 0} passengers'),
          pw.Text('Mileage: ${vehicle.mileage ?? 0} km'),
        ],
      ),
    );
  }

  pw.Widget _buildFleetOverview(
    List<VehicleModel> vehicles, 
    Map<String, List<TripModel>> vehicleTrips
  ) {
    int totalVehicles = vehicles.length;
    int activeVehicles = vehicles.where((v) => v.status == 'active').length;
    int totalTrips = vehicleTrips.values.expand((trips) => trips).length;
    double totalDistance = vehicleTrips.values
        .expand((trips) => trips)
        .fold(0.0, (sum, trip) => sum + trip.totalDistance);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Fleet Overview',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Vehicles: $totalVehicles'),
                  pw.Text('Active Vehicles: $activeVehicles'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Trips: $totalTrips'),
                  pw.Text('Total Distance: ${totalDistance.toStringAsFixed(2)} km'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVehiclePerformanceTable(
    List<VehicleModel> vehicles, 
    Map<String, List<TripModel>> vehicleTrips
  ) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vehicle Performance',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Vehicle', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Trips', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Distance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Avg Speed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...vehicles.map((vehicle) {
                final trips = vehicleTrips[vehicle.id] ?? [];
                final distance = trips.fold(0.0, (sum, trip) => sum + trip.totalDistance);
                final avgSpeed = trips.isEmpty 
                    ? 0.0 
                    : trips.fold(0.0, (sum, trip) => sum + trip.averageSpeed) / trips.length;
                
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(vehicle.licensePlate),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${trips.length}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${distance.toStringAsFixed(1)} km'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${avgSpeed.toStringAsFixed(1)} km/h'),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFleetStatistics(
    List<VehicleModel> vehicles, 
    Map<String, List<TripModel>> vehicleTrips
  ) {
    final allTrips = vehicleTrips.values.expand((trips) => trips).toList();
    final totalDistance = allTrips.fold(0.0, (sum, trip) => sum + trip.totalDistance);
    final totalFuel = allTrips.fold(0.0, (sum, trip) => sum + (trip.totalDistance / trip.fuelEfficiency));
    final avgEfficiency = allTrips.isEmpty 
        ? 0.0 
        : allTrips.fold(0.0, (sum, trip) => sum + trip.fuelEfficiency) / allTrips.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Fleet Statistics',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Distance: ${totalDistance.toStringAsFixed(2)} km'),
                  pw.Text('Fuel Consumed: ${totalFuel.toStringAsFixed(2)} L'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Avg Efficiency: ${avgEfficiency.toStringAsFixed(2)} km/l'),
                  pw.Text('Total Trips: ${allTrips.length}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDriverSummary(
    UserModel driver, 
    List<TripModel> trips, 
    DateTime startDate, 
    DateTime endDate, 
    DateFormat dateFormat
  ) {
    final totalDistance = trips.fold(0.0, (sum, trip) => sum + trip.totalDistance);
    final totalDuration = trips.fold(Duration.zero, (sum, trip) => sum + (trip.duration ?? Duration.zero));
    final avgSpeed = trips.isEmpty 
        ? 0.0 
        : trips.fold(0.0, (sum, trip) => sum + trip.averageSpeed) / trips.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Driver Performance Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Trips: ${trips.length}'),
                  pw.Text('Total Distance: ${totalDistance.toStringAsFixed(2)} km'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Duration: ${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m'),
                  pw.Text('Average Speed: ${avgSpeed.toStringAsFixed(2)} km/h'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDriverTripsTable(List<TripModel> trips, DateFormat dateFormat) {
    if (trips.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        child: pw.Text('No trips found for this period'),
      );
    }

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trip History',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Distance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Duration', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Avg Speed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...trips.take(15).map((trip) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(dateFormat.format(trip.startTime)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${trip.totalDistance.toStringAsFixed(1)} km'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${trip.duration?.inMinutes ?? 0} min'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${trip.averageSpeed.toStringAsFixed(1)} km/h'),
                  ),
                ],
              )),
            ],
          ),
          if (trips.length > 15)
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('... and ${trips.length - 15} more trips'),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildDriverPerformanceMetrics(List<TripModel> trips) {
    if (trips.isEmpty) return pw.Container();

    final maxSpeed = trips.fold(0.0, (max, trip) => trip.maxSpeed > max ? trip.maxSpeed : max);
    final avgFuelEfficiency = trips.fold(0.0, (sum, trip) => sum + trip.fuelEfficiency) / trips.length;
    final totalFuelUsed = trips.fold(0.0, (sum, trip) => sum + (trip.totalDistance / trip.fuelEfficiency));

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Performance Metrics',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Max Speed Recorded: ${maxSpeed.toStringAsFixed(2)} km/h'),
                  pw.Text('Average Fuel Efficiency: ${avgFuelEfficiency.toStringAsFixed(2)} km/l'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Fuel Used: ${totalFuelUsed.toStringAsFixed(2)} L'),
                  pw.Text('Trips Completed: ${trips.length}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDocumentFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Text(
            'This document is generated by Vehicle Tracking System',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Vadodara, Gujarat - Ride with confidence',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  // Save PDF to file
  Future<File> savePdfToFile(Uint8List pdfData, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfData);
    return file;
  }

  // Print PDF
  Future<void> printPdf(Uint8List pdfData) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
    );
  }

  // Share PDF
  Future<void> sharePdf(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(
      bytes: pdfData,
      filename: fileName,
    );
  }
}
