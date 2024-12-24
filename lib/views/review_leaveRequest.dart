import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import 'dashboard.dart';

class LeaveReviewPage extends StatefulWidget {
  final String? emId;  // Manager's emId passed from the DashboardPage
  final String role;    // Role passed from the login (e.g., 'manager', 'admin', 'super_admin')

  LeaveReviewPage({this.emId, required this.role});

  @override
  _LeaveReviewPageState createState() => _LeaveReviewPageState();
}

class _LeaveReviewPageState extends State<LeaveReviewPage> {
  List<dynamic>? leaveRequests;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();  // Fetch the leave requests when the page is initialized
  }

  // Function to fetch leave requests
  Future<void> _fetchLeaveRequests() async {
    try {
      // Use getApiUrl to dynamically construct the full URL
      final url = getApiUrl(reviewLeaveRequestEndpoint);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'em_id': widget.emId,
          'role': widget.role,  // Pass role to the API
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            leaveRequests = responseData['data'];
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

  // Function to update the leave request status
  Future<void> _updateLeaveStatus(int leaveId, String status) async {
    print('Updating leave status: LeaveID: $leaveId, Status: $status'); // Log request

    try {
      final url = getApiUrl(updateLeaveStatusEndpoint);

      final response = await http.post(
        Uri.parse(url),
        body: json.encode({
          'leave_id': leaveId,
          'status': status,
          'role': widget.role,  // Pass the role of the current user
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status code: ${response.statusCode}'); // Log response code
      print('Response body: ${response.body}');  // Log response body

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Response data: $responseData');  // Log response data
        if (responseData['status'] == 'success') {
          _showSnackbar('Leave status updated to $status');
          _fetchLeaveRequests(); // Refresh the leave requests after status update
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



  // Helper function to show snackbars
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Leave Requests', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: Text('No leave requests found.'))
          : leaveRequests != null && leaveRequests!.isNotEmpty
          ? _buildLeaveRequestsList()  // Display leave requests if available
          : Center(child: Text('No leave requests found.')),
    );
  }

  // Widget to display the list of leave requests
  Widget _buildLeaveRequestsList() {
    return ListView.builder(
      itemCount: leaveRequests!.length,
      itemBuilder: (context, index) {
        final leaveRequest = leaveRequests![index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text('${leaveRequest['first_name']} ${leaveRequest['last_name']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leave Type: ${leaveRequest['leave_type']}'),
                Text('From: ${leaveRequest['start_date']} To: ${leaveRequest['end_date']}'),
                Text('Reason: ${leaveRequest['reason']}'),
                Text('Status: ${leaveRequest['leave_status']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Buttons only if manager
                if (widget.role == 'MANAGER')
                  ...[
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Pending Admin Approval'),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Rejected'),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.orange),
                      onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Not Approve'),
                    ),
                  ],
                // Buttons for Admin/Super Admin
                if (widget.role == 'ADMIN' || widget.role == 'SUPER ADMIN')
                  if (leaveRequest['leave_status'] == 'Pending Admin Approval') ...[
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Approved'),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Rejected'),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.orange),
                      onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Not Approve'),
                    ),
                  ]
              ],
            ),
          ),
        );
      },
    );
  }
}