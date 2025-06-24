import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createApplication({
    required String userId,
    required String applicationId,
    required String documentUrl,
  }) async {
    final docRef = _firestore.collection('applications').doc(applicationId);
    await docRef.set({
      'studentId': userId,
      'status': 'submitted',
      'documentPath': documentUrl,
      'signaturePath': null,
      'createdAt': FieldValue.serverTimestamp(),
      'signedBy': null,
      'signedAt': null,
    });
  }

  Stream<QuerySnapshot> getDocumentTemplates() {
    return _firestore.collection('document_templates').snapshots();
  }

  Future<void> deleteDocumentTemplate(String templateId) async {
    await _firestore.collection('document_templates').doc(templateId).delete();
  }

  Future<void> updateApplicationSignature({
    required String applicationId,
    required String signatureUrl,
    required String signedByUserId,
    required String role,
  }) async {
    final signatureField = '${role}SignatureUrl';
    final signedAtField = '${role}SignedAt';

    await _firestore.collection('applications').doc(applicationId).update({
      signatureField: signatureUrl,
      'signedBy': FieldValue.arrayUnion([signedByUserId]),
      signedAtField: FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getApplication(String applicationId) async {
    final docRef = _firestore.collection('applications').doc(applicationId);
    return await docRef.get();
  }

  Stream<QuerySnapshot> listenUserApplications(String userId) {
    return _firestore
        .collection('applications')
        .where('studentId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateApplication(
    String applicationId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('applications').doc(applicationId).update(data);
  }

  Future<void> deleteApplication(String applicationId) async {
    await _firestore.collection('applications').doc(applicationId).delete();
  }

  Future<void> reviewApplication({
    required String applicationId,
    required String reviewerId,
    required bool approved,
    String? reviewerSignatureUrl,
  }) async {
    final docRef = _firestore.collection('applications').doc(applicationId);
    final updateData = {
      'status': approved ? 'approved' : 'rejected',
      'reviewedBy': reviewerId,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    if (approved && reviewerSignatureUrl != null) {
      updateData['reviewerSignaturePath'] = reviewerSignatureUrl;
    }
    await docRef.update(updateData);
  }

  Future<void> addDocumentTemplateWithSettings({
    required String title,
    required String storagePath,
    required List<String> targetUsers,
    String? reviewerId,
    required bool requiresReview,
    required bool requiresSignature,
  }) async {
    await _firestore.collection('document_templates').add({
      'title': title,
      'storagePath': storagePath,
      'targetUsers': targetUsers,
      'reviewerId': reviewerId,
      'requiresReview': requiresReview,
      'requiresSignature': requiresSignature,
      'status': requiresReview ? 'pending_review' : 'approved',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
      'reviewHistory': [],
      'signatureHistory': [],
    });

    if (requiresReview && reviewerId != null) {
      await _firestore.collection('notifications').add({
        'userId': reviewerId,
        'type': 'template_review_request',
        'title': 'New Template Review Request',
        'message': 'A new template "$title" requires your review',
        'templateId': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    for (String userId in targetUsers) {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'new_template_available',
        'title': 'New Template Available',
        'message': 'A new template "$title" has been shared with you',
        'templateId': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
