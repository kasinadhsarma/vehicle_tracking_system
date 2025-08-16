import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../core/services/pdf_report_generator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedReportType = 'Trip Report';
  DateTime selectedDate = DateTime.now();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
  bool isGenerating = false;

  final List<String> reportTypes = [
    'Trip Report',
    'Daily Report',
    'Weekly Report', 
    'Monthly Report',
    'Safety Report',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Reports & Analytics'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStats(),
              const SizedBox(height: 30),
              _buildReportGenerator(),
              const SizedBox(height: 30),
              _buildReportHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Quick Stats',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Trips', '47', '🚗', Colors.blue)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatCard('Distance', '1,234 km', '📍', Colors.green)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildStatCard('Avg Speed', '45 km/h', '⚡', Colors.orange)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatCard('Safety Score', '92%', '🛡️', Colors.teal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportGenerator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Generate Report',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 20),

          // Report Type Selector
          Text(
            'Report Type',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedReportType,
                isExpanded: true,
                items: reportTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReportType = value!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date Range Selector
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(DateFormat('dd/MM/yyyy').format(startDate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(DateFormat('dd/MM/yyyy').format(endDate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isGenerating ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isGenerating
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Generating Report...', style: TextStyle(color: Colors.white)),
                    ],
                  )
                : const Text(
                    '📄 Generate PDF Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHistory() {
    final recentReports = [
      {
        'title': 'Weekly Report - Week 32',
        'date': '08/08/2025',
        'type': 'Weekly',
        'size': '2.3 MB',
      },
      {
        'title': 'Trip Report - Vadodara to Surat',
        'date': '05/08/2025',
        'type': 'Trip',
        'size': '1.8 MB',
      },
      {
        'title': 'Monthly Report - July 2025',
        'date': '01/08/2025',
        'type': 'Monthly',
        'size': '4.1 MB',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📚 Recent Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 15),
          ...recentReports.map((report) => _buildReportItem(report)),
        ],
      ),
    );
  }

  Widget _buildReportItem(Map<String, String> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description,
              color: Colors.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      report['type']!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      report['date']!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      report['size']!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _showReportMenu(context, report);
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      isGenerating = true;
    });

    try {
      // Generate sample data
      final tripData = _generateSampleTripData();
      final analytics = _generateSampleAnalytics();

      late final pdfBytes;
      
      switch (selectedReportType) {
        case 'Trip Report':
          pdfBytes = await PDFReportGenerator.generateTripReport(
            vehicleId: 'VH-001',
            driverName: 'Rajesh Patel',
            startTime: startDate,
            endTime: endDate,
            tripData: tripData,
            analytics: analytics,
          );
          break;
        case 'Monthly Report':
          pdfBytes = await PDFReportGenerator.generateMonthlyReport(
            vehicleId: 'VH-001',
            driverName: 'Rajesh Patel',
            month: startDate,
            monthlyData: _generateSampleMonthlyData(),
          );
          break;
        default:
          pdfBytes = await PDFReportGenerator.generateTripReport(
            vehicleId: 'VH-001',
            driverName: 'Rajesh Patel',
            startTime: startDate,
            endTime: endDate,
            tripData: tripData,
            analytics: analytics,
          );
      }

      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) => pdfBytes,
          name: '${selectedReportType.replaceAll(' ', '_')}_${DateFormat('yyyy_MM_dd').format(DateTime.now())}',
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF Report Generated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _generateSampleTripData() {
    return List.generate(20, (index) {
      final baseTime = startDate.add(Duration(hours: index ~/ 3, minutes: (index % 3) * 20));
      return {
        'timestamp': baseTime.toIso8601String(),
        'location': _getLocationName(index),
        'speed': 30.0 + (index % 10) * 5.0,
        'status': index % 8 == 0 ? 'Speeding' : 'Normal',
      };
    });
  }

  String _getLocationName(int index) {
    final locations = [
      'Vadodara Railway Station',
      'Sayajigunj Circle',
      'Alkapuri Society',
      'Makarpura GIDC',
      'Fatehgunj Area',
      'Karelibaug Cross Roads',
      'Manjalpur Junction',
      'Harni Road',
      'Gotri Main Road',
      'BPC Road',
    ];
    return locations[index % locations.length];
  }

  Map<String, dynamic> _generateSampleAnalytics() {
    return {
      'totalDistance': 125.6,
      'duration': 180,
      'avgSpeed': 42.5,
      'speedViolations': 3,
      'hardBraking': 2,
      'rapidAcceleration': 1,
    };
  }

  Map<String, dynamic> _generateSampleMonthlyData() {
    return {
      'totalTrips': 47,
      'totalDistance': 1234.5,
      'avgTripTime': 45,
      'weeklyData': [
        {'week': 'Week 1', 'trips': 12, 'distance': 310.2, 'avgSpeed': 44.5},
        {'week': 'Week 2', 'trips': 11, 'distance': 289.7, 'avgSpeed': 43.2},
        {'week': 'Week 3', 'trips': 13, 'distance': 325.8, 'avgSpeed': 45.1},
        {'week': 'Week 4', 'trips': 11, 'distance': 308.8, 'avgSpeed': 44.0},
      ],
    };
  }

  void _showReportMenu(BuildContext context, Map<String, String> report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View functionality coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download functionality coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
