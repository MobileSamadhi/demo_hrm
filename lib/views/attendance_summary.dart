import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../views/dashboard.dart'; // Update this import based on your project structure
import '../constants.dart'; // Contains endpoint and utility methods like `getApiUrl`

// Model for Attendance Summary
class AttendanceSummary {
  final String id;
  final String date;
  final String signInTime;
  final String signOutTime;
  final String workingHours;
  final String place;
  final String absence;
  final String overtime;
  final String status;

  AttendanceSummary({
    required this.id,
    required this.date,
    required this.signInTime,
    required this.signOutTime,
    required this.workingHours,
    required this.place,
    required this.absence,
    required this.overtime,
    required this.status,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      id: json['id'].toString(),
      date: json['atten_date'] ?? 'N/A',
      signInTime: json['signin_time'] ?? 'N/A',
      signOutTime: json['signout_time'] ?? 'N/A',
      workingHours: json['working_hour'] ?? 'N/A',
      place: json['place'] ?? 'Unknown',
      absence: json['absence'] ?? 'No',
      overtime: json['overtime'] ?? 'None',
      status: json['status'] ?? 'Pending',
    );
  }
}

class AttendanceSummaryPage extends StatefulWidget {
  final String sessionId;

  AttendanceSummaryPage({required this.sessionId});

  @override
  _AttendanceSummaryPageState createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  List<AttendanceSummary> _attendanceList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    const String apiUrl = 'https://macksonsmobi.synnexcloudpos.com/attendance_summary.php';

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> attendanceData = data['data'];
          setState(() {
            _attendanceList = attendanceData
                .map((attendance) => AttendanceSummary.fromJson(attendance))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
          'Failed to fetch attendance data. HTTP Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Summary',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D9494),
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? _buildErrorState()
            : _attendanceList.isEmpty
            ? _buildEmptyState()
            : _buildAttendanceTable(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.beach_access, size: 100, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Attendance Records Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Hours', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _attendanceList.map((attendance) {
          return DataRow(cells: [
            DataCell(Text(attendance.date)),
            DataCell(Text(attendance.signInTime)),
            DataCell(Text(attendance.signOutTime)),
            DataCell(Text(attendance.workingHours)),
            DataCell(Text(
              attendance.status,
              style: TextStyle(
                color: attendance.status == 'Present'
                    ? Colors.green
                    : attendance.status == 'Absent'
                    ? Colors.red
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
