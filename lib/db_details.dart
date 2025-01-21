import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseService {
  final String authEndpoint;

  DatabaseService({required this.authEndpoint});

  // Fetches the database details for the given company code.
  Future<Map<String, String>?> fetchDatabaseDetails(String companyCode) async {
    final url = Uri.parse(authEndpoint); // Replace with your actual authentication endpoint.
    try {
      // Send POST request to get the database details
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_code': companyCode}),
      );

      // If the response status is 200, process the data
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Check if the data is not empty and the status is successful
        if (data.isNotEmpty && data[0]['status'] == 1) {
          final dbDetails = data[0];
          // Return the database details in a Map format
          return {
            'database_host': dbDetails['database_host'],
            'database_name': dbDetails['database_name'],
            'database_username': dbDetails['database_username'],
            'database_password': dbDetails['database_password'],
          };
        }
      }
    } catch (e) {
      print('Error fetching database details: $e');
    }
    return null;
  }
}


