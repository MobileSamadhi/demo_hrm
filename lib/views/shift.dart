// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:hrm_system/constants.dart';
// import 'package:hrm_system/views/shift_management.dart';
// import 'package:http/http.dart' as http;
//
// class Shifts {
//   final int SFID;
//   final TimeOfDay intime;
//   final TimeOfDay outtime;
//   final int status;
//
//   Shifts({
//     required this.SFID,
//     required this.intime,
//     required this.outtime,
//     required this.status,
//   });
//
//   factory Shifts.fromJson(Map<String, dynamic> json) {
//     return Shifts(
//       SFID: json['SFID'], // No need to parse as int if it's already an int
//       intime: _parseTimeOfDay(json['intime']),
//       outtime: _parseTimeOfDay(json['outtime']),
//       status: json['status'], // No need to parse as int if it's already an int
//     );
//   }
//
//
//   static TimeOfDay _parseTimeOfDay(String time) {
//     final parts = time.split(':');
//     return TimeOfDay(
//       hour: int.parse(parts[0]),
//       minute: int.parse(parts[1]),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'SFID': SFID.toString(),
//       'intime': '${intime.hour}:${intime.minute}:00',
//       'outtime': '${outtime.hour}:${outtime.minute}:00',
//       'status': status.toString(),
//     };
//   }
// }
//
// class ShiftsPage extends StatefulWidget {
//   @override
//   _ShiftsPageState createState() => _ShiftsPageState();
// }
//
// class _ShiftsPageState extends State<ShiftsPage> {
//   late Future<List<Shifts>> futureShifts;
//   List<Shifts> _filteredShifts = [];
//   List<Shifts> _allShifts = [];
//   TextEditingController _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     futureShifts = fetchShifts();
//     futureShifts.then((shifts) {
//       setState(() {
//         _allShifts = shifts;
//         _filteredShifts = shifts;
//       });
//     });
//     _searchController.addListener(_onSearchChanged);
//   }
//
//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _onSearchChanged() {
//     filterShifts();
//   }
//
//   void filterShifts() {
//     List<Shifts> results = [];
//     if (_searchController.text.isEmpty) {
//       results = _allShifts;
//     } else {
//       results = _allShifts.where((shift) {
//         final intimeString = '${shift.intime.hour}:${shift.intime.minute.toString().padLeft(2, '0')}';
//         final outtimeString = '${shift.outtime.hour}:${shift.outtime.minute.toString().padLeft(2, '0')}';
//         return shift.SFID.toString().contains(_searchController.text) ||
//             intimeString.contains(_searchController.text) ||
//             outtimeString.contains(_searchController.text);
//       }).toList();
//     }
//
//     setState(() {
//       _filteredShifts = results;
//     });
//   }
//
//   Future<List<Shifts>> fetchShifts() async {
//     final url = getApiUrl(shiftsEndpoint);
//
//     final response = await http.get(Uri.parse(url));
//
//     if (response.statusCode == 200) {
//       // Decode the JSON response into a Map
//       Map<String, dynamic> jsonResponse = json.decode(response.body);
//
//       // Access the 'data' key from the response and convert it into a list
//       List shiftsJson = jsonResponse['data'];
//
//       // Now map the shiftsJson to a List of Shifts objects
//       return shiftsJson.map<Shifts>((data) => Shifts.fromJson(data)).toList();
//     } else {
//       throw Exception('Failed to load shifts');
//     }
//   }
//
//
//   Future<void> updateShift(Shifts shift) async {
//     // Use getApiUrl to dynamically construct the full URL
//     final url = getApiUrl(updateShiftEndpoint);
//
//     final response = await http.put(
//       Uri.parse(url),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(shift.toJson()),
//     );
//
//     if (response.statusCode != 200) {
//       throw Exception('Failed to update shift');
//     }
//   }
//
//
//   Future<void> deleteShift(int shiftId) async {
//     // Use getApiUrl to dynamically construct the full URL with query parameters
//     final url = getApiUrl(deleteShiftEndpoint) + '?SFID=$shiftId';
//
//     final response = await http.delete(Uri.parse(url));
//
//     if (response.statusCode != 200) {
//       throw Exception('Failed to delete shift');
//     }
//   }
//
//   void _editShift(Shifts shift) async {
//     final editedShift = await _showEditDialog(context, shift);
//     if (editedShift != null) {
//       await updateShift(editedShift);
//       setState(() {
//         futureShifts = fetchShifts();  // Refresh the list after update
//       });
//     }
//   }
//
//   void _deleteShift(Shifts shift) async {
//     final confirm = await _showConfirmDeleteDialog(context);
//     if (confirm == true) {
//       await deleteShift(shift.SFID);
//       setState(() {
//         futureShifts = fetchShifts();  // Refresh the list after delete
//       });
//     }
//   }
//
//   Future<Shifts?> _showEditDialog(BuildContext context, Shifts shift) async {
//     final intimeController = TextEditingController(
//       text: '${shift.intime.hour}:${shift.intime.minute.toString().padLeft(2, '0')}',
//     );
//     final outtimeController = TextEditingController(
//       text: '${shift.outtime.hour}:${shift.outtime.minute.toString().padLeft(2, '0')}',
//     );
//     int status = shift.status;
//
//     return showDialog<Shifts>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Edit Shift'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: intimeController,
//                 decoration: InputDecoration(labelText: 'In Time (HH:mm)'),
//               ),
//               TextField(
//                 controller: outtimeController,
//                 decoration: InputDecoration(labelText: 'Out Time (HH:mm)'),
//               ),
//               DropdownButton<int>(
//                 value: status,
//                 onChanged: (newValue) {
//                   setState(() {
//                     status = newValue!;
//                   });
//                 },
//                 items: <int>[0, 1]
//                     .map<DropdownMenuItem<int>>((int value) {
//                   return DropdownMenuItem<int>(
//                     value: value,
//                     child: Text(value == 0 ? 'Inactive' : 'Active'),
//                   );
//                 }).toList(),
//               ),
//             ],
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text('Save'),
//               onPressed: () {
//                 final intimeParts = intimeController.text.split(':');
//                 final outtimeParts = outtimeController.text.split(':');
//
//                 final updatedShift = Shifts(
//                   SFID: shift.SFID,
//                   intime: TimeOfDay(
//                     hour: int.parse(intimeParts[0]),
//                     minute: int.parse(intimeParts[1]),
//                   ),
//                   outtime: TimeOfDay(
//                     hour: int.parse(outtimeParts[0]),
//                     minute: int.parse(outtimeParts[1]),
//                   ),
//                   status: status,
//                 );
//
//                 Navigator.of(context).pop(updatedShift);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<bool?> _showConfirmDeleteDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Shift'),
//           content: Text('Are you sure you want to delete this shift?'),
//           actions: <Widget>[
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Shifts List'),
//         backgroundColor: Color(0xFF7CB9E8),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search',
//                 hintText: 'Search by Shift ID, In Time, or Out Time',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.all(Radius.circular(25.0)),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Center(
//               child: FutureBuilder<List<Shifts>>(
//                 future: futureShifts,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return CircularProgressIndicator();
//                   } else if (snapshot.hasError) {
//                     return Text(
//                       '${snapshot.error}',
//                       style: TextStyle(color: Colors.red, fontSize: 18),
//                     );
//                   } else {
//                     return ListView.builder(
//                       itemCount: _filteredShifts.length,
//                       itemBuilder: (context, index) {
//                         Shifts shift = _filteredShifts[index];
//                         return Card(
//                           elevation: 5,
//                           margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15.0),
//                           ),
//                           color: Colors.white,
//                           child: Padding(
//                             padding: const EdgeInsets.all(10.0),
//                             child: ListTile(
//                               title: Text(
//                                 'Shift ID: ${shift.SFID}',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                   color: Colors.blueAccent,
//                                 ),
//                               ),
//                               subtitle: Padding(
//                                 padding: const EdgeInsets.only(top: 8.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         Icon(Icons.timer, size: 16, color: Colors.grey),
//                                         SizedBox(width: 5),
//                                         Text(
//                                           'In: ${shift.intime.format(context)}',
//                                           style: TextStyle(
//                                             fontSize: 16,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     SizedBox(height: 5),
//                                     Row(
//                                       children: [
//                                         Icon(Icons.timer_off, size: 16, color: Colors.grey),
//                                         SizedBox(width: 5),
//                                         Text(
//                                           'Out: ${shift.outtime.format(context)}',
//                                           style: TextStyle(
//                                             fontSize: 16,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     SizedBox(height: 5),
//                                     Row(
//                                       children: [
//                                         Icon(Icons.info, size: 16, color: Colors.grey),
//                                         SizedBox(width: 5),
//                                         Text(
//                                           'Status: ${shift.status == 1 ? 'Active' : 'Inactive'}',
//                                           style: TextStyle(
//                                             fontSize: 16,
//                                             color: shift.status == 1 ? Colors.green : Colors.red,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   }
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
