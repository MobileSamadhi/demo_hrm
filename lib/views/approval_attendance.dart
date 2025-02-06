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

  List<int> selectedAttendanceIds = []; // Store selected IDs
  bool selectAll = false; // To handle "Select All"


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
        //_showSnackbar('Failed to fetch data. Status code: ${response.statusCode}');
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

  Future<void> _updateBulkAttendanceStatus(String status) async {
    if (selectedAttendanceIds.isEmpty) {
      _showSnackbar('No attendance requests selected.');
      return;
    }

    try {
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


      final url = getApiUrl(updateBulkAttendanceStatusEndpoint);
      print('API URL: $url');

      final requestBody = jsonEncode({
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'attendance_ids': selectedAttendanceIds, // Sending list of IDs
        'status': status,
        'role': widget.role,
      });

      print('Request Payload: $requestBody');
      print('Selected Attendance IDs: $selectedAttendanceIds');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          _showSnackbar('Attendance status updated to $status');

          // Remove updated records from the list
          setState(() {
            attendanceRequests!.removeWhere((request) =>
                selectedAttendanceIds.contains(request['id'] ?? request['attendance_id']));
            selectedAttendanceIds.clear();
            selectAll = false; // Unselect all
          });
        } else {
          _showSnackbar('Error updating status: ${responseData['message']}');
        }
      } else {
        _showSnackbar('Failed to update status. Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Exception: $e');
      print('Stack Trace: $stackTrace');
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
    return Column(
      children: [
        // "Select All" Checkbox
        CheckboxListTile(
          title: Text(
            'Select All',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          value: selectAll,
          onChanged: (bool? value) {
            setState(() {
              selectAll = value!;
              selectedAttendanceIds = selectAll
                  ? attendanceRequests!.map<int>((req) => (req['id'] ?? req['attendance_id']) as int).toList()
                  : [];
            });
          },
        ),

        Expanded(
          child: ListView.builder(
            itemCount: attendanceRequests!.length,
            itemBuilder: (context, index) {
              final request = attendanceRequests![index];
              final attendanceId = request['id'] ?? request['attendance_id'];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Name and Checkbox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${request['first_name']} ${request['last_name']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: selectedAttendanceIds.contains(attendanceId),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value!) {
                                  selectedAttendanceIds.add(attendanceId as int);
                                } else {
                                  selectedAttendanceIds.remove(attendanceId);
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 6),

                      // Attendance Details
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.blueGrey),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Place: ${request['place']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Icons.date_range, size: 18, color: Colors.blueGrey),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Date: ${request['atten_date']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.blueGrey),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sign In: ${request['signin_time']}  |  Sign Out: ${request['signout_time']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Icons.timelapse, size: 18, color: Colors.blueGrey),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Working Hours: ${request['working_hour']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Status
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: _getStatusColor(request['status'])),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Status: ${request['status']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _getStatusColor(request['status']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Action Buttons
                      if (attendanceId != null)
                        _buildActionButtons(attendanceId, index)
                      else
                        Text(
                          'Invalid ID',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bulk Action Buttons
        if (selectedAttendanceIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconWithLabel(
                  icon: Icons.check,
                  color: Colors.green,
                  label: 'Bulk Approve',
                  onPressed: () => _updateBulkAttendanceStatus('Approved'),
                ),
                SizedBox(width: 10),
                _buildIconWithLabel(
                  icon: Icons.close,
                  color: Colors.red,
                  label: 'Bulk Reject',
                  onPressed: () => _updateBulkAttendanceStatus('Rejected'),
                ),
              ],
            ),
          ),
      ],
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
