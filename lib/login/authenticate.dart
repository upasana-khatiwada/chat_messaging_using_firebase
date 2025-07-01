import 'package:chat_messaging_firebase/login/sign_in.dart';
import 'package:chat_messaging_firebase/login/signup.dart';
import 'package:flutter/material.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({Key? key}) : super(key: key);

  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showSignIn = true;

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1F1F1F), // Dark background
      body: showSignIn 
          ? SignIn(toggleView)
          : SignUp(toggleView),
    );
  }
}