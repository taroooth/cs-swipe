import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CsvSwipeApp());
}

class CsvSwipeApp extends StatelessWidget {
  const CsvSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSV Swipe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}
