import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../constants.dart';
import 'dashboard.dart';

class PendingLeaveOverview extends StatefulWidget {
  @override
  _PendingLeaveOverviewState createState() => _PendingLeaveOverviewState();
}

class _PendingLeaveOverviewState extends State<PendingLeaveOverview> {
  List pendingLeaves = [];
  TextEditingController _startDateController = TextEditingController();
  DateTime? _selectedStartDate;

  @override
  void initState() {
    super.initState();
    fetchPendingLeaves(); // Initial load without any filters
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
  // Fetch pending leave data from the PHP backend
  Future<void> fetchPendingLeaves({String? startDate}) async {
    try {
      // Retrieve company code from shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      // Fetch database details
      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details. Please log in again.');
      }

      // Construct the API URL
      String url = getApiUrl(fetchPendingLeavesEndpoint);

      // Append `startDate` query parameter if provided
      if (startDate != null) {
        url += '?start_date=$startDate';
      }

      // Log the request URL and payload
      print('Fetching pending leaves from: $url');
      print('Request Payload: ${jsonEncode({
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
      })}');

      // Make the POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
        }),
      );

      // Log the response code and body for debugging
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse response data
        final responseData = json.decode(response.body);

        // Check for success status and pending leaves data
        if (responseData['status'] == 'success' && responseData['pending_leaves'] != null) {
          // Update the state with pending leaves data
          setState(() {
            pendingLeaves = List<Map<String, dynamic>>.from(responseData['pending_leaves']);
          });
        } else {
          // Handle the case where no pending leaves are found
          print('No pending leaves or invalid response structure');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("No pending leaves found"),
          ));
        }
      } else {
        // Handle non-200 status codes
        print('Failed to load pending leaves: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to load pending leaves: ${response.statusCode}"),
        ));
      }
    } catch (e) {
      // Log and handle any errors during the process
      print('Error fetching pending leaves: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error fetching pending leaves"),
      ));
    }
  }


  // Date picker for selecting start date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _startDateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
        _selectedStartDate = pickedDate;
      });
    }
  }

  // Trigger search by calling fetchPendingLeaves with the selected start date
  void _performSearch() {
    if (_startDateController.text.isNotEmpty) {
      fetchPendingLeaves(startDate: _startDateController.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please select a start date."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Leaves', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      prefixIcon: Icon(Icons.date_range, color: Color(0xFF0D9494)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: Color(0xFF0D9494)),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    readOnly: true,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _performSearch,
            child: Text("Search", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0D9494),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Expanded(
            child: pendingLeaves.isEmpty
                ? Center(child: Text("No pending leaves found"))
                : ListView.builder(
              itemCount: pendingLeaves.length,
              itemBuilder: (context, index) {
                final leave = pendingLeaves[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name: ${leave['first_name'] ?? 'N/A'} ${leave['last_name'] ?? 'N/A'}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9494),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Employee ID: ${leave['em_id'] ?? 'N/A'}",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Apply Date: ${leave['apply_date'] ?? 'N/A'}",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    super.dispose();
  }
}


