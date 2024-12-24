// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:hrm_system/profile/change_password.dart';
// import 'dart:math' as math;
//
// import '../views/dashboard.dart';
//
// class DocumentPage extends StatefulWidget {
//   @override
//   _DocumentPageState createState() => _DocumentPageState();
// }
//
// class _DocumentPageState extends State<DocumentPage> {
//   String? _fileName;
//   String? _filePath;
//   String? _fileSize;
//
//   Future<void> _chooseFile() async {
//     final result = await FilePicker.platform.pickFiles();
//
//     if (result != null) {
//       setState(() {
//         _fileName = result.files.single.name;
//         _filePath = result.files.single.path;
//         _fileSize = _formatBytes(result.files.single.size);
//       });
//     }
//   }
//
//   String _formatBytes(int bytes, [int decimalPlaces = 2]) {
//     if (bytes == 0) return "0 Bytes";
//     const units = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
//     final i = (math.log(bytes) / math.log(1024)).floor();
//     return "${(bytes / math.pow(1024, i)).toStringAsFixed(decimalPlaces)} ${units[i]}";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Upload Document',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor:  Color(0xFF0D9494),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => DashboardPage(emId: '',)),
//             );
//           },
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Icon(
//                 Icons.file_upload,
//                 size: 80.0,
//                 color:  Color(0xFF0D9494),
//               ),
//             ),
//             SizedBox(height: 20.0),
//             Center(
//               child: Text(
//                 'Please choose a document to upload',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                   color:  Color(0xFF0D9494),
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             SizedBox(height: 30.0),
//
//             // File Information
//             Card(
//               elevation: 5,
//               margin: EdgeInsets.symmetric(vertical: 10.0),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10.0),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Selected File:',
//                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 10.0),
//                     Row(
//                       children: [
//                         Icon(
//                           _fileName != null ? Icons.insert_drive_file : Icons.error,
//                           color: _fileName != null ? Colors.green : Colors.red,
//                           size: 30,
//                         ),
//                         SizedBox(width: 10.0),
//                         Expanded(
//                           child: Text(
//                             _fileName ?? 'No file chosen',
//                             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                               color: _fileName != null ? Colors.green : Colors.red,
//                               fontSize: 16.0,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (_fileName != null) ...[
//                       SizedBox(height: 15.0),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on,
//                             color:  Color(0xFF0D9494),
//                           ),
//                           SizedBox(width: 10.0),
//                           Expanded(
//                             child: Text(
//                               _filePath ?? '',
//                               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                                 color: Colors.grey[700],
//                                 fontSize: 15.0,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 10.0),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.sd_storage,
//                             color:  Color(0xFF0D9494),
//                           ),
//                           SizedBox(width: 10.0),
//                           Text(
//                             'Size: ',
//                             style: Theme.of(context).textTheme.titleMedium,
//                           ),
//                           Text(
//                             _fileSize ?? '',
//                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                               color: Colors.grey[700],
//                               fontSize: 15.0,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 20.0),
//
//             // Choose File Button
//             Center(
//               child: Tooltip(
//                 message: 'Click to choose a file from your device',
//                 child: ElevatedButton.icon(
//                   onPressed: _chooseFile,
//                   icon: Icon(Icons.file_open),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:  Color(0xFF0D9494),
//                     padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                   label: Text(
//                     'Choose File',
//                     style: TextStyle(fontSize: 16.0),
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 30.0),
//
//             // Submit Button
//             if (_fileName != null)
//               Center(
//                 child: Tooltip(
//                   message: 'Submit the selected document',
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Document submitted successfully!')),
//                       );
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) =>ChangePasswordPage()), // Ensure AddressInfoPage is implemented
//                       );
//                     },
//                     icon: Icon(Icons.check_circle),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                       ),
//                     ),
//                     label: Text(
//                       'Submit',
//                       style: TextStyle(fontSize: 16.0),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
