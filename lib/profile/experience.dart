import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  Future<void> _fetchExperienceData() async {
    final String apiUrl = getApiUrl(experienceEndpoint);

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
          final List<dynamic> experienceData = data['data'];
          setState(() {
            _experienceList =
                experienceData.map((exp) => Experience.fromJson(exp)).toList();
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
          _errorMessage = 'Failed to fetch experience data.';
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

  final DateFormat _yearFormat = DateFormat('yyyy'); // Format for year only

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.experience.expCompany);
    _positionController = TextEditingController(text: widget.experience.expComPosition);
    _addressController = TextEditingController(text: widget.experience.expComAddress);
    _durationController = TextEditingController(text: widget.experience.expWorkDuration);
  }

  Future<void> _updateExperience() async {
    final String apiUrl = getApiUrl(updateExperienceEndpoint);

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
          'id': widget.experience.id,
          'exp_company': _companyController.text,
          'exp_com_position': _positionController.text,
          'exp_com_address': _addressController.text,
          'exp_workduration': _durationController.text,
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
        _showError('Failed to update experience.');
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