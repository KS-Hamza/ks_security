import 'package:encrypt/encrypt.dart';

class AESEncryptionHelper {
  final Key key = Key.fromUtf8('1234567890'); // 32-byte key for AES-256
  final IV iv = IV.fromUtf8('1234567890123456'); // 16-byte IV for AES

  final Encrypter encrypter;

  AESEncryptionHelper()
      : encrypter = Encrypter(AES(Key.fromUtf8('12345678901234567890123456789012'), mode: AESMode.cbc));

  String encrypt(String plainText) {
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedBase64Text) {
    try {
      final decrypted = encrypter.decrypt64(encryptedBase64Text, iv: iv);
      return decrypted;
    } catch (e) {
      print('Decryption failed: $e');
      throw FormatException('Decryption failed: $e');
    }
  }
}






























/*import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JWTUtils {
  // Hardcoded secret key (For demonstration purposes only; not recommended for production)
  static const String _fixedSecretKey = '123'; // Make sure this key is consistent everywhere.

  /// Encrypt data using the hardcoded secret key
  static String encryptData(String data) {
    try {
      final jwt = JWT({'data': data});
      final token = jwt.sign(SecretKey(_fixedSecretKey));
      print("Data encrypted successfully: $token");
      return token;
    } catch (e) {
      print("Encryption failed: $e");
      throw Exception("Encryption failed: $e");
    }
  }

  /// Decrypt data using the hardcoded secret key
  static String decryptData(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_fixedSecretKey));
      final decryptedData = jwt.payload['data'];
      print("Data decrypted successfully: $decryptedData");
      return decryptedData;
    } catch (e) {
      print("Decryption failed: $e");
      throw Exception("Decryption failed: $e");
    }
  }
}*/
