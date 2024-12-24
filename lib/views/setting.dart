import 'package:flutter/material.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _siteLogoPath;
  String _siteTitle = 'H R M System';
  String _description = 'This is a Human resource management system powered by Synnex IT Solution (Pvt) Ltd.';
  String _copyright = 'Synnex IT Solution (Pvt) Ltd';
  String _contact = '0112559466';
  String _currency = 'LKR';
  String _symbol = 'Rs';
  String _systemEmail = 'asiatradecentre542@yahoo.com';
  String _address = 'address...';
  String _address2 = '';

  // Future<void> _pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final PickedFile? pickedFile = await picker.getImage(source: ImageSource.gallery);

  //   if (pickedFile != null) {
  //     setState(() {
  //       _siteLogoPath = pickedFile.path;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text('Upload Site Logo'),
                // trailing: ElevatedButton(
                //   // onPressed: _pickImage,
                //   child: Text('Upload Logo'),
                // ),
              ),
              _siteLogoPath == null
                  ? Text('No file chosen')
                  : Image.file(File(_siteLogoPath!)),
              TextFormField(
                initialValue: _siteTitle,
                decoration: InputDecoration(labelText: 'Site Title'),
                onChanged: (value) {
                  setState(() {
                    _siteTitle = value;
                  });
                },
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _description = value;
                  });
                },
              ),
              TextFormField(
                initialValue: _copyright,
                decoration: InputDecoration(labelText: 'Copyright'),
                onChanged: (value) {
                  setState(() {
                    _copyright = value;
                  });
                },
              ),
              TextFormField(
                initialValue: _contact,
                decoration: InputDecoration(labelText: 'Contact'),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  setState(() {
                    _contact = value;
                  });
                },
              ),
              TextFormField(
                initialValue: _currency,
                decoration: InputDecoration(labelText: 'Currency'),
                onChanged: (value) {
                  setState(() {
                    _currency = value;
                  });
                },
              ),
              TextFormField(
                initialValue: _symbol,
                decoration: InputDecoration(labelText: 'Symbol'),
                onChanged: (value) {
                  setState(() {
                    _symbol = value;
                  });
                },
              ),
              TextFormField(
                initialValue: _systemEmail,
                decoration: InputDecoration(labelText: 'System Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  setState(() {
                    _systemEmail = value;
                  });
                },
              ),
              TextFormField(
                initialValue: _address,
                decoration: InputDecoration(labelText: 'Address'),
                onChanged: (value) {
                  setState(() {
                    _address = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Address 2'),
                onChanged: (value) {
                  setState(() {
                    _address2 = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save form data or perform some action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Settings saved')),
                    );
                  }
                },
                child: Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


