import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 40.h),

                // Lock icon
                CircleAvatar(
                  radius: 40.r,
                  backgroundColor: Colors.white,
                  child: Icon(
                    CupertinoIcons.lock_fill,
                    size: 32.sp,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 30.h),
                // Main Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24.sp),
                      border: Border.all(color: Color(0xFFE5E7EB), width: 0.1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x66000000),
                          offset: const Offset(0, 25),
                          blurRadius: 50,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Forgot Password?",
                          style: GoogleFonts.roboto(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Don't worry! It happens. Please enter the email address associated with your account.",
                          style: GoogleFonts.roboto(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 42.h),

                        // Email field
                        _buildTextField(
                          controller: emailController,
                          hint: "Enter your email address",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        SizedBox(height: 58.h),

                        // Send Reset Link button
                        SizedBox(
                          width: 285.w,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            onPressed: () {
                              // Reset password logic here
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Send Reset Link",
                                  style: GoogleFonts.roboto(
                                    color: const Color(0xFF171F2C),
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                const Icon(
                                  CupertinoIcons.arrow_right,
                                  color: Color(0xFF0F172A),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          "Remember your password?",
                          style: GoogleFonts.roboto(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Back to Sign In
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Back to Sign In",
                            style: GoogleFonts.roboto(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 54.h),

                // Help box
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1220),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 0.1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.question_circle_fill,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              "Need Help?",
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.w),
                        Text(
                          "If you don't receive an email within 5 minutes, check your spam folder or contact our support team.",
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w400,
                            color: Colors.white60,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(
            color: Colors.white70,
            fontSize: 12.63,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: icon != null ? Icon(icon, color: Colors.white54) : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.1),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.1),
          ),
          filled: false,
        ),
      ),
    );
  }
}
