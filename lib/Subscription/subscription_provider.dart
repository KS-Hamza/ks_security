// subscription_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_services.dart';
import '../encryption.dart';

class SubscriptionProvider with ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _filteredSubscriptions = [];

  // Getter for filtered subscriptions
  List<Map<String, dynamic>> get filteredSubscriptions => _filteredSubscriptions;

  // Fetch subscriptions from API for a given userId
  Future<void> fetchSubscriptions(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedData = await _apiServices.fetchSubscriptions(userId);
      if (fetchedData != null && fetchedData['data'] != null) {
        _subscriptions = List<Map<String, dynamic>>.from(fetchedData['data']).map((subscription) {
          // Decrypt sensitive fields
          subscription['service_name'] = encryptionHelper.decrypt(subscription['service_name']);
          subscription['username'] = encryptionHelper.decrypt(subscription['username']);
          subscription['password'] = encryptionHelper.decrypt(subscription['password']);
          subscription['url'] = encryptionHelper.decrypt(subscription['url']);
          subscription['other_description'] = encryptionHelper.decrypt(subscription['other_description']);

          // Ensure 'is_favourite' is correctly parsed as boolean
          subscription['is_favourite'] = subscription['is_favourite'] == 1;

          return subscription;
        }).toList();

        _filteredSubscriptions = List.from(_subscriptions); // Update filtered list
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter subscriptions based on search query
  void filterSubscriptions(String query) {
    _filteredSubscriptions = _subscriptions.where((subscription) {
      final serviceName = subscription['service_name']?.toLowerCase() ?? '';
      return serviceName.contains(query);
    }).toList();
    notifyListeners();
  }

  // Filter subscriptions by type (e.g., favourite or recently added)
  void filterByType(String filter) {
    if (filter == "favourite") {
      _filteredSubscriptions = _subscriptions.where((subscription) => subscription['is_favourite'] == true).toList();
    } else if (filter == "recent") {
      _filteredSubscriptions = _subscriptions.where((subscription) => subscription['recently_added'] == true).toList();
    } else {
      _filteredSubscriptions = List.from(_subscriptions); // Show all if "all" is selected
    }
    notifyListeners();
  }

  // Toggle favourite status for a subscription
  Future<void> toggleFavorite(int index, int subscriptionId) async {
    final isFavorite = _filteredSubscriptions[index]['is_favourite'] ?? false;
    _filteredSubscriptions[index]['is_favourite'] = !isFavorite;
    notifyListeners();

    try {
      final url = isFavorite
          ? 'https://karsaazebs.com/BMS/api/favourite/subscription_isnot_favourite.php?id=$subscriptionId'
          : 'https://karsaazebs.com/BMS/api/favourite/subscription_is_favourite.php?id=$subscriptionId';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': _apiServices.authHeader,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Revert the change if the API call fails
        _filteredSubscriptions[index]['is_favourite'] = isFavorite;
        notifyListeners();
        print('Failed to update favorite status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating favorite status: $e');
      // Revert the change on exception
      _filteredSubscriptions[index]['is_favourite'] = isFavorite;
      notifyListeners();
    }
  }

  // Add a new subscription
  Future<void> addSubscription({
    required int userId,
    required String serviceName,
    String? url,
    required String username,
    required String password,
    required bool autoRenewal,
    required String nextRenewalDate,
    required String expiryDate,
    String? otherDescription,
    required bool isActive,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Encrypt sensitive fields
    String encryptedServiceName = encryptionHelper.encrypt(serviceName);
    String encryptedUsername = encryptionHelper.encrypt(username);
    String encryptedPassword = encryptionHelper.encrypt(password);
    String encryptedUrl = url != null ? encryptionHelper.encrypt(url) : '';
    String encryptedOtherDescription = otherDescription != null ? encryptionHelper.encrypt(otherDescription) : '';

    // Prepare the request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://karsaazebs.com/BMS/api/v1.php?table=subscription&action=insert'),
    );

    // Populate request fields
    request.fields['user_id'] = userId.toString();
    request.fields['service_name'] = encryptedServiceName;
    request.fields['url'] = encryptedUrl;
    request.fields['username'] = encryptedUsername;
    request.fields['password'] = encryptedPassword;
    request.fields['auto_renewal'] = autoRenewal ? '1' : '0';
    request.fields['next_renewal_date'] = nextRenewalDate;
    request.fields['expiry_date'] = expiryDate;
    request.fields['other_description'] = encryptedOtherDescription;
    request.fields['active'] = isActive ? '1' : '0';

    // Set headers
    request.headers['Authorization'] = _apiServices.authHeader;
    request.headers['Content-Type'] = 'multipart/form-data';

    try {
      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Subscription added successfully!');
        await fetchSubscriptions(userId);
      } else {
        print('Failed to add subscription with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing subscription
  Future<void> updateSubscription({
    required String subscriptionId,
    required String serviceName,
    String? url,
    required String username,
    required String password,
    required bool autoRenewal,
    required String nextRenewalDate,
    required String expiryDate,
    String? otherDescription,
    required bool isActive,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Encrypt sensitive data
    String encryptedServiceName = encryptionHelper.encrypt(serviceName);
    String encryptedUsername = encryptionHelper.encrypt(username);
    String encryptedPassword = encryptionHelper.encrypt(password);
    String encryptedUrl = url != null ? encryptionHelper.encrypt(url) : '';
    String encryptedOtherDescription = otherDescription != null ? encryptionHelper.encrypt(otherDescription) : '';

    // Set up the data to be sent to the API
    Map<String, String> subscriptionData = {
      'service_name': encryptedServiceName,
      'url': encryptedUrl,
      'username': encryptedUsername,
      'password': encryptedPassword,
      'auto_renewal': autoRenewal ? '1' : '0',
      'next_renewal_date': nextRenewalDate,
      'expiry_date': expiryDate,
      'other_description': encryptedOtherDescription,
      'active': isActive ? '1' : '0',
    };

    try {
      // Call the API service to update the subscription
      final success = await _apiServices.updateSubscription(subscriptionId, subscriptionData);
      if (success) {
        print('Subscription updated successfully');
        // Optionally, add code here to refresh data or perform additional tasks if needed
      }
    } catch (e) {
      print('Error updating subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  // Delete a subscription
  Future<void> deleteSubscription(String subscriptionId, int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiServices.deleteSubscription(subscriptionId);
      if (success) {
        await fetchSubscriptions(userId);
      }
    } catch (e) {
      print('Error deleting subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
