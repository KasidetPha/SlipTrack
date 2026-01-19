import 'package:flutter/material.dart';

class NotiferPage extends StatelessWidget {
  const NotiferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifier"),
        centerTitle: true,
      ),
      body: Center(child: Text("Notifier Page")),
    );
  }
}