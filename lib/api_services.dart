import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';


class ApiServices {
  final String _baseUrl = 'https://karsaazebs.com/BMS/api/';
  String get baseUrl => _baseUrl;
  // Basic authentication credentials
  final String _username = 'admin';
  final String _password = 'admin123';

  // Authorization header variable
  late String _authHeader;

  ApiServices() {
    // Initialize the Authorization header with the credentials
    _authHeader = 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
  }

  // Getter for the authHeader
  String get authHeader => _authHeader;

  get userId => null;

  // Bank API Methods

  // Fetch the list of bank details
  Future<Map<String, dynamic>?> fetchBankList(int userId) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=bank_details&action=list&q=(user_id~equals~$userId)");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load bank details with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching bank details: $e');
      return null;
    }
  }
  // Add New Subscription Payment with File Upload
  // Add a new subscription payment with an attachment
  Future<bool> addNewSubscriptionPayments(Map<String, String> paymentData, File? important_attachments) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription_payments&action=insert");
    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = _authHeader;

    // Add form fields
    paymentData.forEach((key, value) {
      request.fields[key] = value;
    });

    // Convert and add file as Blob if provided
    if (important_attachments != null) {
      try {
        // Read file as bytes (this acts similarly to Blob format)
        Uint8List fileBytes = await important_attachments.readAsBytes();
        String fileName = important_attachments.path.split('/').last; // Only filename with extension

        print("Preparing file for upload: $fileName, Size: ${fileBytes.length} bytes");

        request.files.add(http.MultipartFile.fromBytes(
          'important_attachments', // Name expected by the API
          fileBytes,
          filename: fileName, // Only the file name and extension
          contentType: MediaType('image', 'jpeg'), // Adjust based on file type
        ));
      } catch (e) {
        print("Error reading file: $e");
        return false;
      }
    } else {
      print("No file attached to request.");
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString(); // Get response body for debugging

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("File upload successful. Server response: $responseBody");
        return true;
      } else {
        print("Failed to add subscription payment: ${response.statusCode}");
        print("Server response: $responseBody"); // Print server response for error debugging
        return false;
      }
    } catch (e) {
      print("Error sending request: $e");
      return false;
    }
  }

  // Fetch a single bank detail by ID
  Future<Map<String, dynamic>?> fetchBankDetailById(String bankId) async {
    final url = Uri.parse("https://karsaazebs.com/BMS/api/v1.php?table=bank_details&action=view&editid1=$bankId");
    final response = await http.get(url, headers: {
      'Authorization': _authHeader, // Check that _authHeader is correctly set in ApiServices
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      print('Failed to fetch bank detail with status code: ${response.statusCode}');
      return null;
    }
}


  // Add a new bank detail
  Future<bool> addNewBank(Map<String, String> bankData) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=bank_details&action=insert");
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = _authHeader;
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add form fields
      bankData.forEach((key, value) {
        request.fields[key] = value;
      });

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to add bank detail: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding bank detail: $e');
      return false;
    }
  }

  // Update a bank detail
  Future<bool> updateBank(String bankId, Map<String, String> bankData) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=bank_details&action=update&editid1=$bankId");
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = _authHeader;
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add form fields
      bankData.forEach((key, value) {
        request.fields[key] = value;
      });

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to update bank detail: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating bank detail: $e');
      return false;
    }
  }

  // Delete a bank detail
  Future<bool> deleteBank(String bankId) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=bank_details&action=delete&editid1=$bankId");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to delete bank detail: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting bank detail: $e');
      return false;
    }
  }
  // Update a bank detail
  Future<bool> updateBankDetail(String bankId, Map<String, String> bankData) async {
    final url = Uri.parse("https://karsaazebs.com/BMS/api/v1.php?table=bank_details&action=update&editid1=$bankId");

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = _authHeader;
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add form fields from the provided bank data
      bankData.forEach((key, value) {
        request.fields[key] = value;
      });

      final response = await request.send();

      // Check for a successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to update bank detail: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating bank detail: $e');
      return false;
    }
  }

  // Subscription API Methods

  Future<Map<String, dynamic>?> fetchSubscriptions(int userId) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription&action=list&q=(user_id~equals~$userId)");;
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load subscriptions with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchSubscriptionById(String subscriptionId) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription&action=list&q=(id~equals~$subscriptionId)");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData = json.decode(response.body) as Map<String, dynamic>;
        if (responseData['data'] != null && responseData['data'].isNotEmpty) {
          return responseData['data'][0];
        } else {
          return null;
        }
      } else {
        print('Failed to load subscription with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }

  Future<bool> addNewSubscription(Map<String, String> subscriptionData) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription&action=insert");
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = _authHeader;
      request.headers['Content-Type'] = 'multipart/form-data';

      subscriptionData.forEach((key, value) {
        request.fields[key] = value;
      });

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to add subscription: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding subscription: $e');
      return false;
    }
  }

  Future<bool> updateSubscription(String subscriptionId, Map<String, String> subscriptionData) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription&action=update&editid1=$subscriptionId");
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = _authHeader;
      request.headers['Content-Type'] = 'multipart/form-data';

      subscriptionData.forEach((key, value) {
        request.fields[key] = value;
      });

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to update subscription: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating subscription: $e');
      return false;
    }
  }

  Future<bool> deleteSubscription(String id) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription&action=delete&editid1=$id");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to delete subscription: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting subscription: $e');
      return false;
    }
  }

  // Subscription Payment API Methods

  // Fetch all payments related to a subscription
  Future<Map<String, dynamic>?> fetchSubscriptionPayments(int subscriptionId) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription_payments&action=list&q=(subscription_id~equals~$subscriptionId)");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load subscription payments with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching subscription payments: $e');
      return null;
    }
  }

  // Fetch a single subscription payment by ID
  Future<Map<String, dynamic>?> fetchSubscriptionPaymentById(String paymentId) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription_payments&action=list&q=(id~equals~$paymentId)");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData = json.decode(response.body) as Map<String, dynamic>;
        if (responseData['data'] != null && responseData['data'].isNotEmpty) {
          return responseData['data'][0];
        } else {
          return null;
        }
      } else {
        print('Failed to load subscription payment with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching subscription payment: $e');
      return null;
    }
  }

  // Add a new subscription payment


  // Update a subscription payment
  Future<bool> updateSubscriptionPayments(String paymentId, Map<String, String> paymentData, File? important_attachments) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription_payments&action=update&editid1=$paymentId");
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = _authHeader;
    request.headers['Content-Type'] = 'multipart/form-data';

    // Add form fields
    paymentData.forEach((key, value) {
      request.fields[key] = value;
    });

    // Add file if selected
    if (important_attachments != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'important_attachments',
        important_attachments.path,
        contentType: MediaType('application', 'octet-stream'),
      ));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to update subscription payment: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating subscription payment: $e');
      return false;
    }
  }

  // Delete a subscription payment
  Future<bool> deleteSubscriptionPayments(String id) async {
    final url = Uri.parse("${_baseUrl}v1.php?table=subscription_payments&action=delete&editid1=$id");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to delete subscription payment: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting subscription payment: $e');
      return false;
    }
  }

  // Login
  Future<Map<String, dynamic>?> userLogin({
    required String userName,
    required String password,
    String? userId, // Make userId an optional parameter
  }) async {
    final url = Uri.parse("${_baseUrl}login.php");
    try {
      // Include 'id' in the body only if it's provided
      final body = {
        'user_name': userName,
        'password': password,
        if (userId != null) 'id': userId,
      };

      final response = await http.post(
        url,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Login failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }


  // Fetch Currencies List
  Future<Map<String, dynamic>?> fetchCurrencies() async {
    final url = Uri.parse("${_baseUrl}v1.php?table=currency&action=list");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load currencies with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching currencies: $e');
      return null;
    }
  }

  // Fetch Payment Methods List
  Future<Map<String, dynamic>?> fetchPaymentMethods() async {
    final url = Uri.parse("${_baseUrl}v1.php?table=payment_method&action=list");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load payment methods with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching payment methods: $e');
      return null;
    }
  }
  // Fetch Account Status List
  Future<Map<String, dynamic>?> fetchAccountStatusList() async {
    final url = Uri.parse("${_baseUrl}v1.php?table=bank_account_status&action=list");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load account status list with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching account status list: $e');
      return null;
    }
  }

  // Fetch Account Type List
  Future<Map<String, dynamic>?> fetchAccountTypeList() async {
    final url = Uri.parse("${_baseUrl}v1.php?table=bank_account_type&action=list");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load account type list with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching account type list: $e');
      return null;
    }
  }

  // Fetch Currencies List
  Future<Map<String, dynamic>?> fetchCurrenciesList() async {
    final url = Uri.parse("${_baseUrl}v1.php?table=currency&action=list");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load currency list with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching currency list: $e');
      return null;
    }
  }

  // Fetch Payment Method List
  Future<Map<String, dynamic>?> fetchPaymentMethodsList() async {
    final url = Uri.parse("${_baseUrl}v1.php?table=payment_method&action=list");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load payment methods list with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching payment methods list: $e');
      return null;
    }
  }
  // credential list
  Future<Map<String, dynamic>?> fetchCredentialList(int userId) async {
    final url = Uri.parse("$_baseUrl/v1.php?table=credentials&action=list&q=(user_id~equals~$userId)");
    try {
      final response = await http.get(url, headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response and return it if successful
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Log the error response from the server
        print('Failed to fetch credentials. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      // Print error for connection or other request issues
      print('Error fetching credentials list: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>?> fetchCredentialById(String credentialId) async {
    final url = Uri.parse("$_baseUrl/v1.php?table=credentials&action=view&editid1=$credentialId");
    try {
      final response = await http.get(url, headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      });
      return response.statusCode == 200 ? json.decode(response.body) as Map<String, dynamic> : null;
    } catch (e) {
      print('Error fetching credential: $e');
      return null;
    }
  }

  Future<bool> addCredential(Map<String, String> credentialData) async {
    final url = Uri.parse("$_baseUrl/v1.php?table=credentials&action=insert");
    try {
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = _authHeader
        ..headers['Content-Type'] = 'multipart/form-data'
        ..fields.addAll(credentialData);

      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding credential: $e');
      return false;
    }
  }

  Future<bool> updateCredential(String credentialId, Map<String, String> credentialData) async {
    final url = Uri.parse("$_baseUrl/v1.php?table=credentials&action=update&editid1=$credentialId");
    try {
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = _authHeader
        ..headers['Content-Type'] = 'multipart/form-data'
        ..fields.addAll(credentialData);

      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error updating credential: $e');
      return false;
    }
  }

  Future<bool> deleteCredential(String credentialId) async {
    final url = Uri.parse("$_baseUrl/v1.php?table=credentials&action=delete&editid1=$credentialId");
    try {
      final response = await http.get(url, headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error deleting credential: $e');
      return false;
    }
  }
  // New method to fetch items near to expire
  Future<Map<String, dynamic>?> fetchNearToExpireItems(int userId) async {
    final url = Uri.parse("$_baseUrl/near_to_expire.php?user_id=$userId");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load near-to-expire items with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching near-to-expire items: $e');
      return null;
    }
  }

  // Expired API
  Future<Map<String, dynamic>?> fetchExpireItems(int userId) async {
    final url = Uri.parse("$_baseUrl/expired.php?user_id=$userId");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load expire items with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching expire items: $e');
      return null;
    }
  }

  // favourite bank details list
  Future<Map<String, dynamic>?> fetchFavoriteBankDetails(int userId) async {
    final url = Uri.parse(
        "${_baseUrl}v1.php?table=bank_details&action=list&q=(user_id~equals~$userId)(favourite~equals~1)");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to fetch favorite bank details. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching favorite bank details: $e');
      return null;
    }
  }

  // favourite subscription list
  Future<Map<String, dynamic>?> fetchFavoriteSubscription(int userId) async {
    final url = Uri.parse(
        "${_baseUrl}v1.php?table=subscription&action=list&q=(user_id~equals~$userId)(favourite~equals~1)");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to fetch favorite subscription. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching favorite subscription details: $e');
      return null;
    }
  }
 // favourite credentials list

  Future<Map<String, dynamic>?> fetchFavoriteCredentials(int userId) async {
    final url = Uri.parse(
        "${_baseUrl}v1.php?table=credentials&action=list&q=(user_id~equals~$userId)(favourite~equals~1)");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to fetch favorite credential. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching favorite credential: $e');
      return null;
    }
  }
}
