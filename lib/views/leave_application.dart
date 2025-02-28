import 'dart:io'; // For Platform checks
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants.dart';
import '../notification.dart';
import 'dashboard.dart';

class LeaveApplicationPage extends StatefulWidget {
  final String emId;
  final String role;

  LeaveApplicationPage({required this.emId, required this.role});

  @override
  _LeaveApplicationPageState createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final _formKey = GlobalKey<FormState>();

  // Fields for the form
  late String _employeeId = widget.emId;
  String? _selectedLeaveType;
  int? _selectedTypeId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _leaveDuration = '';
  String _applyDate = DateTime.now().toLocal().toString().split(' ')[0]; // Today's date
  String _reason = '';
  late String _role = widget.role;

  // List of leave types
  List<Map<String, dynamic>> _leaveTypes = [];
  bool _isLoadingLeaveTypes = false;

  // Fetch leave types from API
  Future<void> _fetchLeaveTypes() async {
    setState(() => _isLoadingLeaveTypes = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    if (companyCode == null || companyCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Company code is missing. Please log in again.')),
      );
      return;
    }

    // Fetch database details first
    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch database details.')),
      );
      return;
    }

    // Call the leave types API
    try {
      final url = getApiUrl(leaveTypeEndpoint);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
        }),
      );


      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Parsed leave types: $data');
        setState(() {
          _leaveTypes = data
              .where((item) => item['type_id'] != null && item['name'] != null)
              .map((item) => {
            'id': item['type_id'], // Map type_id to id
            'type_name': item['name'], // Map name to type_name
          })
              .toList();
        });
        print('Mapped leave types: $_leaveTypes');
      } else {
        throw Exception('Failed to fetch leave types. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching leave types: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching leave types: $e')),
      );
    } finally {
      setState(() => _isLoadingLeaveTypes = false);
    }
  }

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
      _formKey.currentState!.save(); // Save form values

      if (_selectedTypeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a leave type.')),
        );
        return;
      }

      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? companyCode = prefs.getString('company_code');

        if (companyCode == null || companyCode.isEmpty) {
          throw Exception('Company code is missing. Please log in again.');
        }

        final dbDetails = await fetchDatabaseDetails(companyCode);
        if (dbDetails == null) {
          throw Exception('Failed to fetch database details.');
        }

        final url = getApiUrl(leaveApplicationEndpoint);

        final Map<String, dynamic> payload = {
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
          'em_id': _employeeId,
          'typeid': _selectedTypeId,
          'leave_type': _selectedLeaveType,
          'start_date': _startDate.toLocal().toString().split(' ')[0],
          'end_date': _endDate.toLocal().toString().split(' ')[0],
          'leave_duration': _calculateLeaveDuration(),
          'apply_date': _applyDate,
          'reason': _reason,
          'role': _role,
        };

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          final String status = result['status'] ?? 'error';
          final String message = result['message'] ?? 'Unknown error';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$status: $message'),
              backgroundColor: Colors.green,
            ),
          );

          // ✅ Send local notification after successful leave application submission
          await NotificationService.showLocalNotification(
            "Leave Application Submitted",
            "Employee $_employeeId applied for leave from ${_startDate.toLocal().toString().split(' ')[0]} to ${_endDate.toLocal().toString().split(' ')[0]}.",
          );

          _clearForm();
        } else {
          throw Exception('Failed to connect to the server. Status code: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('Form validation failed.');
    }
  }


  void _clearForm() {
    setState(() {
      _selectedLeaveType = null; // Reset dropdown
      _selectedTypeId = null;
      _selectedLeaveType = '';
      _startDate = DateTime.now(); // Reset start date
      _endDate = DateTime.now(); // Reset end date
      _leaveDuration = ''; // Reset leave duration
      _reason = ''; // Clear reason
    });
    _formKey.currentState!.reset(); // Reset form validation state
  }



  String _calculateLeaveDuration() {
    int difference = _endDate.difference(_startDate).inDays + 1;
    return difference.toString(); // Convert to string
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
  void initState() {
    super.initState();
    _fetchLeaveTypes();
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
                child: _buildTextFormField(
                  labelText: 'Employee Role',
                  icon: Icons.person,
                  initialValue: _role,
                  readOnly: true,
                ),
              ),

              SizedBox(height: 20),

              // Leave Type Dropdown
              _buildFormCard(
                title: 'Leave Details',
                child:
                _buildDropdownButtonFormField(
                  labelText: 'Leave Type',
                  icon: Icons.category,
                  value: _selectedLeaveType,
                  items: [
                    ..._leaveTypes.map((item) => DropdownMenuItem<String>(
                      value: item['type_name'],
                      child: Text(item['type_name']!),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLeaveType = value;
                      _selectedTypeId = value == 'Select Here..'
                          ? null
                          : _leaveTypes
                          .firstWhere((item) => item['type_name'] == value)['id'];
                    });
                  },
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
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
      validator: (value) =>
      value == null || value.isEmpty ? 'Please select $labelText' : null,
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