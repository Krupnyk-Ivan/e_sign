import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  _ResetPasswordPage createState() => _ResetPasswordPage();
}

class _ResetPasswordPage extends State<ResetPasswordPage> {
  String erorMessege = "";
  TextEditingController controllerEmail = TextEditingController();
  void resetPassword() async {
    try {
      await authService.value.resetPassword(email: controllerEmail.text);
      showSnackBar();
    } on FirebaseAuthException catch (e) {
      setState(() {
        erorMessege = e.message ?? 'This is not working';
      });
      print(erorMessege);
    }
  }

  void showSnackBar() {
    ScaffoldMessenger.of(context).clearMaterialBanners();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Check your email "),
        showCloseIcon: true,
        backgroundColor: Color.fromARGB(218, 13, 110, 253),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: true),
      body: Container(
        padding: EdgeInsets.all(32),

        child: Center(
          child: Column(
            children: <Widget>[
              SizedBox(height: 30),

              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Forgot password?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Enter your email address to get the passwrod reset link",
                  style: TextStyle(
                    color: Color.fromARGB(255, 144, 144, 144),
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email address",
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextFormField(
                controller: controllerEmail,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'hello@example.com',
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 144, 144, 144),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: ElevatedButton(
                      onPressed: () {
                        resetPassword();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Color.fromARGB(218, 13, 110, 253),
                      ),

                      child: Text(
                        'Password reset',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 253, 253),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
