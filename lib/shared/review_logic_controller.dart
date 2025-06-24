import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sign/services/application_service.dart';
import 'package:e_sign/services/auth_service.dart';
import 'package:e_sign/services/document_sign_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class ReviewLogicController {
  final ApplicationService _applicationService = ApplicationService();
  final AuthService _authService = AuthService();

  String? get currentUserId => _authService.currentUser?.uid;

  Stream<QuerySnapshot> getApplicationsStream(String statusFilter) {
    final uid = currentUserId;
    if (uid == null) return Stream.empty();

    Query query = FirebaseFirestore.instance
        .collection('applications')
        .where('reviewerId', isEqualTo: uid);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots();
  }

  Future<String> downloadDocument(Map<String, dynamic> appData) async {
    final url = appData['documentPath'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Document path not found');
    }

    final ref = FirebaseStorage.instance.refFromURL(url);
    final bytes = await ref.getData();

    if (bytes == null) {
      throw Exception('Failed to download document');
    }

    final fileName = _extractFilename(url);
    final directory = await getApplicationDocumentsDirectory();

    final sanitizedFileName = fileName
        .replaceAll('/', '_')
        .replaceAll('\\', '_');
    final fullPath = '${directory.path}/$sanitizedFileName';
    final file = File(fullPath);

    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);

    return file.path;
  }

  String _extractFilename(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  Future<void> rejectApplication({
    required String applicationId,
    String? rejectionReason,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _applicationService.reviewApplication(
      applicationId: applicationId,
      reviewerId: userId,
      approved: false,
    );
  }

  Future<String> approveApplication({
    required String applicationId,
    required Map<String, dynamic> appData,
    String? jksPassword,
    String? reviewerCertPath,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    String? reviewerSignatureUrl;

    if (reviewerCertPath != null &&
        jksPassword != null &&
        jksPassword.isNotEmpty) {
      reviewerSignatureUrl = await _signDocument(
        appData: appData,
        reviewerCertPath: reviewerCertPath,
        jksPassword: jksPassword,
        applicationId: applicationId,
        userId: userId,
      );
    }

    await _applicationService.reviewApplication(
      applicationId: applicationId,
      reviewerId: userId,
      approved: true,
      reviewerSignatureUrl: reviewerSignatureUrl,
    );

    return reviewerSignatureUrl != null
        ? 'Application approved and signed successfully'
        : 'Application approved successfully';
  }

  Future<String?> _signDocument({
    required Map<String, dynamic> appData,
    required String reviewerCertPath,
    required String jksPassword,
    required String applicationId,
    required String userId,
  }) async {
    final certFile = File(reviewerCertPath);
    if (!await certFile.exists()) {
      throw Exception('Certificate file not found at: $reviewerCertPath');
    }

    final url = appData['documentPath'] as String?;
    if (url == null) {
      throw Exception('Document path not found');
    }

    final ref = FirebaseStorage.instance.refFromURL(url);
    final docBytes = await ref.getData();

    if (docBytes == null) {
      throw Exception('Failed to download document for signing');
    }

    final signResult = await DocumentSignService.signWithJKS(
      fileBytes: docBytes,
      keystorePath: reviewerCertPath,
      password: jksPassword,
      alias: 'reviewerAlias',
      userId: userId,
      applicationId: applicationId,
      signerRole: 'reviewer',
    );

    return signResult['signatureUrl'];
  }

  List<DocumentSnapshot> filterDocuments(
    List<DocumentSnapshot> docs,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toLowerCase();
      final studentId = (data['studentId'] ?? '').toLowerCase();
      final templateTitle = (data['templateTitle'] ?? '').toLowerCase();

      return title.contains(searchQuery.toLowerCase()) ||
          studentId.contains(searchQuery.toLowerCase()) ||
          templateTitle.contains(searchQuery.toLowerCase());
    }).toList();
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }
}
