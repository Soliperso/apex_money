import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalApp());
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('Minimal Test')),
        body: const Center(
          child: Text('Hello World!', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
