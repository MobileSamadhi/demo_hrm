// import 'dart:convert';
// import 'dart:io'; // For Platform checks
// import 'package:flutter/material.dart';
// import 'package:hrm_system/constants.dart';
// import 'package:http/http.dart' as http;
// import 'dashboard.dart';
//
// class ShiftManagementPage extends StatefulWidget {
//   @override
//   _ShiftManagementPageState createState() => _ShiftManagementPageState();
// }
//
// class _ShiftManagementPageState extends State<ShiftManagementPage> {
//   final List<Shift> shifts = [];
//
//   final TextEditingController shiftNameController = TextEditingController();
//   final TextEditingController shiftStartTimeController = TextEditingController();
//   final TextEditingController shiftEndTimeController = TextEditingController();
//
//
//   final apiurl = getApiUrl(addShiftsEndpoint);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Add Shift',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: Platform.isIOS ? 20 : 22, // Smaller font size for iOS
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Different colors for iOS and Android
//         leading: IconButton(
//           icon: Icon(Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
//             );
//           },
//         ),
//       ),
//       body: shifts.isNotEmpty
//           ? _buildShiftList()
//           : _buildEmptyState(), // Show empty state when there are no shifts
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _showShiftBottomSheet(isEdit: false);
//         },
//         child: Icon(Icons.add),
//         backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
//       ),
//     );
//   }
//
//   // Empty state to display when no shifts exist
//   Widget _buildEmptyState() {
//     return Center(
//       child: Text(
//         'No shifts available. Tap the + button to add a shift.',
//         style: TextStyle(
//           fontSize: 16,
//           color: Colors.grey,
//         ),
//       ),
//     );
//   }
//
//   // Build the shift list
//   Widget _buildShiftList() {
//     return ListView.builder(
//       itemCount: shifts.length,
//       itemBuilder: (context, index) {
//         final shift = shifts[index];
//         return Card(
//           margin: const EdgeInsets.all(8.0),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           child: ListTile(
//             title: Text(
//               shift.name,
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             subtitle: Text('Start: ${shift.startTime} | End: ${shift.endTime}'),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.edit, color: Color(0xFF0D9494)),
//                   onPressed: () {
//                     _showShiftBottomSheet(shift: shift, index: index, isEdit: true);
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.delete, color: Colors.redAccent),
//                   onPressed: () => _deleteShift(index),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // Show a bottom sheet for adding or editing shifts
//   void _showShiftBottomSheet({Shift? shift, int? index, required bool isEdit}) {
//     if (isEdit && shift != null) {
//       shiftNameController.text = shift.name;
//       shiftStartTimeController.text = shift.startTime;
//       shiftEndTimeController.text = shift.endTime;
//     } else {
//       _clearForm();
//     }
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//             left: 16,
//             right: 16,
//             top: 16,
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildTextField(
//                   controller: shiftNameController,
//                   labelText: 'Employee ID',
//                   icon: Icons.work,
//                 ),
//                 SizedBox(height: 10),
//                 _buildTimePicker(
//                   controller: shiftStartTimeController,
//                   labelText: 'Start Time',
//                   icon: Icons.timer,
//                 ),
//                 SizedBox(height: 10),
//                 _buildTimePicker(
//                   controller: shiftEndTimeController,
//                   labelText: 'End Time',
//                   icon: Icons.timer_off,
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (_validateForm()) {
//                       if (isEdit) {
//                         _editShift(index!);
//                       } else {
//                         _addNewShift();
//                       }
//                       Navigator.pop(context);
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     padding: EdgeInsets.symmetric(vertical: 12.0),
//                   ),
//                   child: Text(
//                     isEdit ? 'Update Shift' : 'Add Shift',
//                     style: TextStyle(fontSize: 18.0),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String labelText,
//     required IconData icon,
//   }) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: labelText,
//         prefixIcon: Icon(icon, color: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494)), // Platform-specific icon color
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//         ),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//     );
//   }
//
//   Widget _buildTimePicker({
//     required TextEditingController controller,
//     required String labelText,
//     required IconData icon,
//   }) {
//     return GestureDetector(
//       onTap: () async {
//         TimeOfDay? pickedTime = await showTimePicker(
//           context: context,
//           initialTime: TimeOfDay.now(),
//         );
//         if (pickedTime != null) {
//           setState(() {
//             controller.text = pickedTime.format(context);
//           });
//         }
//       },
//       child: AbsorbPointer(
//         child: _buildTextField(
//           controller: controller,
//           labelText: labelText,
//           icon: icon,
//         ),
//       ),
//     );
//   }
//
//   bool _validateForm() {
//     if (shiftNameController.text.isEmpty ||
//         shiftStartTimeController.text.isEmpty ||
//         shiftEndTimeController.text.isEmpty) {
//       _showSnackbar('Please fill all fields');
//       return false;
//     }
//     return true;
//   }
//
//   void _addNewShift() async {
//     final shift = Shift(
//       name: shiftNameController.text,
//       startTime: shiftStartTimeController.text,
//       endTime: shiftEndTimeController.text,
//     );
//
//     // Call the API to insert the shift data
//     final response = await http.post(
//       Uri.parse(apiurl),
//       body: {
//         'shift_name': shift.name,
//         'start_time': shift.startTime,
//         'end_time': shift.endTime,
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final responseData = json.decode(response.body);
//       if (responseData['error'] == null) {
//         setState(() {
//           shifts.add(shift);
//           _clearForm();
//         });
//         _showSnackbar('Shift added successfully');
//       } else {
//         _showSnackbar(responseData['error']);
//       }
//     } else {
//       _showSnackbar('Failed to add shift. Please try again later.');
//     }
//   }
//
//   void _editShift(int index) {
//     setState(() {
//       shifts[index] = Shift(
//         name: shiftNameController.text,
//         startTime: shiftStartTimeController.text,
//         endTime: shiftEndTimeController.text,
//       );
//       _clearForm();
//     });
//     _showSnackbar('Shift updated successfully');
//   }
//
//   void _deleteShift(int index) {
//     setState(() {
//       shifts.removeAt(index);
//     });
//     _showSnackbar('Shift deleted successfully');
//   }
//
//   void _clearForm() {
//     shiftNameController.clear();
//     shiftStartTimeController.clear();
//     shiftEndTimeController.clear();
//   }
//
//   void _showSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
// }
//
// class Shift {
//   String name;
//   String startTime;
//   String endTime;
//
//   Shift({
//     required this.name,
//     required this.startTime,
//     required this.endTime,
//   });
// }
