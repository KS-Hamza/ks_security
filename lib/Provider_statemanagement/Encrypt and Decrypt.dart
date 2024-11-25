import 'package:encrypt/encrypt.dart';

class encrypted {
  final _key = Key.fromUtf8('my32hamzahsupersecretnooneknows1'); // 32 chars key
  final _iv = IV.fromLength(16);

  String encrypt(String plainText) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    final encrypt = Encrypter(AES(_key, mode: AESMode.cbc));
    final decrypted = encrypt.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}
//my32lengthsupersecretnooneknows1