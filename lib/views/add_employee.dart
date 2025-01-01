
// import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// import 'dashboard.dart';

// class AddEmployeePage extends StatefulWidget {
//   @override
//   _AddEmployeePageState createState() => _AddEmployeePageState();
// }

// class _AddEmployeePageState extends State<AddEmployeePage> {
//   final _formKey = GlobalKey<FormState>();

//   String? _selectedDepartment;
//   String? _selectedDesignation;
//   String? _selectedRole;
//   String? _selectedGender;
//   String? _selectedBloodGroup;
//   DateTime? _dateOfBirth;
//   DateTime? _dateOfJoining;
//   DateTime? _dateOfLeaving;
//   String? _imagePath;

//   List<String> departments = ["HR", "Engineering", "Marketing", "Sales"];
//   List<String> designations = ["Manager", "Developer", "Designer", "Analyst"];
//   List<String> roles = ["Admin", "User", "Guest"];
//   List<String> genders = ["Male", "Female", "Other"];
//   List<String> bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

//   Future<void> _selectDate(BuildContext context, DateTime? initialDate, ValueChanged<DateTime> onDateSelected) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate ?? DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != initialDate) onDateSelected(picked);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Add Employee Details',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Color(0xFF0D9494),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
//             );
//           },
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               Text(
//                 'Personal Information',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blueGrey[700],
//                 ),
//               ),
//               SizedBox(height: 10),
//               _buildTextField('First Name'),
//               SizedBox(height: 10),
//               _buildTextField('Last Name'),
//               SizedBox(height: 10),
//               _buildTextField('Employee Code'),
//               SizedBox(height: 20),
//               Text(
//                 'Job Details',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blueGrey[700],
//                 ),
//               ),
//               SizedBox(height: 10),
//               _buildDropdown('Department', _selectedDepartment, departments, (newValue) {
//                 setState(() {
//                   _selectedDepartment = newValue;
//                 });
//               }),
//               SizedBox(height: 10),
//               _buildDropdown('Designation', _selectedDesignation, designations, (newValue) {
//                 setState(() {
//                   _selectedDesignation = newValue;
//                 });
//               }),
//               SizedBox(height: 10),
//               _buildDropdown('Role', _selectedRole, roles, (newValue) {
//                 setState(() {
//                   _selectedRole = newValue;
//                 });
//               }),
//               SizedBox(height: 20),
//               Text(
//                 'Personal Details',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blueGrey[700],
//                 ),
//               ),
//               SizedBox(height: 10),
//               _buildDropdown('Gender', _selectedGender, genders, (newValue) {
//                 setState(() {
//                   _selectedGender = newValue;
//                 });
//               }),
//               SizedBox(height: 10),
//               _buildDropdown('Blood Group', _selectedBloodGroup, bloodGroups, (newValue) {
//                 setState(() {
//                   _selectedBloodGroup = newValue;
//                 });
//               }),
//               SizedBox(height: 10),
//               _buildTextField('NIC', maxLength: 10),
//               SizedBox(height: 10),
//               _buildTextField('Contact Number', keyboardType: TextInputType.phone),
//               SizedBox(height: 10),
//               _buildTextField('Username'),
//               SizedBox(height: 10),
//               _buildTextField('Email', keyboardType: TextInputType.emailAddress),
//               SizedBox(height: 20),
//               _buildDatePicker('Date of Birth', _dateOfBirth, (date) {
//                 setState(() {
//                   _dateOfBirth = date;
//                 });
//               }),
//               _buildDatePicker('Date of Joining', _dateOfJoining, (date) {
//                 setState(() {
//                   _dateOfJoining = date;
//                 });
//               }),
//               _buildDatePicker('Date of Leaving', _dateOfLeaving, (date) {
//                 setState(() {
//                   _dateOfLeaving = date;
//                 });
//               }),
//               SizedBox(height: 20),
//               _imagePath == null
//                   ? Text(
//                 'No image selected.',
//                 style: TextStyle(color: Color(0xFF0D9494)),
//               )
//                   : Image.file(File(_imagePath!)),
//               // ElevatedButton.icon(
//               //   icon: Icon(Icons.image),
//               //   label: Text('Select Image'),
//               //   style: ElevatedButton.styleFrom(
//               //     backgroundColor: Color(0xFF0D9494),
//               //   ),
//               //   // onPressed: () async {
//               //   //   final image = await ImagePicker().pickImage(source: ImageSource.gallery);
//               //   //   if (image != null) {
//               //   //     setState(() {
//               //   //       _imagePath = image.path;
//               //   //     });
//               //   //   }
//               //   // },
//               // ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     // Save form data
//                   }
//                 },
//                 child: Text('Submit'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF0D9494),
//                   padding: EdgeInsets.symmetric(vertical: 16),
//                   textStyle: TextStyle(fontSize: 18),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, {TextInputType keyboardType = TextInputType.text, int? maxLength}) {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(color: Colors.blueGrey[700]),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderSide: BorderSide(color: Color(0xFF0D9494)),
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//       ),
//       keyboardType: keyboardType,
//       maxLength: maxLength,
//     );
//   }

//   Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
//     return DropdownButtonFormField<String>(
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(color: Colors.blueGrey[700]),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderSide: BorderSide(color: Color(0xFF0D9494)),
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//       ),
//       value: value,
//       onChanged: onChanged,
//       items: items.map((item) {
//         return DropdownMenuItem<String>(
//           value: item,
//           child: Text(item),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildDatePicker(String label, DateTime? selectedDate, ValueChanged<DateTime> onDateSelected) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           '$label: ${selectedDate != null ? selectedDate.toLocal().toString().split(' ')[0] : ''}',
//           style: TextStyle(color: Colors.blueGrey[700]),
//         ),
//         SizedBox(height: 8),
//         ElevatedButton(
//           onPressed: () => _selectDate(context, selectedDate, onDateSelected),
//           child: Text('Select $label'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Color(0xFF0D9494),
//           ),
//         ),
//       ],
//     );
//   }
// }
