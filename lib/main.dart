import 'package:flutter/material.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const RedLightGreenLightApp());
}

class RedLightGreenLightApp extends StatelessWidget {
  const RedLightGreenLightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Light Green Light',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}