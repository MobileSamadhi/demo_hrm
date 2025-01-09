import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
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

  Future<void> _fetchPersonalInfo() async {
    final String apiUrl = getApiUrl(personalInfoEndpoint);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Session-ID': widget.sessionId,
        },
        body: {
          'session_id': widget.sessionId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _personalInfo = PersonalInfo.fromJson(data['data']);
            _isLoading = false;

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
            _errorMessage = data['message'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch personal information.';
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
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
        body: json.encode({
          'session_id': widget.sessionId,
          'data': _personalInfo?.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _errorMessage = 'Information updated successfully!';
          });
        } else {
          setState(() {
            _errorMessage = data['message'];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save changes.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
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
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 16)))
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