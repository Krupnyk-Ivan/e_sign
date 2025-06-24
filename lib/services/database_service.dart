import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  Future<void> create({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final DatabaseReference ref = _firebaseDatabase.ref().child(path);
    await ref.set(data);
  }

  Stream<List<Map<String, String>>> getUsersStream() {
    final ref = FirebaseDatabase.instance.ref('users');
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final List<Map<String, String>> users = [];
      data.forEach((key, value) {
        users.add({
          'id': key,
          'email': value['email'] ?? '',
          'role': value['role'] ?? 'applicant',
        });
      });
      return users;
    });
  }

  Future<DataSnapshot?> read({required String path}) async {
    final DatabaseReference ref = _firebaseDatabase.ref().child(path);
    final DataSnapshot snapshot = await ref.get();
    return snapshot.exists ? snapshot : null;
  }

  Future<List<Map<String, String>>> getUsers() async {
    final snapshot = await DatabaseService().read(path: "users/");
    if (snapshot == null || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final users =
        data.entries.map<Map<String, String>>((entry) {
          final userData = Map<String, dynamic>.from(entry.value as Map);
          return {
            'id': entry.key,
            'email': userData['email']?.toString() ?? 'no-email',
            'role': userData['role']?.toString() ?? 'no-role',
          };
        }).toList();

    return users;
  }

  Future<void> update({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final DatabaseReference ref = _firebaseDatabase.ref().child(path);
    await ref.update(data);
  }

  Future<String?> getCurrentUserRole() async {
    String id = FirebaseAuth.instance.currentUser!.uid;
    DataSnapshot? snapshot = await DatabaseService().read(
      path: "users/$id/role",
    );
    String role = snapshot!.value.toString();
    return role;
  }

  Future<List<Map<String, dynamic>>> getReviewers() async {
    List<Map<String, dynamic>> allReviewers = [];

    try {
      print("Fetching reviewers from Realtime Database...");
      final DatabaseService _databaseService = DatabaseService();
      final realtimeDbSnapshot = await _databaseService.read(path: "users/");

      if (realtimeDbSnapshot != null && realtimeDbSnapshot.value != null) {
        final data = Map<String, dynamic>.from(realtimeDbSnapshot.value as Map);
        data.forEach((key, value) {
          print(value);
          if (value['role'] == 'reviewer') {
            final reviewerData = Map<String, dynamic>.from(value);
            reviewerData['id'] = key;
            allReviewers.add(reviewerData);
          }
        });
        print("Realtime DB reviewers found: ${data.length}");
      } else {
        print(
          "No data found or snapshot is null in Realtime Database for users.",
        );
      }
    } catch (e) {
      print('Error getting reviewers from Realtime Database: $e');
    }
    final Map<String, Map<String, dynamic>> uniqueReviewers = {};
    for (var reviewer in allReviewers) {
      uniqueReviewers[reviewer['id']] = reviewer;
    }
    print(uniqueReviewers.values.toList());
    return uniqueReviewers.values.toList();
  }

  Future<void> addUser({
    required String uid,
    required String email,
    required String role,
  }) async {
    final String path = 'users/$uid';

    final Map<String, dynamic> userData = {'email': email, 'role': role};

    await create(path: path, data: userData);
  }
}
