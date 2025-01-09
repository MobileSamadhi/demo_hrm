import 'dart:convert';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import 'department_details.dart';

class Employee {
  final String emId;
  final String firstName;
  final String lastName;

  Employee({
    required this.emId,
    required this.firstName,
    required this.lastName,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      emId: json['em_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}

class Department {
  final int id;
  final String depName;
  final List<Employee> employees;

  Department({
    required this.id,
    required this.depName,
    required this.employees,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    var employeesJson = json['employees'] as List;
    List<Employee> employeesList = employeesJson.map((i) => Employee.fromJson(i)).toList();

    return Department(
      id: int.parse(json['id'].toString()),  // Convert `id` to int
      depName: json['dep_name'],
      employees: employeesList,
    );
  }
}


class DepartmentPage extends StatefulWidget {
  @override
  _DepartmentPageState createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  late Future<List<Department>> futureDepartment;
  TextEditingController _searchController = TextEditingController();
  List<Department> _filteredDepartments = [];
  List<Department> _allDepartments = [];

  @override
  void initState() {
    super.initState();
    futureDepartment = fetchDepartment();
    futureDepartment.then((departments) {
      setState(() {
        _allDepartments = departments;
        _filteredDepartments = departments;
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
    filterDepartments();
  }

  void filterDepartments() {
    List<Department> results = [];
    if (_searchController.text.isEmpty) {
      results = _allDepartments;
    } else {
      results = _allDepartments.where((department) =>
      department.depName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          department.id.toString().contains(_searchController.text)).toList();
    }

    setState(() {
      _filteredDepartments = results;
    });
  }

  Future<List<Department>> fetchDepartment() async {
    final url = getApiUrl(departmentEndpoint);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map<Department>((data) => Department.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load departments');
    }
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
            child: FutureBuilder<List<Department>>(
              future: futureDepartment,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: _filteredDepartments.length,
                    itemBuilder: (context, index) {
                      Department department = _filteredDepartments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(20.0),
                          shadowColor: Colors.black12,
                          color: Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20.0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DepartmentDetailPage(department: department),
                                ),
                              );
                            },
                            child: _buildDepartmentCard(department),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text('Department List', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
      title: Text('Department List', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: Color(0xFF0D9494),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Platform.isIOS
        ? CupertinoTextField(
      controller: _searchController,
      placeholder: 'Search by Name',
      prefix: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey),
      ),
      suffix: _searchController.text.isNotEmpty
          ? GestureDetector(
        onTap: () {
          _searchController.clear();
          filterDepartments();
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(CupertinoIcons.clear_circled, color: CupertinoColors.systemGrey),
        ),
      )
          : null,
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: CupertinoColors.lightBackgroundGray,
        borderRadius: BorderRadius.circular(30.0),
      ),
    )
        : TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Departments',
        hintText: 'Search by Name',
        prefixIcon: Icon(Icons.search, color: Color(0xFF0D9494)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            filterDepartments();
          },
        )
            : null,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      style: TextStyle(fontSize: 16.0),
    );
  }

  Widget _buildDepartmentCard(Department department) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListTile(
          title: Text(
            department.depName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF0D9494),
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
}
