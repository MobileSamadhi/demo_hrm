import 'dart:convert';
import 'dart:io'; // For platform checks
import 'package:flutter/cupertino.dart'; // For iOS widgets
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dashboard.dart';

class Attendance {
  final int id;
  final String empId;
  final String attenDate;
  final String? signinTime;
  final String? signoutTime;
  final String? workingHour;
  final String place;
  final String? absence;
  final String? overtime;
  final String? earnleave;
  final String? status;
  final String firstName; // Add this
  final String lastName; // Add this

  Attendance({
    required this.id,
    required this.empId,
    required this.attenDate,
    this.signinTime,
    this.signoutTime,
    this.workingHour,
    required this.place,
    this.absence,
    this.overtime,
    this.earnleave,
    this.status,
    required this.firstName,
    required this.lastName,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'] ?? 0,
      empId: json['emp_id']?.toString() ?? 'N/A', // Handle null emp_id
      attenDate: json['atten_date']?.toString() ?? 'N/A', // Handle null atten_date
      signinTime: json['signin_time']?.toString() ?? 'N/A',
      signoutTime: json['signout_time']?.toString() ?? 'N/A',
      workingHour: json['working_hour']?.toString() ?? 'N/A',
      place: json['place']?.toString() ?? 'N/A',
      absence: json['absence']?.toString() ?? 'N/A',
      overtime: json['overtime']?.toString() ?? 'N/A',
      earnleave: json['earnleave']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'N/A',
      firstName: json['first_name']?.toString() ?? 'Unknown', // Ensure first name is not null
      lastName: json['last_name']?.toString() ?? 'Unknown', // Ensure last name is not null
    );
  }


}

class AttendancePage extends StatefulWidget {

  final String emId;
  final String role;

  const AttendancePage({required this.emId, required this.role, Key? key}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<List<Attendance>> futureAttendance;
  List<Attendance> _attendanceList = [];
  List<Attendance> _filteredAttendanceList = [];
  TextEditingController _searchController = TextEditingController();

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

  /// Fetches attendance records from the server.
  Future<List<Attendance>> fetchAttendance() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    if (companyCode == null || companyCode.isEmpty) {
      throw Exception('Company code is missing. Please log in again.');
    }

    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      throw Exception('Failed to fetch database details. Please log in again.');
    }

    final url = getApiUrl(attendanceEndpoint); // Replace with your actual endpoint

    final emId = (widget.role == 'EMPLOYEE' || widget.role == 'MANAGER')
        ? widget.emId
        : 'ALL'; // Pass em_id for EMPLOYEE and MANAGER, 'ALL' for ADMIN and SUPER ADMIN

    final Map<String, dynamic> requestData = {
      'em_id': emId,  // 'ALL' for ADMIN/SUPER ADMIN, actual em_id for EMPLOYEE
      'role': widget.role,
      'database_host': dbDetails['database_host'],
      'database_name': dbDetails['database_name'],
      'database_username': dbDetails['database_username'],
      'database_password': dbDetails['database_password'],
      'company_code': companyCode, // Ensure company code is included
    };

    print('🔍 Sending API Request: $requestData'); // Log request

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      print('⚡ Response Status: ${response.statusCode}');
      print('⚡ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        final List<Attendance> attendanceList = jsonResponse
            .map<Attendance>((data) => Attendance.fromJson(data))
            .toList()
          ..sort((a, b) => b.attenDate.compareTo(a.attenDate)); // Descending order

        return attendanceList;
      } else {
        throw Exception('Failed to load attendance. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      rethrow;
    }
  }



  @override
  void initState() {
    super.initState();
    futureAttendance = fetchAttendance();
    futureAttendance.then((attendanceList) {
      setState(() {
        _attendanceList = attendanceList;
        _filteredAttendanceList = attendanceList;
      });
    });
    _searchController.addListener(_filterAttendance);
  }

  void _filterAttendance() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAttendanceList = _attendanceList.where((attendance) {
        return attendance.empId.toLowerCase().contains(query) ||
            attendance.attenDate.toLowerCase().contains(query) ||
            attendance.firstName.toLowerCase().contains(query) ||
            attendance.lastName.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSearchField(),
          ),
          Expanded(
            child: FutureBuilder<List<Attendance>>(
              future: futureAttendance,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: _filteredAttendanceList.length,
                    itemBuilder: (context, index) {
                      Attendance attendance = _filteredAttendanceList[index];
                      return _buildAttendanceCard(attendance);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  );
                }

                return Center(
                  child: Platform.isIOS
                      ? CupertinoActivityIndicator()
                      : CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Platform-specific AppBar
  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text('Attendance List',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: Color(0xFF0D9494),
      leading: CupertinoButton(
        child: Icon(CupertinoIcons.back, color: CupertinoColors.white),
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    )
        : AppBar(
      title: Text('Attendance List',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
    );
  }

  // Platform-specific Search Field
  Widget _buildSearchField() {
    return Platform.isIOS
        ? CupertinoTextField(
      controller: _searchController,
      placeholder: 'Search by Employee Name, ID or Date',
      prefix: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey),
      ),
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: CupertinoColors.lightBackgroundGray,
        borderRadius: BorderRadius.circular(12.0),
      ),
    )
        : TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search by Employee Name, ID or Date',
        prefixIcon: Icon(Icons.search, color: Color(0xFF0D9494)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  // Attendance Card
  Widget _buildAttendanceCard(Attendance attendance) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blueGrey[100],
            child: Icon(
              Platform.isIOS ? CupertinoIcons.person_alt : Icons.person,
              size: 30,
              color: Color(0xFF0D9494),
            ),
          ),
          title: Text(
            '${attendance.firstName} ${attendance.lastName}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF0D9494),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range, color: Colors.grey[600]),
                    SizedBox(width: 5),
                    Text(
                      'Date: ${attendance.attenDate}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                _buildRow(
                    Platform.isIOS ? CupertinoIcons.clock : Icons.login,
                    'Sign In: ${attendance.signinTime ?? "N/A"}'),
                _buildRow(
                    Platform.isIOS ? CupertinoIcons.clock : Icons.logout,
                    'Sign Out: ${attendance.signoutTime ?? "N/A"}'),
                _buildRow(
                    Platform.isIOS ? CupertinoIcons.timer : Icons.timer,
                    'Working Hours: ${attendance.workingHour ?? "N/A"}'),
                _buildRow(Platform.isIOS ? CupertinoIcons.location : Icons.location_on,
                    'Place: ${attendance.place}'),
                _buildRow(
                    Platform.isIOS ? CupertinoIcons.person_badge_minus : Icons.person_off,
                    'Absence: ${attendance.absence ?? "N/A"}'),
                _buildRow(
                    Platform.isIOS ? CupertinoIcons.timer : Icons.add_alarm,
                    'Overtime: ${attendance.overtime ?? "N/A"}'),
                _buildRow(
                    Platform.isIOS ? CupertinoIcons.leaf_arrow_circlepath : Icons.beach_access,
                    'Earn Leave: ${attendance.earnleave ?? "N/A"}'),
                _buildRow(
                    Platform.isIOS ? CupertinoIcons.checkmark_seal : Icons.assignment_turned_in,
                    'Status: ${attendance.status ?? "N/A"}'),
              ],
            ),
          ),
          trailing: Icon(
            Platform.isIOS ? CupertinoIcons.forward : Icons.arrow_forward_ios,
            color: Color(0xFF0D9494),
          ),
        ),
      ),
    );
  }


  // Helper method to build rows in the attendance card
  Widget _buildRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items properly
      children: [
        Icon(icon, color: Colors.grey[600]),
        SizedBox(width: 5),
        Expanded( // Ensures the text does not overflow
          child: Text(
            text,
            style: TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis, // Adds "..." if the text is too long
            maxLines: 2, // Prevents single-line overflow
          ),
        ),
      ],
    );
  }
}