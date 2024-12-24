import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard.dart';

class EarnLeavePage extends StatefulWidget {
  @override
  _EarnLeavePageState createState() => _EarnLeavePageState();
}

class _EarnLeavePageState extends State<EarnLeavePage> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String? _selectedLeaveType;
  final List<String> _leaveTypeOptions = ['All', 'Sick Leave', 'Casual Leave', 'Paid Leave'];
  List<Map<String, dynamic>> _leaveData = [];
  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaveData();
  }

  Future<void> _fetchLeaveData() async {
    try {
      final url = getApiUrl(earnLeaveEndpoint);

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _leaveData = List<Map<String, dynamic>>.from(data.map((entry) => {
            'em_id': entry['em_id'] ?? 'N/A',
            'first_name': entry['first_name'] ?? 'Unknown',
            'last_name': entry['last_name'] ?? 'Unknown',
            'leave_type': entry['leave_type'] ?? 'Unknown',
            'start_date': entry['start_date'] ?? 'N/A',
            'end_date': entry['end_date'] ?? 'N/A',
            'leave_duration': entry['leave_duration'] ?? '0',
          }));
          _filteredData = _leaveData;
        });
      } else {
        throw Exception('Failed to load leave data');
      }
    } catch (e) {
      print('Error fetching leave data: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
            colorScheme: ColorScheme.light(primary: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  void _filterLeave() {
    setState(() {
      _filteredData = _leaveData.where((entry) {
        bool matchesType = _selectedLeaveType == 'All' || _selectedLeaveType == null || entry['leave_type'] == _selectedLeaveType;
        return matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPlatformAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDateField('Start Date', _startDateController, context),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDateField('End Date', _endDateController, context),
                ),
              ],
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLeaveType,
              items: _leaveTypeOptions.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              decoration: InputDecoration(
                labelText: 'Leave Type',
                prefixIcon: Icon(
                  Icons.filter_list,
                  color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedLeaveType = value;
                  _filterLeave();
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: _filteredData.isEmpty
                  ? Center(
                child: Text(
                  'No leave records found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredData.length,
                itemBuilder: (context, index) {
                  var leave = _filteredData[index];
                  return _buildLeaveCard(leave);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildPlatformAppBar() {
    return AppBar(
      title: Text(
        'Earned Leave Report',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: Platform.isIOS ? 20 : 22),
      ),
      backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
      leading: IconButton(
        icon: Icon(
          Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
          );
        },
      ),
      elevation: 4,
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.date_range,
          color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.calendar_today,
            color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
          ),
          onPressed: () {
            _selectDate(context, controller);
          },
        ),
      ),
      readOnly: true,
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    String empName = "${leave['first_name']} ${leave['last_name']}";

    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getLeaveTypeColor(leave['leave_type']),
          child: _getLeaveTypeIcon(leave['leave_type']),
        ),
        title: Text(
          empName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('Date: ${leave['start_date']} to ${leave['end_date']}'),
      ),
    );
  }

  Color _getLeaveTypeColor(String leaveType) {
    switch (leaveType) {
      case 'Sick Leave':
        return Colors.red;
      case 'Casual Leave':
        return Colors.orange;
      case 'Paid Leave':
        return Colors.green;
      default:
        return Colors.cyan;
    }
  }

  // Get icon based on leave type
  Icon _getLeaveTypeIcon(String leaveType) {
    switch (leaveType) {
      case 'Sick Leave':
        return Icon(Icons.medical_services, color: Colors.white);
      case 'Casual Leave':
        return Icon(Icons.local_cafe, color: Colors.white);
      case 'Paid Leave':
        return Icon(Icons.attach_money, color: Colors.white);
      default:
        return Icon(Icons.leave_bags_at_home, color: Colors.white);
    }
  }
}
