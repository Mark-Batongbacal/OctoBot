import 'package:flutter/material.dart';

void main() => runApp(const OctoBotApp());

class OctoBotApp extends StatelessWidget {
  const OctoBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('OctoBot'))),
    );
  }
}
