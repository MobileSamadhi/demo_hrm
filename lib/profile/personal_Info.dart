import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/dashboard.dart';

class PersonalInfo {
  String firstName;
  String lastName;
  String email;
  String phone;
  String gender;
  String birthday;
  String address;
  String bloodGroup;
  String nid;
  String emJoiningDate;

  PersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthday,
    required this.address,
    required this.bloodGroup,
    required this.nid,
    required this.emJoiningDate,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['em_email'] ?? '',
      phone: json['em_phone'] ?? '',
      gender: json['em_gender'] ?? '',
      birthday: json['em_birthday'] ?? '',
      address: json['em_address'] ?? '',
      bloodGroup: json['em_blood_group'] ?? '',
      nid: json['em_nid'] ?? '',
      emJoiningDate: json['em_joining_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "first_name": firstName,
    "last_name": lastName,
    "em_email": email,
    "em_phone": phone,
    "em_gender": gender,
    "em_birthday": birthday,
    "em_address": address,
    "em_blood_group": bloodGroup,
    "em_nid": nid,
    "em_joining_date": emJoiningDate,
  };
}

class PersonalInfoPage extends StatefulWidget {
  final String sessionId;

  PersonalInfoPage({required this.sessionId});

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  PersonalInfo? _personalInfo;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedGender;

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController birthdayController;
  late TextEditingController bloodGroupController;
  late TextEditingController nidController;
  late TextEditingController joiningDateController;

  @override
  void initState() {
    super.initState();
    _fetchPersonalInfo();
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


  Future<void> _fetchPersonalInfo() async {
    final String apiUrl = getApiUrl(personalInfoEndpoint);

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

      print('Fetching personal information with payload: $payload'); // Debug log

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
          setState(() {
            _personalInfo = PersonalInfo.fromJson(data['data']);
            _isLoading = false;

            // Initialize controllers with the fetched personal information
            firstNameController = TextEditingController(text: _personalInfo?.firstName);
            lastNameController = TextEditingController(text: _personalInfo?.lastName);
            emailController = TextEditingController(text: _personalInfo?.email);
            phoneController = TextEditingController(text: _personalInfo?.phone);
            addressController = TextEditingController(text: _personalInfo?.address);
            birthdayController = TextEditingController(text: _personalInfo?.birthday);
            bloodGroupController = TextEditingController(text: _personalInfo?.bloodGroup);
            nidController = TextEditingController(text: _personalInfo?.nid);
            joiningDateController = TextEditingController(text: _personalInfo?.emJoiningDate);
            _selectedGender = _personalInfo?.gender;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Unknown error occurred.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch personal information. HTTP Status: ${response.statusCode}';
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


  Future<void> _savePersonalInfo() async {
    final String apiUrl = getApiUrl(updatePersonalInfoEndpoint);

    setState(() {
      _isLoading = true; // Show a loading indicator
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

      // Update _personalInfo with the current form data
      _personalInfo?.firstName = firstNameController.text;
      _personalInfo?.lastName = lastNameController.text;
      _personalInfo?.email = emailController.text;
      _personalInfo?.phone = phoneController.text;
      _personalInfo?.address = addressController.text;
      _personalInfo?.birthday = birthdayController.text;
      _personalInfo?.gender = _selectedGender ?? '';
      _personalInfo?.bloodGroup = bloodGroupController.text;
      _personalInfo?.nid = nidController.text;
      _personalInfo?.emJoiningDate = joiningDateController.text;

      // Prepare the payload for the request
      final Map<String, dynamic> payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'session_id': widget.sessionId,
        'data': _personalInfo?.toJson(),
      };

      print('Saving personal information with payload: $payload'); // Debug log

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
          setState(() {
            _isLoading = false;
            _errorMessage = 'Information updated successfully!';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Information updated successfully!'),
              backgroundColor: Colors.green),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Unknown error occurred.';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Unknown error')),
          );
        }
      } else {
        throw Exception('Failed to save personal information. HTTP Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'),
          backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Scrollbar(
        thickness: 5.0,
        radius: Radius.circular(8.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(child: CupertinoActivityIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.green, fontSize: 20)))
              : _buildEditForm(),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildTextField('First Name', firstNameController, CupertinoIcons.person),
        _buildTextField('Last Name', lastNameController, CupertinoIcons.person),
        _buildTextField('Email', emailController, CupertinoIcons.mail),
        _buildTextField('Phone', phoneController, CupertinoIcons.phone),
        _buildTextField('Address', addressController, CupertinoIcons.location),
        _buildDateField('Birthday', birthdayController),
        _buildGenderDropdown(),
        _buildTextField('Blood Group', bloodGroupController, CupertinoIcons.drop),
        _buildTextField('NID', nidController, CupertinoIcons.creditcard),
        _buildDateField('Joining Date', joiningDateController),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF0D9494)),
          labelStyle: TextStyle(color: Color(0xFF0D9494)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0D9494)),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        items: ['Male', 'Female'].map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: Icon(CupertinoIcons.person_2_fill, color: Color(0xFF0D9494)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0D9494)),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context, controller),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(CupertinoIcons.calendar_today, color: Color(0xFF0D9494)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0D9494)),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Personal Information',
        style: TextStyle(
          color: Colors.white,
          fontSize: Platform.isIOS ? 20 : 22,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: FloatingActionButton.extended(
            onPressed: _savePersonalInfo,
            icon: Icon(Icons.save, color: Colors.white),
            label: Text(
              "Save",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF0D9494),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}