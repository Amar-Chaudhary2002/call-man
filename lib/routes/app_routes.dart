import 'package:call_app/presentation/auth/login_success_screen.dart';
import 'package:call_app/presentation/auth/login_with_password_screen.dart';
import 'package:call_app/presentation/auth/otp_screen.dart';
import 'package:call_app/presentation/auth/sign_in_screen.dart';
import 'package:call_app/presentation/auth/sign_up_screen.dart';
import 'package:call_app/presentation/dashboard/call_features/call_end_screen.dart';
import 'package:call_app/presentation/dashboard/recent_call_screen.dart';
import 'package:call_app/presentation/onboarding/block_spam_screen.dart';
import 'package:call_app/presentation/onboarding/custom_dialer_screen.dart';
import 'package:call_app/presentation/onboarding/smart_log_screen.dart';
import 'package:call_app/presentation/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String blockSpam = '/block-spam';
  static const String smartLog = '/smart-log';
  static const String customDialer = '/custom-dialer';
  static const String signUp = '/sign-up';
  static const String signIn = '/sign-in';
  static const String otp = '/otp';
  static const String loginSuccess = '/login-success';
  static const String loginWithPassword = '/login-password';
  static const String home = '/home';
  static const String callInteractionScreen = '/call-interaction';

  static final routes = <String, WidgetBuilder>{
    welcome: (_) => const WelcomeScreen(),
    blockSpam: (_) => const BlockSpamScreen(),
    smartLog: (_) => const SmartLogScreen(),
    customDialer: (_) => const CustomDialerScreen(),
    signUp: (_) => const SignUpScreen(),
    signIn: (_) => const SignInScreen(),
    otp: (_) => OtpScreen(phoneNumber: '', verificationId: ''),
    // loginSuccess: (_) => const LoginSuccessScreen(),
    loginWithPassword: (_) => const LoginWithPasswordScreen(),
    home: (_) => const RecentCallScreen(),
    callInteractionScreen: (_) => const CallInteractionScreen(),
  };

  // You can also add a method to navigate with parameters
  static void navigateToCallInteraction(
      BuildContext context, {
        String? phoneNumber,
        String? callState,
        String? callId,
        String? timestamp,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallInteractionScreen(
          phoneNumber: phoneNumber,
          callState: callState,
          callId: callId,
          timestamp: timestamp,
        ),
      ),
    );
  }
}