import 'package:flutter/material.dart';
import 'package:hrm_system/views/login.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); // Initialize local notifications
  tz.initializeTimeZones(); // Initialize time zones

  runApp(HRMSystem());
}

class HRMSystem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRM System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false, // Disable the debug banner
    );
  }
}
