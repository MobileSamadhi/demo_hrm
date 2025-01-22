import 'dart:io'; // For platform-specific checks
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'dashboard.dart';

const String toDoTaskEndpoint = '/to-do-task.php'; // API endpoint constant

class ToDoListSection extends StatefulWidget {
  final String userId;
  final String sessionId;

  ToDoListSection({required this.userId, required this.sessionId});

  @override
  _ToDoListSectionState createState() => _ToDoListSectionState();
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


class _ToDoListSectionState extends State<ToDoListSection> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController taskController = TextEditingController();


  Future<void> addTask() async {
    try {
      // Retrieve company code from shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      // Fetch database details dynamically
      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details. Please log in again.');
      }

      // Prepare the API URL
      final url = getApiUrl(toDoTaskEndpoint);

      // Log the request body for debugging
      print('Sending request body: ${jsonEncode({
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'action': 'add',
        'to_dodata': taskController.text,
        'date': DateTime.now().toIso8601String(),
        'value': '1',
      })}');

      // Send the POST request to add a task
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId, // Include session ID
        },
        body: jsonEncode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
          'action': 'add',
          'to_dodata': taskController.text,
          'date': DateTime.now().toIso8601String(),
          'value': '1',
        }),
      );

      // Log the response for debugging
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle the server response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            tasks.add({
              'to_dodata': taskController.text,
              'date': DateTime.now().toIso8601String(),
              'value': '1',
            });
            taskController.clear();
          });
          print('Task added successfully.');
        } else {
          throw Exception(responseData['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Failed to add task. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Log and handle errors
      print('Error adding task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  Future<void> fetchTasks() async {
    try {
      // Retrieve company code from shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      // Fetch database details dynamically
      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details. Please log in again.');
      }

      // Prepare the API URL
      final url = getApiUrl(toDoTaskEndpoint);

      // Log the request body for debugging
      print('Sending request body: ${jsonEncode({
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'action': 'add',
        'to_dodata': taskController.text,
        'date': DateTime.now().toIso8601String(),
        'value': '1',
      })}');

      // Send the POST request to add a task
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId, // Include session ID
        },
        body: jsonEncode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
          'action': 'add',
          'to_dodata': taskController.text,
          'date': DateTime.now().toIso8601String(),
          'value': '1',
        }),
      );

      // Log the response for debugging
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle the server response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            tasks.add({
              'to_dodata': taskController.text,
              'date': DateTime.now().toIso8601String(),
              'value': '1',
            });
            taskController.clear();
          });
          print('Task fetched successfully.');
        } else {
          throw Exception(responseData['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Failed to fetch task. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      print('Error feching task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error feching task: $e')),
      );
    } finally {
      // Optional: Add cleanup code if necessary
      print('Add fetch attempt completed.');
    }
  }

  Future<void> removeTask(int index) async {
    final response = await http.post(
      Uri.parse(getApiUrl(toDoTaskEndpoint)),
      headers: {
        'Content-Type': 'application/json',
        'Session-ID': widget.sessionId,
      },
      body: json.encode({
        'action': 'delete',
        'id': tasks[index]['id'].toString(),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          tasks.removeAt(index);
        });
      }
    } else {
      throw Exception('Failed to delete task');
    }
  }



  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPlatformAppBar(),
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Tasks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPlatformTextField(),
                ),
                SizedBox(width: 10),
                _buildPlatformButton('Add', addTask),
              ],
            ),
            SizedBox(height: 16),
            tasks.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No tasks available. Add your first task!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            )
                : _buildTaskList(),
          ],
        ),
      ),
    );
  }

  AppBar _buildPlatformAppBar() {
    return AppBar(
      title: Text(
        'To-Do List',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: Platform.isIOS ? 20 : 22,
        ),
      ),
      backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
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
        IconButton(
          icon: Icon(
            Platform.isIOS ? CupertinoIcons.refresh : Icons.refresh,
            color: Colors.white,
          ),
          onPressed: fetchTasks,
        ),
      ],
    );
  }

  Widget _buildPlatformTextField() {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: taskController,
        placeholder: 'Enter task',
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[900]!),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    } else {
      return TextField(
        controller: taskController,
        decoration: InputDecoration(
          labelText: 'Enter task',
          labelStyle: TextStyle(color: Color(0xFF0D9494)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF0D9494)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF0D9494)),
          ),
        ),
      );
    }
  }

  Widget _buildPlatformButton(String text, VoidCallback onPressed) {
    if (Platform.isIOS) {
      return CupertinoButton.filled(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        borderRadius: BorderRadius.circular(12),
        child: Text(text),
        onPressed: onPressed,
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: Color(0xFF0D9494),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      );
    }
  }

  Widget _buildTaskList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return ToDoItem(
          task: tasks[index]['to_dodata'],
          onDelete: () => removeTask(index),
        );
      },
    );
  }
}

class ToDoItem extends StatelessWidget {
  final String task;
  final VoidCallback onDelete;

  ToDoItem({required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      shadowColor: Color(0xFF0D9494).withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                task,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
