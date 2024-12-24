import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'dashboard.dart';

class AssignShiftPage extends StatefulWidget {
  @override
  _AssignShiftPageState createState() => _AssignShiftPageState();
}

class _AssignShiftPageState extends State<AssignShiftPage> {
  final TextEditingController employeeNumberController = TextEditingController();
  final TextEditingController SFIDController = TextEditingController(); // For SFID input
  DateTime? selectedDate;
  String selectedStatus = 'Assigned';

  final List<String> statuses = ['Assigned', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on outside tap
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: employeeNumberController,
                labelText: 'Employee ID',
                prefixIcon: Icons.badge,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              _buildDatePicker(context),
              SizedBox(height: 20),
              _buildTextField(
                controller: SFIDController,
                labelText: 'SFID',
                prefixIcon: Icons.confirmation_number,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 30),
              _buildButton(
                text: 'Assign Shift',
                onPressed: () {
                  if (_validateForm()) {
                    _assignShift(); // Call to the backend PHP script
                  } else {
                    _showSnackbar(context, 'Please fill all fields');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Assign Shift',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Color(0xFF0D9494),
      leading: IconButton(
        icon: Platform.isIOS
            ? Icon(Icons.arrow_back_ios, color: Colors.white)
            : Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
          );
        },
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return Platform.isIOS
        ? CupertinoButton(
      onPressed: onPressed,
      color: Color(0xFF0D9494),
      child: Text(
        text,
        style: TextStyle(fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    )
        : ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14.0),
        backgroundColor: Color(0xFF0D9494),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return Platform.isIOS
        ? CupertinoTextField(
      controller: controller,
      placeholder: labelText,
      prefix: prefixIcon != null ? Icon(prefixIcon, color: Color(0xFF0D9494)) : null,
      keyboardType: keyboardType,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.0),
      ),
    )
        : TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Color(0xFF0D9494)) : null,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
      readOnly: onTap != null,
      onTap: onTap,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        DateTime? date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() {
            selectedDate = date;
          });
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(
          controller: TextEditingController(
            text: selectedDate != null
                ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                : '',
          ),
          labelText: 'Shift Date',
          prefixIcon: Icons.calendar_today,
        ),
      ),
    );
  }

  bool _validateForm() {
    return employeeNumberController.text.isNotEmpty &&
        SFIDController.text.isNotEmpty &&
        selectedDate != null &&
        selectedStatus.isNotEmpty;
  }

  void _assignShift() async {

    final url = getApiUrl(assignShiftsEndpoint);

    final response = await http.post(
      Uri.parse(url), // Update this to your PHP URL
      body: {
        'emp_id': employeeNumberController.text,
        'SFID': SFIDController.text,
        'shift_date': "${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}",
        'status': selectedStatus == 'Assigned' ? '1' : '0', // Adjust mapping for status
      },
    );

    final responseData = json.decode(response.body);
    if (responseData['success'] == true) {
      _showSnackbar(context, 'Shift assigned successfully!');
      _clearForm();
    } else {
      _showSnackbar(context, responseData['error'] ?? 'Error assigning shift.');
    }
  }

  void _clearForm() {
    employeeNumberController.clear();
    SFIDController.clear();
    setState(() {
      selectedDate = null;
      selectedStatus = 'Assigned';
    });
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF0D9494),
        duration: Duration(seconds: 2),
      ),
    );
  }
}