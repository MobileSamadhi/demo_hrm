import 'dart:io'; // For Platform checks
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants.dart';
import 'dashboard.dart';

class LeaveApplicationPage extends StatefulWidget {
  final String emId; // Accept em_id as a parameter

  LeaveApplicationPage({required this.emId});

  @override
  _LeaveApplicationPageState createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final _formKey = GlobalKey<FormState>();

  // Fields for the form
  late String _employeeId = widget.emId;
  String _leaveType = 'Select Here..';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _leaveDuration = '';
  String _applyDate = DateTime.now().toLocal().toString().split(' ')[0]; // Today's date
  String _reason = '';
  String _role = 'Select Here..'; // Default role

  /// Fetch database details for a given company code
  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        } else {
          print('Invalid response data: $data');
          return null;
        }
      } else {
        print('Error: Failed to fetch database details. Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching database details: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Save the form values into state variables

      try {
        // Fetch company code from shared preferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? companyCode = prefs.getString('company_code');

        if (companyCode == null || companyCode.isEmpty) {
          throw Exception('Company code is missing. Please log in again.');
        }

        // Fetch database details using the company code
        final dbDetails = await fetchDatabaseDetails(companyCode);
        if (dbDetails == null) {
          throw Exception('Failed to fetch database details.');
        }

        // Prepare API URL for submitting the leave application
        final url = getApiUrl(leaveApplicationEndpoint);

        // Prepare the payload with all required fields
        final Map<String, dynamic> payload = {
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
          'em_id': _employeeId,
          'typeid': 1, // Replace with actual type ID if needed
          'leave_type': _leaveType,
          'start_date': _startDate.toLocal().toString().split(' ')[0],
          'end_date': _endDate.toLocal().toString().split(' ')[0],
          'leave_duration': _leaveDuration,
          'apply_date': _applyDate,
          'reason': _reason,
          'role': _role,
        };

        print('Submitting leave application with payload: $payload'); // Debug log

        // Send the POST request to the server
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        // Handle the server response
        print('Response Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          final String status = result['status'] ?? 'error';
          final String message = result['message'] ?? 'Unknown error';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$status: $message')),
          );
        } else {
          throw Exception('Failed to connect to the server. Status code: ${response.statusCode}');
        }
      } catch (e) {
        // Handle any exceptions during the process
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  // Show a snackbar with a message
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Select start date
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate; // Ensure the end date is not before the start date
        }
      });
    }
  }

  // Select end date
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate, // Ensure endDate is after startDate
      firstDate: _startDate, // Prevent selecting an end date before the start date
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leave Application',
          style: TextStyle(
            color: Colors.white,
            fontSize: Platform.isIOS ? 20 : 22, // Different font size for iOS
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(
            Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave Application Form',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9494),
                ),
              ),
              SizedBox(height: 20),

              // Employee ID Field
              // Employee ID Field
              _buildFormCard(
                title: 'Employee Details',
                child: _buildTextFormField(
                  labelText: 'Employee ID',
                  icon: Icons.person,
                  initialValue: _employeeId,
                  readOnly: true,
                ),
              ),

              SizedBox(height: 20),

              _buildFormCard(
                title: 'User Role',
                child: _buildDropdownButtonFormField(
                  labelText: 'Role',
                  icon: Icons.person,
                  value: _role,
                  items: [
                    'Select Here..',
                    'EMPLOYEE',
                    'MANAGER',
                    'ADMIN',
                    'SUPERADMIN',
                  ],
                  onChanged: (newValue) => setState(() => _role = newValue!),
                ),
              ),
              SizedBox(height: 20),

              // Leave Type Dropdown
              _buildFormCard(
                title: 'Leave Details',
                child: _buildDropdownButtonFormField(
                  labelText: 'Leave Type',
                  icon: Icons.category,
                  value: _leaveType,
                  items: [
                    'Select Here..',
                    'Leave Without Pay',
                    'Public Holiday',
                    'Paternal Leave',
                    'Maternity Leave',
                    'Sick Leave',
                    'Casual Leave',
                  ],
                  onChanged: (newValue) => setState(() => _leaveType = newValue!),
                ),
              ),
              SizedBox(height: 20),

              // Date Pickers
              _buildFormCard(
                title: 'Leave Dates',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Start Date: ${_startDate.toLocal().toString().split(' ')[0]}'),
                      trailing: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: _selectStartDate,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('End Date: ${_endDate.toLocal().toString().split(' ')[0]}'),
                      trailing: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: _selectEndDate,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Reason Field
              _buildFormCard(
                title: 'Reason for Leave',
                child: _buildTextFormField(
                  labelText: 'Leave Reason',
                  icon: Icons.comment,
                  maxLines: 3,
                  onSaved: (value) => _reason = value ?? '',
                ),
              ),

              SizedBox(height: 20),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D9494), // Button color
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


// Helper method to build TextFormField
  // Helper method to build TextFormField
  Widget _buildTextFormField({
    required String labelText,
    required IconData icon,
    int? maxLines,
    FormFieldSetter<String>? onSaved,
    String? initialValue,
    bool readOnly = false,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }


  // Helper method to build DropdownButtonFormField
  Widget _buildDropdownButtonFormField({
    required String labelText,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value == 'Select Here..') {
          return 'Please select a value from the list.';
        }
        return null;
      },
    );
  }

  // Helper method to build a card for form sections
  Widget _buildFormCard({required String title, required Widget child}) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9494),
              ),
            ),
            SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
