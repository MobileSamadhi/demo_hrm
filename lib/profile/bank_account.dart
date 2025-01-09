import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io'; // For Platform checks
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart'; // Import Cupertino for iOS

import '../constants.dart';
import '../views/dashboard.dart';

class BankInfo {
  final String holderName;
  final String bankName;
  final String branchName;
  final String accountNumber;
  final String accountType;

  BankInfo({
    required this.holderName,
    required this.bankName,
    required this.branchName,
    required this.accountNumber,
    required this.accountType,
  });

  factory BankInfo.fromJson(Map<String, dynamic> json) {
    return BankInfo(
      holderName: json['holder_name'],
      bankName: json['bank_name'],
      branchName: json['branch_name'],
      accountNumber: json['account_number'],
      accountType: json['account_type'],
    );
  }
}

class BankInfoPage extends StatefulWidget {
  final String sessionId;

  BankInfoPage({required this.sessionId});

  @override
  _BankInfoPageState createState() => _BankInfoPageState();
}

class _BankInfoPageState extends State<BankInfoPage> {
  List<BankInfo> _bankInfoList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBankInfoData();
  }

  Future<void> _fetchBankInfoData() async {
    final String apiUrl = getApiUrl(bankAccountEndpoint);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> bankInfoData = data['data'];
          setState(() {
            _bankInfoList = bankInfoData.map((bank) => BankInfo.fromJson(bank)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch bank information.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(), // Platform-specific AppBar
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
          child: Platform.isIOS
              ? CupertinoActivityIndicator()
              : CircularProgressIndicator(),
        )
            : _errorMessage.isNotEmpty
            ? _buildErrorState()
            : _bankInfoList.isEmpty
            ? _buildEmptyState()
            : _buildBankInfoList(),
      ),
    );
  }

  // Platform-Specific AppBar
  PreferredSizeWidget _buildAppBar() {
    return Platform.isIOS
        ? CupertinoNavigationBar(
      middle: Text('Bank Information',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),),
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
        'Bank Information',
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
    );
  }

  // Error State UI
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Empty State UI when no data is available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 100, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Bank Information Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // List of Bank Information Cards
  Widget _buildBankInfoList() {
    return ListView.builder(
      itemCount: _bankInfoList.length,
      itemBuilder: (context, index) {
        final bankInfo = _bankInfoList[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBankInfoTitle(bankInfo),
                SizedBox(height: 10),
                _buildBankDetailRow('Holder Name', bankInfo.holderName),
                _buildBankDetailRow('Bank Name', bankInfo.bankName),
                _buildBankDetailRow('Branch Name', bankInfo.branchName),
                _buildBankDetailRow('Account Number', bankInfo.accountNumber),
                _buildBankDetailRow('Account Type', bankInfo.accountType),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bank Information Title with Icon
  Widget _buildBankInfoTitle(BankInfo bankInfo) {
    return Row(
      children: [
        Icon(
          Platform.isIOS ? CupertinoIcons.creditcard : Icons.account_balance_wallet,
          color: Color(0xFF0D9494),
          size: 24,
        ),
        SizedBox(width: 10),
        Text(
          'Bank Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal[800],
          ),
        ),
      ],
    );
  }

  // Method to build individual bank details
  Widget _buildBankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
