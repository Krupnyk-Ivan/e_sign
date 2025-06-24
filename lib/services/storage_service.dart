import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required String userId,
    required String applicationId,
    required File file,
    required String filename,
  }) async {
    final path = 'documents/$userId/$applicationId/$filename';
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});

    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> uploadTemplate(File file, String fileName) async {
    final path = 'templates/$fileName';
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    print(ref.getDownloadURL());
    return ref.getDownloadURL();
  }

  String extractStoragePathFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;

    final startIndex = segments.indexOf('o');
    if (startIndex == -1 || startIndex + 1 >= segments.length) {
      throw FormatException('Invalid Firebase Storage URL');
    }

    return Uri.decodeFull(segments[startIndex + 1]);
  }

  Future<void> deleteFileByPath(String url) async {
    try {
      final path = extractStoragePathFromUrl(url);
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      print("Problem in storage service deleteFileByPath");

      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<String> uploadBytes({
    required String userId,
    required String applicationId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = 'documents/$userId/$applicationId/$filename';
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putData(bytes);
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<Uint8List?> downloadFile({
    required String userId,
    required String applicationId,
    required String filename,
  }) async {
    try {
      final path = 'documents/$userId/$applicationId/$filename';
      final ref = _storage.ref().child(path);
      final data = await ref.getData();
      return data;
    } catch (e) {
      print('Помилка завантаження файлу: $e');
      return null;
    }
  }
}
