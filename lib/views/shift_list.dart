// import 'dart:io'; // Needed for Platform checks
// import 'package:flutter/material.dart';
// import 'dashboard.dart';
//
// class Shift {
//   final String id;
//   final String inTime;
//   final String outTime;
//
//   Shift({
//     required this.id,
//     required this.inTime,
//     required this.outTime,
//   });
// }
//
// class ShiftListPage extends StatefulWidget {
//   @override
//   _ShiftListPageState createState() => _ShiftListPageState();
// }
//
// class _ShiftListPageState extends State<ShiftListPage> {
//   final List<Shift> shifts = [
//     Shift(id: 'S001', inTime: '08:00 AM', outTime: '04:00 PM'),
//     Shift(id: 'S002', inTime: '04:00 PM', outTime: '12:00 AM'),
//     Shift(id: 'S003', inTime: '12:00 AM', outTime: '08:00 AM'),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         // Platform-specific AppBar background color
//         backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494),
//         title: Text(
//           'Shift List',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         leading: IconButton(
//           icon: Icon(Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
//             );
//           },
//         ),
//         elevation: 6.0, // Adds shadow to the AppBar
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(child: _buildShiftList()), // Switch to the card-based layout
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildShiftList() {
//     return ListView.builder(
//       itemCount: shifts.length,
//       itemBuilder: (context, index) {
//         return _buildShiftCard(shifts[index]);
//       },
//     );
//   }
//
//   Widget _buildShiftCard(Shift shift) {
//     return Card(
//       elevation: 5,
//       margin: EdgeInsets.symmetric(vertical: 10),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: ListTile(
//         contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//         leading: CircleAvatar(
//           radius: 30,
//           backgroundColor: Platform.isIOS ? Color(0xFF0D9494) : Color(0xFF0D9494), // Different background colors for avatar
//           child: Icon(
//             Platform.isIOS ? Icons.assignment : Icons.work, // Platform-specific icon
//             color: Colors.white,
//             size: 30,
//           ),
//         ),
//         title: Text(
//           'Shift: ${shift.id}',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF0D9494), // Shift card title color
//             fontSize: 18,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: 5),
//             Row(
//               children: [
//                 Icon(
//                   Platform.isIOS ? Icons.access_time : Icons.schedule, // Different icons for time
//                   color: Colors.teal,
//                 ),
//                 SizedBox(width: 5),
//                 Text(
//                   'In Time: ${shift.inTime}',
//                   style: TextStyle(fontSize: 16, color: Colors.black87),
//                 ),
//               ],
//             ),
//             SizedBox(height: 5),
//             Row(
//               children: [
//                 Icon(
//                   Platform.isIOS ? Icons.timer_off : Icons.timelapse, // Different icons for out time
//                   color: Colors.redAccent,
//                 ),
//                 SizedBox(width: 5),
//                 Text(
//                   'Out Time: ${shift.outTime}',
//                   style: TextStyle(fontSize: 16, color: Colors.black87),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         trailing: _buildActions(shift),
//       ),
//     );
//   }
//
//   Widget _buildActions(Shift shift) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         IconButton(
//           // Platform-specific edit icon
//           icon: Icon(Platform.isIOS ? Icons.create : Icons.edit, color: Color(0xFF0D9494)),
//           tooltip: 'Edit Shift',
//           onPressed: () {
//             _editShift(shift);
//           },
//         ),
//         IconButton(
//           // Platform-specific delete icon
//           icon: Icon(Platform.isIOS ? Icons.delete_outline : Icons.delete, color: Colors.redAccent),
//           tooltip: 'Delete Shift',
//           onPressed: () {
//             _deleteShift(shift);
//           },
//         ),
//       ],
//     );
//   }
//
//   void _editShift(Shift shift) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Edit Shift ${shift.id}')),
//     );
//   }
//
//   void _deleteShift(Shift shift) {
//     setState(() {
//       shifts.remove(shift);
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Shift ${shift.id} deleted')),
//     );
//   }
// }
