import 'dart:convert';
import 'dart:io'; // Needed for Platform.isIOS and Platform.isAndroid
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dashboard.dart';

class AttendanceReportPage extends StatefulWidget {
  @override
  _AttendanceReportPageState createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String? _selectedStatus;
  String? _selectedPlace;
  final List<String> _attendanceStatusOptions = ['All', 'Present', 'Absent', 'Late', 'Excused'];
  final List<String> _placeOptions = [ 'Office', 'Field'];
  List<Map<String, dynamic>> _attendanceData = [];

  @override
  void initState() {
    super.initState();
  }

  /// Fetches the database details for the given company code.
  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.
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

  Future<void> _fetchAttendanceData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    if (companyCode == null || companyCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Company code is missing. Please log in again.')),
      );
      return;
    }

    // Fetch database details
    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch database details. Please log in again.')),
      );
      return;
    }

    print('Database details: $dbDetails'); // Debugging

    String startDate = _startDateController.text;
    String endDate = _endDateController.text;
    String status = _selectedStatus ?? 'All';
    String place = _selectedPlace ?? 'All';

    if (startDate.isEmpty || endDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    final url = getApiUrl(attendanceReportEndpoint); // Replace with your actual attendance endpoint

    try {
      // Make the POST request with database credentials, filters, and company code
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode, // Include company_code in the payload
          'start_date': startDate,
          'end_date': endDate,
          'status': status,
          'place': place,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debugging
      print('Response body: ${response.body}'); // Debugging

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _attendanceData = List<Map<String, dynamic>>.from(result['data']);

            // Map and sort the data by atten_date in descending order
            _attendanceData = _attendanceData.map((record) {
              record['status'] = _mapStatusFromDatabase(record['status']);
              return record;
            }).toList()
              ..sort((a, b) => b['atten_date'].compareTo(a['atten_date']));
          });
        } else {
          setState(() {
            _attendanceData.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'No attendance records found')),
          );
        }
      } else {
        print('Error details: ${response.body}'); // Log error details
        throw Exception('Failed to load attendance. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance data.')),
      );
    }
  }



  String _mapStatusFromDatabase(String dbStatus) {
    switch (dbStatus) {
      case 'A':
        return 'Present';
      case 'B':
        return 'Absent';
      default:
        return '';
    }
  }

  void _filterAttendance() {
    _fetchAttendanceData();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Platform-specific icon styles
    final calendarIcon = Icon(
      Platform.isIOS ? Icons.calendar_today : Icons.date_range,
      color: Color(0xFF0D9494),
    );

    final placeIcon = Icon(
      Platform.isIOS ? Icons.location_on : Icons.place,
      color: Color(0xFF0D9494),
    );

    // Platform-specific button styles
    final buttonStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
      textStyle: TextStyle(fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Report',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      prefixIcon: calendarIcon,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: IconButton(
                        icon: calendarIcon,
                        onPressed: () {
                          _selectDate(context, _startDateController);
                        },
                      ),
                    ),
                    readOnly: true,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      prefixIcon: calendarIcon,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: IconButton(
                        icon: calendarIcon,
                        onPressed: () {
                          _selectDate(context, _endDateController);
                        },
                      ),
                    ),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPlace,
              items: _placeOptions.map((place) {
                return DropdownMenuItem(
                  value: place,
                  child: Text(place),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Place',
                prefixIcon: placeIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedPlace = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _filterAttendance,
              child: Text('Search'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // Set text color to white
                backgroundColor: Color(0xFF0D9494),   // Example background color
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

            SizedBox(height: 16),
            Expanded(
              child: _attendanceData.isEmpty
                  ? Center(
                child: Text(
                  'No attendance records found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _attendanceData.length,
                itemBuilder: (context, index) {
                  var attendance = _attendanceData[index];
                  String employeeName = attendance['employee_name'] ?? '';
                  String empId = attendance['emp_id'] ?? 'Unknown';
                  String attenDate = attendance['atten_date'] ?? 'No date';
                  String place = attendance['place'] ?? 'No place';
                  String status = attendance['status'] ?? 'No status';

                  return Card(
                    elevation: 6,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(status),
                        child: _getStatusIcon(status),
                      ),
                      title: Text(
                        employeeName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text('Date: $attenDate\nPlace: $place'),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange;
      case 'Excused':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return Icon(Icons.check, color: Colors.white);
      case 'Absent':
        return Icon(Icons.close, color: Colors.white);
      case 'Late':
        return Icon(Icons.access_time, color: Colors.white);
      case 'Excused':
        return Icon(Icons.info, color: Colors.white);
      default:
        return Icon(Icons.account_tree_sharp, color: Colors.white);
    }
  }
}
