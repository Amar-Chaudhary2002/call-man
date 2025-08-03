import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:call_app/core/constant/app_color.dart';

class PhoneKeyboardSheet extends StatefulWidget {
  const PhoneKeyboardSheet({super.key});

  @override
  State<PhoneKeyboardSheet> createState() => _PhoneKeyboardSheetState();
}

class _PhoneKeyboardSheetState extends State<PhoneKeyboardSheet> {
  String phoneNumber = '';
  final List<Map<String, String>> keypadButtons = [
    {'number': '1', 'letters': ''},
    {'number': '2', 'letters': 'ABC'},
    {'number': '3', 'letters': 'DEF'},
    {'number': '4', 'letters': 'GHI'},
    {'number': '5', 'letters': 'JKL'},
    {'number': '6', 'letters': 'MNO'},
    {'number': '7', 'letters': 'PQRS'},
    {'number': '8', 'letters': 'TUV'},
    {'number': '9', 'letters': 'WXYZ'},
    {'number': '*', 'letters': ''},
    {'number': '0', 'letters': '+'},
    {'number': '#', 'letters': ''},
  ];

  void _onKeypadTap(String value) => setState(() => phoneNumber += value);

  void _onBackspace() {
    if (phoneNumber.isNotEmpty) {
      setState(
        () => phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1),
      );
    }
  }

  void _onCall() async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    final Uri url = Uri.parse('tel:$phoneNumber');
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Calling $phoneNumber...')));
      } else {
        _showDialerError();
      }
    } catch (e) {
      _showDialerError();
    }
  }

  void _showDialerError() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not launch phone dialer.'),
        action: SnackBarAction(
          label: 'Copy Number',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: phoneNumber));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number copied to clipboard')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Text(
              phoneNumber.isEmpty ? '+1 (555) 123' : phoneNumber,
              style: TextStyle(
                color: phoneNumber.isEmpty
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 40,
                  mainAxisSpacing: 9,
                ),
                itemCount: keypadButtons.length,
                itemBuilder: (context, index) {
                  final button = keypadButtons[index];
                  return KeypadButton(
                    number: button['number']!,
                    letters: button['letters']!,
                    onTap: () => _onKeypadTap(button['number']!),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30, left: 40, right: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 70),
                Expanded(
                  child: IconButton(
                    onPressed: _onCall,
                    icon: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFF252424),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _onBackspace,
                  icon: SvgPicture.asset('assets/icons/close.svg'),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KeypadButton extends StatelessWidget {
  final String number;
  final String letters;
  final VoidCallback onTap;

  const KeypadButton({
    super.key,
    required this.number,
    required this.letters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}
