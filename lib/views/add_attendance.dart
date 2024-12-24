import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants.dart';
import 'dashboard.dart';

class AddAttendancePage extends StatefulWidget {
  final String emCode; // Accept em_id as a parameter

  AddAttendancePage({required this.emCode});

  @override
  _AddAttendancePageState createState() => _AddAttendancePageState();
}

class _AddAttendancePageState extends State<AddAttendancePage> {
  final _formKey = GlobalKey<FormState>();
  late String _employeeCode = widget.emCode;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _signinTimeController = TextEditingController();
  final TextEditingController _signoutTimeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _workingHoursController = TextEditingController();

  String? _selectedPlace;
  final List<String> _placeOptions = ['Office', 'Field'];

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
      final formattedTime = pickedTime.format(context); // e.g., 09:30 AM
      setState(() {
        controller.text = formattedTime;
        _calculateAndSetWorkingHours(); // Calculate working hours when time is selected
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
    final format = RegExp(r'(\d+):(\d+) (AM|PM)');
    var signInMatch = format.firstMatch(signInTime);
    var signOutMatch = format.firstMatch(signOutTime);

    if (signInMatch == null || signOutMatch == null) return '0 hours';

    int signInHour = int.parse(signInMatch.group(1)!);
    int signInMinute = int.parse(signInMatch.group(2)!);
    int signOutHour = int.parse(signOutMatch.group(1)!);
    int signOutMinute = int.parse(signOutMatch.group(2)!);

    // Convert to 24-hour format
    if (signInMatch.group(3) == 'PM' && signInHour != 12) signInHour += 12;
    if (signOutMatch.group(3) == 'PM' && signOutHour != 12) signOutHour += 12;
    if (signInMatch.group(3) == 'AM' && signInHour == 12) signInHour = 0;
    if (signOutMatch.group(3) == 'AM' && signOutHour == 12) signOutHour = 0;

    final signIn = Duration(hours: signInHour, minutes: signInMinute);
    final signOut = Duration(hours: signOutHour, minutes: signOutMinute);
    final workingDuration = signOut - signIn;

    // Handle negative duration (e.g., crossing midnight)
    if (workingDuration.isNegative) {
      final nextDayDuration = Duration(hours: 24) - signIn + signOut;
      return "${nextDayDuration.inHours} hours";
    }

    // Return formatted working hours
    return "${workingDuration.inHours} hours";
  }

      Future<void> _submitAttendance() async {
        if (_formKey.currentState!.validate()) {
          if (_dateController.text.isEmpty ||
              _signinTimeController.text.isEmpty ||
              _signoutTimeController.text.isEmpty ||
              _workingHoursController.text.isEmpty ||
              _selectedPlace == null) {

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
            );
            return;
          }

      final url = getApiUrl(addAttendanceEndpoint);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'emp_id': _employeeCode,
          'atten_date': _dateController.text,
          'signin_time': _signinTimeController.text,
          'signout_time': _signoutTimeController.text,
          'working_hour': _workingHoursController.text,
          'place': _selectedPlace,
          'reason': _reasonController.text,
        }),
      );

      final result = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Employee ID
              TextFormField(
                initialValue: _employeeCode,
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

              // Sign-in Time
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

              // Sign-out Time
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

              // Reason for Absence or Late

              // Working Hours
              TextFormField(
                controller: _workingHoursController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Working Hours',
                  prefixIcon: Icon(Icons.work_history, color: Color(0xFF0D9494)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter working hours' : null,
              ),
              SizedBox(height: 16),

              // Place Dropdown
              DropdownButtonFormField<String>(
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
