import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.

    try {
      print('Fetching database details for company code: $companyCode');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Parsed database details response: $data');

        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          print('Database details extracted: $dbDetails');
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
        print('Failed to fetch database details. Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching database details: $e');
      return null;
    }
  }
  Future<void> _fetchLeaveRequests() async {
    try {
      print('Fetching leave requests...');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');
      print('Company code retrieved: $companyCode');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      final dbDetails = await fetchDatabaseDetails(companyCode);
      print('Database details: $dbDetails');

      if (dbDetails == null) {
        throw Exception('Failed to fetch database details.');
      }

      final url = getApiUrl(reviewLeaveRequestEndpoint);
      final payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'em_id': widget.emId,
        'role': widget.role, // Pass role to the API
      };

      print('Fetching leave requests with payload: $payload');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed leave requests response: $responseData');

        if (responseData['status'] == 'success') {
          setState(() {
            leaveRequests = responseData['data'];
            isLoading = false;
          });
          print('Leave requests loaded: $leaveRequests');
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
          print('Error in API response: ${responseData['message']}');
          _showSnackbar('Error: ${responseData['message']}');
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        print('Failed to fetch leave requests. Status Code: ${response.statusCode}');
        _showSnackbar('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print('Exception while fetching leave requests: $e');
      _showSnackbar('An error occurred: $e');
    }
  }
  Future<void> _updateLeaveStatus(int leaveId, String status) async {
    print('Updating leave status: LeaveID: $leaveId, Status: $status');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');
      print('Company code retrieved: $companyCode');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      final dbDetails = await fetchDatabaseDetails(companyCode);
      print('Database details: $dbDetails');

      if (dbDetails == null) {
        throw Exception('Failed to fetch database details.');
      }

      final url = getApiUrl(updateLeaveStatusEndpoint);
      final payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'leave_id': leaveId,
        'status': status,
        'role': widget.role, // Pass the role of the current user
      };

      print('Updating leave status with payload: $payload');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed response for leave status update: $responseData');

        if (responseData['status'] == 'success') {
          _showSnackbar('Leave status updated to $status');
          await _fetchLeaveRequests(); // Refresh leave requests
        } else {
          print('Error in leave status update: ${responseData['message']}');
          _showSnackbar('Error updating status: ${responseData['message']}');
        }
      } else {
        print('Failed to update leave status. Status Code: ${response.statusCode}');
        _showSnackbar('Failed to update status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while updating leave status: $e');
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
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
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
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 4, // Add shadow for better aesthetics
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Leave Type
                Text(
                  '${leaveRequest['first_name']} ${leaveRequest['last_name']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave Type: ${leaveRequest['leave_type']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                // Dates
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'From: ${leaveRequest['start_date']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'To: ${leaveRequest['end_date']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                // Reason
                const SizedBox(height: 8),
                Text(
                  'Reason: ${leaveRequest['reason']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                // Status
                const SizedBox(height: 8),
                Text(
                  'Status: ${leaveRequest['leave_status']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(leaveRequest['leave_status']),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Buttons
                const SizedBox(height: 16),
                if (leaveRequest['leave_id'] != null)
                  _buildActionButtons(leaveRequest)
                else
                  const Text(
                    'Invalid Leave ID',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }



  Widget _buildActionButtons(Map<String, dynamic> leaveRequest) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Buttons for MANAGER role
            if (widget.role == 'MANAGER') ...[
              _buildIconWithLabel(
                icon: Icons.check,
                color: Colors.green,
                label: 'Approve',
                onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Pending Admin Approval'),
              ),
              SizedBox(width: 8.0), // Add spacing between buttons
              _buildIconWithLabel(
                icon: Icons.close,
                color: Colors.red,
                label: 'Reject',
                onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Rejected'),
              ),
              SizedBox(width: 8.0), // Add spacing between buttons
              _buildIconWithLabel(
                icon: Icons.remove_circle,
                color: Colors.orange,
                label: 'Not Approve',
                onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Not Approve'),
              ),
            ],
            // Buttons for Admin/Super Admin role
            if (widget.role == 'ADMIN' || widget.role == 'SUPER ADMIN')
              if (leaveRequest['leave_status'] == 'Pending Admin Approval') ...[
                _buildIconWithLabel(
                  icon: Icons.check,
                  color: Colors.green,
                  label: 'Approve',
                  onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Approved'),
                ),
                SizedBox(width: 8.0), // Add spacing between buttons
                _buildIconWithLabel(
                  icon: Icons.close,
                  color: Colors.red,
                  label: 'Reject',
                  onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Rejected'),
                ),
                SizedBox(width: 8.0), // Add spacing between buttons
                _buildIconWithLabel(
                  icon: Icons.remove_circle,
                  color: Colors.orange,
                  label: 'Not Approve',
                  onPressed: () => _updateLeaveStatus(leaveRequest['leave_id'], 'Not Approve'),
                ),
              ],
          ],
        ),
      ],
    );
  }

  Widget _buildIconWithLabel({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: color.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      ),
      icon: Icon(
        icon,
        size: 18,
        color: Colors.white, // Set the icon color to white
      ),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      onPressed: onPressed,
    );
  }


}