import 'dart:convert';
import 'dart:io'; // Import the dart:io library
import 'package:flutter/cupertino.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    futureNotices = fetchNotices();
  }

  Future<List<Notice>> fetchNotices() async {
    final url = getApiUrl(noticeEndpoint);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      try {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map<Notice>((data) => Notice.fromJson(data)).toList();
      } catch (e) {
        throw Exception('Failed to parse JSON: $e');
      }
    } else {
      throw Exception('Failed to load notices');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notice Board', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
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
