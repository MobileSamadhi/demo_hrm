import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../views/dashboard.dart'; // Update this import based on your project structure
import '../constants.dart'; // Contains endpoint and utility methods like `getApiUrl`

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
    final String apiUrl = getApiUrl(attendanceSummaryEndpoint);

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
  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text(
        'Attendance Summary',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      backgroundColor: Color(0xFF0D9494).withOpacity(0.9),
      leading: CupertinoButton(
        child: Icon(CupertinoIcons.back, color: CupertinoColors.white),
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => DashboardPage(emId: '')),
          );
        },
      ),
    )
        : AppBar(
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
            MaterialPageRoute(builder: (context) => DashboardPage(emId: '')),
          );
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
        child: _isLoading
            ? Center(
          child: Platform.isIOS
              ? CupertinoActivityIndicator()
              : CircularProgressIndicator(color: Color(0xFF0D9494)),
        )
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
        headingRowColor: MaterialStateColor.resolveWith((states) => Color(0xFF0D9494)),
        columns: [
          DataColumn(label: Text('Date', style: _tableHeaderStyle())),
          DataColumn(label: Text('Sign In', style: _tableHeaderStyle())),
          DataColumn(label: Text('Sign Out', style: _tableHeaderStyle())),
          DataColumn(label: Text('Hours', style: _tableHeaderStyle())),
          DataColumn(label: Text('Status', style: _tableHeaderStyle())),
        ],
        rows: _attendanceList.map((attendance) {
          return DataRow(
            cells: [
              DataCell(Text(attendance.date)),
              DataCell(Text(attendance.signInTime)),
              DataCell(Text(attendance.signOutTime)),
              DataCell(Text(attendance.workingHours)),
              DataCell(Text(
                attendance.status,
                style: TextStyle(
                  color: attendance.status == 'Approved'
                      ? Colors.green
                      : attendance.status == 'Rejected'
                      ? Colors.red
                      : Color(0xFF0D9494),
                  fontWeight: FontWeight.bold,
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
}
