import 'package:flutter/material.dart';
import 'package:hrm_system/views/login.dart';

void main() {
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
