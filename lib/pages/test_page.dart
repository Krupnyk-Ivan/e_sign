import 'dart:io';

import 'package:e_sign/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  _TestPage createState() => _TestPage();
}

class _TestPage extends State<TestPage> {
  final storage = FlutterSecureStorage();
  final algorithm = Ed25519();
  static const platform = MethodChannel('document_signer');
  String generatedPfxPath = '';
  String? originalPath;
  String? signaturePath;

  Future<void> pickOriginalFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        originalPath = result.files.single.path!;
      });
    }
  }

  Future<void> pickSignatureFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      setState(() {
        signaturePath = result.files.single.path!;
      });
    }
  }

  String signatureBase64 = '';
  String signingMethod = 'JKS';

  // JKS Configuration
  String jksPath = '';
  String jksPassword = '';
  String jksAlias = '';
  String jkUserId = '';

  Future<void> generatePfx() async {
    try {
      final exists = await platform.invokeMethod<bool>('pfxExists', {
        'alias': jksAlias.isNotEmpty ? jksAlias : 'testalias',
      });

      if (exists == true) {
        print(" PFX already exists, skipping generation");
        return;
      }

      final pfxPath = await platform.invokeMethod<String>('generatePfx', {
        'password': jksPassword.isNotEmpty ? jksPassword : 'testpass',
        'alias': jksAlias.isNotEmpty ? jksAlias : 'testalias',
        'userId':
            jkUserId.isNotEmpty ? jkUserId : authService.value.currentUser!.uid,
      });
      print(' PFX згенеровано: $authService.value.currentUser!.uid');

      if (pfxPath != null) {
        setState(() => generatedPfxPath = pfxPath);
        print(' PFX згенеровано: $pfxPath');
      }
    } catch (e) {
      _showError('Помилка генерації PFX: $e');
    }
  }

  Future<void> runCryptoTest() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) {
      print('Файл не обрано');
      return;
    }

    final file = result.files.first;
    final fileBytes = file.bytes ?? await File(file.path!).readAsBytes();
    final fileName = file.name;

    if (fileBytes == null) {
      print('Неможливо прочитати файл');
      return;
    }

    print('Обрано файл: $fileName');

    if (signingMethod == 'JKS') {
      await signWithJKS(fileBytes);
    }
  }

  Future<void> signWithJKS(Uint8List fileBytes) async {
    if (jksPath.isEmpty || jksPassword.isEmpty || jksAlias.isEmpty) {
      _showError('Будь ласка, заповніть всі поля JKS конфігурації');
      return;
    }

    try {
      final result = await platform.invokeMethod('signWithJKS', {
        'fileBytes': fileBytes,
        'keystorePath': jksPath,
        'password': jksPassword,
        'alias': jksAlias,
      });

      final signatureStr = result['signature'] as String;
      final publicKeyStr = result['publicKey'] as String;
      final hashStr = result['hash'] as String;

      print('JKS Hash: $hashStr');
      print('JKS Signature: $signatureStr');
      print('JKS Public Key: $publicKeyStr');
    } catch (e) {
      _showError('Помилка підпису з JKS: $e');
    }
  }

  Future<void> pickJKSFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select JKS/KeyStore file',
      );

      if (result != null && result.files.isNotEmpty) {
        final selectedFile = result.files.first;
        final fileName = selectedFile.name.toLowerCase();

        // Check if it's likely a keystore file
        if (fileName.endsWith('.jks') ||
            fileName.endsWith('.keystore') ||
            fileName.contains('keystore') ||
            fileName.contains('jks')) {
          setState(() {
            jksPath = selectedFile.path ?? '';
          });
        } else {
          // Allow any file but show warning
          setState(() {
            jksPath = selectedFile.path ?? '';
          });
          _showWarning(
            'Selected file may not be a keystore file. Please ensure it\'s a valid JKS or KeyStore file.',
          );
        }
      }
    } catch (e) {
      _showError('Error selecting file: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showKeystoreInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Creating a Test Keystore'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('To create a test keystore, use one of these methods:'),
                SizedBox(height: 12),
                Text(
                  'Option 1: PKCS12 (Recommended for Android)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    'keytool -genkeypair -alias testkey -keyalg RSA -keysize 2048 -keystore test.p12 -storetype PKCS12 -storepass password123 -keypass password123 -dname "CN=Test"',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Option 2: Try with Android Keystore',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Use password: password123'),
                Text('• Use alias: testkey'),
                Text('• File extension: .p12 or .pfx'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJKSConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JKS Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // JKS File Path
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'JKS File Path',
                      hintText: 'Enter path or browse...',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: jksPath),
                    onChanged: (value) => setState(() => jksPath = value),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: pickJKSFile, child: Text('Browse')),
              ],
            ),
            SizedBox(height: 12),

            // Password
            TextField(
              decoration: InputDecoration(
                labelText: 'Keystore Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) => jksPassword = value,
            ),
            SizedBox(height: 12),

            // Alias
            TextField(
              decoration: InputDecoration(
                labelText: 'Key Alias',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => jksAlias = value,
            ),
          ],
        ),
      ),
    );
  }

  void verify() async {
    if (originalPath == null || signaturePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Оберіть обидва файли")));
      return;
    }

    final isValid = await SignatureService.verifySignature(
      originalPath: originalPath!,
      signaturePath: signaturePath!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isValid ? " Підпис дійсний" : " Підпис недійсний"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Signing Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Signing method selection
              SizedBox(height: 16),

              // JKS Configuration (show only when JKS is selected)
              if (signingMethod == 'JKS') ...[
                _buildJKSConfiguration(),
                SizedBox(height: 16),
              ],

              // Sign button
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      child: Text('Sign Document'),
                      onPressed: runCryptoTest,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (signingMethod == 'JKS')
                      TextButton(
                        onPressed: () => _showKeystoreInstructions(),
                        child: Text('Need help creating a keystore?'),
                      ),
                    if (signingMethod == 'JKS') ...[
                      ElevatedButton(
                        onPressed: generatePfx,
                        child: Text(' Generate PFX'),
                      ),
                      if (generatedPfxPath.isNotEmpty) ...[
                        SizedBox(height: 8),
                        SelectableText(
                          'PFX path:\n$generatedPfxPath',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                      ElevatedButton(
                        onPressed: pickOriginalFile,
                        child: const Text("Оберіть PDF"),
                      ),
                      if (originalPath != null)
                        Text(
                          "PDF: $originalPath",
                          style: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: pickSignatureFile,
                        child: const Text("Оберіть підпис (.p7s)"),
                      ),
                      if (signaturePath != null)
                        Text(
                          "Підпис: $signaturePath",
                          style: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: verify,
                        child: const Text("Перевірити підпис"),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Results
              if (signatureBase64.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signature Result ($signingMethod)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Signature (Base64):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            signatureBase64,
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SignatureService {
  static const _channel = MethodChannel('document_signer');

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
      print('Verification failed: ${e.message}');
      return false;
    }
  }
}
