import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../views/dashboard.dart';

// Model for Experience
class Experience {
  final String id;
  final String expCompany;
  final String expComPosition;
  final String expComAddress;
  final String expWorkDuration;

  Experience({
    required this.id,
    required this.expCompany,
    required this.expComPosition,
    required this.expComAddress,
    required this.expWorkDuration,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'].toString(),
      expCompany: json['exp_company']?.toString() ?? 'Unknown Company',
      expComPosition: json['exp_com_position']?.toString() ?? 'Unknown Position',
      expComAddress: json['exp_com_address']?.toString() ?? 'Unknown Address',
      expWorkDuration: json['exp_workduration']?.toString() ?? 'Unknown Duration',
    );
  }
}

// Main Page to List Experiences
class ExperienceInfoPage extends StatefulWidget {
  final String sessionId;

  ExperienceInfoPage({required this.sessionId});

  @override
  _ExperienceInfoPageState createState() => _ExperienceInfoPageState();
}

class _ExperienceInfoPageState extends State<ExperienceInfoPage> {
  List<Experience> _experienceList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchExperienceData();
  }


  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      // Log the response code and body for debugging
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Check if the response contains valid data
        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        } else {
          print('Invalid response: ${data}');
          return null;
        }
      } else {
        // Handle non-200 status codes
        print('Error fetching database details. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching database details: $e');
      return null;
    }
  }


  Future<void> _fetchExperienceData() async {
    final String apiUrl = getApiUrl(experienceEndpoint);

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch company code from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      // Fetch database details using the company code
      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details. Please log in again.');
      }

      // Prepare the payload for the request
      final Map<String, dynamic> payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'session_id': widget.sessionId, // Include session ID if required
      };

      print('Fetching education data with payload: $payload'); // Debug log

      // Make the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId, // Include Session-ID if needed
        },
        body: jsonEncode(payload),
      );

      // Log the response
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> educationData = data['data'];
          setState(() {
            _experienceList = educationData.map((edu) => Experience.fromJson(edu)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Unknown error occurred.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch experience data. HTTP Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Experience Records',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? _buildErrorState()
            : _experienceList.isEmpty
            ? _buildEmptyState()
            : _buildExperienceList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work, size: 100, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Experience Records Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceList() {
    return ListView.builder(
      itemCount: _experienceList.length,
      itemBuilder: (context, index) {
        final experience = _experienceList[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      experience.expCompany,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        bool? isUpdated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditExperiencePage(
                              experience: experience,
                              sessionId: widget.sessionId,
                            ),
                          ),
                        );
                        if (isUpdated == true) {
                          _fetchExperienceData();
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Position: ${experience.expComPosition}',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Text(
                  'Address: ${experience.expComAddress}',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Text(
                  'Duration: ${experience.expWorkDuration}',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Page to Edit Individual Experience
class EditExperiencePage extends StatefulWidget {
  final Experience experience;
  final String sessionId;

  EditExperiencePage({required this.experience, required this.sessionId});

  @override
  _EditExperiencePageState createState() => _EditExperiencePageState();
}

class _EditExperiencePageState extends State<EditExperiencePage> {
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _addressController;
  late TextEditingController _durationController;
  bool _isSaving = false;
  String _errorMessage = '';

  final DateFormat _yearFormat = DateFormat('yyyy'); // Format for year only

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.experience.expCompany);
    _positionController = TextEditingController(text: widget.experience.expComPosition);
    _addressController = TextEditingController(text: widget.experience.expComAddress);
    _durationController = TextEditingController(text: widget.experience.expWorkDuration);
  }

  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      // Log the response code and body for debugging
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Check if the response contains valid data
        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        } else {
          print('Invalid response: ${data}');
          return null;
        }
      } else {
        // Handle non-200 status codes
        print('Error fetching database details. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching database details: $e');
      return null;
    }
  }

  Future<void> _updateExperience() async {
    final String apiUrl = getApiUrl(updateExperienceEndpoint);

    setState(() {
      _isSaving = true;
      _errorMessage = ''; // Initialize error message
    });

    try {
      // Fetch company code from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      // Fetch database details using the company code
      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details. Please log in again.');
      }

      // Prepare the payload for the request
      final Map<String, dynamic> payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'session_id': widget.sessionId,
        'id': widget.experience.id,
        'exp_company': _companyController.text,
        'exp_com_position': _positionController.text,
        'exp_com_address': _addressController.text,
        'exp_workduration': _durationController.text,
      };

      print('Updating experience data with payload: $payload'); // Debug log

      // Make the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
        body: jsonEncode(payload),
      );

      // Log the response
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // Show success Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Experience details updated successfully!'),
              backgroundColor: Colors.green, // Green for success
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true); // Close the screen and indicate success
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Unknown error occurred.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage)),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to update experience. HTTP Status: ${response.statusCode}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } finally {
      setState(() {
        _isSaving = false; // Stop the saving indicator
      });
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year - 2),
        end: now,
      ),
    );

    if (picked != null) {
      setState(() {
        _durationController.text =
        '${_yearFormat.format(picked.start)} - ${_yearFormat.format(picked.end)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Experience',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStyledTextField(
              controller: _companyController,
              label: 'Company',
              icon: Icons.business,
            ),
            SizedBox(height: 16),
            _buildStyledTextField(
              controller: _positionController,
              label: 'Position',
              icon: Icons.work,
            ),
            SizedBox(height: 16),
            _buildStyledTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on,
            ),
            SizedBox(height: 16),
            _buildStyledTextField(
              controller: _durationController,
              label: 'Duration',
              icon: Icons.timer,
              onTap: () => _selectDateRange(context),
            ),
            SizedBox(height: 24),
            _isSaving
                ? Center(child: CircularProgressIndicator(color: Color(0xFF0D9494)))
                : ElevatedButton(
              onPressed: _updateExperience,
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF0D9494),
                padding: EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: onTap != null, // Make field read-only if onTap is provided
      onTap: onTap, // Open date range picker when tapped
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF0D9494)),
        prefixIcon: Icon(icon, color: Color(0xFF0D9494)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D9494)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D9494), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}