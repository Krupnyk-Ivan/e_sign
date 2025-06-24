import 'dart:io';
import 'dart:typed_data';
import 'package:e_sign/services/auth_service.dart';
import 'package:e_sign/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class DocumentSignService {
  static const MethodChannel _channel = MethodChannel('document_signer');

  static Future<String?> pickFile({List<String>? allowedExtensions}) async {
    try {
      FileType type = FileType.any;
      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        type = FileType.custom;
      }
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
      );
      if (result == null) return null;
      return result.files.single.path;
    } on PlatformException catch (e) {
      print('File pick error: ${e.message}');
      return null;
    }
  }

  static Future<Uint8List> readFileBytes(String path) async {
    final file = File(path);
    return await file.readAsBytes();
  }

  static Future<Map<String, String>> signWithJKS({
    required Uint8List fileBytes,
    required String keystorePath,
    required String password,
    required String alias,
    required String userId,
    required String applicationId,
    required String signerRole,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('signWithJKS', {
        'fileBytes': fileBytes,
        'keystorePath': keystorePath,
        'password': password,
        'alias': alias,
      });
      if (result == null) {
        throw Exception('Empty result from native signWithJKS');
      }

      final p7sPath = result['p7sPath'] as String;
      final p7sFile = File(p7sPath);
      final bytes = await p7sFile.readAsBytes();
      final filename = '${signerRole}_$alias.p7s';

      final url = await StorageService().uploadFile(
        file: p7sFile,
        userId: userId,
        applicationId: applicationId,
        filename: filename,
      );

      print('Signature file uploaded: $url');

      return {
        'signature': result['signature']?.toString() ?? '',
        'publicKey': result['publicKey']?.toString() ?? '',
        'hash': result['hash']?.toString() ?? '',
        '${signerRole}SignatureUrl': url,
      };
    } on PlatformException catch (e) {
      throw Exception('Native error during signWithJKS: ${e.message}');
    } catch (e) {
      throw Exception('Error during signWithJKS: $e');
    }
  }

  static Future<bool> pfxExists({required String alias}) async {
    try {
      final exists = await _channel.invokeMethod<bool>('pfxExists', {
        'alias': alias,
      });
      return exists ?? false;
    } on PlatformException catch (e) {
      print('pfxExists error: ${e.message}');
      return false;
    }
  }

  static Future<String?> generatePfx({
    required String password,
    required String alias,
    required String userId,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('generatePfx', {
        'password': password,
        'alias': alias,
        'userId': userId,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Native error during generatePfx: ${e.message}');
    }
  }

  static Future<bool> verifySignature({
    required String originalPath,
    required String signaturePath,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('verifySignature', {
        'originalPath': originalPath,
        'signaturePath': signaturePath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('verifySignature error: ${e.message}');
      return false;
    }
  }
}
