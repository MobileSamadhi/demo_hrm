import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrm_system/profile/address.dart';
import 'package:hrm_system/profile/bank_account.dart';
import 'package:hrm_system/profile/change_password.dart';
import 'package:hrm_system/profile/document.dart';
import 'package:hrm_system/profile/education.dart';
import 'package:hrm_system/profile/experience.dart';
import 'package:hrm_system/profile/leave.dart';
import 'package:hrm_system/profile/personal_Info.dart';
import 'package:hrm_system/profile/salary.dart';
import 'package:hrm_system/views/earned_leave.dart';
import 'package:hrm_system/views/logout_page.dart';
import 'package:hrm_system/views/payslip_report.dart';
import 'package:hrm_system/views/pending_leave.dart';
import 'package:hrm_system/views/review_leaveRequest.dart';
import 'package:hrm_system/views/shift.dart';
import 'package:hrm_system/views/shift_management.dart';
import 'package:hrm_system/views/shifts_list.dart';
import 'package:hrm_system/views/to_do_tasks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'add_attendance.dart';
import 'approval_attendance.dart';
import 'assign_shift.dart';
import 'attendance.dart';
import 'attendance_report.dart';
import 'department.dart';
import 'designation.dart';
import 'disciplinary.dart';
import 'employee_salary.dart';
import 'employee_shifts.dart';
import 'employees.dart';
import 'holiday_section.dart';
import 'holidaypage.dart';
import 'inactive_users.dart';
import 'leave_application.dart';
import 'leave_report.dart';
import 'leave_summary.dart';
import 'leave_type.dart';
import 'loan.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'notice_Board.dart';

class DashboardPage extends StatefulWidget {

  final String emId; // Manager's emId passed from the login page

  DashboardPage({required this.emId});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? role;
  String? emId;

  @override
  void initState() {
    super.initState();
    _getUserRole(); // Fetch the user's role
  }

  Future<void> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'employee'; // Default to 'employee' if not found
    });
    print('User role: $role'); // Debugging line
  }

  Future<void> _getEmId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emId = prefs.getString('emCode'); // Assuming you store emCode in SharedPreferences
    });
    print('Employee code: $emId'); // Debugging line
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10.0), // Adjust padding as needed
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Powered by Synnex IT Solution 2024',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('HRM Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // Set the icon color to white
        ),
        backgroundColor: Color(0xFF0D9494),
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular image on the left
                  Container(
                    width: 250, // Adjust the width as needed
                    height: 100, // Adjust the height as needed
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle, // Ensures a rectangular shape
                      borderRadius: BorderRadius.circular(8), // Optional: Adjust this to get rounded corners
                      image: DecorationImage(
                        image: AssetImage('lib/assets/logo.png'), // Replace with your image path
                        fit: BoxFit.cover, // Ensures the image covers the container
                      ),
                    ),
                  ),

                  SizedBox(width: 20),
                  // Text on the right
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              text: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Organization and Employees sections only available for 'super admin' and 'admin'
            if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
              _buildExpansionTile(
                context,
                title: 'Organization',
                icon: Icons.business,
                children: [
                  _buildDrawerItem(
                    text: 'Department',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DepartmentPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    text: 'Designation',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DesignationPage()),
                      );
                    },
                  ),
                ],
              ),

            if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
              _buildExpansionTile(
                context,
                title: 'Employees',
                icon: Icons.person_rounded,
                children: [
                  _buildDrawerItem(
                    text: 'Employees',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeePage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    text: 'Disciplinary',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DisciplinaryPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    text: 'Employee Salary',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeSalaryPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    text: 'Inactive User',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InactiveUserPage()),
                      );
                    },
                  ),
                ],
              ),
              _buildExpansionTile(
                context,
                title: 'Attendance',
                icon: Icons.view_agenda_rounded,
                children: [
                  if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
                  _buildDrawerItem(
                    text: 'Attendance List',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AttendancePage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    text: 'Add Attendance',
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final employeeCode = prefs.getString('em_code');

                      if (employeeCode != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAttendancePage(emCode: employeeCode),
                          ),
                        );
                      } else {
                        print("Employee ID not found");
                        // Optionally show an error or prompt the user to log in again
                      }
                    },
                  ),
                  if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
                  _buildDrawerItem(
                    text: 'Attendance Report',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AttendanceReportPage()),
                      );
                    },
                  ),
                  if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN' || role?.toUpperCase() == 'MANAGER')
                    _buildDrawerItem(
                      text: 'Attendance Approval',
                      onTap: () async {
                        // Fetch emId and userRole from SharedPreferences before navigating
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        String? managerEmId = prefs.getString('em_id'); // emId is used for managers
                        String? userRole = prefs.getString('role'); // Fetch user role from preferences

                        if (userRole != null && userRole.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendanceApprovalPage(
                                emId: managerEmId, // Pass emId if manager, null for admin/super_admin
                                role: userRole, // Pass user role
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('User role or Manager ID not found')),
                          );
                        }
                      },
                    ),
                ],
              ),
            if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
            _buildExpansionTile(
              context,
              title: 'Shift',
              icon: Icons.filter_tilt_shift,
              children: [
                if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
                  _buildDrawerItem(
                    text: 'Shift List',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShiftsPage()),
                      );
                    },
                  ),
                if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
                  _buildDrawerItem(
                    text: 'Employee Shift List',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeShiftPage()),
                      );
                    },
                  ),
              /*  _buildDrawerItem(
                  text: 'Add Shift',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ShiftManagementPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  text: 'Assign Shift',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AssignShiftPage()),
                    );
                  },
                ),*/
              ],
            ),
            _buildExpansionTile(
              context,
              title: 'Leave',
              icon: Icons.person_off,
              children: [
                // Holiday and Leave Application - visible to all users
                _buildDrawerItem(
                  text: 'Holiday',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HolidayPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  text: 'Leave Application',
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final employeeId = prefs.getString('em_id');

                    if (employeeId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaveApplicationPage(emId: employeeId),
                        ),
                      );
                    } else {
                      print("Employee ID not found");
                      // Optionally show an error or prompt the user to log in again
                    }
                  },
                ),

                // Leave Type, Earned Leave, and Report - visible only to 'admin' or 'super admin'
                if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
                  _buildDrawerItem(
                    text: 'Leave Type',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LeaveTypePage()),
                      );
                    },
                  ),
                if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
                  _buildDrawerItem(
                    text: 'Earned Leave',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EarnLeavePage()),
                      );
                    },
                  ),
                if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN' || role?.toUpperCase() == 'MANAGER')
                  _buildDrawerItem(
                    text: 'Review Leave Request',
                    onTap: () async {
                      // Fetch emId and userRole from SharedPreferences before navigating
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      String? managerEmId = prefs.getString('em_id'); // emId is used only for managers
                      String? userRole = prefs.getString('role'); // Fetch user role from preferences

                      if (userRole != null && userRole.isNotEmpty) {
                        // If the user is admin or super_admin, managerEmId is not required
                        if (userRole == 'admin' || userRole == 'super_admin') {
                          // Navigate to LeaveReviewPage and pass role with empty emId for admin/super_admin
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaveReviewPage(
                                emId: '', // Admins and Super Admins don't need emId
                                role: userRole, // Pass the role
                              ),
                            ),
                          );
                        } else if (managerEmId != null && managerEmId.isNotEmpty) {
                          // If the user is a manager, pass both emId and role
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaveReviewPage(
                                emId: managerEmId, // Pass the manager's emId
                                role: userRole, // Pass the role (manager)
                              ),
                            ),
                          );
                        } else {
                          // Handle the case where the manager's emId is missing
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Manager ID not found')),
                          );
                        }
                      } else {
                        // Handle the case where the userRole is missing
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('User role not found')),
                        );
                      }
                    },
                  ),
                if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
                  _buildDrawerItem(
                    text: 'Report',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LeaveReportPage()),
                      );
                    },
                  ),
              ],
            ),
            _buildExpansionTile(
              context,
              title: 'Payroll',
              icon: Icons.padding_rounded,
              children: [
                _buildDrawerItem(
                  text: 'Payslip Report',
                  onTap: () async {
                    // Retrieve role and em_id from SharedPreferences
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String? emId = prefs.getString('em_id'); // Retrieve em_id
                    String? role = prefs.getString('role');

                    // Debug statements to log em_id and role
                    print('Retrieved em_id: $emId'); // Debug log
                    print('Retrieved role: $role');   // Debug log

                    if (role != null && role.isNotEmpty) {
                      // Check if the user is ADMIN or SUPER ADMIN
                      if (role.toUpperCase() == 'ADMIN' || role.toUpperCase() == 'SUPER ADMIN') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaySalaryPage(
                              emId: '', // Pass an empty emId for admin/super admin
                              role: role,
                            ),
                          ),
                        );
                      }
                      // Check if the user is MANAGER or EMPLOYEE and requires em_id
                      else if ((role.toUpperCase() == 'MANAGER' || role.toUpperCase() == 'EMPLOYEE') && emId != null && emId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaySalaryPage(
                              emId: emId, // Pass emId for MANAGER/EMPLOYEE
                              role: role,
                            ),
                          ),
                        );
                      } else {
                        // Handle missing emId for MANAGER/EMPLOYEE
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Employee ID not found for Manager/Employee')),
                        );
                      }
                    } else {
                      // Show error if role is not found
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User role not found')),
                      );
                    }
                  },
                ),
              ],
            ),


            if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
              _buildExpansionTile(
                context,
                title: 'Loan',
                icon: Icons.money,
                children: [
                  _buildDrawerItem(
                    text: 'Loan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoanPage()),
                      );
                    },
                  ),
                ],

              ),
            _buildExpansionTile(
              context,
              title: 'Profile',
              icon: Icons.web_asset,
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  text: 'Personal Informations',
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String? sessionId = prefs.getString('session_id');

                    if (sessionId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalInfoPage(sessionId: sessionId), // Pass sessionId
                        ),
                      );
                    } else {
                      print('Session ID not found. Please login first.');
                    }
                  },
                ),
               /* _buildDrawerItem(
                  icon: Icons.home_filled,
                  text: 'Address',
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String? sessionId = prefs.getString('session_id');

                    if (sessionId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressPage(sessionId: sessionId), // Pass sessionId
                        ),
                      );
                    } else {
                      print('Session ID not found. Please login first.');
                    }
                  },
                ),*/
                _buildDrawerItem(
                  icon: Icons.cast_for_education,
                  text: 'Education',
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String? sessionId = prefs.getString('session_id');

                    if (sessionId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EducationInfoPage(sessionId: sessionId), // Pass sessionId
                        ),
                      );
                    } else {
                      print('Session ID not found. Please login first.');
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.join_full,
                  text: 'Experiences',
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String? sessionId = prefs.getString('session_id');

                    if (sessionId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExperienceInfoPage(sessionId: sessionId), // Pass sessionId
                        ),
                      );
                    } else {
                      print('Session ID not found. Please login first.');
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.comment_bank,
                  text: 'Bank Informations',
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String? sessionId = prefs.getString('session_id');

                    if (sessionId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BankInfoPage(sessionId: sessionId), // Pass sessionId
                        ),
                      );
                    } else {
                      print('Session ID not found. Please login first.');
                    }
                  },
                ),
                /* _buildDrawerItem(
                  icon: Icons.padding_rounded,
                  text: 'Documents',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DocumentPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.money,
                  text: 'Salary',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SalaryPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.time_to_leave,
                  text: 'Leave',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Leave()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.password,
                  text: 'Change Password',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                    );
                  },
                ),*/
              ],
            ),
            _buildExpansionTile(
              context,
              title: 'Logout',
              icon: Icons.logout,
              children: [
                _buildDrawerItem(
                  text: 'Logout',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogoutPage()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/background.jpg'), // Your background image asset
                fit: BoxFit.cover, // Cover the entire screen
              ),
            ),
          ),
          Container(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OverviewSection(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],),);
  }

  Widget _buildDrawerItem({IconData? icon, required String text, GestureTapCallback? onTap}) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: Color(0xFF0D9494)) : null,
      title: Text(
        text,
        style: TextStyle(color: Color(0xFF0D9494), fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }

  Widget _buildExpansionTile(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return ExpansionTile(
      leading: Icon(icon, color: Color(0xFF0D9494)),
      title: Text(
        title,
        style: TextStyle(color: Color(0xFF0D9494), fontWeight: FontWeight.bold),
      ),
      children: children,
    );
  }
}


class SectionTitle extends StatelessWidget {
  final String title;

  SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}

class OverviewSection extends StatefulWidget {
  @override
  _OverviewSectionState createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  int formerEmployeesCount = 0; // This will hold the actual count of former employees
  int loanCount = 0;
  int totalPendingCount = 0;
  String?role;

  @override
  void initState() {
    super.initState();
    _fetchFormerEmployeesCount(); // Fetch count when widget is created
    _fetchLoansCount();
    _fetchLeaveCount();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'employee'; // Default to 'employee' if not found
    });
    print('User role: $role'); // Debugging line
  }

  // Function to fetch the correct count from the API
  Future<void> _fetchFormerEmployeesCount() async {
    try {
      final url = getApiUrl(formerEmployeesCountEndpoint);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Ensure the count is parsed as an integer
        setState(() {
          formerEmployeesCount = int.parse(
              responseData['count'].toString()); // Fix: Convert string to int
        });
      } else {
        // Handle error or set a default value
        print('Failed to load former employees count');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Function to fetch the correct loan count from the API
  Future<void> _fetchLoansCount() async {
    try {
      final url = getApiUrl(loanCountEndpoint);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Ensure the count is parsed as an integer
        setState(() {
          loanCount = int.parse(
              responseData['count'].toString()); // Fix: Convert string to int
        });
      } else {
        // Handle error or set a default value
        print('Failed to load loan count');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Function to fetch the correct leave count from the API

  Future<void> _fetchLeaveCount() async {
    try {
      final url = getApiUrl(leaveCountEndpoint);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Check if 'status' is 'success' and 'total_pending_count' is present
        if (responseData['status'] == 'success' &&
            responseData.containsKey('total_pending_count')) {

          setState(() {
            // Safely convert 'total_pending_count' to an integer
            totalPendingCount = int.parse(responseData['total_pending_count'].toString());
          });
        } else {
          print('Invalid response data');
        }
      } else {
        print('Failed to load leave count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        // Former Employees Card
        OverviewCards(
          title: 'Employees',
          count: formerEmployeesCount,
          // This will show the correct count from API
          color: Color(0xFF0D9494).withOpacity(0.7),
          icon: Icons.people,
          onTap: (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN') // Check user role
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EmployeePage()),
            );
          }
              : null, // Disable tap for other roles
        ),
        // Pending Leaves Card
        if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
          OverviewCards(
            title: 'Pending Leaves',
            count: totalPendingCount,
            color: Color(0xFF0D9494).withOpacity(0.7),
            icon: Icons.time_to_leave_outlined,
            onTap: (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN') // Check user role
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PendingLeaveOverview()),
              );
            }
                : null, // Disable tap for other roles
          ),
        // Loan Applications Card
        if (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN')
          OverviewCards(
            title: 'Loan Applications',
            count: loanCount,
            color: Color(0xFF0D9494).withOpacity(0.7),
            icon: Icons.attach_money,
            onTap: (role?.toUpperCase() == 'SUPER ADMIN' || role?.toUpperCase() == 'ADMIN') // Check user role
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoanPage()),
              );
            }
                : null, // Disable tap for other roles
          ),
        // My Tasks Card
        OverviewCard(
          title: 'My Tasks',
          color: Color(0xFF0D9494).withOpacity(0.7),
          icon: Icons.padding_sharp,
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? sessionId = prefs.getString('session_id');

            if (sessionId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ToDoListSection(sessionId: sessionId, userId: '',), // Pass sessionId
                ),
              );
            } else {
              print('Session ID not found. Please login first.');
            }
          },
        ),
        // Notice Board Card
        OverviewCard(
          title: 'Notice Board',
          color: Color(0xFF0D9494).withOpacity(0.7),
          icon: Icons.notifications_active,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NoticeBoardSection()),
            );
          },
        ),
        // Holidays Card
        OverviewCard(
          title: 'Holidays',
          color: Color(0xFF0D9494).withOpacity(0.7),
          icon: Icons.holiday_village,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HolidaysSection()),
            );
          },
        ),
        OverviewCard(
          title: 'Leave Summary',
          color: Color(0xFF0D9494).withOpacity(0.7),
          icon: Icons.leave_bags_at_home,
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? sessionId = prefs.getString('session_id');

            if (sessionId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaveSummaryPage(sessionId: sessionId), // Pass sessionId
                ),
              );
            } else {
              print('Session ID not found. Please login first.');
            }
          },
        ),

        OverviewCard(
          title: 'Attendance Summary',
          color: Color(0xFF0D9494).withOpacity(0.7),
          icon: Icons.present_to_all,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HolidaysSection()),
            );
          },
        ),
      ],
    );
  }
}

class OverviewCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const OverviewCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: Platform.isIOS ? 2 : 4, // Lower elevation for iOS for a flatter design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Platform.isIOS ? 20 : 10), // Larger border radius for iOS
        ),
        color: color,
        child: Padding(
          padding: EdgeInsets.all(Platform.isIOS ? 12.0 : 16.0), // Adjust padding based on platform
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: Platform.isIOS ? 36 : 40, // Slightly smaller icon for iOS
                color: Colors.white,
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: Platform.isIOS ? 16 : 18, // Smaller font size for iOS
                  color: Colors.white,
                  fontWeight: Platform.isIOS ? FontWeight.w500 : FontWeight.bold, // Lighter weight for iOS
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class OverviewCards extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  OverviewCards({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Call onTap if it's not null
      child: Card(
        elevation: Platform.isIOS ? 2 : 4, // Lower elevation for iOS
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Platform.isIOS ? 20 : 10), // Larger border radius for iOS
        ),
        color: color,
        child: Padding(
          padding: EdgeInsets.all(Platform.isIOS ? 12.0 : 16.0), // Adjust padding based on platform
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: Platform.isIOS ? 36 : 40, // Slightly smaller icon on iOS
                color: Colors.white,
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: Platform.isIOS ? 16 : 18, // Smaller text size for iOS
                  color: Colors.white,
                  fontWeight: Platform.isIOS ? FontWeight.w500 : FontWeight.bold, // Lighter weight for iOS
                ),
              ),
              SizedBox(height: 10),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: Platform.isIOS ? 22 : 24, // Slightly smaller font for iOS
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}