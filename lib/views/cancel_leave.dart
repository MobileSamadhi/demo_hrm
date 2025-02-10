import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'dashboard.dart';

class CancelLeavePage extends StatefulWidget {
  @override
  _CancelLeavePageState createState() => _CancelLeavePageState();
}

class _CancelLeavePageState extends State<CancelLeavePage> {
  bool _isLoading = true;
  List<dynamic> leaveList = [];

  @override
  void initState() {
    super.initState();
    fetchApprovedLeaves();
  }

  // Fetch database details using company code
  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint);

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
      return null;
    } catch (e) {
      print('Error fetching database details: $e');
      return null;
    }
  }

  // Fetch all approved leaves with employee names
  Future<void> fetchApprovedLeaves() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    if (companyCode == null || companyCode.isEmpty) {
      _showMessage("Company code is missing. Please log in again.", false);
      return;
    }

    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      _showMessage("Failed to fetch database details. Please log in again.", false);
      return;
    }

    final url = getApiUrl(getApprovedLeavesEndpoint);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "database_host": dbDetails['database_host'],
          "database_name": dbDetails['database_name'],
          "database_username": dbDetails['database_username'],
          "database_password": dbDetails['database_password'],
          "company_code": companyCode,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        setState(() {
          leaveList = responseData;
          _isLoading = false;
        });
      } else {
        _showMessage("Failed to load leaves.", false);
      }
    } catch (error) {
      _showMessage("An error occurred: $error", false);
    }
  }

  // Cancel leave request
  Future<void> cancelLeave(String leaveId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    if (companyCode == null || companyCode.isEmpty) {
      _showMessage("Company code is missing. Please log in again.", false);
      return;
    }

    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      _showMessage("Failed to fetch database details. Please log in again.", false);
      return;
    }

    final url = getApiUrl(cancelLeaveEndpoint);

    final Map<String, dynamic> requestBody = {
      "database_host": dbDetails['database_host'],
      "database_name": dbDetails['database_name'],
      "database_username": dbDetails['database_username'],
      "database_password": dbDetails['database_password'],
      "company_code": companyCode,
      "leave_id": leaveId
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == "success") {
        _showMessage("Leave cancelled successfully!", true);
        fetchApprovedLeaves(); // Refresh leave list
      } else {
        _showMessage(responseData['error'] ?? "Error cancelling leave", false);
      }
    } catch (error) {
      _showMessage("An error occurred: $error", false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cancel Leaves',
          style: TextStyle(
            color: Colors.white,
            fontSize: Platform.isIOS ? 20 : 22, // Different font size for iOS
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(
            Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF0D9494)))
          : leaveList.isEmpty
          ? Center(child: Text("No approved leaves found"))
          : ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: leaveList.length,
        itemBuilder: (context, index) {
          final leave = leaveList[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${leave['full_name']}", // Display full employee name
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text("Leave ID: ${leave['id']}"),
                  Text("Type: ${leave['leave_type']}"),
                  Text("Start Date: ${leave['start_date']}"),
                  Text("End Date: ${leave['end_date']}"),
                  Text("Status: ${leave['leave_status']}"),
                  SizedBox(height: 10),
                  if (leave['leave_status'] == "Approved") // Show button only for approved leaves
                    ElevatedButton(
                      onPressed: () {
                        cancelLeave(leave['id'].toString());
                      },
                      child: Text(
                        "Cancel Leave",
                        style: TextStyle(color: Colors.white), // Set text color to white
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D9494),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
