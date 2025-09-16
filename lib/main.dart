import 'package:chat_application/Presentation/auth_gate.dart';
import 'package:chat_application/Presentation/facedetection.dart';
import 'package:chat_application/Presentation/home.dart';
import 'package:chat_application/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qnmjmhyxyyhuiyobdebk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFubWptaHl4eXlodWl5b2JkZWJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwNzU4NjAsImV4cCI6MjA3MDY1MTg2MH0.YTNoraJyuxGOzhGvcratUWBfgK5sSKMQqmxTD_Hw7FE',
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustChat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: AuthGate(),
      home: FaceMatchScreen(),
    );
  }
}
