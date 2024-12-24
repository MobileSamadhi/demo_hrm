import 'dart:convert';
import 'dart:io'; // For platform checks
import 'package:flutter/cupertino.dart'; // For iOS widgets
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'dashboard.dart';

class Employees {
  final int id;
  final String em_id;
  final String? em_code;
  final int? des_id;
  final int? dep_id;
  final String? first_name;
  final String? last_name;
  final String? em_email;
  final String em_password;
  final String em_role;
  final int shift;
  final String? em_address;
  final String status;
  final String em_gender;
  final String? em_phone;
  final String? em_birthday;
  final String? em_blood_group;
  final String? em_joining_date;
  final String? em_contact_end;
  final String? em_nid;
  final int is_sent;
  final int is_update;
  final String? Hik_id;
  final int is_del;
  final String? is_permanent;
  final String reporting_person;

  Employees({
    required this.id,
    required this.em_id,
    this.em_code,
    this.des_id,
    this.dep_id,
    this.first_name,
    this.last_name,
    this.em_email,
    required this.em_password,
    required this.em_role,
    required this.shift,
    this.em_address,
    required this.status,
    required this.em_gender,
    this.em_phone,
    this.em_birthday,
    this.em_blood_group,
    this.em_joining_date,
    this.em_contact_end,
    this.em_nid,
    required this.is_sent,
    required this.is_update,
    this.Hik_id,
    required this.is_del,
    this.is_permanent,
    required this.reporting_person,
  });

  factory Employees.fromJson(Map<String, dynamic> json) {
    return Employees(
      id: int.parse(json['id'].toString()),
      em_id: json['em_id'].toString(),
      em_code: json['em_code']?.toString(),
      des_id: json['des_id'] != null ? int.parse(json['des_id'].toString()) : null,
      dep_id: json['dep_id'] != null ? int.parse(json['dep_id'].toString()) : null,
      first_name: json['first_name']?.toString(),
      last_name: json['last_name']?.toString(),
      em_email: json['em_email']?.toString(),
      em_password: json['em_password'].toString(),
      em_role: json['em_role'].toString(),
      shift: int.parse(json['shift'].toString()),
      em_address: json['em_address']?.toString(),
      status: json['status'].toString(),
      em_gender: json['em_gender'].toString(),
      em_phone: json['em_phone']?.toString(),
      em_birthday: json['em_birthday']?.toString(),
      em_blood_group: json['em_blood_group']?.toString(),
      em_joining_date: json['em_joining_date']?.toString(),
      em_contact_end: json['em_contact_end']?.toString(),
      em_nid: json['em_nid']?.toString(),
      is_sent: int.parse(json['is_sent'].toString()),
      is_update: int.parse(json['is_update'].toString()),
      Hik_id: json['Hik_id']?.toString(),
      is_del: int.parse(json['is_del'].toString()),
      is_permanent: json['is_permanent']?.toString(),
      reporting_person: json['reporting_person'].toString(),
    );
  }
}


class EmployeePage extends StatefulWidget {
  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  late Future<List<Employees>> futureEmployees;
  List<Employees> _employeesList = [];
  List<Employees> _filteredEmployeesList = [];
  TextEditingController _searchController = TextEditingController();

  Future<List<Employees>> fetchEmployees() async {

    final url = getApiUrl(employeeEndpoint);

    final response = await http.get(Uri.parse(url));


    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map<Employees>((data) => Employees.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load Employees');
    }
  }

  @override
  void initState() {
    super.initState();
    futureEmployees = fetchEmployees();
    futureEmployees.then((employees) {
      setState(() {
        _employeesList = employees;
        _filteredEmployeesList = employees;
      });
    });
    _searchController.addListener(_filterEmployees);
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployeesList = _employeesList.where((employee) {
        return employee.em_code.toString().contains(query) ||
            (employee.first_name?.toLowerCase().contains(query) ?? false) ||
            (employee.last_name?.toLowerCase().contains(query) ?? false) ||
            employee.status.toLowerCase().contains(query) ||
            employee.em_role.toLowerCase().contains(query);
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
            padding: const EdgeInsets.all(12.0),
            child: _buildSearchField(),
          ),
          Expanded(
            child: FutureBuilder<List<Employees>>(
              future: futureEmployees,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: Platform.isIOS
                          ? CupertinoActivityIndicator()
                          : CircularProgressIndicator(
                        color: Color(0xFF0D9494),
                      ));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  );
                } else if (snapshot.hasData) {
                  return _buildEmployeeTable();
                }
                return Container(); // Empty container when no data
              },
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
      middle: Text('Employees List'),
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
        'Employees List',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Roboto',
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
      centerTitle: true,
    );
  }

  // Platform-specific Search Field
  Widget _buildSearchField() {
    return Platform.isIOS
        ? CupertinoTextField(
      controller: _searchController,
      placeholder: 'Search by EPF_No, Name',
      padding: EdgeInsets.all(12.0),
      prefix: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey),
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.lightBackgroundGray,
        borderRadius: BorderRadius.circular(30.0),
      ),
    )
        : TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search by EPF_No, Name',
        prefixIcon: Icon(Icons.search, color: Color(0xFF0D9494)),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D9494), width: 2.0),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      style: TextStyle(fontSize: 16.0, fontFamily: 'Roboto'),
    );
  }

  // Employee Data Table
  Widget _buildEmployeeTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
          dataRowHeight: 60, // Increased row height for better spacing
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
            fontSize: 16,
            fontFamily: 'Roboto',
          ),
          dataTextStyle: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontFamily: 'Roboto',
          ),
          columns: [
            DataColumn(label: Text('EPF_No')),
            DataColumn(label: Text('First Name')),
            DataColumn(label: Text('Last Name')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Birthday')),
            DataColumn(label: Text('Blood Group')),
            DataColumn(label: Text('Permanent')),
            DataColumn(label: Text('Reporting Person')),

          ],
          rows: _filteredEmployeesList.asMap().entries.map((entry) {
            int index = entry.key;
            Employees employee = entry.value;
            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  // Alternate row colors
                  if (index.isOdd) {
                    return Colors.teal.withOpacity(0.05);
                  }
                  return null; // Use default color
                },
              ),
              cells: [
                DataCell(Text(employee.em_code ?? 'N/A')),
                DataCell(Text(employee.first_name ?? 'N/A')),
                DataCell(Text(employee.last_name ?? 'N/A')),
                DataCell(Text(employee.status)),
                DataCell(Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.teal),
                    SizedBox(width: 5),
                    Text(employee.em_email ?? 'N/A'),
                  ],
                )),
                DataCell(Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.teal),
                    SizedBox(width: 5),
                    Text(employee.em_phone ?? 'N/A'),
                  ],
                )),
                DataCell(Text(employee.em_birthday ?? 'N/A')),
                DataCell(Text(employee.em_blood_group ?? 'N/A')),
                DataCell(Text(employee.is_permanent == "1" ? "Yes" : "No")),
                DataCell(Text(employee.reporting_person ?? 'N/A')),

              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
