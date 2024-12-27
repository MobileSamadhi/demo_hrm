import 'dart:convert';
import 'dart:io'; // Needed for Platform checks
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'assign_shift.dart';
import 'dashboard.dart';

class EmployeeShift {
  final int id;
  final String empId;
  final int SFID;
  final String shiftDate;
  late final int status;
  final String firstName;
  final String lastName;

  EmployeeShift({
    required this.id,
    required this.empId,
    required this.SFID,
    required this.shiftDate,
    required this.status,
    required this.firstName,
    required this.lastName,
  });

  factory EmployeeShift.fromJson(Map<String, dynamic> json) {
    return EmployeeShift(
      id: json['id'],  // id is an integer, no need to parse
      empId: json['emp_id'].toString(),  // Ensure emp_id is treated as a string
      SFID: json['SFID'],  // SFID is an integer
      shiftDate: json['shift_date'],  // shift_date is a string
      status: json['status'],  // status is an integer
      firstName: json['first_name'],  // first_name is a string
      lastName: json['last_name'],  // last_name is a string
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'emp_id': empId,
      'SFID': SFID.toString(),
      'shift_date': shiftDate,
      'status': status.toString(),
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}



class EmployeeShiftPage extends StatefulWidget {
  @override
  _EmployeeShiftPageState createState() => _EmployeeShiftPageState();
}

class _EmployeeShiftPageState extends State<EmployeeShiftPage> {
  late Future<List<EmployeeShift>> futureShifts;
  List<EmployeeShift> _filteredShifts = [];
  List<EmployeeShift> _allShifts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureShifts = fetchEmployeeShifts();
    futureShifts.then((shifts) {
      setState(() {
        _allShifts = shifts;
        _filteredShifts = shifts;
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
    filterShifts();
  }

  void filterShifts() {
    String searchText = _searchController.text.toLowerCase();
    List<EmployeeShift> results = [];

    if (searchText.isEmpty) {
      results = _allShifts;
    } else {
      results = _allShifts.where((shift) {
        String statusString = shift.status == 1 ? 'active' : 'inactive';
        return shift.empId.toLowerCase().contains(searchText) ||
            shift.SFID.toString().contains(searchText) ||
            shift.shiftDate.contains(searchText) ||
            shift.firstName.toLowerCase().contains(searchText) ||
            shift.lastName.toLowerCase().contains(searchText);
            statusString.contains(searchText);
      }).toList();
    }

    setState(() {
      _filteredShifts = results;
    });
  }

  Future<List<EmployeeShift>> fetchEmployeeShifts() async {

    final url = getApiUrl(employeeShiftsEndpoint);

    final response = await http.get(Uri.parse(url));


    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map<EmployeeShift>((data) => EmployeeShift.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load employee shifts');
    }
  }

  Future<void> updateShiftStatus(EmployeeShift shift, int newStatus) async {
    shift.status = newStatus;

    final response = await http.put(

    Uri.parse('http://10.0.2.2/example_api/update_employee_shift.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(shift.toJson()),
    );

    if (response.statusCode == 200) {
      setState(() {
        futureShifts = fetchEmployeeShifts();
      });
    } else {
      throw Exception('Failed to update shift status');
    }
  }

  void _showEditStatusSheet(EmployeeShift shift) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Shift Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Active'),
                leading: Radio(
                  value: 1,
                  groupValue: shift.status,
                  onChanged: (int? value) {
                    updateShiftStatus(shift, value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Inactive'),
                leading: Radio(
                  value: 0,
                  groupValue: shift.status,
                  onChanged: (int? value) {
                    updateShiftStatus(shift, value!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Platform-specific color for AppBar
        backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
        title: Text(
          'Employee Shifts',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        leading: IconButton(
          // Platform-specific back icon
          icon: Icon(Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back, color: Colors.white),
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
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search by Employee Name, ID, SFID, Date, or Status',
                prefixIcon: Icon(
                  // Platform-specific search icon
                  Platform.isIOS ? Icons.search : Icons.search,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EmployeeShift>>(
              future: futureShifts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: _filteredShifts.length,
                    itemBuilder: (context, index) {
                      EmployeeShift shift = _filteredShifts[index];
                      return Card(
                        elevation: 6,
                        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), Color(0xFF0D9494)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ListTile(
                              leading: Icon(Icons.schedule, color: Colors.white),
                              title: Text(
                                'Shift ID: ${shift.SFID}',
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
                                    Text(
                                      'Employee name: ${shift.firstName + " " + shift.lastName}',
                                      style: TextStyle(fontSize: 16, color: Colors.white70),
                                    ),
                                    Text(
                                      'Employee ID: ${shift.empId}',
                                      style: TextStyle(fontSize: 16, color: Colors.white70),
                                    ),
                                    Text(
                                      'Shift Date: ${shift.shiftDate}',
                                      style: TextStyle(fontSize: 16, color: Colors.white70),
                                    ),
                                    Text(
                                      'Status: ${shift.status == 1 ? 'Active' : 'Inactive'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: shift.status == 1 ? Colors.greenAccent : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }
}