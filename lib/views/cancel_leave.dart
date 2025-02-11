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
      print("DEBUG: Company code is null or empty.");
      return;
    }

    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      _showMessage("Failed to fetch database details. Please log in again.", false);
      print("DEBUG: Failed to fetch database details.");
      return;
    }

    final url = getApiUrl(getApprovedLeavesEndpoint);
    print("DEBUG: API URL -> $url");

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

      print("DEBUG: API Response Status Code -> ${response.statusCode}");
      print("DEBUG: API Response Body -> ${response.body}");

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse is List) {
          setState(() {
            leaveList = decodedResponse;
            _isLoading = false;
          });
          print("DEBUG: Successfully loaded ${leaveList.length} leave(s).");
        } else if (decodedResponse is Map<String, dynamic>) {
          print("DEBUG: Response is a Map instead of List. Possible incorrect API response format.");
          if (decodedResponse.containsKey("data") && decodedResponse["data"] is List) {
            setState(() {
              leaveList = decodedResponse["data"];
              _isLoading = false;
            });
            print("DEBUG: Extracted ${leaveList.length} leave(s) from 'data' field.");
          } else {
            setState(() {
              leaveList = [];
              _isLoading = false;
            });
            _showMessage("No approved leaves found.", false);
            print("DEBUG: 'data' key missing or not a List. Setting leaveList to empty.");
          }
        } else {
          _showMessage("Unexpected response format.", false);
          print("DEBUG: Unexpected JSON format: $decodedResponse");
        }
      } else {
        _showMessage("Failed to load leaves.", false);
        print("DEBUG: API request failed with status code ${response.statusCode}");
      }
    } catch (error) {
      _showMessage("An error occurred: $error", false);
      print("DEBUG: Exception caught -> $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                        // Show confirmation dialog before canceling leave
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirm Cancel'),
                              content: Text('Are you sure you want to cancel the leave?'),
                              actions: <Widget>[
                                // Cancel button to close the dialog
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close the dialog
                                  },
                                  child: Text('Cancel'),
                                ),
                                // Confirm button to proceed with leave cancellation
                                TextButton(
                                  onPressed: () {
                                    // Call the cancelLeave function if confirmed
                                    cancelLeave(leave['id'].toString());
                                    Navigator.of(context).pop(); // Close the dialog
                                  },
                                  child: Text('Confirm'),
                                ),
                              ],
                            );
                          },
                        );
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
