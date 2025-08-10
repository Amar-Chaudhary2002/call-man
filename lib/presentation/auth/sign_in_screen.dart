import 'package:call_app/core/constant/app_color.dart';
import 'package:call_app/core/image_constant.dart';
import 'package:call_app/presentation/auth/login_with_password_screen.dart';
import 'package:call_app/presentation/auth/otp_screen.dart';
import 'package:call_app/presentation/auth/sign_up_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final phoneController = TextEditingController();
  String _countryCode = '+91';
  late AuthCubit _authCubit;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit();
  }

  @override
  void dispose() {
    phoneController.dispose();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          print(
            '🔥 SignIn BlocListener - Auth state changed: ${state.runtimeType}',
          );

          if (state is AuthLoading) {
            print('🔥 SignIn - AuthLoading detected');
            _isDialogShowing = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          } else {
            // Remove loader if present
            if (_isDialogShowing && Navigator.canPop(context)) {
              print('🔥 SignIn - Closing loading dialog');
              Navigator.pop(context);
              _isDialogShowing = false;
            }
          }

          if (state is AuthError) {
            print('🔥 SignIn - AuthError detected: ${state.message}');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }

          if (state is OtpSent) {
            print(
              '🔥 SignIn - OtpSent detected! Verification ID: ${state.verificationId}',
            );
            print('🔥 SignIn - Phone number: ${state.phoneNumber}');

            // Navigate after a short delay to ensure dialog is closed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print(
                '🔥 SignIn - PostFrameCallback executing, mounted: $mounted',
              );
              if (mounted) {
                print('🔥 SignIn - Actually navigating to OTP screen');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtpScreen(
                      verificationId: state.verificationId,
                      phoneNumber: state.phoneNumber,
                    ),
                  ),
                );
                print('🔥 SignIn - Navigation to OTP screen completed');
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
                  SizedBox(height: 36.h),
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
                            phoneNumberField(
                              hint: "9876543210",
                              controller: phoneController,
                              initialCountryCode: _countryCode,
                              onCountryChanged: (val) {
                                setState(() => _countryCode = val);
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              textAlign: TextAlign.center,
                              '** By proceeding you are agreeing to CallMan’s Terms and conditions \n& Privacy Policy',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 9.2.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 127.h),
                            SizedBox(
                              width: 278.w,
                              child: ElevatedButton(
                                onPressed: () {
                                  final phone = phoneController.text.trim();
                                  if (phone.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Phone number required'),
                                      ),
                                    );
                                    return;
                                  }
                                  print(
                                    "🚀 SignIn - calling to otp screen with phone: $_countryCode$phone",
                                  );

                                  // Use the stored cubit instance directly
                                  _authCubit.sendOtp('$_countryCode$phone');
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
                                      "Send OTP",
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
                            SizedBox(height: 20.h),
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
                            SizedBox(height: 20.h),
                            SizedBox(
                              width: 278.w,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginWithPasswordScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    side: BorderSide(
                                      color: Color(0xFFE5E7EB),
                                      width: 0.1.w,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Login with password",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SignUpScreen(),
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

  Widget phoneNumberField({
    required String hint,
    required TextEditingController controller,
    required String initialCountryCode,
    required void Function(String) onCountryChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: initialCountryCode,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              dropdownColor: const Color(0xFF25316D),
              style: const TextStyle(color: Colors.white),
              items: <String>['+91', '+1', '+44', '+61']
                  .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) onCountryChanged(newValue);
              },
            ),
          ),
          const VerticalDivider(color: Colors.white24, thickness: 1, width: 20),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Colors.white70,
                  fontFamily: "Roboto",
                  fontSize: 13.63,
                  fontWeight: FontWeight.w400,
                ),

                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
