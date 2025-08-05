// Fixed LoginWithPasswordScreen with proper navigation handling

import 'dart:developer';

import 'package:call_app/core/constant/app_color.dart';
import 'package:call_app/core/image_constant.dart';
import 'package:call_app/presentation/auth/login_success_screen.dart';
import 'package:call_app/presentation/auth/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';

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
                    builder: (context) => const LoginSuccessScreen(),
                  ),
                  (route) => false,
                );
                log('🔥 Navigation completed');
              }
            });
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.primaryColor,
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 50.h),
                Image.asset(ImageConstant.callmanicon),
                SizedBox(height: 1.h),
                Text(
                  "CallMan",
                  style: TextStyle(
                    fontFamily: "Roboto",
                    color: Colors.white,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Manage your calls efficiently",
                  style: TextStyle(
                    fontFamily: "Roboto",
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 36.h),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(23.sp),
                        border: Border.all(
                          color: Color(0xFFE5E7EB),
                          width: 0.1,
                        ),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF082046), Color(0xFF45006E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                            style: TextStyle(
                              fontFamily: "Roboto",
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            "Sign In to your account",
                            style: TextStyle(
                              fontFamily: "Roboto",
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
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(() => rememberMe = value ?? false);
                                },
                                activeColor: Colors.white,
                                checkColor: Colors.black,
                              ),
                              Text(
                                "Remember me",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Roboto",
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Spacer(),
                              Text(
                                "Forgot password?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Roboto",
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 200.h),
                          SizedBox(
                            width: double.infinity,
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
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignUpScreen(),
                                ),
                              );
                            },
                            child: const Text.rich(
                              TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: Colors.white70),
                                children: [
                                  TextSpan(
                                    text: "Sign Up",
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
                SizedBox(height: 5.h),
                const Text(
                  "Your data is protected with end-to-end encryption",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
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
    VoidCallback? onSuffixTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.white,
          fontFamily: "Roboto",
          fontSize: 13.63,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFF25316D),
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
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
      ),
    );
  }
}
