import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'secure_storage_service.dart';

class EncryptionService {
  static const int _ivLength = 16;

  static Future<encrypt.Encrypter> _getEncrypter() async {
    final keyBytes = await SecureStorageService.getEncryptionKey();
    final key = encrypt.Key(keyBytes);
    return encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
  }

  static Future<Uint8List> encryptData(Uint8List data) async {
    final encrypter = await _getEncrypter();
    final iv = encrypt.IV.fromSecureRandom(_ivLength);
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    // Prepend IV to encrypted data
    final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
    result.setAll(0, iv.bytes);
    result.setAll(iv.bytes.length, encrypted.bytes);
    
    return result;
  }

  static Future<Uint8List> decryptData(Uint8List encryptedData) async {
    if (encryptedData.length < _ivLength) {
      throw ArgumentError('Invalid encrypted data');
    }

    final encrypter = await _getEncrypter();
    final iv = encrypt.IV(Uint8List.sublistView(encryptedData, 0, _ivLength));
    final encrypted = encrypt.Encrypted(
      Uint8List.sublistView(encryptedData, _ivLength),
    );
    
    return Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: iv));
  }

  static Future<void> encryptFile(String inputPath, String outputPath) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw FileSystemException('Input file not found', inputPath);
    }

    final data = await inputFile.readAsBytes();
    final encrypted = await encryptData(data);
    
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(encrypted);
  }

  static Future<void> decryptFile(String inputPath, String outputPath) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw FileSystemException('Encrypted file not found', inputPath);
    }

    final data = await inputFile.readAsBytes();
    final decrypted = await decryptData(data);
    
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(decrypted);
  }

  static Future<String> encryptText(String text) async {
    final data = Uint8List.fromList(utf8.encode(text));
    final encrypted = await encryptData(data);
    return base64Encode(encrypted);
  }

  static Future<String> decryptText(String encryptedText) async {
    final data = base64Decode(encryptedText);
    final decrypted = await decryptData(data);
    return utf8.decode(decrypted);
  }

  static Future<bool> verifyFileIntegrity(String filePath, String expectedHash) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    return hash == expectedHash;
  }

  static Future<String> computeFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}
