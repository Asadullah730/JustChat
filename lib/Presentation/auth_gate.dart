import 'dart:ffi';

import 'package:chat_application/Presentation/home.dart';
import 'package:chat_application/Presentation/login.dart';
import 'package:chat_application/Presentation/profilesetup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<bool> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data?['name'] != null && data?['photoUrl'] != null) {
          return true;
        } else {
          return false;
        }
      }
    }
    return false;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return LoginScreen();
    } else {
      return FutureBuilder(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            if (snapshot.hasData && snapshot.data == true) {
              if (kDebugMode) {
                print(
                  "USER LOGGED IN : ${currentUser.uid} , PROFILE SETUP DONE : ${snapshot.data}",
                );
              }
              return const HomeScreen();
            } else {
              return ProfileSetupScreen(uid: currentUser.uid);
            }
          }
        },
      );
    }
  }
}
