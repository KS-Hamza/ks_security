// credential_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_services.dart';
import '../encryption.dart';

class CredentialsProvider with ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _credentials = [];
  List<Map<String, dynamic>> _filteredCredentials = [];

  List<Map<String, dynamic>> get filteredCredentials => _filteredCredentials;

  // Fetch credentials from the API
  Future<void> fetchCredentials(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedData = await _apiServices.fetchCredentialList(userId);
      if (fetchedData != null && fetchedData['data'] != null) {
        _credentials = List<Map<String, dynamic>>.from(fetchedData['data']).map((credential) {
          credential['username'] = encryptionHelper.decrypt(credential['username']);
          credential['url'] = encryptionHelper.decrypt(credential['url'] ?? '');
          credential['remarks'] = encryptionHelper.decrypt(credential['remarks'] ?? '');

          credential['is_favourite'] = credential['is_favourite'] == 1;
          return credential;
        }).toList();
        _filteredCredentials = List.from(_credentials); // Initialize filtered list
      }
    } catch (e) {
      print('Error fetching credentials: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to filter credentials by search query
  void filterCredentials(String query) {
    _filteredCredentials = _credentials.where((credential) {
      final username = credential['username']?.toLowerCase() ?? '';
      return username.contains(query.toLowerCase());
    }).toList();
    notifyListeners();
  }

  // Method to filter credentials by status
  void filterByStatus(String status) {
    if (status == "active") {
      _filteredCredentials = _credentials.where((credential) => credential['status'] == "Active").toList();
    } else if (status == "inactive") {
      _filteredCredentials = _credentials.where((credential) => credential['status'] == "Inactive").toList();
    } else {
      _filteredCredentials = List.from(_credentials); // Show all if "all" is selected
    }
    notifyListeners();
  }

  // Add a new credential
  Future<void> addCredential({
    required int userId,
    required String username,
    required String password,
    String? remarks,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Encrypt sensitive fields
    String encryptedUsername = encryptionHelper.encrypt(username);
    String encryptedPassword = encryptionHelper.encrypt(password);
    String encryptedRemarks = remarks != null ? encryptionHelper.encrypt(remarks) : '';

    // Prepare the request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://karsaazebs.com/BMS/api/v1.php?table=credentials&action=insert'),
    );

    // Populate request fields
    request.fields['user_id'] = userId.toString();
    request.fields['username'] = encryptedUsername;
    request.fields['password'] = encryptedPassword;
    request.fields['remarks'] = encryptedRemarks;

    // Set headers
    request.headers['Authorization'] = _apiServices.authHeader;
    request.headers['Content-Type'] = 'multipart/form-data';

    try {
      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Credential added successfully!');
        await fetchCredentials(userId);
      } else {
        print('Failed to add credential with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding credential: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing credential
  Future<void> updateCredential({
    required String credentialId,
    required String username,
    required String password,
    String? remarks,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Encrypt sensitive data
    String encryptedUsername = encryptionHelper.encrypt(username);
    String encryptedPassword = encryptionHelper.encrypt(password);
    String encryptedRemarks = remarks != null ? encryptionHelper.encrypt(remarks) : '';

    // Set up the data to be sent to the API
    Map<String, String> credentialData = {
      'username': encryptedUsername,
      'password': encryptedPassword,
      'remarks': encryptedRemarks,
    };

    try {
      // Call the API service to update the credential
      final success = await _apiServices.updateCredential(credentialId, credentialData);
      if (success) {
        print('Credential updated successfully');
        await fetchCredentials(int.parse(credentialData['user_id']!));
      }
    } catch (e) {
      print('Error updating credential: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void filterByType(String filter) {
    if (filter == "favourite") {
      _filteredCredentials = _credentials.where((credentials) => credentials['is_favourite'] == true).toList();
    } else if (filter == "recent") {
      _filteredCredentials = _credentials.where((credentials) => credentials['recently_added'] == true).toList();
    } else {
      _filteredCredentials = List.from(_credentials); // Show all if "all" is selected
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(int index, int credentialsId) async {
    final isFavorite = _filteredCredentials[index]['is_favourite'] ?? false;

    // Optimistically update the state
    _filteredCredentials[index]['is_favourite'] = !isFavorite;
    notifyListeners();

    try {
      final url = isFavorite
          ? 'https://karsaazebs.com/BMS/api/favourite/credentials_isnot_favourite.php?id=$credentialsId'
          : 'https://karsaazebs.com/BMS/api/favourite/credentials_is_favourite.php?id=$credentialsId';

      print('API URL: $url');

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': _apiServices.authHeader,
      });

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update favorite status');
      }
    } catch (e) {
      // Revert the optimistic update on failure
      _filteredCredentials[index]['is_favourite'] = isFavorite;
      notifyListeners();

      print('Error updating favorite status: $e');
    }
  }


  // Delete a credential
  Future<void> deleteCredential(String credentialId, int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiServices.deleteCredential(credentialId);
      if (success) {
        await fetchCredentials(userId);
      }
    } catch (e) {
      print('Error deleting credential: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
