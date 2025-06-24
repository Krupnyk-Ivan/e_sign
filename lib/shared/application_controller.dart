import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sign/services/application_service.dart';
import 'package:e_sign/services/storage_service.dart';
import 'package:e_sign/services/document_sign_service.dart';
import 'package:e_sign/services/auth_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ApplicationController {
  final ApplicationService _applicationService = ApplicationService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  Function(String)? onError;
  Function(String)? onSuccess;
  Function(bool)? onLoadingChanged;

  ApplicationController({this.onError, this.onSuccess, this.onLoadingChanged});

  void _setLoading(bool loading) {
    onLoadingChanged?.call(loading);
  }

  void _showError(String message) {
    onError?.call(message);
  }

  void _showSuccess(String message) {
    onSuccess?.call(message);
  }

  Stream<QuerySnapshot> getApplicationsStream() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      return FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: currentUser.uid)
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  Stream<QuerySnapshot> getDocumentTemplates() {
    return _applicationService.getDocumentTemplates();
  }

  Future<void> attachDocument(String applicationId) async {
    _setLoading(true);
    try {
      final filePath = await DocumentSignService.pickFile(
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (filePath != null) {
        final file = File(filePath);
        final fileName = filePath.split('/').last;
        final userId = _authService.currentUser?.uid;

        if (userId == null) {
          throw Exception("User not authenticated.");
        }

        _showSuccess("Uploading $fileName...");

        final downloadUrl = await _storageService.uploadFile(
          userId: userId,
          applicationId: applicationId,
          file: file,
          filename: fileName,
        );

        final appDoc = await _applicationService.getApplication(applicationId);
        final appData = appDoc.data() as Map<String, dynamic>;

        List<dynamic> documents = appData['documents'] ?? [];
        documents.add({'name': fileName, 'url': downloadUrl});

        await _applicationService.updateApplication(applicationId, {
          'documents': documents,
        });

        _showSuccess('Document attached successfully');
      }
    } catch (e) {
      _showError('Failed to attach document: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> downloadDocument({
    required String documentName,
    required String applicationId,
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _showError("User not authenticated.");
      return;
    }

    _showSuccess('Downloading $documentName...');
    _setLoading(true);

    try {
      final bytes = await _storageService.downloadFile(
        userId: userId,
        applicationId: applicationId,
        filename: documentName,
      );

      if (bytes == null) {
        throw Exception("File not found in storage.");
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$documentName';
      final file = File(path);
      await file.writeAsBytes(bytes);

      _showSuccess('$documentName saved to Documents');
    } catch (e) {
      _showError('Failed to download document: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> downloadMainDocument({
    required String documentUrl,
    required String applicationId,
  }) async {
    _setLoading(true);
    _showSuccess('Downloading main document...');

    try {
      final uri = Uri.parse(documentUrl);
      final fileName = uri.pathSegments.last.split('?').first;

      final ref = FirebaseStorage.instance.refFromURL(documentUrl);
      final bytes = await ref.getData();

      if (bytes == null) {
        throw Exception("Failed to download file from storage.");
      }

      final directory = await getApplicationDocumentsDirectory();

      final sanitizedFileName = fileName
          .replaceAll('/', '_')
          .replaceAll('\\', '_');
      final fullPath = '${directory.path}/$sanitizedFileName';
      final file = File(fullPath);

      await file.parent.create(recursive: true);

      await file.writeAsBytes(bytes);

      _showSuccess('Main document saved to Documents');
    } catch (e) {
      print(documentUrl);
      print(e);
      _showError('Failed to download main document: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> downloadSignature({
    required String signatureUrl,
    required String applicationId,
  }) async {
    _setLoading(true);
    _showSuccess('Downloading signature...');

    try {
      final ref = FirebaseStorage.instance.refFromURL(signatureUrl);
      final bytes = await ref.getData();

      if (bytes == null) {
        throw Exception("Failed to download signature from storage.");
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/signature_$applicationId.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes);

      _showSuccess('Signature saved to Documents');
    } catch (e) {
      _showError('Failed to download signature: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createApplicationFromTemplate(
    String templateId,
    String templateTitle,
    String? templatePath,
  ) async {
    final user = _authService.currentUser;
    if (user == null) {
      _showError("User not authenticated.");
      return;
    }

    try {
      final templateDoc =
          await FirebaseFirestore.instance
              .collection('document_templates')
              .doc(templateId)
              .get();

      if (!templateDoc.exists) {
        _showError("Template not found.");
        return;
      }

      final templateData = templateDoc.data()!;
      final String? reviewerId = templateData['reviewerId'];
      final bool requiresReview = templateData['requiresReview'] ?? false;
      final bool requiresSignature = templateData['requiresSignature'] ?? false;

      final applicationId = DateTime.now().millisecondsSinceEpoch.toString();

      final Map<String, dynamic> newAppData = {
        'studentId': user.uid,
        'templateId': templateId,
        'title': templateTitle,
        'status': 'pending',
        'reviewerId': reviewerId,
        'reviewStatus': requiresReview ? 'pending_review' : 'not_required',
        'requiresReview': requiresReview,
        'requiresSignature': requiresSignature,
        'signatureStatus':
            requiresSignature ? 'pending_signature' : 'not_required',
        'documents': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
        'documentPath': templatePath,
        'signaturePath': null,
        'signedBy': null,
        'signedAt': null,
        'reviewedAt': null,
        'reviewComments': null,
        'reviewHistory': <Map<String, dynamic>>[],
      };

      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .set(newAppData);

      _showSuccess('Application created: $templateTitle');
    } catch (e) {
      _showError('Failed to create application: $e');
    }
  }

  Future<void> updateApplication(String applicationId, String newTitle) async {
    try {
      await _applicationService.updateApplication(applicationId, {
        'title': newTitle,
      });
      _showSuccess('Application updated successfully');
    } catch (e) {
      _showError('Failed to update application: $e');
    }
  }

  Future<void> deleteApplication(String applicationId) async {
    try {
      await _applicationService.deleteApplication(applicationId);
      _showSuccess('Application deleted successfully');
    } catch (e) {
      _showError('Failed to delete application: $e');
    }
  }

  Future<void> signWithJKS(String applicationId, String jksPassword) async {
    if (jksPassword.isEmpty) {
      _showError('Please enter the keystore password');
      return;
    }

    _setLoading(true);

    try {
      if (_authService.currentUser == null) {
        throw Exception('User not authenticated');
      }

      final certificatePath =
          '/data/user/0/com.example.e_sign/cache/testalias.pfx';
      final certificateFile = File(certificatePath);

      if (!await certificateFile.exists()) {
        throw Exception(
          'Certificate file not found. Please generate or import a certificate first.',
        );
      }
      final appDoc = await _applicationService.getApplication(applicationId);
      final appData = appDoc.data() as Map<String, dynamic>;
      final documentUrl = appData['documentPath'];

      if (documentUrl == null || documentUrl.isEmpty) {
        throw Exception('Application has no main document to sign.');
      }

      final ref = FirebaseStorage.instance.refFromURL(documentUrl);

      final documentBytes = await ref.getData();
      if (documentBytes == null)
        throw Exception('Failed to load document to sign.');

      final result = await DocumentSignService.signWithJKS(
        fileBytes: documentBytes,
        keystorePath: certificatePath,
        password: jksPassword,
        alias: 'testalias',
        userId: _authService.currentUser!.uid,
        applicationId: applicationId,
        signerRole: 'applicant',
      );
      final signatureUrl = result['applicantSignatureUrl'];

      if (signatureUrl == null || signatureUrl.isEmpty) {
        throw Exception('Failed to get signature URL after signing.');
      }

      print('Document signed successfully. Signature URL: $signatureUrl');

      await _applicationService.updateApplicationSignature(
        applicationId: applicationId,
        signatureUrl: signatureUrl,
        signedByUserId: _authService.currentUser!.uid,
        role: 'applicant',
      );

      _showSuccess('Document signed successfully! 📄✅');
    } catch (e) {
      print('Signing error: $e');
      _showError('Failed to sign document: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'signed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      case 'submitted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'signed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      case 'submitted':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  List<DocumentSnapshot> sortApplications(List<DocumentSnapshot> docs) {
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['createdAt'] as Timestamp?;
      final bTime = bData['createdAt'] as Timestamp?;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime);
    });
    return docs;
  }
}
