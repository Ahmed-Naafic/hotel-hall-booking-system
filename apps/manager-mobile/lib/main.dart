import 'package:flutter/material.dart';

void main() {
  runApp(const ManagerMobileApp());
}

class ManagerMobileApp extends StatelessWidget {
  const ManagerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Manager Mobile',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hotel Manager Mobile'),
              Text('Workspace initialized. No features implemented yet.'),
            ],
          ),
        ),
      ),
    );
  }
}
