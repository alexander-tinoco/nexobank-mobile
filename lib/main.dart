import 'package:flutter/material.dart';

void main() {
  runApp(const NexoBankApp());
}

class NexoBankApp extends StatelessWidget {
  const NexoBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'NexoBank',
      home: Scaffold(
        body: Center(child: Text('NexoBank')),
      ),
    );
  }
}
