import 'dart:convert';
import 'dart:io'; // For platform checks
import 'package:flutter/cupertino.dart'; // For iOS widgets
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dashboard.dart';

class EmployeeSalary {
  final int id;
  final String empId;
  final int typeId;
  final String total;
  final String firstName;
  final String lastName;

  EmployeeSalary({
    required this.id,
    required this.empId,
    required this.typeId,
    required this.total,
    required this.firstName,
    required this.lastName,
  });

  factory EmployeeSalary.fromJson(Map<String, dynamic> json) {
    return EmployeeSalary(
      id: json['id'] is String ? int.parse(json['id']) : json['id'], // Check and convert if it's a string
      empId: json['emp_id'].toString(),  // Ensure empId is always a string
      typeId: json['type_id'] is String ? int.parse(json['type_id']) : json['type_id'], // Check and convert if it's a string
      total: json['total'].toString(), // Ensure total is always a string
      firstName: json['first_name'].toString(),
      lastName: json['last_name'].toString(),
    );
  }
}


class EmployeeSalaryPage extends StatefulWidget {
  @override
  _EmployeeSalaryPageState createState() => _EmployeeSalaryPageState();
}

class _EmployeeSalaryPageState extends State<EmployeeSalaryPage> {
  late Future<List<EmployeeSalary>> futureEmployeeSalary;
  TextEditingController _searchController = TextEditingController();
  List<EmployeeSalary> _filteredSalaries = [];
  List<EmployeeSalary> _allSalaries = [];

  @override
  void initState() {
    super.initState();
    futureEmployeeSalary = fetchEmployeeSalary();
    futureEmployeeSalary.then((salaries) {
      setState(() {
        _allSalaries = salaries;
        _filteredSalaries = salaries;
      });
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    filterSalaries();
  }

  void filterSalaries() {
    List<EmployeeSalary> results = [];
    if (_searchController.text.isEmpty) {
      results = _allSalaries;
    } else {
      results = _allSalaries.where((salary) {
        final query = _searchController.text.toLowerCase();
        return salary.empId.toLowerCase().contains(query) ||
            salary.id.toString().contains(query) ||
            salary.total.contains(query) ||
            salary.firstName.toLowerCase().contains(query) ||
            salary.lastName.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredSalaries = results;
    });
  }


  String getApiUrl(String endpoint) {
    return '$apiDomain$endpoint';
  }

  /// Fetch database details for a given company code
  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.

    try {
      // Send POST request to fetch database details
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      // Log the response for debugging
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse response body
        final List<dynamic> data = jsonDecode(response.body);

        // Validate the response data
        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        } else {
          print('Invalid response data: $data');
          return null;
        }
      } else {
        // Handle non-200 status codes
        print('Error: Failed to fetch database details. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      // Log any errors that occur
      print('Error fetching database details: $e');
      return null;
    }
  }

  /// Fetch department data
  Future<List<EmployeeSalary>> fetchEmployeeSalary() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    // Ensure company code is available
    if (companyCode == null || companyCode.isEmpty) {
      throw Exception('Company code is missing. Please log in again.');
    }

    // Fetch database details
    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      throw Exception('Failed to fetch database details. Please log in again.');
    }

    final url = getApiUrl(empSalaryEndpoint); // Replace with your actual endpoint

    try {
      // Prepare request body
      final requestBody = jsonEncode({
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
      });

      // Log the request body
      print('Request Body: $requestBody');

      // Send POST request to fetch departments
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // Log the response
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse and map the response data to Department objects
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map<EmployeeSalary>((data) =>EmployeeSalary.fromJson(data)).toList();
      } else {
        // Handle non-200 responses
        print('Error: Failed to load employees salary: Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load employees salary. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Log any errors that occur
      print('Error fetching employees salary: $e');
      throw Exception('Error fetching employees salary: $e');
    }
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
            child: Center(
              child: FutureBuilder<List<EmployeeSalary>>(
                future: futureEmployeeSalary,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Platform.isIOS
                        ? CupertinoActivityIndicator()
                        : CircularProgressIndicator(color: Color(0xFF0D9494));
                  } else if (snapshot.hasError) {
                    return Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    );
                  } else if (_filteredSalaries.isEmpty) {
                    return Center(
                      child: Text(
                        'No records found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: _filteredSalaries.length,
                    itemBuilder: (context, index) {
                      EmployeeSalary salary = _filteredSalaries[index];
                      return _buildSalaryCard(salary);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Platform-Specific AppBar
  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text('Employee Salary List',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
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
      title: Text(
        'Employee Salary List',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  // Platform-Specific Search Field
  Widget _buildSearchField() {
    return Platform.isIOS
        ? CupertinoTextField(
      controller: _searchController,
      placeholder: 'Search by Employee ID, Salary ID, or Total',
      prefix: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey),
      ),
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: CupertinoColors.lightBackgroundGray,
        borderRadius: BorderRadius.circular(25.0),
      ),
    )
        : TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search',
        hintText: 'Search by Salary ID, or Total',
        prefixIcon: Icon(Icons.search, color: Color(0xFF0D9494)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(color: Color(0xFF0D9494)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        fillColor: Colors.grey[200],
        filled: true,
      ),
    );
  }

  // Salary Card
  Widget _buildSalaryCard(EmployeeSalary salary) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D9494), Color(0xFF0D9494)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Platform.isIOS ? CupertinoIcons.person_alt : Icons.person_outline,
              color: Color(0xFF0D9494),
            ),
          ),
          title: Text(
            'Name: ${salary.firstName + " " + salary.lastName}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Platform.isIOS ? CupertinoIcons.creditcard : Icons.badge, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Salary ID: ${salary.id}',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Platform.isIOS ? CupertinoIcons.money_dollar : Icons.attach_money, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Total: ${salary.total}',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: Icon(
            Platform.isIOS ? CupertinoIcons.forward : Icons.arrow_forward_ios,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}