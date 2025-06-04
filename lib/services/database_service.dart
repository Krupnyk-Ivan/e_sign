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

  Future<DataSnapshot?> read({required String path}) async {
    final DatabaseReference ref = _firebaseDatabase.ref().child(path);
    final DataSnapshot snapshot = await ref.get();
    return snapshot.exists ? snapshot : null;
  }

  Future<String?> getCurrentUserRole() async {
    String id = FirebaseAuth.instance.currentUser!.uid;
    DataSnapshot? snapshot = await DatabaseService().read(
      path: "users/$id/role",
    );
    String role = snapshot!.value.toString();
    return role;
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
