import 'package:flutter/material.dart';
import '../api_services.dart';

class LoginProvider with ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  bool _isLoading = false;
  bool _isLoggedIn = false;
  int? _userId; // Store user ID
  String? _userName; // Store username
  String ?_password;
  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get password => _password;

  // Login method
  Future<bool> login(String userName, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      var response = await _apiServices.userLogin(userName: userName, password: password);
      _isLoading = false;

      if (response != null && response['status'] == 1) {
        // Parse and store the user ID and username from the response
        _userId = int.tryParse(response['id']);
        _userName = response['username'] ?? userName;
        _password = response['password']?? password;// Use the returned username or the input username
        print('User ID after login: $_userId');
        print('User Name after login: $_userName');

        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        _isLoggedIn = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _isLoggedIn = false;
      notifyListeners();
      print('Login error: $e');
      return false;
    }
  }

  // Logout method to clear user data
  void logout() {
    _isLoggedIn = false;
    _userId = null;
    _userName = null;
    _password = null;
    notifyListeners();
  }
}
