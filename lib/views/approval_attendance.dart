import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class AttendanceApprovalPage extends StatefulWidget {
  final String role;
  final String? emId;

  AttendanceApprovalPage({required this.role, this.emId});

  @override
  _AttendanceApprovalPageState createState() => _AttendanceApprovalPageState();
}

class _AttendanceApprovalPageState extends State<AttendanceApprovalPage> {
  List<dynamic>? attendanceRecords;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingAttendance();
  }

  Future<void> _fetchPendingAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = getApiUrl(fetchPendingAttendanceEndpoint);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'role': widget.role, 'em_id': widget.emId}),
      );

      final data = json.decode(response.body);

      if (data['success']) {
        setState(() {
          attendanceRecords = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          attendanceRecords = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateAttendanceStatus(int attendanceId, String status) async {
    try {
      final url = getApiUrl(updateAttendanceStatusEndpoint);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'attendance_id': attendanceId, 'status': status}),
      );

      final data = json.decode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      if (data['success']) {
        _fetchPendingAttendance(); // Refresh data after updating
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Approval',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0D9494),
        ),
      )
          : attendanceRecords == null || attendanceRecords!.isEmpty
          ? Center(
        child: Text(
          'No pending attendance records',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        itemCount: attendanceRecords!.length,
        itemBuilder: (context, index) {
          final record = attendanceRecords![index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${record['first_name']} ${record['last_name']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () => _updateAttendanceStatus(record['attendance_id'], 'Approved'),
                              ),
                              Text(
                                'Approve',
                                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          SizedBox(width: 8.0), // Spacing between buttons
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () => _updateAttendanceStatus(record['attendance_id'], 'Rejected'),
                              ),
                              Text(
                                'Reject',
                                style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          SizedBox(width: 8.0), // Spacing between buttons
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle, color: Colors.orange),
                                onPressed: () => _updateAttendanceStatus(record['attendance_id'], 'Not Approved'),
                              ),
                              Text(
                                'Not Approve',
                                style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Date: ${record['atten_date']}',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  Text(
                    'Sign-in: ${record['signin_time']}',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  Text(
                    'Sign-out: ${record['signout_time']}',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  Text(
                    'Working Hours: ${record['working_hour']}',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  Text(
                    'Place: ${record['place']}',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
