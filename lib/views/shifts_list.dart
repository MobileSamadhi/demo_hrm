import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:hrm_system/views/shift_management.dart';
import 'package:http/http.dart' as http;

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

  Future<List<Shifts>> fetchShifts() async {
    final url = getApiUrl(shiftsEndpoint);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      List shiftsJson = jsonResponse['data'];
      return shiftsJson.map<Shifts>((data) => Shifts.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load shifts');
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
