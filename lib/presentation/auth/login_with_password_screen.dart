// Fixed LoginWithPasswordScreen with proper navigation handling

import 'dart:developer';

// import 'package:call_app/core/constant/app_color.dart';
import 'package:call_app/core/image_constant.dart';
import 'package:call_app/presentation/auth/forget_password.dart';
import 'package:call_app/presentation/auth/sign_in_screen.dart';
// import 'package:call_app/presentation/auth/login_success_screen.dart';
import 'package:call_app/presentation/auth/sign_up_screen.dart';
import 'package:call_app/presentation/dashboard/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
// import '../dashboard/home.dart';

class LoginWithPasswordScreen extends StatefulWidget {
  const LoginWithPasswordScreen({super.key});

  @override
  State<LoginWithPasswordScreen> createState() =>
      _LoginWithPasswordScreenState();
}

class _LoginWithPasswordScreenState extends State<LoginWithPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool rememberMe = false;
  bool obscurePassword = true;
  bool _isDialogShowing = false;
  late AuthCubit _authCubit; // Store reference to cubit

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(); // Create cubit instance
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    _authCubit.close(); // Close cubit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          log('🔥 BlocListener - Auth state changed: ${state.runtimeType}');

          if (state is AuthLoading) {
            log('🔥 BlocListener - AuthLoading detected');
            _isDialogShowing = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is AuthError) {
            log('🔥 BlocListener - AuthError detected: ${state.message}');
            // Close loading dialog if open
            if (_isDialogShowing && Navigator.canPop(context)) {
              Navigator.pop(context);
              _isDialogShowing = false;
            }

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }

          if (state is AuthSuccess) {
            log(
              '🔥 BlocListener - AuthSuccess detected! User: ${state.user.id}',
            );

            // Close loading dialog if open
            if (_isDialogShowing && Navigator.canPop(context)) {
              log('🔥 Closing loading dialog');
              Navigator.pop(context);
              _isDialogShowing = false;
            }

            log('🔥 About to navigate to LoginSuccessScreen');

            // Navigate immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              log('🔥 PostFrameCallback executing, mounted: $mounted');
              if (mounted) {
                log('🔥 Actually navigating now');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                  (route) => false,
                );
                log('🔥 Navigation completed');
              }
            });
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
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 50.h),
                  // Image.asset(ImageConstant.callmanicon),
                  Container(
                    height: 64.h,
                    width: 64.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text("LOGO"),
                  ),
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
                              "Welcome Back",
                              style: GoogleFonts.roboto(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              "Sign In to your account",
                              style: GoogleFonts.roboto(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Email/Phone field
                            _buildTextField(
                              controller: emailController,
                              hint: "Enter your email",
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),
                            // Password field with toggle
                            _buildTextField(
                              controller: passController,
                              hint: "Enter your password",
                              icon: obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              obscureText: obscurePassword,
                              onSuffixTap: () {
                                setState(
                                  () => obscurePassword = !obscurePassword,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  side: BorderSide(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                  value: rememberMe,
                                  onChanged: (value) {
                                    setState(() => rememberMe = value ?? false);
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
                                Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => ForgotPasswordScreen(),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              const begin = Offset(1.0, 0.0);
                                              const end = Offset.zero;
                                              const curve = Curves.ease;

                                              var tween = Tween(
                                                begin: begin,
                                                end: end,
                                              ).chain(CurveTween(curve: curve));

                                              return SlideTransition(
                                                position: animation.drive(
                                                  tween,
                                                ),
                                                child: child,
                                              );
                                            },
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Roboto",
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            SizedBox(
                              width: 278.w,
                              child: ElevatedButton(
                                onPressed: () {
                                  final email = emailController.text.trim();
                                  final password = passController.text.trim();

                                  if (email.isEmpty || password.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Email and password required',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  log('🚀 Attempting login with email: $email');
                                  _authCubit.loginWithEmail(
                                    email: email,
                                    password: password,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Login",
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
                            SizedBox(height: 25.h),
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
                            SizedBox(height: 25.h),
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
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const SignInScreen(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.ease;

                                          var tween = Tween(
                                            begin: begin,
                                            end: end,
                                          ).chain(CurveTween(curve: curve));

                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              child: Container(
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
                            ),
                            SizedBox(height: 32.h),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const SignUpScreen(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.ease;

                                          var tween = Tween(
                                            begin: begin,
                                            end: end,
                                          ).chain(CurveTween(curve: curve));

                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 10.sp,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Sign Up",
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
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
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/images/secutiry.svg"),
                      SizedBox(width: 5.w),
                      Text(
                        "Your data is protected with end-to-end encryption",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 9.2.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
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
    VoidCallback? onSuffixTap,
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(
            color: Colors.white70,
            fontSize: 12.63,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: icon != null
              ? GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(icon, color: Colors.white54),
                )
              : null,
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
