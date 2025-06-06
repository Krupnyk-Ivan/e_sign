import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_page.dart';
import 'role_based_nav.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPage createState() => _RegisterPage();
}

@override
void initState() {}

class _RegisterPage extends State<RegisterPage> {
  bool passwordVisible = true;
  bool isChecked = false;
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();
  TextEditingController controllerUsername = TextEditingController();

  String erorMessege = '';
  void register() async {
    try {
      final userCredential = await authService.value.createAccount(
        email: controllerEmail.text,
        password: controllerPassword.text,
      );
      final uid = userCredential.user!.uid;
      authService.value.updateUsername(username: controllerUsername.text);

      await DatabaseService().addUser(
        uid: uid,
        email: controllerEmail.text,
        role: 'appliciant',
      );
      String? role = await DatabaseService().getCurrentUserRole();
      print(userCredential.user!.displayName);
      await authService.value.signIn(
        email: controllerEmail.text,
        password: controllerPassword.text,
      );
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  RoleBasedNav(role: role),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        erorMessege = e.message ?? 'This is not working';
      });
      print(erorMessege);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: <Widget>[
              SizedBox(height: 30),

              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Create an account',
                  style: TextStyle(
                    fontSize: 30,
                    color: Color.fromARGB(255, 8, 8, 8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),

              TextFormField(
                controller: controllerUsername,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'John Doe',
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 144, 144, 144),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 1, 1, 1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              TextFormField(
                obscureText: passwordVisible,
                controller: controllerPassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '********',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 144, 144, 144),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        passwordVisible = !passwordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(erorMessege),
              SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: ElevatedButton(
                      onPressed: () {
                        register();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Color.fromARGB(218, 13, 110, 253),
                      ),

                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 253, 253),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.all(8), child: Text("OR")),
                  Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: ElevatedButton.icon(
                      onPressed: register,
                      icon: Icon(
                        MdiIcons.google,
                        color: const Color.fromARGB(255, 55, 55, 55),
                      ),
                      label: Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 54, 54, 54),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(50),
                        backgroundColor: Color.fromARGB(255, 207, 207, 207),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?"),
                  Container(
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      LoginPage(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                        child: Text(
                          "Sign in here",
                          style: TextStyle(
                            color: Color.fromARGB(218, 13, 110, 253),
                          ),
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
