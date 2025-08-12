import 'package:call_app/core/image_constant.dart';
import 'package:call_app/presentation/auth/sign_in_screen.dart';
import 'package:call_app/presentation/dashboard/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final _formKey = GlobalKey<FormState>();

  bool rememberMe = false;
  bool _isDialogShowing = false;

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // ---------- Loader helpers ----------
  void _showLoader() {
    if (!_isDialogShowing && mounted) {
      _isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }
  }

  void _hideLoader() {
    if (_isDialogShowing && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogShowing = false;
    }
  }

  // ---------- Validators ----------
  String? _emailValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[A-Za-z]{2,}$',
    ).hasMatch(s);
    return ok ? null : 'Please enter a valid email';
  }

  String? _phoneValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Phone number is required';
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6 || digits.length > 15)
      return 'Enter a valid phone number';
    return null;
  }

  String? _passwordValidator(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'[0-9]').hasMatch(s)) {
      return 'Password must contain letters and numbers';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          _showLoader();
        } else {
          _hideLoader();
        }
        if (state is AuthError) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        if (state is AuthSuccess) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration Successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
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

                // ---------- Card ----------
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24.sp),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 0.1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            offset: Offset(0, 25),
                            blurRadius: 50,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
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

                            // ---------- Inputs ----------
                            _inputField(
                              controller: phoneController,
                              hint: "Enter your phone number",
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: _phoneValidator,
                            ),
                            const SizedBox(height: 16),
                            _inputField(
                              controller: emailController,
                              hint: "Enter your email address",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 16),
                            _inputField(
                              controller: passController,
                              hint: "Enter your password",
                              icon: Icons.visibility_outlined,
                              obscureText: true,
                              validator: _passwordValidator,
                            ),
                            const SizedBox(height: 16),
                            _inputField(
                              controller: confirmController,
                              hint: "Re-Enter your password",
                              obscureText: true,
                              validator: (v) => v == passController.text
                                  ? null
                                  : 'Passwords do not match',
                            ),

                            const SizedBox(height: 2),

                            // ---------- Remember me ----------
                            Row(
                              children: [
                                Checkbox(
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                  value: rememberMe,
                                  onChanged: (val) =>
                                      setState(() => rememberMe = val ?? false),
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

                            // ---------- Sign up button ----------
                            SizedBox(
                              width: 278.w,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!(_formKey.currentState?.validate() ??
                                      false))
                                    return;
                                  context.read<AuthCubit>().register(
                                    email: emailController.text.trim(),
                                    password: passController.text.trim(),
                                    phoneNumber: phoneController.text.trim(),
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
                                        color: const Color(0xFF0F172A),
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
                                    const Icon(
                                      CupertinoIcons.arrow_right,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 19.h),

                            // ---------- Or continue with ----------
                            Row(
                              children: [
                                SizedBox(width: 33.w),
                                const Expanded(
                                  child: Divider(color: Colors.white24),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
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

                            // ---------- Google pill (as per new UI sizing) ----------
                            GestureDetector(
                              onTap: () =>
                                  context.read<AuthCubit>().signInWithGoogle(),
                              child: Container(
                                width: 167.w,
                                height: 25.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 0.1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Swap the asset path if yours differs:
                                    SvgPicture.asset(
                                      "assets/images/google icon.svg",
                                      height: 18,
                                      width: 18,
                                    ),
                                    const SizedBox(width: 6),
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
                            ),

                            SizedBox(height: 12.h),

                            // ---------- Sign in with OTP pill (as per new UI sizing) ----------
                            GestureDetector(
                              onTap: () {
                                // Take users to Sign In -> Send OTP flow
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
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
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

                            const SizedBox(height: 24),

                            // ---------- Footer link ----------
                            GestureDetector(
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
                ),
                // Optional security footer (mirror Sign In)
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Reusable input ----------
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
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
      validator: validator,
    );
  }
}
