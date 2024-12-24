import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../views/dashboard.dart';


// Define the Salary model class
class Salary {
  final double basicSalary;
  final String salaryType;
  final double houseRent;
  final double medical;
  final double conveyance;
  final double insurance;
  final double tax;
  final double providentFund;
  final double others;

  Salary({
    required this.basicSalary,
    required this.salaryType,
    required this.houseRent,
    required this.medical,
    required this.conveyance,
    required this.insurance,
    required this.tax,
    required this.providentFund,
    required this.others,
  });

  double get totalAdditions => houseRent + medical + conveyance;
  double get totalDeductions => insurance + tax + providentFund + others;
  double get totalSalary => basicSalary + totalAdditions - totalDeductions;
}

class SalaryPage extends StatefulWidget {
  @override
  _SalaryPageState createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  final _formKey = GlobalKey<FormState>();

  double _basicSalary = 0.0;
  String _salaryType = '';
  double _houseRent = 0.0;
  double _medical = 0.0;
  double _conveyance = 0.0;
  double _insurance = 0.0;
  double _tax = 0.0;
  double _providentFund = 0.0;
  double _others = 0.0;

  Salary? _salary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salary Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:  Color(0xFF0D9494),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Salary
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Basic Salary',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter basic salary';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _basicSalary = double.parse(value!);
                  },
                ),
                SizedBox(height: 16.0),

                // Salary Type
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Salary Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter salary type';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _salaryType = value!;
                  },
                ),
                SizedBox(height: 16.0),

                // Additions
                Text(
                  'Additions',
                  style: Theme.of(context).textTheme.titleLarge, // updated property
                ),
                SizedBox(height: 8.0),
                _buildAdditionField('House Rent', (value) => _houseRent = double.parse(value!)),
                SizedBox(height: 8.0),
                _buildAdditionField('Medical', (value) => _medical = double.parse(value!)),
                SizedBox(height: 8.0),
                _buildAdditionField('Conveyance', (value) => _conveyance = double.parse(value!)),
                SizedBox(height: 16.0),

                // Deductions
                Text(
                  'Deductions',
                  style: Theme.of(context).textTheme.titleLarge, // updated property
                ),
                SizedBox(height: 8.0),
                _buildDeductionField('Insurance', (value) => _insurance = double.parse(value!)),
                SizedBox(height: 8.0),
                _buildDeductionField('Tax', (value) => _tax = double.parse(value!)),
                SizedBox(height: 8.0),
                _buildDeductionField('Provident Fund', (value) => _providentFund = double.parse(value!)),
                SizedBox(height: 8.0),
                _buildDeductionField('Others', (value) => _others = double.parse(value!)),
                SizedBox(height: 16.0),

                // Submit Button
                ElevatedButton(
                  onPressed: _calculateSalary,
                  child: Text('Calculate Salary'),
                ),

                if (_salary != null) ...[
                  SizedBox(height: 16.0),
                  Text(
                    'Total Additions: ${_salary!.totalAdditions.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge, // updated property
                  ),
                  Text(
                    'Total Deductions: ${_salary!.totalDeductions.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge, // updated property
                  ),
                  Text(
                    'Total Salary: ${_salary!.totalSalary.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium, // updated property
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.add),
      ),
      keyboardType: TextInputType.number,
      onSaved: onSaved,
    );
  }

  Widget _buildDeductionField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.remove),
      ),
      keyboardType: TextInputType.number,
      onSaved: onSaved,
    );
  }

  void _calculateSalary() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _salary = Salary(
          basicSalary: _basicSalary,
          salaryType: _salaryType,
          houseRent: _houseRent,
          medical: _medical,
          conveyance: _conveyance,
          insurance: _insurance,
          tax: _tax,
          providentFund: _providentFund,
          others: _others,
        );
      });
    }
  }
}
