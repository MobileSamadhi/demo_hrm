import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;

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

class Designation {
  final int id;
  final String desName;
  final List<Employee> employees;

  Designation({
    required this.id,
    required this.desName,
    required this.employees,
  });

  factory Designation.fromJson(Map<String, dynamic> json) {
    var employeesJson = json['employees'] as List;
    List<Employee> employeesList = employeesJson.map((e) => Employee.fromJson(e)).toList();

    return Designation(
      id: int.parse(json['id'].toString()),
      desName: json['des_name'],
      employees: employeesList,
    );
  }
}

class DesignationPage extends StatefulWidget {
  @override
  _DesignationPageState createState() => _DesignationPageState();
}

class _DesignationPageState extends State<DesignationPage> {
  late Future<List<Designation>> futureDesignations;
  List<Designation> _filteredDesignations = [];
  List<Designation> _allDesignations = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureDesignations = fetchDesignations();
    futureDesignations.then((designations) {
      setState(() {
        _allDesignations = designations;
        _filteredDesignations = designations;
      });
    });
    _searchController.addListener(_onSearchChanged);
  }

  Future<List<Designation>> fetchDesignations() async {
    final url = getApiUrl(designationEndpoint);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map<Designation>((data) => Designation.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load designations');
    }
  }

  void _onSearchChanged() {
    filterDesignations();
  }

  void filterDesignations() {
    List<Designation> results = [];
    if (_searchController.text.isEmpty) {
      results = _allDesignations;
    } else {
      results = _allDesignations.where((designation) =>
      designation.desName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          designation.id.toString().contains(_searchController.text)).toList();
    }

    setState(() {
      _filteredDesignations = results;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // Remove the debug label
      home: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildSearchField(),
            ),
            Expanded(
              child: FutureBuilder<List<Designation>>(
                future: futureDesignations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return ListView.builder(
                      itemCount: _filteredDesignations.length,
                      itemBuilder: (context, index) {
                        Designation designation = _filteredDesignations[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(12.0),
                            shadowColor: Colors.black26,
                            color: Colors.white,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DesignationDetailPage(designation: designation),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  gradient: LinearGradient(
                                    colors: [Colors.teal.shade50, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.teal.shade100,
                                      child: Icon(
                                        Icons.work,
                                        color: Color(0xFF0D9494),
                                        size: 28,
                                      ),
                                    ),
                                    SizedBox(width: 16.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            designation.desName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              color: Color(0xFF0D9494),
                                            ),
                                          ),
                                          SizedBox(height: 4.0),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Color(0xFF0D9494),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text('Designations List', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
      title: Text('Designations List', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Designations',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
}


class DesignationDetailPage extends StatelessWidget {
  final Designation designation;

  DesignationDetailPage({required this.designation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${designation.desName}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: designation.employees.isEmpty
            ? Center(
          child: Text(
            'No employees found for this designation.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        )
            : ListView.builder(
          itemCount: designation.employees.length,
          itemBuilder: (context, index) {
            final employee = designation.employees[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  radius: 24,
                  child: Text(
                    employee.firstName[0],
                    style: TextStyle(
                      color: Color(0xFF0D9494),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  '${employee.firstName} ${employee.lastName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
