import 'dart:convert';
import 'dart:io'; // For platform checks
import 'package:flutter/cupertino.dart'; // For iOS widgets
import 'package:flutter/material.dart';
import 'package:hrm_system/constants.dart';
import 'package:http/http.dart' as http;
import 'dashboard.dart';

class Disciplinary {
  final int id;
  final String em_id;
  final String action;
  final String title;
  final String description;

  Disciplinary({
    required this.id,
    required this.em_id,
    required this.action,
    required this.title,
    required this.description,
  });

  factory Disciplinary.fromJson(Map<String, dynamic> json) {
    return Disciplinary(
      id: json['id'], // Assuming 'id' is always an int
      em_id: json['em_id'].toString(), // Convert to string if it might be an int
      action: json['action'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}


class DisciplinaryPage extends StatefulWidget {
  @override
  _DisciplinaryPageState createState() => _DisciplinaryPageState();
}

class _DisciplinaryPageState extends State<DisciplinaryPage> {
  late Future<List<Disciplinary>> futureDisciplinary;
  List<Disciplinary> _disciplinaryList = [];
  List<Disciplinary> _filteredDisciplinaryList = [];
  TextEditingController _searchController = TextEditingController();

  Future<List<Disciplinary>> fetchDisciplinary() async {
    final url = getApiUrl(disciplinaryEndpoint);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map<Disciplinary>((data) => Disciplinary.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load Disciplinaries');
    }
  }

  @override
  void initState() {
    super.initState();
    futureDisciplinary = fetchDisciplinary();
    futureDisciplinary.then((disciplinaryList) {
      setState(() {
        _disciplinaryList = disciplinaryList;
        _filteredDisciplinaryList = disciplinaryList;
      });
    });
    _searchController.addListener(_filterDisciplinary);
  }

  void _filterDisciplinary() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDisciplinaryList = _disciplinaryList.where((disciplinary) {
        return disciplinary.em_id.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSearchField(),
          ),
          Expanded(
            child: FutureBuilder<List<Disciplinary>>(
              future: futureDisciplinary,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Platform.isIOS
                        ? CupertinoActivityIndicator()
                        : CircularProgressIndicator(color: Color(0xFF0D9494)),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  );
                } else if (_filteredDisciplinaryList.isEmpty) {
                  return Center(
                    child: Text(
                      'No records found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _filteredDisciplinaryList.length,
                  itemBuilder: (context, index) {
                    Disciplinary disciplinary = _filteredDisciplinaryList[index];
                    return _buildDisciplinaryCard(disciplinary);
                  },
                );
              },
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
      middle: Text('Disciplinary Records'),
      backgroundColor: Color(0xFF0D9494),
      leading: CupertinoButton(
        child: Icon(CupertinoIcons.back, color: CupertinoColors.white),
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    )
        : AppBar(
      title: Text(
        'Disciplinary Records',
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
    );
  }

  // Platform-specific Search Field
  Widget _buildSearchField() {
    return Platform.isIOS
        ? CupertinoTextField(
      controller: _searchController,
      placeholder: 'Search by Employee ID',
      prefix: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey),
      ),
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: CupertinoColors.lightBackgroundGray,
        borderRadius: BorderRadius.circular(25.0),
      ),
    )
        : TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search by Employee ID',
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(Icons.search, color: Color(0xFF0D9494)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(color: Color(0xFF0D9494)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        fillColor: Colors.grey[200],
        filled: true,
      ),
    );
  }

  // Disciplinary Card with platform-specific icons
  Widget _buildDisciplinaryCard(Disciplinary disciplinary) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D9494), Color(0xFF0D9494)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Platform.isIOS ? CupertinoIcons.person_alt : Icons.person_outline,
              color: Color(0xFF0D9494),
            ),
          ),
          title: Text(
            'ID: ${disciplinary.id}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Platform.isIOS ? CupertinoIcons.person : Icons.person, color: Colors.white),
                    SizedBox(width: 5),
                    Flexible(  // Wrap with Flexible to prevent overflow
                      child: Text(
                        'Employee ID: ${disciplinary.em_id}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        overflow: TextOverflow.ellipsis,  // In case the text is too long
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Platform.isIOS ? CupertinoIcons.news_solid : Icons.gavel, color: Colors.white),
                    SizedBox(width: 5),
                    Flexible(  // Wrap with Flexible to prevent overflow
                      child: Text(
                        'Action: ${disciplinary.action}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Platform.isIOS ? CupertinoIcons.bookmark : Icons.title, color: Colors.white),
                    SizedBox(width: 5),
                    Flexible(  // Wrap with Flexible to prevent overflow
                      child: Text(
                        'Title: ${disciplinary.title}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Platform.isIOS ? CupertinoIcons.text_bubble : Icons.description, color: Colors.white),
                    SizedBox(width: 5),
                    Flexible(  // Wrap with Flexible to prevent overflow
                      child: Text(
                        'Description: ${disciplinary.description}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: Icon(
            Platform.isIOS ? CupertinoIcons.forward : Icons.arrow_forward_ios,
            color: Colors.white,
          ),
          onTap: () {
            // Handle tap action here
          },
        ),
      ),
    );
  }
}
