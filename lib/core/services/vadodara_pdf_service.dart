import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class VadodaraPDFService {
  static VadodaraPDFService? _instance;
  static VadodaraPDFService get instance => _instance ??= VadodaraPDFService._();
  VadodaraPDFService._();

  // Generate trip receipt (like Ola/Uber)
  Future<Uint8List> generateTripReceipt({
    required Map<String, dynamic> tripData,
    required Map<String, dynamic> driverData,
    required Map<String, dynamic> vehicleData,
  }) async {
    final pdf = pw.Document();
    
    // Load logo and fonts
    final logoImage = await _loadAssetImage('assets/images/logo.png');
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo and company info
              pw.Row(
                children: [
                  if (logoImage != null)
                    pw.Image(logoImage, width: 60, height: 60),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Vadodara Vehicle Tracker',
                          style: pw.TextStyle(font: boldFont, fontSize: 24),
                        ),
                        pw.Text(
                          'Your Trusted Ride Partner in Gujarat',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                        pw.Text(
                          'Vadodara, Gujarat - 390001',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Trip Receipt Title
              pw.Center(
                child: pw.Text(
                  'TRIP RECEIPT',
                  style: pw.TextStyle(font: boldFont, fontSize: 20),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Trip Details
              pw.Container(
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
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                    pw.SizedBox(height: 12),
                    _buildDetailRow('Trip ID:', tripData['tripId'] ?? 'N/A', font, boldFont),
                    _buildDetailRow('Date & Time:', tripData['dateTime'] ?? 'N/A', font, boldFont),
                    _buildDetailRow('From:', tripData['pickup'] ?? 'N/A', font, boldFont),
                    _buildDetailRow('To:', tripData['destination'] ?? 'N/A', font, boldFont),
                    _buildDetailRow('Distance:', '${tripData['distance'] ?? 0} km', font, boldFont),
                    _buildDetailRow('Duration:', tripData['duration'] ?? 'N/A', font, boldFont),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Driver & Vehicle Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Driver & Vehicle Information',
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                    pw.SizedBox(height: 12),
                    _buildDetailRow('Driver Name:', driverData['name'] ?? 'N/A', font, boldFont),
                    _buildDetailRow('Driver Phone:', driverData['phone'] ?? 'N/A', font, boldFont),
                    _buildDetailRow('Vehicle Number:', vehicleData['number'] ?? 'N/A', font, boldFont),
                    _buildDetailRow('Vehicle Type:', vehicleData['type'] ?? 'N/A', font, boldFont),
                    _buildDetailRow('License Plate:', vehicleData['licensePlate'] ?? 'N/A', font, boldFont),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Fare Breakdown
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Fare Breakdown',
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                    pw.SizedBox(height: 12),
                    _buildDetailRow('Base Fare:', '₹${tripData['baseFare'] ?? 0}', font, boldFont),
                    _buildDetailRow('Distance Charge:', '₹${tripData['distanceCharge'] ?? 0}', font, boldFont),
                    _buildDetailRow('Time Charge:', '₹${tripData['timeCharge'] ?? 0}', font, boldFont),
                    if ((tripData['tolls'] ?? 0) > 0)
                      _buildDetailRow('Tolls:', '₹${tripData['tolls']}', font, boldFont),
                    if ((tripData['taxes'] ?? 0) > 0)
                      _buildDetailRow('Taxes & Fees:', '₹${tripData['taxes']}', font, boldFont),
                    pw.Divider(),
                    _buildDetailRow(
                      'Total Amount:', 
                      '₹${tripData['totalAmount'] ?? 0}', 
                      font, 
                      boldFont,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Payment Method
              _buildDetailRow('Payment Method:', tripData['paymentMethod'] ?? 'Cash', font, boldFont),
              
              pw.Spacer(),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for choosing Vadodara Vehicle Tracker!',
                      style: pw.TextStyle(font: boldFont, fontSize: 14),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Safe travels in beautiful Vadodara!',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Support: +91-XXXXX-XXXXX | vadodara.support@vehicletracker.com',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Generate vehicle registration certificate
  Future<Uint8List> generateVehicleRegistrationCertificate({
    required Map<String, dynamic> vehicleData,
    required Map<String, dynamic> ownerData,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'VEHICLE REGISTRATION CERTIFICATE',
                      style: pw.TextStyle(font: boldFont, fontSize: 24),
                    ),
                    pw.Text(
                      'Vadodara Vehicle Tracker',
                      style: pw.TextStyle(font: boldFont, fontSize: 18),
                    ),
                    pw.Text(
                      'Vadodara, Gujarat, India',
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Certificate Number
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Certificate No: VVT-${vehicleData['registrationId'] ?? DateTime.now().millisecondsSinceEpoch}',
                    style: pw.TextStyle(font: boldFont, fontSize: 12),
                  ),
                  pw.Text(
                    'Date: ${DateTime.now().toString().split(' ')[0]}',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Vehicle Information
              pw.Text(
                'VEHICLE INFORMATION',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  _buildTableRow('Vehicle Number:', vehicleData['number'] ?? 'N/A', font, boldFont),
                  _buildTableRow('Vehicle Type:', vehicleData['type'] ?? 'N/A', font, boldFont),
                  _buildTableRow('Make & Model:', vehicleData['makeModel'] ?? 'N/A', font, boldFont),
                  _buildTableRow('Year:', vehicleData['year']?.toString() ?? 'N/A', font, boldFont),
                  _buildTableRow('Color:', vehicleData['color'] ?? 'N/A', font, boldFont),
                  _buildTableRow('Engine Number:', vehicleData['engineNumber'] ?? 'N/A', font, boldFont),
                  _buildTableRow('Chassis Number:', vehicleData['chassisNumber'] ?? 'N/A', font, boldFont),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Owner Information
              pw.Text(
                'OWNER INFORMATION',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  _buildTableRow('Owner Name:', ownerData['name'] ?? 'N/A', font, boldFont),
                  _buildTableRow('Phone Number:', ownerData['phone'] ?? 'N/A', font, boldFont),
                  _buildTableRow('Email:', ownerData['email'] ?? 'N/A', font, boldFont),
                  _buildTableRow('License Number:', ownerData['licenseNumber'] ?? 'N/A', font, boldFont),
                  _buildTableRow('Address:', ownerData['address'] ?? 'Vadodara, Gujarat', font, boldFont),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Registration Details
              pw.Text(
                'REGISTRATION DETAILS',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  _buildTableRow('Registration Date:', DateTime.now().toString().split(' ')[0], font, boldFont),
                  _buildTableRow('Valid Until:', DateTime.now().add(const Duration(days: 365)).toString().split(' ')[0], font, boldFont),
                  _buildTableRow('Operating Area:', 'Vadodara Municipal Corporation Area', font, boldFont),
                  _buildTableRow('Service Type:', 'Taxi/Ride Sharing', font, boldFont),
                  _buildTableRow('Status:', 'Active', font, boldFont),
                ],
              ),
              
              pw.Spacer(),
              
              // Signature and Seal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('_________________________'),
                      pw.Text('Vehicle Owner Signature', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('_________________________'),
                      pw.Text('Authorized Signatory', style: pw.TextStyle(font: font, fontSize: 10)),
                      pw.Text('Vadodara Vehicle Tracker', style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Center(
                child: pw.Text(
                  'This certificate is valid for commercial vehicle operations within Vadodara city limits.',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Generate monthly driver report
  Future<Uint8List> generateDriverReport({
    required Map<String, dynamic> driverData,
    required List<Map<String, dynamic>> trips,
    required String month,
    required String year,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DRIVER MONTHLY REPORT',
                    style: pw.TextStyle(font: boldFont, fontSize: 20),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Vadodara Vehicle Tracker',
                    style: pw.TextStyle(font: font, fontSize: 14),
                  ),
                  pw.Text(
                    'Period: $month $year',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Driver Information
            pw.Text(
              'DRIVER INFORMATION',
              style: pw.TextStyle(font: boldFont, fontSize: 16),
            ),
            pw.SizedBox(height: 10),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  _buildDetailRow('Name:', driverData['name'] ?? 'N/A', font, boldFont),
                  _buildDetailRow('Phone:', driverData['phone'] ?? 'N/A', font, boldFont),
                  _buildDetailRow('License:', driverData['license'] ?? 'N/A', font, boldFont),
                  _buildDetailRow('Vehicle:', driverData['vehicle'] ?? 'N/A', font, boldFont),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Monthly Summary
            pw.Text(
              'MONTHLY SUMMARY',
              style: pw.TextStyle(font: boldFont, fontSize: 16),
            ),
            pw.SizedBox(height: 10),
            
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      border: pw.Border.all(),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Total Trips', style: pw.TextStyle(font: boldFont)),
                        pw.Text('${trips.length}', style: pw.TextStyle(font: font, fontSize: 20)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      border: pw.Border.all(),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Total Distance', style: pw.TextStyle(font: boldFont)),
                        pw.Text('${_calculateTotalDistance(trips)} km', style: pw.TextStyle(font: font, fontSize: 20)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange50,
                      border: pw.Border.all(),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Total Earnings', style: pw.TextStyle(font: boldFont)),
                        pw.Text('₹${_calculateTotalEarnings(trips)}', style: pw.TextStyle(font: font, fontSize: 20)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Trip History
            pw.Text(
              'TRIP HISTORY',
              style: pw.TextStyle(font: boldFont, fontSize: 16),
            ),
            pw.SizedBox(height: 10),
            
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Date', style: pw.TextStyle(font: boldFont)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('From', style: pw.TextStyle(font: boldFont)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('To', style: pw.TextStyle(font: boldFont)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Distance', style: pw.TextStyle(font: boldFont)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Fare', style: pw.TextStyle(font: boldFont)),
                    ),
                  ],
                ),
                ...trips.take(20).map((trip) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(trip['date'] ?? 'N/A', style: pw.TextStyle(font: font, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(trip['from'] ?? 'N/A', style: pw.TextStyle(font: font, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(trip['to'] ?? 'N/A', style: pw.TextStyle(font: font, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${trip['distance'] ?? 0} km', style: pw.TextStyle(font: font, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('₹${trip['fare'] ?? 0}', style: pw.TextStyle(font: font, fontSize: 10)),
                    ),
                  ],
                )).toList(),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Helper methods
  pw.Widget _buildDetailRow(String label, String value, pw.Font font, pw.Font boldFont, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: isTotal ? 14 : 12)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: isTotal ? boldFont : font, fontSize: isTotal ? 14 : 12)),
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildTableRow(String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: 12)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 12)),
        ),
      ],
    );
  }

  Future<pw.ImageProvider?> _loadAssetImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      return null;
    }
  }

  double _calculateTotalDistance(List<Map<String, dynamic>> trips) {
    return trips.fold(0.0, (sum, trip) => sum + (trip['distance'] ?? 0.0));
  }

  double _calculateTotalEarnings(List<Map<String, dynamic>> trips) {
    return trips.fold(0.0, (sum, trip) => sum + (trip['fare'] ?? 0.0));
  }

  // Print or share PDF
  Future<void> printPDF(Uint8List pdfData, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
    );
  }

  Future<void> sharePDF(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(
      bytes: pdfData,
      filename: fileName,
    );
  }
}
