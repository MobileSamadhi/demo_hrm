import 'dart:io'; // For Platform-specific checks
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dashboard.dart';

class LeaveReportPage extends StatefulWidget {
  @override
  _LeaveReportPageState createState() => _LeaveReportPageState();
}

class _LeaveReportPageState extends State<LeaveReportPage> {
  // Leave status options (with "All" to show all records)
  final List<String> _leaveStatusOptions = ['All', 'Approved', 'Not Approve', 'Rejected'];
  String? _selectedLeaveStatus = 'All'; // Default value is 'All'

  List<Map<String, dynamic>> _leaveData = []; // Leave records data

  @override
  void initState() {
    super.initState();
    _fetchLeaveData(); // Fetch leave data when the page loads
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


  Future<void> _fetchLeaveData() async {
    try {
      // Log the selected leave status
      print('Selected Leave Status: $_selectedLeaveStatus');

      // Fetch company code from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      // Log the retrieved company code
      print('Company Code: $companyCode');

      // Fetch database details
      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details. Please log in again.');
      }

      // Log the fetched database details
      print('Database Details: $dbDetails');

      // Construct the API URL
      final url = getApiUrl(leaveReportEndpoint);

      // Build the request payload
      final Map<String, dynamic> payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
      };

      // Include leave_status only if it is not 'All'
      if (_selectedLeaveStatus != null && _selectedLeaveStatus != 'All') {
        payload['leave_status'] = _selectedLeaveStatus;
      }

      // Log the request payload
      print('Request Payload: $payload');

      // Send POST request to fetch leave data
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Log the response details
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse the response data
        final List<dynamic> responseData = jsonDecode(response.body);

        // Apply client-side filtering if necessary
        List<Map<String, dynamic>> filteredData = List<Map<String, dynamic>>.from(responseData);

        if (_selectedLeaveStatus != null && _selectedLeaveStatus != 'All') {
          filteredData = filteredData.where((leave) {
            return leave['leave_status'] == _selectedLeaveStatus;
          }).toList();
        }

        // Update the leave data
        setState(() {
          _leaveData = filteredData;
          print('Filtered Leave Data: $_leaveData');
        });
      } else {
        // Log and throw an exception for non-200 responses
        print('Failed to load leave data. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load leave data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      // Log and handle errors
      print('Error fetching leave data: $e');
      setState(() {
        _leaveData = []; // Clear the data in case of error
      });
    }
  }




  // Call _fetchLeaveData when the user applies the filter
  void _filterLeave() {
    _fetchLeaveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPlatformAppBar(), // Platform-specific AppBar
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for leave status
            DropdownButtonFormField<String>(
              value: _selectedLeaveStatus,
              items: _leaveStatusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Leave Status',
                prefixIcon: Icon(
                  Icons.filter_list,
                  color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Platform-specific icon color
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedLeaveStatus = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Search button to trigger the filter
            ElevatedButton(
              onPressed: _filterLeave,
              child: Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Platform-specific button color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Display fetched leave data
            // Display fetched leave data
            Expanded(
              child: _leaveData.isEmpty
                  ? Center(
                child: Text(
                  'No leave records found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _leaveData.length,
                itemBuilder: (context, index) {
                  var leave = _leaveData[index];

                  // Safely retrieve values, or provide fallback if null
                  String empName = "${leave['first_name'] ?? ''} ${leave['last_name'] ?? ''}".trim();
                  String leaveType = leave['leave_type'] ?? 'No type';
                  String startDate = leave['start_date'] ?? 'No start date';
                  String endDate = leave['end_date'] ?? 'No end date';
                  String status = leave['leave_status'] ?? 'No status';

                  return Card(
                    elevation: 6,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.person,
                        color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Platform-specific icon color
                      ),
                      title: Text(
                        empName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text('Type: $leaveType\nFrom: $startDate to $endDate'),
                      trailing: Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Platform-specific AppBar
  AppBar _buildPlatformAppBar() {
    return AppBar(
      title: Text(
        'Leave Report',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: Platform.isIOS ? 20 : 22, // Different font size for iOS
        ),
      ),
      backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Platform-specific background color
      leading: IconButton(
        icon: Icon(
          Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back, // Platform-specific back icon
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
          );
        },
      ),
    );
  }

  // Helper method to get color based on status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Not Approve':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
