import 'package:flutter/material.dart';

class LeadScreen extends StatelessWidget {
  const LeadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Lead Screen',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
