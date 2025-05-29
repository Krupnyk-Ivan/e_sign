import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

@override
void initState() {}

class _LoginPageState extends State<LoginPage> {
  bool passwordVisible = true;
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();
  String erorMessege = '';
  void signIn() async {
    try {
      await authService.value.signIn(
        email: controllerEmail.text,
        password: controllerPassword.text,
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
                  ),
                ),
              ),
              SizedBox(height: 20),

              Align(alignment: Alignment.centerLeft, child: Text('Email')),

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
                  Text('Password', style: TextStyle(fontSize: 16)),
                  TextButton(onPressed: () {}, child: Text('Forgot Password?')),
                ],
              ),

              TextFormField(
                obscureText: passwordVisible,
                controller: controllerPassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your password',
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
                        signIn();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),

                      child: Text('Login'),
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
