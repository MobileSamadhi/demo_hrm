import 'dart:convert';
import 'dart:io'; // Import the dart:io package
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dashboard.dart';

class HolidaySection {
  final String holiday_name;
  final String from_date;
  final String to_date;
  final String number_of_days;

  HolidaySection({
    required this.holiday_name,
    required this.from_date,
    required this.to_date,
    required this.number_of_days,
  });

  factory HolidaySection.fromJson(Map<String, dynamic> json) {
    return HolidaySection(
      holiday_name: json['holiday_name'],
      from_date: json['from_date'],
      to_date: json['to_date'],
      number_of_days: json['number_of_days'],
    );
  }
}

class HolidaysSection extends StatefulWidget {
  @override
  _HolidaysSectionState createState() => _HolidaysSectionState();
}

class _HolidaysSectionState extends State<HolidaysSection> {
  late Future<List<HolidaySection>> futureHolidays;

  @override
  void initState() {
    super.initState();
    futureHolidays = fetchHolidays();
  }

  Future<List<HolidaySection>> fetchHolidays() async {

    final url = getApiUrl(holidaySectionEndpoint);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      try {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map<HolidaySection>((data) => HolidaySection.fromJson(data)).toList();
      } catch (e) {
        throw Exception('Failed to parse JSON: $e');
      }
    } else {
      throw Exception('Failed to load holidays');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Platform.isIOS
          ? CupertinoNavigationBar(
        middle: Text(
          'Holidays',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: CupertinoNavigationBarBackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (context) => DashboardPage(emId: '',)),
            );
          },
        ),
      )
          : AppBar(
        title: Text(
          'Holidays',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                futureHolidays = fetchHolidays(); // Refresh the holidays list
              });
            },
          ),
        ],
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
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              FutureBuilder<List<HolidaySection>>(
                future: futureHolidays,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Platform.isIOS
                          ? CupertinoActivityIndicator()
                          : CircularProgressIndicator(),
                    );
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
                        'No holidays available',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  } else {
                    return Column(
                      children: snapshot.data!.map((holiday) {
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
                                holiday.holiday_name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0D9494),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.date_range, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text(
                                        'From: ${holiday.from_date}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.date_range_outlined, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text(
                                        'To: ${holiday.to_date}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        'Number of days: ${holiday.number_of_days}',
                                        style: TextStyle(fontSize: 16, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

