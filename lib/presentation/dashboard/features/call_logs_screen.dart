import 'package:flutter/material.dart';

class Page1 extends StatelessWidget {
  const Page1({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Call Logs",
        style: TextStyle(
          color: Colors.green[900],
          fontSize: 45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
