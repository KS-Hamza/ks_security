import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  String? _username;
  int? _userId;

  // Getters for username and userId
  String? get username => _username;
  int? get userId => _userId;

  // Method to set user data
  void setUser(String username, int userId) {
    _username = username;
    _userId = userId;
    notifyListeners();
  }

  // Method to clear user data (if needed, e.g., during logout)
  void clearUser() {
    _username = null;
    _userId = null;
    notifyListeners();
  }
}
