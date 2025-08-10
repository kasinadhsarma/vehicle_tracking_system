import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/custom_widgets.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final List<Map<String, dynamic>> _vehicles = [
    {
      'id': 'VH-001',
      'driver': 'John Smith',
      'phoneNumber': '+1-555-0123',
      'status': 'Active',
      'location': 'Downtown NYC',
      'speed': '45 km/h',
      'fuel': '75%',
      'lastUpdate': '2 min ago',
      'vehicleType': 'Truck',
      'plateNumber': 'ABC-123',
    },
    {
      'id': 'VH-002',
      'driver': 'Jane Doe',
      'phoneNumber': '+1-555-0124',
      'status': 'Idle',
      'location': 'Central Park',
      'speed': '0 km/h',
      'fuel': '89%',
      'lastUpdate': '5 min ago',
      'vehicleType': 'Van',
      'plateNumber': 'XYZ-789',
    },
    {
      'id': 'VH-003',
      'driver': 'Mike Johnson',
      'phoneNumber': '+1-555-0125',
      'status': 'Active',
      'location': 'Brooklyn Bridge',
      'speed': '32 km/h',
      'fuel': '45%',
      'lastUpdate': '1 min ago',
      'vehicleType': 'Car',
      'plateNumber': 'DEF-456',
    },
    {
      'id': 'VH-004',
      'driver': 'Sarah Wilson',
      'phoneNumber': '+1-555-0126',
      'status': 'Offline',
      'location': 'Unknown',
      'speed': '0 km/h',
      'fuel': '60%',
      'lastUpdate': '2 hours ago',
      'vehicleType': 'Truck',
      'plateNumber': 'GHI-321',
    },
    {
      'id': 'VH-005',
      'driver': 'Tom Brown',
      'phoneNumber': '+1-555-0127',
      'status': 'Active',
      'location': 'Times Square',
      'speed': '28 km/h',
      'fuel': '92%',
      'lastUpdate': '30 sec ago',
      'vehicleType': 'Van',
      'plateNumber': 'JKL-654',
    },
  ];

  String _filterStatus = 'All';
  final TextEditingController _vehicleIdController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  String _selectedVehicleType = 'Car';

  @override
  void dispose() {
    _vehicleIdController.dispose();
    _driverNameController.dispose();
    _phoneNumberController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredVehicles = _filterStatus == 'All'
        ? _vehicles
        : _vehicles
              .where((vehicle) => vehicle['status'] == _filterStatus)
              .toList();

    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehicle Management',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage your fleet with phone-based tracking',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'Add Vehicle',
                      icon: Icons.add,
                      onPressed: _showAddVehicleDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Filter and Stats Row
                Row(
                  children: [
                    Expanded(
                      child: CustomCard(
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            const Text('Filter: '),
                            DropdownButton<String>(
                              value: _filterStatus,
                              underline: const SizedBox(),
                              items: ['All', 'Active', 'Idle', 'Offline']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _filterStatus = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomCard(
                        child: Row(
                          children: [
                            Icon(Icons.directions_car, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text('Total: ${_vehicles.length} vehicles'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomCard(
                        child: Row(
                          children: [
                            Icon(Icons.phone, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text('Active: ${_vehicles.where((v) => v['status'] == 'Active').length}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Vehicle List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = filteredVehicles[index];
                return CustomCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(vehicle['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getVehicleIcon(vehicle['vehicleType']),
                        color: _getStatusColor(vehicle['status']),
                        size: 24,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle['id'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(vehicle['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(vehicle['status']).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            vehicle['status'],
                            style: TextStyle(
                              color: _getStatusColor(vehicle['status']),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 4),
                            Expanded(child: Text(vehicle['driver'])),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 4),
                            Expanded(child: Text(vehicle['phoneNumber'])),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Vehicle Details Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    'Vehicle Type',
                                    vehicle['vehicleType'],
                                    Icons.directions_car,
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Plate Number',
                                    vehicle['plateNumber'],
                                    Icons.confirmation_number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    'Location',
                                    vehicle['location'],
                                    Icons.location_on,
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Speed',
                                    vehicle['speed'],
                                    Icons.speed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    'Fuel Level',
                                    vehicle['fuel'],
                                    Icons.local_gas_station,
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Last Update',
                                    vehicle['lastUpdate'],
                                    Icons.update,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Action Buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildActionButton(
                                  'Call Driver',
                                  Icons.phone,
                                  Colors.green,
                                  () => _callDriver(vehicle),
                                ),
                                _buildActionButton(
                                  'Send SMS',
                                  Icons.sms,
                                  Colors.blue,
                                  () => _sendSMS(vehicle),
                                ),
                                _buildActionButton(
                                  'Track Live',
                                  Icons.location_on,
                                  Colors.orange,
                                  () => _trackVehicle(vehicle),
                                ),
                                _buildActionButton(
                                  'View Details',
                                  Icons.info,
                                  Colors.purple,
                                  () => _showVehicleDetails(vehicle),
                                ),
                                _buildActionButton(
                                  'Edit',
                                  Icons.edit,
                                  Colors.teal,
                                  () => _editVehicle(vehicle),
                                ),
                                _buildActionButton(
                                  'Remove',
                                  Icons.delete,
                                  Colors.red,
                                  () => _removeVehicle(vehicle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).primaryColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Idle':
        return Colors.orange;
      case 'Offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'Truck':
        return Icons.local_shipping;
      case 'Van':
        return Icons.airport_shuttle;
      case 'Car':
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }

  void _showAddVehicleDialog() {
    _vehicleIdController.clear();
    _driverNameController.clear();
    _phoneNumberController.clear();
    _plateNumberController.clear();
    _selectedVehicleType = 'Car';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _vehicleIdController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle ID *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                    hintText: 'e.g., VH-006',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _driverNameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Enter driver full name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '+1-555-0128',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _plateNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Plate Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.confirmation_number),
                    hintText: 'e.g., ABC-123',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: ['Car', 'Van', 'Truck']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The phone number will be used for GPS tracking and driver communication.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addVehicle,
            child: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }

  void _addVehicle() {
    if (_vehicleIdController.text.isEmpty ||
        _driverNameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _plateNumberController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    // Check if vehicle ID already exists
    if (_vehicles.any((vehicle) => vehicle['id'] == _vehicleIdController.text)) {
      Get.snackbar(
        'Error',
        'Vehicle ID already exists',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    // Check if phone number already exists
    if (_vehicles.any((vehicle) => vehicle['phoneNumber'] == _phoneNumberController.text)) {
      Get.snackbar(
        'Error',
        'Phone number already registered',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    setState(() {
      _vehicles.add({
        'id': _vehicleIdController.text,
        'driver': _driverNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'status': 'Offline',
        'location': 'Unknown',
        'speed': '0 km/h',
        'fuel': '100%',
        'lastUpdate': 'Just added',
        'vehicleType': _selectedVehicleType,
        'plateNumber': _plateNumberController.text,
      });
    });

    Navigator.pop(context);
    Get.snackbar(
      'Success',
      'Vehicle ${_vehicleIdController.text} added successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _callDriver(Map<String, dynamic> vehicle) {
    Get.snackbar(
      'Calling Driver',
      'Calling ${vehicle['driver']} at ${vehicle['phoneNumber']}',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.phone, color: Colors.white),
    );
  }

  void _sendSMS(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send SMS to ${vehicle['driver']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Phone: ${vehicle['phoneNumber']}'),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Enter your message...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.snackbar(
                'SMS Sent',
                'Message sent to ${vehicle['driver']}',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                icon: const Icon(Icons.sms, color: Colors.white),
              );
            },
            child: const Text('Send SMS'),
          ),
        ],
      ),
    );
  }

  void _trackVehicle(Map<String, dynamic> vehicle) {
    Get.snackbar(
      'Live Tracking',
      'Starting live tracking for ${vehicle['id']}',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.location_on, color: Colors.white),
    );
  }

  void _showVehicleDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vehicle['id']} Details'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Driver', vehicle['driver']),
              _buildDetailRow('Phone', vehicle['phoneNumber']),
              _buildDetailRow('Vehicle Type', vehicle['vehicleType']),
              _buildDetailRow('Plate Number', vehicle['plateNumber']),
              _buildDetailRow('Status', vehicle['status']),
              _buildDetailRow('Location', vehicle['location']),
              _buildDetailRow('Speed', vehicle['speed']),
              _buildDetailRow('Fuel Level', vehicle['fuel']),
              _buildDetailRow('Last Update', vehicle['lastUpdate']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editVehicle(Map<String, dynamic> vehicle) {
    _vehicleIdController.text = vehicle['id'];
    _driverNameController.text = vehicle['driver'];
    _phoneNumberController.text = vehicle['phoneNumber'];
    _plateNumberController.text = vehicle['plateNumber'];
    _selectedVehicleType = vehicle['vehicleType'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vehicle'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _vehicleIdController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                  enabled: false, // Don't allow changing ID
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _driverNameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _plateNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Plate Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: ['Car', 'Van', 'Truck']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateVehicle(vehicle),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updateVehicle(Map<String, dynamic> originalVehicle) {
    if (_driverNameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _plateNumberController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    setState(() {
      final index = _vehicles.indexWhere((v) => v['id'] == originalVehicle['id']);
      if (index != -1) {
        _vehicles[index] = {
          ..._vehicles[index],
          'driver': _driverNameController.text,
          'phoneNumber': _phoneNumberController.text,
          'plateNumber': _plateNumberController.text,
          'vehicleType': _selectedVehicleType,
        };
      }
    });

    Navigator.pop(context);
    Get.snackbar(
      'Success',
      'Vehicle ${originalVehicle['id']} updated successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _removeVehicle(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Vehicle'),
        content: Text('Are you sure you want to remove ${vehicle['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _vehicles.removeWhere((v) => v['id'] == vehicle['id']);
              });
              Navigator.pop(context);
              Get.snackbar(
                'Success',
                'Vehicle ${vehicle['id']} removed successfully!',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                icon: const Icon(Icons.delete, color: Colors.white),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
