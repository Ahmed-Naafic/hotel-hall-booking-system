import 'package:flutter/material.dart';

void main() {
  runApp(const CustomerMobileApp());
}

class CustomerMobileApp extends StatelessWidget {
  const CustomerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Mobile',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Customer Mobile'),
              Text('Workspace initialized. No features implemented yet.'),
            ],
          ),
        ),
      ),
    );
  }
}
