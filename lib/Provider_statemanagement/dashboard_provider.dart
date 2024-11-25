import 'package:flutter/foundation.dart';

class DashboardProvider with ChangeNotifier {
  int _notificationCount = 0;
  double _progress = 0.0; // Add this line

  int get notificationCount => _notificationCount;
  double get progress => _progress; // Add this getter

  void incrementNotification() {
    _notificationCount++;
    notifyListeners();
  }

  void resetNotification() {
    _notificationCount = 0;
    notifyListeners();
  }

  void updateProgress(double value) { // Add this method
    _progress = value;
    notifyListeners();
  }
}
