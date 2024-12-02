import 'package:carrier/Screens/home/MainPageState.dart';
import 'package:carrier/Screens/identity/LoginPageState.dart';
import 'package:carrier/Screens/identity/RegisterPageState.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'PackDelivery',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: AuthCheck(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => MainPage(),
      },
    );
  }
}


