import 'dart:io'; // For platform-specific checks
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'dashboard.dart';

class ToDoListSection extends StatefulWidget {
  final String userId;
  final String sessionId;

  ToDoListSection({required this.userId, required this.sessionId});

  @override
  _ToDoListSectionState createState() => _ToDoListSectionState();
}

class _ToDoListSectionState extends State<ToDoListSection> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController taskController = TextEditingController();

  /// Fetch database details for a given company code
  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      debugPrint('Response Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        } else {
          debugPrint('Invalid response data: $data');
          return null;
        }
      } else {
        debugPrint('Failed to fetch database details. Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching database details: $e');
      return null;
    }
  }

  bool isAddingTask = false; // Add this at the top of your State class

  Future<void> addTask() async {
    if (isAddingTask) return; // Prevent multiple clicks
    if (taskController.text.isNotEmpty) {
      setState(() {
        isAddingTask = true; // Disable button
      });

      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? companyCode = prefs.getString('company_code');

        if (companyCode == null || companyCode.isEmpty) {
          throw Exception('Company code is missing. Please log in again.');
        }

        final dbDetails = await fetchDatabaseDetails(companyCode);
        if (dbDetails == null) {
          throw Exception('Failed to fetch database details.');
        }

        final Map<String, dynamic> payload = {
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
          'action': 'add',
          'to_dodata': taskController.text,
          'date': DateTime.now().toIso8601String(),
          'value': '1',
        };

        debugPrint('Adding task with payload: $payload');

        final response = await http.post(
          Uri.parse(getApiUrl(toDoTaskEndpoint)),
          headers: {'Content-Type': 'application/json', 'Session-ID': widget.sessionId},
          body: jsonEncode(payload),
        );

        debugPrint('Response Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            setState(() {
              tasks.add({
                'to_dodata': taskController.text,
                'date': DateTime.now().toIso8601String(),
                'value': '1',
              });
              taskController.clear();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task added successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            throw Exception(result['message']);
          }
        } else {
          throw Exception('Failed to add task. Status Code: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error adding task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isAddingTask = false; // Re-enable button
        });
      }
    }
  }



  Future<void> fetchTasks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details.');
      }

      final Map<String, dynamic> payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'action': 'fetch',
        'user_id': widget.userId,
      };

      debugPrint('Fetching tasks with payload: $payload');

      final response = await http.post(
        Uri.parse(getApiUrl(toDoTaskEndpoint)),
        headers: {'Content-Type': 'application/json', 'Session-ID': widget.sessionId},
        body: jsonEncode(payload),
      );

      debugPrint('Response Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            tasks.clear();
            tasks.addAll(result['data'].map<Map<String, dynamic>>((task) => {
              'id': task['id'], // Map the task ID properly
              'to_dodata': task['to_dodata'],
              'date': task['date'],
              'value': task['value'],
            }));
          });
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to fetch tasks. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<void> removeTask(int index) async {
    // Show confirmation dialog before deleting the task
    final bool? confirmDeletion = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Dialog background color
          title: Text(
            'Delete Task',
            style: TextStyle(
              color: Color(0xFF0D9494), // Title color
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(
              color: Colors.black87, // Content color
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels deletion
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF0D9494), // Cancel button text color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms deletion
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red, // Delete button text color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
          ),
        );
      },
    );

    // If the user cancels the deletion, stop here
    if (confirmDeletion != true) {
      return;
    }

    try {
      debugPrint('Tasks list: $tasks'); // Debug the tasks list before deletion

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? companyCode = prefs.getString('company_code');

      if (companyCode == null || companyCode.isEmpty) {
        throw Exception('Company code is missing. Please log in again.');
      }

      final dbDetails = await fetchDatabaseDetails(companyCode);
      if (dbDetails == null) {
        throw Exception('Failed to fetch database details.');
      }

      final taskId = tasks[index]['id'];
      if (taskId == null) {
        throw Exception('Refresh the page');
      }

      final Map<String, dynamic> payload = {
        'database_host': dbDetails['database_host'],
        'database_name': dbDetails['database_name'],
        'database_username': dbDetails['database_username'],
        'database_password': dbDetails['database_password'],
        'company_code': companyCode,
        'action': 'delete',
        'id': taskId.toString(), // Use the mapped ID
      };

      debugPrint('Deleting task with payload: $payload');

      final response = await http.post(
        Uri.parse(getApiUrl(toDoTaskEndpoint)),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
        body: jsonEncode(payload),
      );

      debugPrint('Response Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            tasks.removeAt(index);
          });

          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task deleted successfully!'), backgroundColor: Colors.red),
          );
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to delete task. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
        child: isAddingTask
            ? CupertinoActivityIndicator()
            : Text(text),
        onPressed: isAddingTask ? null : onPressed,
      );
    } else {
      return ElevatedButton(
        onPressed: isAddingTask ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: Color(0xFF0D9494),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        child: isAddingTask
            ? SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
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
