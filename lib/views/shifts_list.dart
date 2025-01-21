import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:hrm_system/views/shift_management.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Shifts {
  final int SFID;
  final TimeOfDay intime;
  final TimeOfDay outtime;
  final int status;

  Shifts({
    required this.SFID,
    required this.intime,
    required this.outtime,
    required this.status,
  });

  factory Shifts.fromJson(Map<String, dynamic> json) {
    return Shifts(
      SFID: json['SFID'],
      intime: _parseTimeOfDay(json['intime']),
      outtime: _parseTimeOfDay(json['outtime']),
      status: json['status'],
    );
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SFID': SFID.toString(),
      'intime': '${intime.hour}:${intime.minute}:00',
      'outtime': '${outtime.hour}:${outtime.minute}:00',
      'status': status.toString(),
    };
  }
}

class ShiftsPage extends StatefulWidget {
  @override
  _ShiftsPageState createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  late Future<List<Shifts>> futureShifts;
  List<Shifts> _filteredShifts = [];
  List<Shifts> _allShifts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureShifts = fetchShifts();
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
    List<Shifts> results = [];
    if (_searchController.text.isEmpty) {
      results = _allShifts;
    } else {
      results = _allShifts.where((shift) {
        final intimeString = '${shift.intime.hour}:${shift.intime.minute.toString().padLeft(2, '0')}';
        final outtimeString = '${shift.outtime.hour}:${shift.outtime.minute.toString().padLeft(2, '0')}';
        return shift.SFID.toString().contains(_searchController.text) ||
            intimeString.contains(_searchController.text) ||
            outtimeString.contains(_searchController.text);
      }).toList();
    }

    setState(() {
      _filteredShifts = results;
    });
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
  Future<List<Shifts>> fetchShifts() async {
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

    final url = getApiUrl(shiftsEndpoint); // Replace with your actual endpoint

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

      // Send POST request to fetch shifts
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // Log the response
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse the response body
        final jsonResponse = json.decode(response.body);

        // Check if the response contains a "data" key
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'];

          // Ensure "data" is a list
          if (data is List<dynamic>) {
            return data.map<Shifts>((shift) => Shifts.fromJson(shift)).toList();
          } else {
            throw Exception('Unexpected data format: Expected a list.');
          }
        } else if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('error')) {
          throw Exception(jsonResponse['error']);
        } else {
          throw Exception('Unexpected response format.');
        }
      } else {
        // Handle non-200 responses
        print('Error: Failed to load Shifts. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load Shifts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Log any errors that occur
      print('Error fetching Shifts: $e');
      throw Exception('Error fetching Shifts: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shifts List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
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
                hintText: 'Search by Shift ID, In Time, or Out Time',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: FutureBuilder<List<Shifts>>(
                future: futureShifts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: _filteredShifts.length,
                      itemBuilder: (context, index) {
                        Shifts shift = _filteredShifts[index];
                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          color: Color(0xFF0D9494),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ListTile(
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
                                    Row(
                                      children: [
                                        Icon(Icons.timer, size: 16, color: Colors.white),
                                        SizedBox(width: 5),
                                        Text(
                                          'In: ${shift.intime.format(context)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.timer_off, size: 16, color: Colors.white),
                                        SizedBox(width: 5),
                                        Text(
                                          'Out: ${shift.outtime.format(context)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.info, size: 16, color: Colors.white),
                                        SizedBox(width: 5),
                                        Text(
                                          'Status: ${shift.status == 1 ? 'Active' : 'Inactive'}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: shift.status == 1 ? Colors.greenAccent : Colors.redAccent,
                                          ),
                                        ),
                                      ],
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
          ),
        ],
      ),
    );
  }
}
