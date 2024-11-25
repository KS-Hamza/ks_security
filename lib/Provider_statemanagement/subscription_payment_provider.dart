import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'dart:io';
import '../api_services.dart'; // Import ApiServices

class SubscriptionPaymentProvider with ChangeNotifier {
  final ApiServices apiServices; // Dependency on ApiServices

  // Constructor receives an instance of ApiServices
  SubscriptionPaymentProvider({required this.apiServices});

  Future<bool> addNewSubscriptionPayment(Map<String, dynamic> formData, [File? attachmentFile]) async {
    // Use the base URL and auth header from ApiServices
    final url = Uri.parse("${apiServices.baseUrl}v1.php?table=subscription_payments&action=insert");

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = apiServices.authHeader; // Use authHeader from ApiServices
    request.headers['Content-Type'] = 'multipart/form-data';

    // Add form fields to request
    formData.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Add file if provided and is a valid image file
    if (attachmentFile != null && (attachmentFile.path.endsWith('.jpg') || attachmentFile.path.endsWith('.png'))) {
      print("Adding attachment file: ${attachmentFile.path}");
      request.files.add(await http.MultipartFile.fromPath(
        'important_attachments', // Ensure this matches the server's expected key
        attachmentFile.path,
        contentType: MediaType('image', attachmentFile.path.endsWith('.png') ? 'png' : 'jpeg'),
      ));
    } else if (attachmentFile != null) {
      print('File provided is not in supported format (.jpg or .png): ${attachmentFile.path}');
    } else {
      print('No attachment file provided');
    }

    try {
      // Send the request and handle the response
      final response = await request.send();
      final responseBody = await response.stream.bytesToString(); // Debugging: Print response body
      print('Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Payment added successfully');
        notifyListeners(); // Notify listeners if necessary
        return true;
      } else {
        print('Failed to add subscription payment: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding subscription payment: $e');
      return false;
    }
  }
}
