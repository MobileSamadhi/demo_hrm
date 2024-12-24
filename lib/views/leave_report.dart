import 'dart:io'; // For Platform-specific checks
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
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

  // Fetch leave data from PHP API based on the selected leave status
  Future<void> _fetchLeaveData() async {
    // Build the query parameters
    Map<String, String> queryParams = {};

    // Only add leave_status if it is not 'All'
    if (_selectedLeaveStatus != 'All') {
      queryParams['leave_status'] = _selectedLeaveStatus!;
    }

    // Construct the API URL with query parameters
    var url = Uri.parse(getApiUrl(leaveReportEndpoint)).replace(queryParameters: queryParams);

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          // Parse the JSON response and update the leave data
          _leaveData = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Failed to load leave data');
      }
    } catch (e) {
      print(e.toString());
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
