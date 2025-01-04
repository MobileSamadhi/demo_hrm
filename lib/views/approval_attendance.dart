import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart'; // Replace with your constants file path
import 'dashboard.dart'; // Replace with your dashboard page file path

class AttendanceApprovalPage extends StatefulWidget {
  final String? emId;
  final String role;

  AttendanceApprovalPage({this.emId, required this.role});

  @override
  _AttendanceApprovalPageState createState() => _AttendanceApprovalPageState();
}

class _AttendanceApprovalPageState extends State<AttendanceApprovalPage> {
  List<dynamic>? attendanceRequests;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRequests();
  }

  Future<void> _fetchAttendanceRequests() async {
    try {
      final url = getApiUrl(fetchAttendanceRequestsEndpoint);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'em_id': widget.emId, 'role': widget.role}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            attendanceRequests = responseData['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
          _showSnackbar('Error: ${responseData['message']}');
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        _showSnackbar('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showSnackbar('An error occurred: $e');
    }
  }

  Future<void> _updateAttendanceStatus(int attendanceId, String status, int index) async {
    try {
      final url = getApiUrl(updateAttendanceStatusEndpoint);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'attendance_id': attendanceId, 'status': status, 'role': widget.role}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          _showSnackbar('Attendance status updated to $status');

          // Remove the record from the list
          setState(() {
            attendanceRequests!.removeAt(index);
          });
        } else {
          _showSnackbar('Error updating status: ${responseData['message']}');
        }
      } else {
        _showSnackbar('Failed to update status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('An error occurred: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Approval', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(emId: ''), // Pass required parameters here
              ),
            );
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: Text('No attendance requests found.'))
          : attendanceRequests != null && attendanceRequests!.isNotEmpty
          ? _buildAttendanceRequestsList()
          : Center(child: Text('No attendance requests found.')),
    );
  }

  Widget _buildAttendanceRequestsList() {
    return ListView.builder(
      itemCount: attendanceRequests!.length,
      itemBuilder: (context, index) {
        final request = attendanceRequests![index];
        final attendanceId = request['id'] ?? request['attendance_id'];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text('${request['emp_id']} - ${request['place']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${request['atten_date']}'),
                Text('Sign In: ${request['signin_time']}'),
                Text('Sign Out: ${request['signout_time']}'),
                Text('Working Hours: ${request['working_hour']}'),
                Text('Status: ${request['status']}'),
              ],
            ),
            trailing: attendanceId != null ? _buildActionButtons(attendanceId, index) : Text('Invalid ID'),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(int attendanceId, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.role == 'MANAGER') ...[
          _buildIconWithLabel(
            icon: Icons.check,
            color: Colors.green,
            label: 'Pending Admin Approval',
            onPressed: () => _updateAttendanceStatus(attendanceId, 'Pending Admin Approval', index),
          ),
          _buildIconWithLabel(
            icon: Icons.close,
            color: Colors.red,
            label: 'Not Approved',
            onPressed: () => _updateAttendanceStatus(attendanceId, 'Not Approved', index),
          ),
        ],
        if (widget.role == 'ADMIN' || widget.role == 'SUPER ADMIN') ...[
          _buildIconWithLabel(
            icon: Icons.check,
            color: Colors.green,
            label: 'Approve',
            onPressed: () => _updateAttendanceStatus(attendanceId, 'Approved', index),
          ),
          _buildIconWithLabel(
            icon: Icons.close,
            color: Colors.red,
            label: 'Reject',
            onPressed: () => _updateAttendanceStatus(attendanceId, 'Rejected', index),
          ),
        ],
      ],
    );
  }

  Widget _buildIconWithLabel({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon, color: color), onPressed: onPressed),
        Text(label, style: TextStyle(fontSize: 5)),
      ],
    );
  }
}
