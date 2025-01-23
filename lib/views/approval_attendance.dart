import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your Auth.php endpoint
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

  Future<void> _fetchAttendanceRequests() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Fetch the company code from shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        _showSnackbar('Company code is missing. Please log in again.');
        return;
      }

      // Fetch database details
      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        _showSnackbar('Failed to fetch database details. Please log in again.');
        return;
      }

      // Prepare API request
      final url = getApiUrl(fetchAttendanceRequestsEndpoint);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
          'em_id': widget.emId,
          'role': widget.role,
        }),
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }


  Future<void> _updateAttendanceStatus(int attendanceId, String status, int index) async {
    try {
      // Get the company code from shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        _showSnackbar('Company code is missing. Please log in again.');
        return;
      }

      // Fetch database details
      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        _showSnackbar('Failed to fetch database details. Please log in again.');
        return;
      }

      // Prepare the API URL
      final url = getApiUrl(updateAttendanceStatusEndpoint);

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
          'attendance_id': attendanceId,
          'status': status,
          'role': widget.role,
        }),
      );

      // Handle the response
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

  @override
  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text(
        'Attendance Approval',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      backgroundColor: Color(0xFF0D9494).withOpacity(0.9),
      leading: CupertinoButton(
        child: Icon(CupertinoIcons.back, color: CupertinoColors.white),
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (context) => DashboardPage(emId: ''), // Pass parameters if needed
            ),
          );
        },
      ),
    )
        : AppBar(
      title: Text(
        'Attendance Approval',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      backgroundColor: Color(0xFF0D9494),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(emId: ''), // Pass parameters if needed
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading
          ? Center(child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator())
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
                // Requestor Details
                Text(
                  '${request['first_name']} ${request['last_name']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Place: ${request['place']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                // Attendance Details
                const SizedBox(height: 8),
                Text(
                  'Date: ${request['atten_date']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Sign In: ${request['signin_time']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Sign Out: ${request['signout_time']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Working Hours: ${request['working_hour']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Status: ${request['status']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(request['status']),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Action Buttons
                const SizedBox(height: 16),
                if (attendanceId != null)
                  _buildActionButtons(attendanceId, index)
                else
                  const Text(
                    'Invalid ID',
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


  Widget _buildActionButtons(int attendanceId, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.role == 'MANAGER') ...[
          _buildIconWithLabel(
            icon: Icons.check,
            color: Colors.green,
            label: 'Approve',
            onPressed: () => _updateAttendanceStatus(attendanceId, 'Pending Admin Approval', index),
          ),
          SizedBox(width: 8.0), // Add spacing between buttons
          _buildIconWithLabel(
            icon: Icons.close,
            color: Colors.red,
            label: 'Not Approved',
            onPressed: () => _updateAttendanceStatus(attendanceId, 'Not Approved', index),
          ),
        ],
        SizedBox(width: 8.0), // Add spacing between buttons
        if (widget.role == 'ADMIN' || widget.role == 'SUPER ADMIN') ...[
          _buildIconWithLabel(
            icon: Icons.check,
            color: Colors.green,
            label: 'Approve',
            onPressed: () => _updateAttendanceStatus(attendanceId, 'Approved', index),
          ),
          SizedBox(width: 8.0), // Add spacing between buttons
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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: color.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
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
