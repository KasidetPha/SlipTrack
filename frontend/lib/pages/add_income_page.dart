import 'package:flutter/material.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Income page"),
    );
  }
}