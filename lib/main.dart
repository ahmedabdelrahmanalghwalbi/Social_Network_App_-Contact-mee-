import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/pages/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'socialnetworkapp',
      debugShowCheckedModeBanner: false,
      home: Home(),
      theme: ThemeData(
        primaryColor: Color(0xFF7b5244),
        accentColor: Color(0XFF333333),
      ),
    );
  }
}
//--mainColor:##7b5244;
//--subColor:#333333;