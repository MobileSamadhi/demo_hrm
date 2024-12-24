import 'package:flutter/material.dart';

import '../views/dashboard.dart';



class Leave extends StatefulWidget {
  @override
  _LeaveState createState() => _LeaveState();
}

class _LeaveState extends State<Leave> {
  final _formKey = GlobalKey<FormState>();

  String? _leaveType;
  int _leaveDays = 0;
  String? _leaveYear;

  List<String> leaveTypes = [
    'Select Here...',
    'Leave Without Pay',
    'Public Holiday',
    'Paternal Leave',
    'Maternity Leave',
    'Sick Leave',
    'Casual Leave'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:  Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave Type Dropdown
              DropdownButtonFormField<String>(
                value: _leaveType,
                decoration: InputDecoration(
                  labelText: 'Leave Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: leaveTypes.map((String leaveType) {
                  return DropdownMenuItem<String>(
                    value: leaveType,
                    child: Text(leaveType),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _leaveType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value == 'Select Here...') {
                    return 'Please select a leave type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Leave Days
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Leave Days',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _leaveDays = int.tryParse(value) ?? 0;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter leave days';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Leave Year Dropdown
              DropdownButtonFormField<String>(
                value: _leaveYear,
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.date_range),
                ),
                items: ['Select Here...', '2024', '2025', '2026'].map((String year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _leaveYear = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value == 'Select Here...') {
                    return 'Please select a year';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Process leave request here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Leave Request Submitted')),
                    );
                  }
                },
                child: Text('Submit Leave Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
