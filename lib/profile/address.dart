import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../views/dashboard.dart';

class Address {
  final int id;
  final String empId;
  String city;
  String country;
  String address;
  String type;

  Address({
    required this.id,
    required this.empId,
    required this.city,
    required this.country,
    required this.address,
    required this.type,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      empId: json['emp_id'],
      city: json['city'],
      country: json['country'],
      address: json['address'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'emp_id': empId,
    'city': city,
    'country': country,
    'address': address,
    'type': type,
  };
}

class AddressPage extends StatefulWidget {
  final String sessionId;

  AddressPage({required this.sessionId});

  @override
  _AddressPageState createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  List<Address> _addresses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final String apiUrl = 'https://hrmmobidemo.synnexcloudpos.com/address.php';

    try {
      final response = await http.get(
        Uri.parse('$apiUrl?session_id=${widget.sessionId}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _addresses = (data['data'] as List)
                .map((addressJson) => Address.fromJson(addressJson))
                .toList();
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
          _errorMessage = 'Failed to fetch addresses.';
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

  Future<void> _updateAddress(Address address) async {
    final String apiUrl = 'https://hrmmobidemo.synnexcloudpos.com/update_address.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': widget.sessionId,
        },
        body: json.encode({
          'session_id': widget.sessionId,
          'data': address.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _errorMessage = 'Information updated successfully!';
          });
        } else {
          setState(() {
            _errorMessage = data['message'];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save changes.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Address Information',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF0D9494)))
                  : _errorMessage.isNotEmpty
                  ? Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              )
                  : ListView.builder(
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  return _buildEditableAddressCard(address);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableAddressCard(Address address) {
    TextEditingController cityController = TextEditingController(text: address.city);
    TextEditingController countryController = TextEditingController(text: address.country);
    TextEditingController addressController = TextEditingController(text: address.address);
    TextEditingController typeController = TextEditingController(text: address.type);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEditableField('City', cityController, (value) => address.city = value),
            SizedBox(height: 8),
            _buildEditableField('Country', countryController, (value) => address.country = value),
            SizedBox(height: 8),
            _buildEditableField('Address', addressController, (value) => address.address = value),
            SizedBox(height: 8),
            _buildEditableField('Type', typeController, (value) => address.type = value),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  _updateAddress(address);
                },
                child: Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D9494),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
      String label, TextEditingController controller, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF0D9494),
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0D9494)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0D9494), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}
