import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:call_app/core/constant/app_color.dart';
import 'button.dart';
import 'call_tracking.dart';

class PhoneKeyboardSheet extends StatefulWidget {
  final CallTrackingService callService;

  const PhoneKeyboardSheet({super.key, required this.callService});

  @override
  State<PhoneKeyboardSheet> createState() => _PhoneKeyboardSheetState();
}

class _PhoneKeyboardSheetState extends State<PhoneKeyboardSheet> {
  String phoneNumber = '';
  bool _isDialing = false;

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

  void _onKeypadTap(String value) {
    setState(() {
      phoneNumber += value;
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _onBackspace() {
    if (phoneNumber.isNotEmpty) {
      setState(() {
        phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1);
      });
      HapticFeedback.selectionClick();
    }
  }

  void _onCall() async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    setState(() {
      _isDialing = true;
    });

    log('📞 Attempting to call: $phoneNumber');

    try {
      final success = await widget.callService.makeCall(phoneNumber);

      if (mounted) {
        Navigator.pop(context);

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Calling $phoneNumber...')));
        } else {
          _showDialerError();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showDialerError();
      }
    } finally {
      setState(() {
        _isDialing = false;
      });
    }
  }

  void _showDialerError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Could not launch phone dialer. Please check if you have a phone app installed.',
        ),
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
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        children: [
          // Phone Number Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Text(
              phoneNumber.isEmpty ? 'Enter phone number' : phoneNumber,
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

          // Keypad
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 35,
                  mainAxisSpacing: 9,
                ),
                itemCount: keypadButtons.length,
                itemBuilder: (context, index) {
                  final button = keypadButtons[index];
                  return KeypadButton(
                    number: button['number']!,
                    // letters: button['letters']!,
                    onTap: () => _onKeypadTap(button['number']!),
                  );
                },
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 30, left: 40, right: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Empty space for balance
                const SizedBox(width: 70),
                // Call Button
                Expanded(
                  child: IconButton(
                    onPressed: _isDialing ? null : _onCall,
                    icon: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _isDialing
                            ? Colors.grey
                            : const Color(0xFF32CD32),
                        shape: BoxShape.circle,
                      ),
                      child: _isDialing
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _onBackspace,
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
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
