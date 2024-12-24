import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';

class NotificationsPage extends StatefulWidget {
  final String emId;  // User's employee ID

  NotificationsPage({required this.emId});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic>? notifications;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();  // Fetch notifications when the page is initialized
  }

  // Function to fetch notifications
  Future<void> _fetchNotifications() async {
    try {
      final response = await http.post(
        Uri.parse('https://hrmmobi.synnexcloudpos.com/fetch_notifications.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'em_id': widget.emId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            notifications = responseData['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
          _showSnackbar('Error: ${responseData['message']}');
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        _showSnackbar('Failed to fetch notifications. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showSnackbar('An error occurred: $e');
    }
  }

  // Helper function to show snackbars
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: Text('No notifications found.'))
          : notifications != null && notifications!.isNotEmpty
          ? ListView.builder(
        itemCount: notifications!.length,
        itemBuilder: (context, index) {
          final notification = notifications![index];
          return ListTile(
            title: Text(notification['message']),
            subtitle: Text(notification['created_at']),
          );
        },
      )
          : Center(child: Text('No notifications found.')),
    );
  }
}
