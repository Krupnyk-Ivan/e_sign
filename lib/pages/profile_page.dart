import 'package:e_sign/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dart:io';

import 'package:e_sign/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:e_sign/services/document_sign_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  final storage = FlutterSecureStorage();
  final algorithm = Ed25519();
  String jksPath = '';
  String jksPassword = '';
  String jksAlias = '';
  String generatedPfxPath = '';

  String jkUserId = '';
  static const platform = MethodChannel('document_signer');
  String? url = AuthService().currentUser!.photoURL;
  String? username = AuthService().currentUser?.displayName;
  void loginOut() {
    AuthService().signOut();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> generatePfx() async {
    try {
      final exists = await platform.invokeMethod<bool>('pfxExists', {
        'alias': jksAlias.isNotEmpty ? jksAlias : 'testalias',
      });

      if (exists == true) {
        print(" PFX already exists, skipping generation");
        return;
      }

      final pfxPath = DocumentSignService.generatePfx(
        password: 'testpass',
        alias: 'testalias',
        userId: authService.value.currentUser!.uid,
      );
      print(authService.value.currentUser!.uid);

      if (pfxPath != null) {
        print(' PFX згенеровано: $pfxPath');
      }
    } catch (e) {
      _showError('Помилка генерації PFX: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile"),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  url != null
                      ? NetworkImage(url!)
                      : NetworkImage(
                        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSwVLdSDmgrZN7TkzbHJb8dD0_7ASUQuERL2A&s",
                      ),
            ),
            SizedBox(height: 12),
            Text(
              username ?? "No name available",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 30),

            _buildSettingsCard(
              icon: Icons.vpn_key,
              title: "Add E-Key",
              onTap: generatePfx,
            ),

            _buildSettingsCard(
              icon: Icons.edit,
              title: "Edit Profile",
              onTap: () {},
            ),

            Divider(height: 40),

            _buildSettingsCard(
              icon: Icons.logout,
              title: "Log Out",
              onTap: loginOut,
              iconColor: Colors.red,
              textColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSettingsCard({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Color iconColor = Colors.black,
  Color textColor = Colors.black,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    ),
  );
}
