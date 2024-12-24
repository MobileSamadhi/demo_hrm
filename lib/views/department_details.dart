import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'department.dart';

class DepartmentDetailPage extends StatelessWidget {
  final Department department;

  DepartmentDetailPage({required this.department});

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          department.depName,
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: GestureDetector(
          child: Icon(CupertinoIcons.back, color: Colors.white),
          onTap: () => Navigator.pop(context),
        ),
      ),
      child: buildBody(context),
    )
        : Scaffold(
      appBar: AppBar(
        title: Text(
          department.depName,
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 4,
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Employees',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9494),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: department.employees.length,
              itemBuilder: (context, index) {
                final employee = department.employees[index];
                return Platform.isIOS
                    ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                  child: buildEmployeeCard(employee),
                )
                    : buildEmployeeCard(employee);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmployeeCard(employee) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Color(0xFFE0F2F1),
      elevation: Platform.isAndroid ? 4 : 0, // Higher elevation for Android
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person, color: Color(0xFF0D9494), size: 40),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${employee.firstName} ${employee.lastName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Divider(color: Colors.grey[300]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
