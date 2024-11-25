import 'package:businessmanagemant/Provider_statemanagement/Encrypt%20and%20Decrypt.dart';
import 'package:flutter/foundation.dart';

class BankDetailsProvider with ChangeNotifier {
  final _encryptionHelper = encrypted();
  String _bankDetails = '';

  String get bankDetails => _encryptionHelper.decrypt(_bankDetails);

  void updateBankDetails(String newDetails) {
    _bankDetails = _encryptionHelper.encrypt(newDetails);
    notifyListeners();
  }
}
