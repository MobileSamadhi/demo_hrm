import 'dart:io'; // For platform-specific checks
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';

class LeaveType {
  final int type_id;
  final String name;
  final String leave_day;
  final int status;

  LeaveType({
    required this.type_id,
    required this.name,
    required this.leave_day,
    required this.status,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      type_id: json['type_id'] is String ? int.parse(json['type_id']) : json['type_id'], // Handle case where type_id might be a string
      name: json['name'] is String ? json['name'] : json['name'].toString(), // Ensure name is a string
      leave_day: json['leave_day'] is String ? json['leave_day'] : json['leave_day'].toString(), // Ensure leave_day is a string
      status: json['status'] is String ? int.parse(json['status']) : json['status'], // Handle case where status might be a string
    );
  }

}

class LeaveTypePage extends StatefulWidget {
  @override
  _LeaveTypePageState createState() => _LeaveTypePageState();
}

class _LeaveTypePageState extends State<LeaveTypePage> {
  late Future<List<LeaveType>> futureLeaveType;
  List<LeaveType> _leaveTypeList = [];
  List<LeaveType> _filteredLeaveTypeList = [];
  TextEditingController _searchController = TextEditingController();

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

// Method to fetch department data
  Future<List<LeaveType>> fetchLeaveType() async {
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

    final url = getApiUrl(leaveTypeEndpoint); // Replace with your actual endpoint

    try {
      // Log the request body before sending it
      print('Sending request body: ${jsonEncode({
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode, // Include company_code here
      })}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode, // Ensure company_code is included in the request
        }),
      );

      // Log the response body
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse JSON response
        List<dynamic> jsonResponse = json.decode(response.body);

        // Map JSON to Department objects
        return jsonResponse.map<LeaveType>((data) => LeaveType.fromJson(data)).toList();
      } else {
        // Log the response body if the status code is not 200
        print('Failed to load Leave Types. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load Leave Types. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Leave Types: $e');
      throw Exception('Error fetching Leave Types: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    futureLeaveType = fetchLeaveType();
    futureLeaveType.then((leaveTypeList) {
      setState(() {
        _leaveTypeList = leaveTypeList;
        _filteredLeaveTypeList = leaveTypeList;
      });
    });
    _searchController.addListener(_filterLeaveTypes);
  }

  void _filterLeaveTypes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLeaveTypeList = _leaveTypeList.where((leaveType) {
        return leaveType.name.toLowerCase().contains(query) ||
            leaveType.type_id.toString().contains(query);
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
      appBar: _buildPlatformAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSearchField(),
          ),
          Expanded(
            child: FutureBuilder<List<LeaveType>>(
              future: futureLeaveType,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: _filteredLeaveTypeList.length,
                    itemBuilder: (context, index) {
                      LeaveType leaveType = _filteredLeaveTypeList[index];
                      return _buildLeaveTypeCard(leaveType);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  );
                }

                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  // Platform-specific AppBar
  AppBar _buildPlatformAppBar() {
    return AppBar(
      title: Text(
        'Leave Types',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: Platform.isIOS ? 20 : 22, // Adjust font size for iOS
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
      elevation: 0,
    );
  }

  // Platform-specific Search Field
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search by Type ID or Leave Name',
        prefixIcon: Icon(
          Icons.search,
          color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Platform-specific icon color
        ),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // LeaveType Card
  Widget _buildLeaveTypeCard(LeaveType leaveType) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Platform-specific avatar color
          child: Text(
            leaveType.name.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          leaveType.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Leave Day: ${leaveType.leave_day}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Type ID: ${leaveType.type_id}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Status: ${leaveType.status == 1 ? 'Active' : 'Inactive'}',
              style: TextStyle(
                color: leaveType.status == 1 ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Platform.isIOS ? Icons.arrow_forward_ios : Icons.arrow_forward, // Platform-specific trailing icon
          color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
        ),
      ),
    );
  }
}
