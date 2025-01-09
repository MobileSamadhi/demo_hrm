import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../views/dashboard.dart';

class Education {
  final String id;
  final String eduType;
  final String institute;
  final String result;
  final String year;

  Education({
    required this.id,
    required this.eduType,
    required this.institute,
    required this.result,
    required this.year,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id']?.toString() ?? '',
      eduType: json['edu_type']?.toString() ?? 'Unknown Type',
      institute: json['institute']?.toString() ?? 'Unknown Institute',
      result: json['result']?.toString() ?? 'Unknown Result',
      year: json['year']?.toString() ?? 'Unknown Year',
    );
  }
}

class EducationInfoPage extends StatefulWidget {
  final String sessionId;

  EducationInfoPage({required this.sessionId});

  @override
  _EducationInfoPageState createState() => _EducationInfoPageState();
}

class _EducationInfoPageState extends State<EducationInfoPage> {
  List<Education> _educationList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEducationData();
  }

  Future<void> _fetchEducationData() async {
    final String apiUrl = getApiUrl(educationEndpoint);

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> educationData = data['data'];
          setState(() {
            _educationList =
                educationData.map((edu) => Education.fromJson(edu)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch education data.';
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
        title: Text(
          'Education Records',
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
              MaterialPageRoute(
                builder: (context) => DashboardPage(emId: ''),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF0D9494)))
            : _errorMessage.isNotEmpty
            ? Center(
          child: Text(
            _errorMessage,
            style: TextStyle(color: Colors.red),
          ),
        )
            : _educationList.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 100, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Education Records Found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        )
            : _buildEducationList(),
      ),
    );
  }

  Widget _buildEducationList() {
    return ListView.builder(
      itemCount: _educationList.length,
      itemBuilder: (context, index) {
        final education = _educationList[index];
        return Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              education.eduType,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D9494),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${education.institute}\n${education.year} - ${education.result}',
                style: TextStyle(height: 1.4, color: Colors.grey[700]),
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF0D9494)),
              onPressed: () async {
                bool? isUpdated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEducationPage(
                      education: education,
                      sessionId: widget.sessionId,
                    ),
                  ),
                );
                if (isUpdated == true) {
                  _fetchEducationData();
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class EditEducationPage extends StatefulWidget {
  final Education education;
  final String sessionId;

  EditEducationPage({required this.education, required this.sessionId});

  @override
  _EditEducationPageState createState() => _EditEducationPageState();
}

class _EditEducationPageState extends State<EditEducationPage> {
  late TextEditingController _typeController;
  late TextEditingController _instituteController;
  late TextEditingController _resultController;
  late TextEditingController _yearController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.education.eduType);
    _instituteController = TextEditingController(text: widget.education.institute);
    _resultController = TextEditingController(text: widget.education.result);
    _yearController = TextEditingController(text: widget.education.year);
  }

  Future<void> _updateEducation() async {
    final String apiUrl = getApiUrl(updateEducationEndpoint);

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
        body: json.encode({
          'id': widget.education.id,
          'edu_type': _typeController.text,
          'institute': _instituteController.text,
          'result': _resultController.text,
          'year': _yearController.text,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          Navigator.pop(context, true);
        } else {
          _showError(data['message']);
        }
      } else {
        _showError('Failed to update education.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Education',
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
              MaterialPageRoute(
                builder: (context) => DashboardPage(emId: ''),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStyledTextField(
              controller: _typeController,
              label: 'Type',
              icon: Icons.school,
            ),
            SizedBox(height: 16),
            _buildStyledTextField(
              controller: _instituteController,
              label: 'Institute',
              icon: Icons.location_city,
            ),
            SizedBox(height: 16),
            _buildStyledTextField(
              controller: _resultController,
              label: 'Result',
              icon: Icons.grade,
            ),
            SizedBox(height: 16),
            _buildStyledTextField(
              controller: _yearController,
              label: 'Year',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),
            _isSaving
                ? Center(child: CircularProgressIndicator(color: Color(0xFF0D9494)))
                : ElevatedButton(
              onPressed: _updateEducation,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF0D9494)),
        labelStyle: TextStyle(color: Color(0xFF0D9494)),
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