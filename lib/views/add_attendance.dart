import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../constants.dart';
import 'dashboard.dart';

class AddAttendancePage extends StatefulWidget {
  final String emId; // Accept em_id as a parameter
  final String role;

  AddAttendancePage({required this.emId, required this.role});

  @override
  _AddAttendancePageState createState() => _AddAttendancePageState();
}

class _AddAttendancePageState extends State<AddAttendancePage> {
  final _formKey = GlobalKey<FormState>();
  late String _employeeId = widget.emId;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _signinTimeController = TextEditingController();
  final TextEditingController _signoutTimeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _workingHoursController = TextEditingController();
  late String _employeeRole = widget.role;


  String? _selectedPlace;
  final List<String> _placeOptions = ['Office', 'Field'];

  String _selectedAttendanceType = "Sign In";

  @override
  void initState() {
    super.initState();
    _workingHoursController.text = '0 hours'; // Initialize working hours
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Format the time in AM/PM
      final formattedTime = DateFormat.jm().format(selectedTime);
      setState(() {
        controller.text = formattedTime; // Update the text field
        _calculateAndSetWorkingHours(); // Recalculate working hours
      });
    }
  }

  void _calculateAndSetWorkingHours() {
    final signInTime = _signinTimeController.text;
    final signOutTime = _signoutTimeController.text;

    if (signInTime.isNotEmpty && signOutTime.isNotEmpty) {
      _workingHoursController.text = _calculateWorkingHours(signInTime, signOutTime);
    }
  }

  String _calculateWorkingHours(String signInTime, String signOutTime) {
    final dateFormat = DateFormat.jm(); // Handles AM/PM format, e.g., "10:00 AM"
    try {
      // Parse the sign-in and sign-out times
      final signIn = dateFormat.parse(signInTime);
      final signOut = dateFormat.parse(signOutTime);

      // Calculate the duration
      Duration workingDuration = signOut.difference(signIn);

      // Handle crossing midnight
      if (workingDuration.isNegative) {
        workingDuration += Duration(hours: 24); // Add a day if the time crosses midnight
      }

      // Format hours and minutes
      final hours = workingDuration.inHours;
      final minutes = workingDuration.inMinutes.remainder(60);

      return "$hours hours $minutes minutes";
    } catch (e) {
      // Return "0 hours" if parsing fails
      return '0 hours 0 minutes';
    }
  }


  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

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
        }
      }
    } catch (e) {
      print('Error fetching database details: $e');
    }
    return null;
  }
  Future<void> _submitAttendance() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint("DEBUG: Form validation failed.");
      return;
    }

    debugPrint("DEBUG: Form validation passed!");

    // Validate required fields
    if (_dateController.text.isEmpty ||
        (_selectedAttendanceType == "Sign In" && _signinTimeController.text.isEmpty) ||
        (_selectedAttendanceType == "Sign Out" && _signoutTimeController.text.isEmpty) ||
        _selectedPlace == null) {

      debugPrint("DEBUG: Validation failed!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    if (companyCode == null || companyCode.isEmpty) {
      _showErrorDialog("Company code is missing. Please log in again.");
      return;
    }

    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      _showErrorDialog("Failed to fetch database details. Please log in again.");
      return;
    }

    final url = getApiUrl(addAttendanceEndpoint);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'database_host': dbDetails['database_host'] ?? '',
          'database_name': dbDetails['database_name'] ?? '',
          'database_username': dbDetails['database_username'] ?? '',
          'database_password': dbDetails['database_password'] ?? '',
          'company_code': companyCode,
          'emp_id': _employeeId,
          'atten_date': _dateController.text,
          'signin_time': _selectedAttendanceType == "Sign In" ? _signinTimeController.text : null,
          'signout_time': _selectedAttendanceType == "Sign Out" ? _signoutTimeController.text : null,
          'working_hour': _workingHoursController.text.isNotEmpty ? _workingHoursController.text : '0 hours 0 minutes',
          'place': _selectedPlace ?? 'Unknown Place',
          'reason': _reasonController.text.isEmpty ? 'No reason provided' : _reasonController.text,
          'role': _employeeRole,
        }),
      );

      final result = json.decode(response.body);
      debugPrint("DEBUG: API Response -> $result");

      if (result['success'] == true) {
        _showSuccessDialog(result['message']);

        // Reset form on success
        _formKey.currentState!.reset();
        _dateController.clear();
        _signinTimeController.clear();
        _signoutTimeController.clear();
        _workingHoursController.text = '0 hours';
        _reasonController.clear();
        setState(() {
          _selectedPlace = null;
        });

      } else {
        // Show the exact API error message
        if (result.containsKey('error')) {
          _showErrorDialog(result['error']);  // This ensures correct message is displayed
        } else {
          _showErrorDialog("Something went wrong. Please try again.");
        }
      }
    } catch (e) {
      debugPrint("ERROR: $e");
      _showErrorDialog("Something went wrong. Please try again.");
    }
  }

// Show error popup
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFF0D9494)), // Icon for error
            SizedBox(width: 8),
            Text(
              "Error",
              style: TextStyle(
                color: Color(0xFF0D9494), // Custom title color
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16, color: Colors.black87), // Styled content text
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF0D9494), // Button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded button
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }


// Show success popup
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF0D9494)), // Success Icon
            SizedBox(width: 8),
            Text(
              "Success",
              style: TextStyle(
                color: Color(0xFF0D9494), // Custom title color
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16, color: Colors.black87), // Styled content text
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF0D9494), // Button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded button
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }




  @override
  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text(
        'Add Attendance',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Color(0xFF0D9494).withOpacity(0.9),
      leading: CupertinoButton(
        child: Icon(CupertinoIcons.back, color: CupertinoColors.white),
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    )
        : AppBar(
      title: Text(
        'Add Attendance',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Color(0xFF0D9494),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Employee ID (Read-Only)
              TextFormField(
                initialValue: _employeeId,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Employee ID',
                  prefixIcon: Icon(Icons.badge, color: Color(0xFF0D9494)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              SizedBox(height: 16),

              // Attendance Date
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Attendance Date',
                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0D9494)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.date_range, color: Color(0xFF0D9494)),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) => value == null || value.isEmpty ? 'Please select a date' : null,
              ),
              SizedBox(height: 16),

              // Employee Role (Read-Only)
              TextFormField(
                initialValue: _employeeRole,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Employee Role',
                  prefixIcon: Icon(Icons.badge, color: Color(0xFF0D9494)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              SizedBox(height: 20),

              // Sign In / Sign Out Option
              Text("Attendance Type:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text("Sign In"),
                      value: "Sign In",
                      groupValue: _selectedAttendanceType,
                      onChanged: (value) {
                        setState(() {
                          _selectedAttendanceType = value!;
                          _signoutTimeController.clear(); // Clear Sign Out time when Sign In is selected
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text("Sign Out"),
                      value: "Sign Out",
                      groupValue: _selectedAttendanceType,
                      onChanged: (value) {
                        setState(() {
                          _selectedAttendanceType = value!;
                          _signinTimeController.clear(); // Clear Sign In time when Sign Out is selected
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Sign-in Time (Show only if Sign In is selected)
              if (_selectedAttendanceType == "Sign In") ...[
                TextFormField(
                  controller: _signinTimeController,
                  decoration: InputDecoration(
                    labelText: 'Sign-in Time',
                    prefixIcon: Icon(Icons.timer, color: Color(0xFF0D9494)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.access_time, color: Color(0xFF0D9494)),
                      onPressed: () => _selectTime(context, _signinTimeController),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) => value == null || value.isEmpty ? 'Please select sign-in time' : null,
                ),
                SizedBox(height: 16),
              ],

              // Sign-out Time (Show only if Sign Out is selected)
              if (_selectedAttendanceType == "Sign Out") ...[
                TextFormField(
                  controller: _signoutTimeController,
                  decoration: InputDecoration(
                    labelText: 'Sign-out Time',
                    prefixIcon: Icon(Icons.timer_off, color: Color(0xFF0D9494)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.access_time, color: Color(0xFF0D9494)),
                      onPressed: () => _selectTime(context, _signoutTimeController),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) => value == null || value.isEmpty ? 'Please select sign-out time' : null,
                ),
                SizedBox(height: 16),
              ],

              // Working Hours (Auto-calculated)
              TextFormField(
                controller: _workingHoursController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Working Hours',
                  prefixIcon: Icon(Icons.work_history, color: Color(0xFF0D9494)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              SizedBox(height: 16),

              // Place Dropdown
              DropdownButtonFormField<String?>(
                value: _selectedPlace,
                items: _placeOptions
                    .map((place) => DropdownMenuItem(value: place, child: Text(place)))
                    .toList(),
                decoration: InputDecoration(
                  labelText: 'Place',
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF0D9494)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onChanged: (value) => setState(() => _selectedPlace = value),
                validator: (value) => value == null || value.isEmpty ? 'Please select a place' : null,
              ),
              SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: _submitAttendance,
                child: Text('Submit', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Color(0xFF0D9494),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}
