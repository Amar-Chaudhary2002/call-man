import 'package:call_app/presentation/dashboard/home.dart';
import 'package:call_app/presentation/dashboard/recent_call_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:call_app/core/constant/app_color.dart';
import 'package:call_app/core/image_constant.dart';
import 'package:call_app/presentation/auth/sign_in_screen.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();
  bool rememberMe = false;

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          // Optionally show a loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
        } else {
          // Remove loader if any
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration Successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DashboardScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          // color: Color(0xFF0F172A),
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 50.h),
                Image.asset(ImageConstant.callmanicon),
                SizedBox(height: 1.h),
                Text(
                  "CallMan",
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Manage your calls efficiently",
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 30.h),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24.sp),
                        border: Border.all(
                          color: Color(0xFFE5E7EB),
                          width: 0.1,
                        ),
                        // gradient: const LinearGradient(
                        //   colors: [Color(0xFF082046), Color(0xFF45006E)],
                        //   begin: Alignment.topLeft,
                        //   end: Alignment.bottomRight,
                        // ),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 6.h),
                          Text(
                            "Welcome",
                            style: GoogleFonts.roboto(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            "Sign Up to your account",
                            style: GoogleFonts.roboto(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: phoneController,
                            hint: "Enter your phone number",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: emailController,
                            hint: "Enter your email address",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: passController,
                            hint: "Enter your password",
                            icon: Icons.visibility_outlined,
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: confirmController,
                            hint: "Re-Enter your password",
                            obscureText: true,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Checkbox(
                                side: BorderSide(color: Colors.white, width: 1),
                                value: rememberMe,
                                onChanged: (val) {
                                  setState(() {
                                    rememberMe = val ?? false;
                                  });
                                },
                                activeColor: Colors.white,
                                checkColor: Colors.black,
                              ),
                              Text(
                                "Remember me",
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: 278.w,
                            child: ElevatedButton(
                              onPressed: () {
                                final email = emailController.text.trim();
                                final phone = phoneController.text.trim();
                                final password = passController.text.trim();
                                final confirm = confirmController.text.trim();

                                if (email.isEmpty ||
                                    phone.isEmpty ||
                                    password.isEmpty ||
                                    confirm.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("All fields are required"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (password != confirm) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Passwords do not match"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                // Trigger registration
                                context.read<AuthCubit>().register(
                                  email: email,
                                  password: password,
                                  phoneNumber: phone,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Sign up",
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
                          SizedBox(height: 19.h),
                          Row(
                            children: [
                              SizedBox(width: 33.w),
                              const Expanded(
                                child: Divider(color: Colors.white24),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "Or continue with",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Colors.white24),
                              ),
                              SizedBox(width: 33.w),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Container(
                            width: 167.w,
                            height: 25.h,
                            // margin: EdgeInsets.only(left: 35, right: 35),
                            // padding: EdgeInsets.symmetric(
                            //   // horizontal: 20,
                            //   vertical: 7,
                            // ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Color(0xFFE5E7EB),
                                width: 0.1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  "assets/images/google icon.svg",
                                  height: 30,
                                  width: 30,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "Continue with google",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            width: 167.w,
                            height: 25.h,
                            // margin: EdgeInsets.only(left: 35, right: 35),
                            // padding: EdgeInsets.symmetric(
                            //   // horizontal: 20,
                            //   vertical: 7,
                            // ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Color(0xFFE5E7EB),
                                width: 0.1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Sign in with OTP",
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignInScreen(),
                                ),
                              );
                            },
                            child: const Text.rich(
                              TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(color: Colors.white70),
                                children: [
                                  TextSpan(
                                    text: "Sign in",
                                    style: TextStyle(
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
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
