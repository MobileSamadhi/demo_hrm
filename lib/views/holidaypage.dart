import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Import the dart:io library to access platform information
import '../constants.dart';
import 'dashboard.dart';

class HolidayPage extends StatefulWidget {
  @override
  _HolidayPageState createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _holidayNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _numberOfDaysController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String _holidayName = '';
  String _startDate = '';
  String _endDate = '';
  String _numberOfDays = '';
  String _year = '';

  @override
  void dispose() {
    _holidayNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _numberOfDaysController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String holidayName = _holidayNameController.text;
      final String startDate = _startDateController.text;
      final String endDate = _endDateController.text;
      final String numberOfDays = _numberOfDaysController.text;
      final String year = _yearController.text;

      final url = getApiUrl(holidayEndpoint);
      final response = await http.post(

        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'add',
          'holiday_name': holidayName,
          'from_date': startDate,
          'to_date': endDate,
          'number_of_days': numberOfDays,
          'year': year,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final status = result['status'];
        final message = result['message'] ?? 'Unknown error';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$status: $message')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to the server')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Holiday Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: Platform.isIOS ? 20 : 22, // Different font size for iOS
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
            );
          },
        ),
        elevation: Platform.isIOS ? 0 : 4, // No shadow for iOS
        // iOS-style back button
        // You can also add additional style properties if desired
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: Platform.isIOS ? 20.0 : 16.0), // Adjust padding for iOS
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Enter Holiday Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9494),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _holidayNameController,
                label: 'Holiday Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a holiday name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildDateField(
                controller: _startDateController,
                label: 'Start Date',
                onTap: () => _selectDate(context, _startDateController),
              ),
              SizedBox(height: 20),
              _buildDateField(
                controller: _endDateController,
                label: 'End Date',
                onTap: () => _selectDate(context, _endDateController),
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _numberOfDaysController,
                label: 'Number of Days',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of days';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _yearController,
                label: 'Year',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the year';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: Color(0xFF0D9494),
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      // Add platform-specific styling
      style: Platform.isIOS
          ? TextStyle(color: Colors.black)
          : TextStyle(color: Colors.black),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a date';
            }
            return null;
          },
          // Add platform-specific styling
          style: Platform.isIOS
              ? TextStyle(color: Colors.black)
              : TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
