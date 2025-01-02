import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _fetchLeaveData() async {
    // Set the fixed API URL
    const String apiUrl = 'https://macksonsmobi.synnexcloudpos.com/leave_summary.php';

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Make the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId, // Pass session ID in headers
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> leaveData = data['data'];
          setState(() {
            _leaveList =
                leaveData.map((leave) => LeaveSummary.fromJson(leave)).toList();
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        columns: [
          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Start', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('End', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
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
