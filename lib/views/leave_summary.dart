import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../views/dashboard.dart'; // Update this import based on your project structure
import '../constants.dart'; // Contains endpoint and utility methods like `getApiUrl`

// Model for Leave Summary
class LeaveSummary {
  final String id;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String duration;
  final String applyDate;
  final String reason;
  final String status;

  LeaveSummary({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.applyDate,
    required this.reason,
    required this.status,
  });

  factory LeaveSummary.fromJson(Map<String, dynamic> json) {
    return LeaveSummary(
      id: json['id'].toString(),
      leaveType: json['leave_type'] ?? 'Unknown Leave Type',
      startDate: json['start_date'] ?? 'N/A',
      endDate: json['end_date'] ?? 'N/A',
      duration: json['leave_duration'] ?? 'N/A',
      applyDate: json['apply_date'] ?? 'N/A',
      reason: json['reason'] ?? 'No reason provided',
      status: json['leave_status'] ?? 'Pending',
    );
  }
}

class LeaveSummaryPage extends StatefulWidget {
  final String sessionId;

  LeaveSummaryPage({required this.sessionId});

  @override
  _LeaveSummaryPageState createState() => _LeaveSummaryPageState();
}

class _LeaveSummaryPageState extends State<LeaveSummaryPage> {
  List<LeaveSummary> _leaveList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaveData();
  }

  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      // Log the response code and body for debugging
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Check if the response contains valid data
        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        } else {
          print('Invalid response: ${data}');
          return null;
        }
      } else {
        // Handle non-200 status codes
        print('Error fetching database details. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching database details: $e');
      return null;
    }
  }


// Initialize the notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> _fetchLeaveData() async {
    final String apiUrl = getApiUrl(leaveSummaryEndpoint);

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details. Please log in again.');
      }

      final Map<String, dynamic> payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
      };

      print('Fetching leave data with payload: $payload');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
        body: jsonEncode(payload),
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> leaveData = data['data'];
          List<LeaveSummary> leaveList = leaveData
              .map((leave) => LeaveSummary.fromJson(leave))
              .toList();

          // Find the latest approved or rejected leave
          LeaveSummary? latestLeave = leaveList.firstWhere(
                (leave) => leave.status == 'Approved' || leave.status == 'Rejected',
            orElse: () => LeaveSummary(id: '', leaveType: '', startDate: '', endDate: '', duration: '', applyDate: '', reason: '', status: ''),
          );

          if (latestLeave.id.isNotEmpty) {
            // Show local push notification
            showLeaveNotification(latestLeave);
          }

          setState(() {
            _leaveList = leaveList;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Unknown error occurred.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch leave data. HTTP Status: ${response.statusCode}';
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

  Future<void> showLeaveNotification(LeaveSummary leave) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'leave_channel',
      'Leave Notifications',
      channelDescription: 'Notifies when leave is approved or rejected',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Leave ${leave.status}', // Title
      'Your leave from ${leave.startDate} to ${leave.endDate} has been ${leave.status.toLowerCase()}.', // Body
      notificationDetails,
    );
  }



  @override
  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text(
        'Leave Summary',
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
        'Leave Summary',
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
            : _leaveList.isEmpty
            ? _buildEmptyState()
            : _buildLeaveTable(),
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
            'No Leave Records Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith((states) => Color(0xFF0D9494)),
        columns: [
          DataColumn(label: Text('Type', style: _tableHeaderStyle())),
          DataColumn(label: Text('Start', style: _tableHeaderStyle())),
          DataColumn(label: Text('End', style: _tableHeaderStyle())),
          DataColumn(label: Text('Duration', style: _tableHeaderStyle())),
          DataColumn(label: Text('Status', style: _tableHeaderStyle())),
        ],
        rows: _leaveList.map((leave) {
          return DataRow(cells: [
            DataCell(Text(leave.leaveType)),
            DataCell(Text(leave.startDate)),
            DataCell(Text(leave.endDate)),
            DataCell(Text(leave.duration)),
            DataCell(Text(
              leave.status,
              style: TextStyle(
                color: leave.status == 'Approved'
                    ? Colors.green
                    : leave.status == 'Rejected'
                    ? Colors.red
                    : Color(0xFF0D9494),
                fontWeight: FontWeight.bold,
              ),
            )),
          ]);
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
