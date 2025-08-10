import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PDFReportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Generate comprehensive vehicle tracking report
  static Future<Uint8List> generateVehicleReport({
    required List<Map<String, dynamic>> vehicles,
    required Map<String, dynamic> statistics,
    String? companyName = 'Vadodara Vehicle Tracking System',
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader(companyName!, now),
              pw.SizedBox(height: 20),
              
              // Executive Summary
              _buildExecutiveSummary(statistics),
              pw.SizedBox(height: 20),
              
              // Vehicle Statistics by Service
              _buildServiceBreakdown(vehicles),
              pw.SizedBox(height: 20),
              
              // Vehicle Status Overview
              _buildStatusOverview(vehicles),
              pw.SizedBox(height: 20),
              
              // Detailed Vehicle List
              _buildVehicleTable(vehicles),
              pw.SizedBox(height: 20),
              
              // Performance Metrics
              _buildPerformanceMetrics(vehicles),
              
              // Footer
              _buildFooter(now),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      debugPrint('PDF generated successfully: ${pdfBytes.length} bytes');
      return pdfBytes;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildHeader(String companyName, DateTime now) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Fleet Tracking Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated: ${_dateFormat.format(now)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Vadodara, Gujarat',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExecutiveSummary(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Executive Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Total Vehicles', '${stats['totalVehicles']}'),
              _buildSummaryCard('Active Vehicles', '${stats['activeVehicles']}'),
              _buildSummaryCard('Available Vehicles', '${stats['availableVehicles']}'),
              _buildSummaryCard('Avg Rating', '${stats['averageRating'].toStringAsFixed(1)}'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildServiceBreakdown(List<Map<String, dynamic>> vehicles) {
    final serviceStats = <String, Map<String, int>>{};
    
    for (final vehicle in vehicles) {
      final service = vehicle['service'] as String;
      serviceStats.putIfAbsent(service, () => {'count': 0, 'active': 0});
      serviceStats[service]!['count'] = serviceStats[service]!['count']! + 1;
      
      if (vehicle['status'] != 'standby') {
        serviceStats[service]!['active'] = serviceStats[service]!['active']! + 1;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Service-wise Vehicle Distribution',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Service', isHeader: true),
                _buildTableCell('Total Vehicles', isHeader: true),
                _buildTableCell('Active Vehicles', isHeader: true),
                _buildTableCell('Utilization %', isHeader: true),
              ],
            ),
            ...serviceStats.entries.map((entry) {
              final utilization = (entry.value['active']! / entry.value['count']! * 100).toStringAsFixed(1);
              return pw.TableRow(
                children: [
                  _buildTableCell(entry.key),
                  _buildTableCell('${entry.value['count']}'),
                  _buildTableCell('${entry.value['active']}'),
                  _buildTableCell('$utilization%'),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStatusOverview(List<Map<String, dynamic>> vehicles) {
    final statusStats = <String, int>{};
    
    for (final vehicle in vehicles) {
      final status = vehicle['status'] as String;
      statusStats[status] = (statusStats[status] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Vehicle Status Overview',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 15,
          runSpacing: 10,
          children: statusStats.entries.map((entry) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _getStatusColor(entry.key),
                borderRadius: pw.BorderRadius.circular(15),
              ),
              child: pw.Text(
                '${entry.key}: ${entry.value}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildVehicleTable(List<Map<String, dynamic>> vehicles) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detailed Vehicle Information',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FixedColumnWidth(80),
            2: const pw.FixedColumnWidth(100),
            3: const pw.FixedColumnWidth(80),
            4: const pw.FixedColumnWidth(60),
            5: const pw.FixedColumnWidth(80),
            6: const pw.FixedColumnWidth(80),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('ID', isHeader: true),
                _buildTableCell('Service', isHeader: true),
                _buildTableCell('Driver', isHeader: true),
                _buildTableCell('Vehicle', isHeader: true),
                _buildTableCell('Rating', isHeader: true),
                _buildTableCell('Fuel %', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            ...vehicles.map((vehicle) {
              return pw.TableRow(
                children: [
                  _buildTableCell(vehicle['id']),
                  _buildTableCell(vehicle['service']),
                  _buildTableCell(vehicle['driverName']),
                  _buildTableCell(vehicle['vehicleModel']),
                  _buildTableCell('${vehicle['rating']}'),
                  _buildTableCell('${vehicle['fuelLevel'].toStringAsFixed(1)}%'),
                  _buildTableCell(vehicle['status']),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPerformanceMetrics(List<Map<String, dynamic>> vehicles) {
    final totalTrips = vehicles.fold<int>(0, (sum, v) => sum + (v['totalTrips'] as int));
    final avgFuel = vehicles.fold<double>(0, (sum, v) => sum + (v['fuelLevel'] as double)) / vehicles.length;
    final highRatedVehicles = vehicles.where((v) => (v['rating'] as double) >= 4.5).length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Fleet Performance Metrics',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard('Total Trips', '$totalTrips'),
              _buildMetricCard('Avg Fuel Level', '${avgFuel.toStringAsFixed(1)}%'),
              _buildMetricCard('High Rated Vehicles', '$highRatedVehicles'),
              _buildMetricCard('Fleet Efficiency', '${(highRatedVehicles/vehicles.length*100).toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.green300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildFooter(DateTime now) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Vehicle Tracking System',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page 1 of 1',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return PdfColors.green;
      case 'busy':
      case 'on_trip':
      case 'delivering':
      case 'on_route':
        return PdfColors.blue;
      case 'standby':
        return PdfColors.orange;
      case 'loading':
        return PdfColors.purple;
      case 'picking_up':
        return PdfColors.teal;
      default:
        return PdfColors.grey;
    }
  }

  /// Save PDF to device storage
  static Future<String> savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      // For web, use the browser's download functionality
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '$fileName.pdf',
      );
      return 'Downloaded: $fileName.pdf';
    } else {
      // For desktop/mobile, save to file system
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    }
  }

  /// Generate and save fleet report
  static Future<String> generateAndSaveFleetReport(
    List<Map<String, dynamic>> vehicles,
    Map<String, dynamic> statistics,
  ) async {
    final pdfBytes = await generateVehicleReport(
      vehicles: vehicles,
      statistics: statistics,
    );
    
    final fileName = 'Fleet_Report_${_fileNameFormat.format(DateTime.now())}';
    return await savePDFToDevice(pdfBytes, fileName);
  }

  /// Print PDF report
  static Future<void> printReport(
    List<Map<String, dynamic>> vehicles,
    Map<String, dynamic> statistics,
  ) async {
    try {
      final pdfBytes = await generateVehicleReport(
        vehicles: vehicles,
        statistics: statistics,
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      debugPrint('Error printing PDF: $e');
      rethrow;
    }
  }

  /// Share PDF report
  static Future<void> shareReport(
    List<Map<String, dynamic>> vehicles,
    Map<String, dynamic> statistics,
  ) async {
    try {
      final pdfBytes = await generateVehicleReport(
        vehicles: vehicles,
        statistics: statistics,
      );
      
      final fileName = 'Fleet_Report_${_fileNameFormat.format(DateTime.now())}';
      
      if (kIsWeb) {
        // On web, this will trigger a download
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: '$fileName.pdf',
        );
      } else {
        // On mobile/desktop, this opens the share dialog
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: '$fileName.pdf',
        );
      }
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }
}
