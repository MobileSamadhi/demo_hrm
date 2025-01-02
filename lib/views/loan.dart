import 'dart:io'; // For platform-specific checks
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import 'dashboard.dart';

class Loan {
  final int id;
  final String empId;
  final String firstName;
  final String lastName;
  final String amount;
  final String interestPercentage;
  final String totalAmount;
  final String totalPay;
  final String totalDue;
  final String installment;
  final String loanNumber;
  final String loanDetails;
  final String approveDate;
  final String installPeriod;
  late final String status;

  Loan({
    required this.id,
    required this.empId,
    required this.firstName,
    required this.lastName,
    required this.amount,
    required this.interestPercentage,
    required this.totalAmount,
    required this.totalPay,
    required this.totalDue,
    required this.installment,
    required this.loanNumber,
    required this.loanDetails,
    required this.approveDate,
    required this.installPeriod,
    required this.status,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] is String ? int.parse(json['id']) : json['id'], // Ensure id is parsed as integer
      empId: json['emp_id'].toString(), // Ensure empId is a string
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      amount: json['amount']?.toString() ?? '', // Ensure amount is a string
      interestPercentage: json['interest_percentage']?.toString() ?? '',
      totalAmount: json['total_amount']?.toString() ?? '',
      totalPay: json['total_pay']?.toString() ?? '',
      totalDue: json['total_due']?.toString() ?? '',
      installment: json['installment']?.toString() ?? '',
      loanNumber: json['loan_number']?.toString() ?? '',
      loanDetails: json['loan_details']?.toString() ?? '',
      approveDate: json['approve_date']?.toString() ?? '',
      installPeriod: json['install_period']?.toString() ?? '',
      status: json['status']?.toString() ?? '', // Ensure status is a string
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'emp_id': empId,
      'first_name': firstName,
      'last_name': lastName,
      'amount': amount,
      'interest_percentage': interestPercentage,
      'total_amount': totalAmount,
      'total_pay': totalPay,
      'total_due': totalDue,
      'installment': installment,
      'loan_number': loanNumber,
      'loan_details': loanDetails,
      'approve_date': approveDate,
      'install_period': installPeriod,
      'status': status,
    };
  }
}


class LoanPage extends StatefulWidget {
  @override
  _LoanPageState createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  late Future<List<Loan>> futureLoans;
  List<Loan> _filteredLoans = [];
  List<Loan> _allLoans = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureLoans = fetchLoans();
    futureLoans.then((loans) {
      setState(() {
        _allLoans = loans;
        _filteredLoans = loans;
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
    filterLoans();
  }

  void filterLoans() {
    List<Loan> results = [];
    if (_searchController.text.isEmpty) {
      results = _allLoans;
    } else {
      results = _allLoans.where((loan) {
        return loan.empId.contains(_searchController.text) ||
            loan.loanNumber.contains(_searchController.text) ||
            loan.firstName.toString().contains(_searchController.text) ||
            loan.lastName.toString().contains(_searchController.text);;
        loan.id.toString().contains(_searchController.text);
      }).toList();
    }

    setState(() {
      _filteredLoans = results;
    });
  }

  Future<List<Loan>> fetchLoans() async {
    final response = await http.get(Uri.parse(getApiUrl(loanEndpoint)));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map<Loan>((data) => Loan.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load loans');
    }
  }

  Future<void> updateLoanStatus(Loan loan, String newStatus) async {
    loan.status = newStatus;

    final response = await http.put(
      Uri.parse(getApiUrl(loanEndpoint)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(loan.toJson()),
    );

    if (response.statusCode == 200) {
      setState(() {
        futureLoans = fetchLoans();
      });
    } else {
      throw Exception('Failed to update loan status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPlatformAppBar(), // Platform-specific AppBar
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: 'Search by Employee Name, ID',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Platform.isIOS ? Color(0xFF0D9494) : Colors.teal,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.75, // Set height to allow ListView to scroll independently
              child: FutureBuilder<List<Loan>>(
                future: futureLoans,
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
                  } else {
                    return _filteredLoans.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.money_off, // Use an appropriate icon for loans
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10), // Add spacing between the icon and the text
                          Text(
                            'No loans found.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                   :ListView.builder(
                      itemCount: _filteredLoans.length,
                      itemBuilder: (context, index) {
                        Loan loan = _filteredLoans[index];
                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.teal.shade100, Color(0xFF0D9494).withOpacity(0.5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Loan ID: ${loan.id}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.teal.shade800,
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: loan.status,
                                        items: <String>['Granted', 'Deny', 'Pause', 'Done']
                                            .map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (String? newStatus) {
                                          if (newStatus != null) {
                                            updateLoanStatus(loan, newStatus);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  Divider(color: Color(0xFF0D9494)),
                                  SizedBox(height: 10),
                                  Text(
                                    'Employee Name: ${loan.firstName} ${loan.lastName}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Employee ID: ${loan.empId}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Amount: ${loan.amount}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Status: ${loan.status}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(loan.status),
                                    ),
                                  ),
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
        ),
      ),
    );
  }


  // Platform-specific AppBar
  AppBar _buildPlatformAppBar() {
    return AppBar(
      title: Text(
        'Loan List',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: Platform.isIOS ? 20 : 22, // Different font size for iOS
        ),
      ),
      backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Platform-specific background color
      leading: IconButton(
        icon: Icon(
          Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back, // Platform-specific back icon
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
          );
        },
      ),
    );
  }

  // Helper to get color based on status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Granted':
        return Colors.green;
      case 'Deny':
        return Colors.red;
      case 'Pause':
        return Colors.orange;
      case 'Done':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}