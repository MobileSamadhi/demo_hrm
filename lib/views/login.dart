import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  bool isCompanyCodeVerified = false;
  bool isPasswordVisible = false;

  final TextEditingController companyCodeController = TextEditingController();
  final TextEditingController epfNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();


  // Regular expression for exactly six digits
  final RegExp _companyCodeRegex = RegExp(r'^\d{6}$');

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') ?? false) {
      companyCodeController.text = prefs.getString('company_code') ?? '';
      epfNumberController.text = prefs.getString('epf_number') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      rememberMe = true;
      setState(() {}); // Update the UI to reflect loaded data
    }
  }

  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('company_code', companyCodeController.text);
      await prefs.setString('epf_number', epfNumberController.text);
      await prefs.setString('password', passwordController.text);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('company_code');
      await prefs.remove('epf_number');
      await prefs.remove('password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 500),
                  if (!isCompanyCodeVerified) ...[
                    _buildTextField(
                      controller: companyCodeController,
                      labelText: 'Company Code',
                      hintText: '00000X',
                      prefixIcon: Platform.isIOS
                          ? CupertinoIcons.building_2_fill
                          : Icons.business,
                    ),
                    SizedBox(height: 20),
                    _buildButton(
                      text: 'Verify Company Code',
                      onPressed: () async {
                        String enteredCode = companyCodeController.text.trim();
                        if (_companyCodeRegex.hasMatch(enteredCode)) { // Validate format
                          bool isValidCode = await _verifyCompanyCode(enteredCode);
                          if (isValidCode) {
                            setState(() {
                              isCompanyCodeVerified = true;
                            });
                          } else {
                            _showSnackbar(context, 'Invalid Company Code');
                          }
                        } else {
                          _showSnackbar(context, 'Company Code must be exactly 6 digits');
                        }
                      },
                    ),
                  ] else ...[
                    _buildTextField(
                      controller: epfNumberController,
                      labelText: 'EPF Number',
                      prefixIcon: Platform.isIOS
                          ? CupertinoIcons.person_fill
                          : Icons.account_circle,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 15),
                    _buildTextField(
                      controller: passwordController,
                      labelText: 'Password',
                      prefixIcon: Platform.isIOS
                          ? CupertinoIcons.lock_fill
                          : Icons.lock,
                      obscureText: !isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Color(0xFF0D9494),
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildCheckbox(),
                            Text(
                              'Remember Me',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildButton(
                      text: 'Login',
                      onPressed: () async {
                        if (epfNumberController.text.isNotEmpty &&
                            passwordController.text.isNotEmpty) {
                          bool isLoggedIn = await login(
                            epfNumberController.text,
                            passwordController.text,
                          );
                          if (isLoggedIn) {
                            await _saveCredentials();
                            String managerEmId = await _getManagerEmId();
                            if (managerEmId.isNotEmpty) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => DashboardPage(emId: managerEmId)),
                              );
                            } else {
                              _showSnackbar(context, 'Unable to fetch manager details');
                            }
                          } else {
                            _showSnackbar(context, 'Invalid EPF number or password');
                          }
                        } else {
                          _showSnackbar(context, 'Please enter both EPF number and password');
                        }
                      },
                    ),
                  ],
                  SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your Auth.php endpoint URL
    print('Fetching database details from: $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body); // Change this to List<dynamic>

        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0]; // Access the first item in the list
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        } else {
          print('Error: ${data[0]['status']}');
        }
      } else {
        print('Failed to fetch database details. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching database details: $e');
    }
    return null; // Return null if something goes wrong
  }



  Future<bool> _verifyCompanyCode(String companyCode) async {
    try {
      // Step 1: Fetch database details
      final dbDetails = await fetchDatabaseDetails(companyCode);

      if (dbDetails == null) {
        print('Database details could not be fetched.');
        return false;
      }

      final url = getApiUrl(verifyCompanyEndpoint);
      print('Verifying company code at: $url');

      final body = jsonEncode({
        'company_code': companyCode,
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
      });

      print('Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> dataList = data['data'];
          if (dataList.isNotEmpty) {
            final dbDetails = dataList[0]; // Access the first object in the list
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('database_host', dbDetails['Location']); // Adjust if needed
            await prefs.setString('database_name', dbDetails['CompanyName']); // Adjust if needed
            return true;
          }
        } else {
          print('Error: ${data['error']}');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('Server error: ${response.statusCode}, Message: ${errorData['error']}');
      }
    } catch (e) {
      print('Error verifying company code: $e');
    }
    return false;
  }




  Future<bool> login(String epfNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse(getApiUrl(loginEndpoint)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'epf_number': epfNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_id', data['session_id']);
          await prefs.setString('role', data['role']);
          await prefs.setString('em_id', data['em_id']);
          await prefs.setString('em_code', data['em_code']);

          // Verify if stored correctly
          print("Stored em_id: ${prefs.getString('em_id')}");
          return true;

        }
      }
      return false;
    } catch (error) {
      print('Error logging in: $error');
      return false;
    }
  }

  Future<String> _getManagerEmId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('em_id') ?? '';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
        prefixIcon: Icon(prefixIcon, color: Color(0xFF0D9494)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white70,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Color(0xFF0D9494),
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Color(0xFF0D9494),
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Color(0xFF0D9494),
            width: 2.0,
          ),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    if (Platform.isIOS) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        child: Text(text),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.0),
          backgroundColor: Color(0xFF0D9494),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
            side: BorderSide(color: Color(0xFF0D9494), width: 2),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18.0,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildCheckbox() {
    if (Platform.isIOS) {
      return CupertinoSwitch(
        value: rememberMe,
        onChanged: (bool value) {
          setState(() {
            rememberMe = value;
          });
        },
      );
    } else {
      return Checkbox(
        value: rememberMe,
        onChanged: (bool? value) {
          setState(() {
            rememberMe = value ?? false;
          });
        },
      );
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}