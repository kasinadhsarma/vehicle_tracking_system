import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PDFReportGenerator {
  static Future<Uint8List> generateTripReport({
    required String vehicleId,
    required String driverName,
    required DateTime startTime,
    required DateTime endTime,
    required List<Map<String, dynamic>> tripData,
    required Map<String, dynamic> analytics,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(boldFont),
            pw.SizedBox(height: 20),
            
            // Trip Information
            _buildTripInfo(font, boldFont, vehicleId, driverName, startTime, endTime),
            pw.SizedBox(height: 20),
            
            // Analytics Summary
            _buildAnalyticsSummary(font, boldFont, analytics),
            pw.SizedBox(height: 20),
            
            // Trip Details Table
            _buildTripDetailsTable(font, boldFont, tripData),
            pw.SizedBox(height: 20),
            
            // Safety Summary
            _buildSafetySummary(font, boldFont, analytics),
            
            // Footer
            pw.Spacer(),
            _buildFooter(font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '🚗 Vehicle Tracking Report',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 24,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Vadodara Vehicle Tracking System',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Text(
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTripInfo(
    pw.Font font,
    pw.Font boldFont,
    String vehicleId,
    String driverName,
    DateTime startTime,
    DateTime endTime,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trip Information',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(font, boldFont, 'Vehicle ID:', vehicleId),
                    _buildInfoRow(font, boldFont, 'Driver Name:', driverName),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(font, boldFont, 'Start Time:', DateFormat('dd/MM/yyyy HH:mm').format(startTime)),
                    _buildInfoRow(font, boldFont, 'End Time:', DateFormat('dd/MM/yyyy HH:mm').format(endTime)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(pw.Font font, pw.Font boldFont, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: 12)),
          pw.SizedBox(width: 10),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 12)),
        ],
      ),
    );
  }

  static pw.Widget _buildAnalyticsSummary(
    pw.Font font,
    pw.Font boldFont,
    Map<String, dynamic> analytics,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trip Analytics',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildAnalyticsCard(font, boldFont, 'Total Distance', 
                  '${analytics['totalDistance']?.toStringAsFixed(2) ?? '0'} km', PdfColors.green),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildAnalyticsCard(font, boldFont, 'Duration', 
                  '${analytics['duration'] ?? '0'} mins', PdfColors.blue),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildAnalyticsCard(font, boldFont, 'Avg Speed', 
                  '${analytics['avgSpeed']?.toStringAsFixed(1) ?? '0'} km/h', PdfColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAnalyticsCard(
    pw.Font font,
    pw.Font boldFont,
    String title,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTripDetailsTable(
    pw.Font font,
    pw.Font boldFont,
    List<Map<String, dynamic>> tripData,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Trip Details',
          style: pw.TextStyle(font: boldFont, fontSize: 18),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell(boldFont, 'Time', isHeader: true),
                _buildTableCell(boldFont, 'Location', isHeader: true),
                _buildTableCell(boldFont, 'Speed (km/h)', isHeader: true),
                _buildTableCell(boldFont, 'Status', isHeader: true),
              ],
            ),
            // Data rows (limit to prevent overflow)
            ...tripData.take(15).map((trip) => pw.TableRow(
              children: [
                _buildTableCell(font, DateFormat('HH:mm').format(DateTime.parse(trip['timestamp'] ?? ''))),
                _buildTableCell(font, trip['location'] ?? 'Unknown'),
                _buildTableCell(font, '${trip['speed']?.toStringAsFixed(1) ?? '0'}'),
                _buildTableCell(font, trip['status'] ?? 'Normal'),
              ],
            )),
          ],
        ),
        if (tripData.length > 15)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '... and ${tripData.length - 15} more entries',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildTableCell(pw.Font font, String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 11 : 10,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _buildSafetySummary(
    pw.Font font,
    pw.Font boldFont,
    Map<String, dynamic> analytics,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Safety Summary',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSafetyItem(font, boldFont, '⚠️ Speed Violations', 
                  '${analytics['speedViolations'] ?? 0}'),
              ),
              pw.Expanded(
                child: _buildSafetyItem(font, boldFont, '🛑 Hard Braking', 
                  '${analytics['hardBraking'] ?? 0}'),
              ),
              pw.Expanded(
                child: _buildSafetyItem(font, boldFont, '⚡ Rapid Acceleration', 
                  '${analytics['rapidAcceleration'] ?? 0}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSafetyItem(pw.Font font, pw.Font boldFont, String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11)),
        pw.SizedBox(height: 5),
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 14)),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Vadodara Vehicle Tracking System',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page 1',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // Monthly Report Generator
  static Future<Uint8List> generateMonthlyReport({
    required String vehicleId,
    required String driverName,
    required DateTime month,
    required Map<String, dynamic> monthlyData,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '📊 Monthly Tracking Report',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 24,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '${DateFormat('MMMM yyyy').format(month)} - Vehicle: $vehicleId',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Monthly Summary
            _buildMonthlySummary(font, boldFont, monthlyData),
            pw.SizedBox(height: 20),
            
            // Weekly Breakdown
            _buildWeeklyBreakdown(font, boldFont, monthlyData['weeklyData'] ?? []),
            
            pw.Spacer(),
            _buildFooter(font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMonthlySummary(
    pw.Font font,
    pw.Font boldFont,
    Map<String, dynamic> monthlyData,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Monthly Summary',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildAnalyticsCard(font, boldFont, 'Total Trips', 
                  '${monthlyData['totalTrips'] ?? 0}', PdfColors.blue),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildAnalyticsCard(font, boldFont, 'Total Distance', 
                  '${monthlyData['totalDistance']?.toStringAsFixed(1) ?? '0'} km', PdfColors.green),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildAnalyticsCard(font, boldFont, 'Avg Trip Time', 
                  '${monthlyData['avgTripTime'] ?? 0} mins', PdfColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWeeklyBreakdown(
    pw.Font font,
    pw.Font boldFont,
    List<dynamic> weeklyData,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Weekly Breakdown',
          style: pw.TextStyle(font: boldFont, fontSize: 18),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell(boldFont, 'Week', isHeader: true),
                _buildTableCell(boldFont, 'Trips', isHeader: true),
                _buildTableCell(boldFont, 'Distance (km)', isHeader: true),
                _buildTableCell(boldFont, 'Avg Speed', isHeader: true),
              ],
            ),
            ...weeklyData.map((week) => pw.TableRow(
              children: [
                _buildTableCell(font, week['week'] ?? ''),
                _buildTableCell(font, '${week['trips'] ?? 0}'),
                _buildTableCell(font, '${week['distance']?.toStringAsFixed(1) ?? '0'}'),
                _buildTableCell(font, '${week['avgSpeed']?.toStringAsFixed(1) ?? '0'} km/h'),
              ],
            )),
          ],
        ),
      ],
    );
  }
}
