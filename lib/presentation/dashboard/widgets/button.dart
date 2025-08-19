import 'package:flutter/material.dart';

class KeypadButton extends StatelessWidget {
  final String number;
  // final String letters;
  final VoidCallback onTap;

  const KeypadButton({
    super.key,
    required this.number,
    // required this.letters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w300,
            ),
          ),
          // if (letters.isNotEmpty)
          //   Text(
          //     letters,
          //     style: const TextStyle(color: Colors.white54, fontSize: 10),
          //   ),
        ],
      ),
    );
  }
}
