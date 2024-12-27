import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tut4u/CustomerDashboard.dart';
import 'package:tut4u/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CustomerDashboard(
        name: "user",
      ),
    );
  }
}
