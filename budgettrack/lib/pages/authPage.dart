import 'package:budgettrack/pages/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'emailVrification.dart';
import 'homePage.dart';
import 'loginOrReg.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //user logged in
          if (snapshot.hasData) {
            return const EmailVerification();
          }
          //user not logged in
          else {
            return const LoginOrRegiter();
          }
        },
      ),
    );
  }
}