import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dashboard.dart';

class PaySalaryPage extends StatefulWidget {
  final String emId;
  final String role;

  const PaySalaryPage({required this.emId, required this.role, Key? key}) : super(key: key);

  @override
  _PaySalaryPageState createState() => _PaySalaryPageState();
}

class _PaySalaryPageState extends State<PaySalaryPage> {
  late Future<List<dynamic>> _paySalaries;
  String searchQuery = "";

  final List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _paySalaries = fetchPaySalaries();
  }

  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = getApiUrl(authEndpoint); // Replace with your actual authentication endpoint.

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      // Log the response code and body for debugging
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Check if the response contains valid data
        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        } else {
          print('Invalid response: ${data}');
          return null;
        }
      } else {
        // Handle non-200 status codes
        print('Error fetching database details. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching database details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaySalaries() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? companyCode = prefs.getString('company_code');

    if (companyCode == null || companyCode.isEmpty) {
      throw Exception('Company code is missing. Please log in again.');
    }

    final dbDetails = await fetchDatabaseDetails(companyCode);
    if (dbDetails == null) {
      throw Exception('Failed to fetch database details. Please log in again.');
    }

    final String apiUrl = getApiUrl(paySalaryEndpoint);
    final Map<String, dynamic> payload = {
      'em_id': widget.emId,
      'role': widget.role,
      'database_host': dbDetails['database_host'],
      'database_name': dbDetails['database_name'],
      'database_username': dbDetails['database_username'],
      'database_password': dbDetails['database_password'],
      'company_code': companyCode,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Apply filtering logic if searchQuery is not empty
        final List<Map<String, dynamic>> filteredData = data.map((item) {
          final parsedItem = item as Map<String, dynamic>;
          return {
            ...parsedItem,
            'is_permanent': parsedItem['is_permanent'] == 1,
          };
        }).toList();

        if (searchQuery.isNotEmpty) {
          final lowerQuery = searchQuery.toLowerCase();
          return filteredData.where((item) {
            final month = item['month']?.toString().toLowerCase() ?? '';
            final year = item['year']?.toString().toLowerCase() ?? '';
            return month.contains(lowerQuery) || year.contains(lowerQuery);
          }).toList();
        }

        return filteredData;
      } else {
        throw Exception('Failed to load pay salaries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching pay salaries: $e');
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value.trim(); // Update the search query
      _paySalaries = fetchPaySalaries(); // Re-fetch data with the updated query
    });
  }



  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return isIOS
        ? CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Pay Salary Details',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (context) => DashboardPage(emId: ''),
              ),
            );
          },
        ),
        backgroundColor: Color(0xFF0D9494),
      ),
      child: SafeArea(child: _buildBody(context)),
    )
        : Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pay Salary Details',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(emId: ''),
              ),
            );
          },
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search by Month',
              hintText: 'Enter Month',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _paySalaries,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No pay salary data available.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                );
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final salary = snapshot.data![index];
                    final basicSalary = double.tryParse(salary['basic'] ?? '0') ?? 0;
                    final isPermanent = salary['is_permanent'] as bool;

                    final epfEmployee = isPermanent ? (basicSalary * 0.08).toDouble() : 0.0;
                    final epfEmployer = isPermanent ? (basicSalary * 0.12).toDouble() : 0.0;
                    final etf = isPermanent ? (basicSalary * 0.03).toDouble() : 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                    child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                    '${salary['first_name']} ${salary['last_name']}',
                    style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9494),
                    ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                    'Month: ${salary['month'] ?? 'N/A'} - Year: ${salary['year'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Divider(height: 20, color: Color(0xFF0D9494)),
                    TextRow(label: 'Total Days', value: '${salary['total_days']}'),
                    TextRow(label: 'Basic Pay', value: 'LKR: ${salary['basic'] ?? 'N/A'}'),
                    TextRow(label: 'House Rent', value: 'LKR:${salary['house_rent'] ?? 'N/A'}'),
                    TextRow(label: 'Bonus', value: 'LKR:${salary['bonus'] ?? 'N/A'}'),
                    TextRow(label: 'Medical', value: 'LKR:${salary['medical'] ?? 'N/A'}'),
                    TextRow(label: 'Bima', value: 'LKR:${salary['bima'] ?? 'N/A'}'),
                    TextRow(label: 'Tax', value: 'LKR:${salary['tax'] ?? 'N/A'}'),
                    TextRow(label: 'Loan', value: 'LKR:${salary['loan'] ?? 'N/A'}'),
                    TextRow(label: 'Provident Fund', value: 'LKR:${salary['provident_fund'] ?? 'N/A'}'),
                    TextRow(label: 'Addition', value: 'LKR:${salary['addition'] ?? 'N/A'}'),
                    TextRow(label: 'Deduction', value: 'LKR:${salary['diduction'] ?? 'N/A'}'),
                    const Divider(height: 20, color: Color(0xFF0D9494)),
                    TextRow(label: 'EPF (8%)', value: 'LKR: ${epfEmployee.toStringAsFixed(2)}'),
                    TextRow(label: 'EPF (12%)', value: 'LKR: ${epfEmployer.toStringAsFixed(2)}'),
                    TextRow(label: 'ETF (3%)', value: 'LKR: ${etf.toStringAsFixed(2)}'),
                    //TextRow(label: 'Total Pay', value: 'LKR: ${double.parse(salary['total_pay'])}'),
                      const SizedBox(height: 10),
                    ],
                    ),
                      ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class TextRow extends StatelessWidget {
  final String label;
  final String value;

  const TextRow({required this.label, required this.value, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
