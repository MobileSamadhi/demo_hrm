import 'dart:convert';
import 'dart:io'; // For platform checks
import 'package:flutter/cupertino.dart'; // For iOS widgets
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'dashboard.dart';

class InactiveUser {
  final String emId;
  final String emRole;
  final String firstName;
  final String lastName;
  final String emPhone;

  InactiveUser({
    required this.emId,
    required this.emRole,
    required this.firstName,
    required this.lastName,
    required this.emPhone,
  });

  factory InactiveUser.fromJson(Map<String, dynamic> json) {
    return InactiveUser(
      emId: json['em_id'],
      emRole: json['em_role'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      emPhone: json['em_phone'],
    );
  }
}

class InactiveUserPage extends StatefulWidget {
  @override
  _InactiveUserPageState createState() => _InactiveUserPageState();
}

class _InactiveUserPageState extends State<InactiveUserPage> {
  late Future<List<InactiveUser>> futureInactiveUsers;
  TextEditingController _searchController = TextEditingController();
  List<InactiveUser> _filteredUsers = [];
  List<InactiveUser> _allUsers = [];

  @override
  void initState() {
    super.initState();
    futureInactiveUsers = fetchInactiveUsers();
    futureInactiveUsers.then((users) {
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    filterUsers();
  }

  void filterUsers() {
    List<InactiveUser> results = [];
    if (_searchController.text.isEmpty) {
      results = _allUsers;
    } else {
      results = _allUsers.where((user) =>
      user.firstName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          user.emId.contains(_searchController.text) ||
          user.emPhone.contains(_searchController.text) ||
          user.emRole.toString().contains(_searchController.text)).toList();
    }

    setState(() {
      _filteredUsers = results;
    });
  }

  Future<List<InactiveUser>> fetchInactiveUsers() async {
    final url = getApiUrl(inactiveUsersEndpoint);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse['status'] == 'success') {
        List<dynamic> data = jsonResponse['data'];
        return data.map<InactiveUser>((item) => InactiveUser.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load inactive users: ${jsonResponse['message']}');
      }
    } else {
      throw Exception('Failed to load inactive users');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSearchField(),
          ),
          Expanded(
            child: Center(
              child: FutureBuilder<List<InactiveUser>>(
                future: futureInactiveUsers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator(color: Color(0xFF0D9494)));
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    if (_filteredUsers.isEmpty) {
                      return _noUsersFound();
                    }
                    return ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        InactiveUser user = _filteredUsers[index];
                        return _userCard(user);
                      },
                    );
                  } else {
                    return Center(child: Text('No data available'));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Platform-specific AppBar
  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text('Inactive Users'),
      backgroundColor: Color(0xFF0D9494),
      leading: CupertinoButton(
        child: Icon(CupertinoIcons.back, color: CupertinoColors.white),
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      trailing: CupertinoButton(
        child: Icon(CupertinoIcons.refresh, color: CupertinoColors.white),
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() {
            futureInactiveUsers = fetchInactiveUsers();
            futureInactiveUsers.then((users) {
              setState(() {
                _allUsers = users;
                _filteredUsers = users;
              });
            });
          });
        },
      ),
    )
        : AppBar(
      title: Text(
        'Inactive Users',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
      elevation: 8,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            setState(() {
              futureInactiveUsers = fetchInactiveUsers();
              futureInactiveUsers.then((users) {
                setState(() {
                  _allUsers = users;
                  _filteredUsers = users;
                });
              });
            });
          },
        ),
      ],
    );
  }

  // Platform-specific Search Field
  Widget _buildSearchField() {
    return Platform.isIOS
        ? CupertinoTextField(
      controller: _searchController,
      placeholder: 'Search by ID, or Phone',
      prefix: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey),
      ),
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: CupertinoColors.lightBackgroundGray,
        borderRadius: BorderRadius.circular(20.0),
      ),
    )
        : TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Users',
        labelStyle: TextStyle(color: Color(0xFF0D9494)),
        hintText: 'Enter ID, or phone',
        prefixIcon: Icon(Icons.search, color: Color(0xFF0D9494)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: Color(0xFF0D9494), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: Color(0xFF0D9494), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _noUsersFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Platform.isIOS ? CupertinoIcons.person_badge_minus : Icons.person_off, size: 64, color: Colors.grey[600]),
          SizedBox(height: 16),
          Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _userCard(InactiveUser user) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: Color(0xFF0D9494),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on ${user.firstName}')),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Platform.isIOS ? CupertinoIcons.person_alt : Icons.person_outline, color: Color(0xFF0D9494)),
            ),
            title: Text(
              'Employee ID: ${user.emId}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _userInfoRow(Platform.isIOS ? CupertinoIcons.person : Icons.person, 'Name: ${user.firstName + ' ' + user.lastName}'),
                  _userInfoRow(Platform.isIOS ? CupertinoIcons.phone : Icons.phone, 'Phone: ${user.emPhone}'),
                  _userInfoRow(Platform.isIOS ? CupertinoIcons.building_2_fill : Icons.domain, 'Role: ${user.emRole}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
