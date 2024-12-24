import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  // Fetch pending leave data from the PHP backend
  Future<void> fetchPendingLeaves({String? startDate}) async {
    // Start by constructing the base URL using the endpoint constant
    String url = getApiUrl(fetchPendingLeavesEndpoint);

    // Add query parameter for start_date if provided
    if (startDate != null) {
      url += '?start_date=$startDate';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print("Response Data: $responseData"); // Debugging output

        // Ensure responseData is parsed correctly
        if (responseData['status'] == 'success' && responseData['pending_leaves'] != null) {
          setState(() {
            pendingLeaves = List<Map<String, dynamic>>.from(responseData['pending_leaves']);
          });
        } else {
          print('No pending leaves or incorrect response structure');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("No pending leaves found"),
          ));
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to load data: ${response.statusCode}"),
        ));
      }
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error fetching data"),
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
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


