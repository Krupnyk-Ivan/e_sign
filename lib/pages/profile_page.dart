import 'package:e_sign/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Container(
        padding: EdgeInsets.all(32),
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            Column(
              children: [
                SizedBox(height: 10),

                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      (url) != null
                          ? NetworkImage(url!)
                          : NetworkImage(
                            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSwVLdSDmgrZN7TkzbHJb8dD0_7ASUQuERL2A&s",
                          ),
                ),
                SizedBox(height: 10),

                Text(
                  username ?? "No name available",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40),

                Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text("Add E key"),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text("Edit profile"),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text("Log out"),
                    trailing: Icon(Icons.chevron_right),
                    onTap: loginOut,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
