import 'package:call_app/core/constant/app_color.dart';
import 'package:call_app/core/image_constant.dart';
import 'package:call_app/presentation/auth/login_success_screen.dart';
import 'package:call_app/presentation/dashboard/home.dart';
import 'package:call_app/presentation/dashboard/recent_call_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    required this.verificationId,
    required this.phoneNumber,
    Key? key,
  }) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        } else {
          // Remove loader if present
          if (Navigator.canPop(context)) Navigator.pop(context);
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is AuthSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,

          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: 50.h),
                Image.asset(ImageConstant.lockicon, height: 150),
                SizedBox(height: 5.h),
                Text(
                  "Enter OTP",
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the OTP sent to ${widget.phoneNumber}",
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Pinput(
                  controller: _otpController,
                  length: 6,

                  defaultPinTheme: PinTheme(
                    width: 56.w,
                    height: 56.h,

                    textStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      // gradient: const LinearGradient(
                      //   colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      //   begin: Alignment.centerLeft,
                      //   end: Alignment.centerRight,
                      // ),
                      border: Border.all(color: Color(0xFFE5E7EB), width: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          offset: Offset(0, 10),
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Color(0x1A000000),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Auto-filled boxes for 6-digit OTP",
                  style: GoogleFonts.roboto(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  "Didn't get it?",
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    // You can call resend here if needed
                    context.read<AuthCubit>().sendOtp(widget.phoneNumber);
                  },
                  child: Text(
                    "Resend OTP",
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 278.h,
                  child: ElevatedButton(
                    onPressed: () {
                      final otp = _otpController.text.trim();
                      if (otp.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid 6-digit OTP'),
                          ),
                        );
                        return;
                      }
                      context.read<AuthCubit>().verifyOtp(
                        otp,
                        widget.verificationId,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      elevation: 0,
                      // shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Verify & Continue",
                          style: GoogleFonts.roboto(
                            color: Color(0xFF0F172A),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Icon(
                          CupertinoIcons.arrow_right,
                          color: Color(0xFF0F172A),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 50.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
