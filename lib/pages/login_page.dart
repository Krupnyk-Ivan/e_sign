import 'package:e_sign/pages/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/auth_service.dart';
import '../pages/list_apply_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

@override
void initState() {}

class _LoginPageState extends State<LoginPage> {
  bool passwordVisible = true;
  bool isChecked = false;
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();
  String erorMessege = '';
  void signIn() async {
    try {
      await authService.value.signIn(
        email: controllerEmail.text,
        password: controllerPassword.text,
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const ListApplyPage()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        erorMessege = e.message ?? 'This is not working';
      });
      print(erorMessege);
    }
  }

  void register() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
        padding: new EdgeInsets.all(32),
        child: Center(
          child: new Column(
            children: <Widget>[
              SizedBox(height: 30),

              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Login',
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
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color.fromARGB(218, 16, 107, 245),
                      ),
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
                  Checkbox(
                    value: isChecked,
                    activeColor: Color.fromARGB(218, 13, 110, 253),
                    onChanged: (bool? value) {
                      setState(() {
                        isChecked = value!;
                      });
                    },
                  ),
                  Text(" Keep me signed in"),
                ],
              ),

              SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: ElevatedButton(
                      onPressed: () {
                        signIn();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Color.fromARGB(218, 13, 110, 253),
                      ),

                      child: Text(
                        'Login',
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
                      onPressed: signIn,
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

              Container(
                child: Center(
                  child: TextButton(
                    onPressed: register,
                    child: Text(
                      "Create an account",
                      style: TextStyle(
                        color: Color.fromARGB(218, 13, 110, 253),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
