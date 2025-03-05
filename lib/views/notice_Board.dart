import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'dashboard.dart';

class Notice {
  final String title;
  final String date;

  Notice({
    required this.title,
    required this.date,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      title: json['title'],
      date: json['date'],
    );
  }
}

class NoticeBoardSection extends StatefulWidget {
  @override
  _NoticeBoardSectionState createState() => _NoticeBoardSectionState();
}

class _NoticeBoardSectionState extends State<NoticeBoardSection> {
  late Future<List<Notice>> futureNotices;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    futureNotices = fetchNotices();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }


  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

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
        }
      }
    } catch (e) {
      print('Error fetching database details: $e');
    }
    return null;
  }

  Future<List<Notice>> fetchNotices() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    if (companyCode == null || companyCode.isEmpty) {
      throw Exception('Company code is missing. Please log in again.');
    }

    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      throw Exception('Failed to fetch database details. Please log in again.');
    }

    final url = getApiUrl(noticeEndpoint);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'database_host': dbDetails['database_host'],
          'database_name': dbDetails['database_name'],
          'database_username': dbDetails['database_username'],
          'database_password': dbDetails['database_password'],
          'company_code': companyCode,
        }),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        List<Notice> notices = jsonResponse.map<Notice>((data) => Notice.fromJson(data)).toList();

        // Get today's date in both possible formats
        String todayDate1 = DateFormat('yyyy-MM-dd').format(DateTime.now()); // "2025-03-05"
        String todayDate2 = DateFormat('yyyy/MM/dd').format(DateTime.now()); // "2025/03/05"

        // Filter notices for today's date in either format
        List<Notice> todayNotices = notices.where((notice) {
          return notice.date == todayDate1 || notice.date == todayDate2;
        }).toList();

        if (todayNotices.isNotEmpty) {
          for (var notice in todayNotices) {
            _showNotification(notice);
          }
        }

        return notices;
      } else {
        throw Exception('Failed to load notices. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notices: $e');
    }
  }

  Future<void> _showNotification(Notice notice) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'notice_channel',
      'Notice Notifications',
      channelDescription: 'Notifies about new notices',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
      'New Notice: ${notice.title}',
      'Published on ${notice.date}',
      notificationDetails,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notice Board',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
                  builder: (context) => DashboardPage(emId: '',)),
            );
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
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
            FutureBuilder<List<Notice>>(
              future: futureNotices,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No notices available',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: snapshot.data!.map((notice) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(
                                notice.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0D9494),
                                ),
                              ),
                              subtitle: Text(
                                'Date: ${notice.date}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Icon(
                                Icons.notifications,
                                color: Color(0xFF0D9494),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
