import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:call_app/core/constant/app_color.dart';
import 'package:call_app/core/image_constant.dart';
import 'package:call_app/presentation/auth/sign_up_screen.dart';
import 'package:call_app/presentation/auth/otp_screen.dart';
import 'package:call_app/blocs/auth/auth_cubit.dart';
import 'package:call_app/blocs/auth/auth_state.dart';

import 'login_with_password_screen.dart';

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
          if (state is AuthLoading) {
            _isDialogShowing = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          } else {
            if (_isDialogShowing && Navigator.canPop(context)) {
              Navigator.pop(context);
              _isDialogShowing = false;
            }
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }

          if (state is OtpSent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpScreen(
                  verificationId: state.verificationId,
                  phoneNumber: state.phoneNumber,
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.primaryColor,
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
                        border: Border.all(color: Color(0xFFE5E7EB), width: 0.1),
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
                          phoneNumberField(
                            hint: "9876543210",
                            controller: phoneController,
                            initialCountryCode: _countryCode,
                            onCountryChanged: (val) {
                              setState(() => _countryCode = val);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone number required';
                              }
                              if (value.length != 10) {
                                return 'Phone number must be 10 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            textAlign: TextAlign.center,
                            '** By proceeding you are agreeing to CallMan’s Terms and conditions \n& Privacy Policy',
                            style: TextStyle(
                              fontFamily: "Roboto",
                              fontSize: 9.2.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 200.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (phoneController.text.trim().length != 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a valid phone number')),
                                  );
                                  return;
                                }
                                _authCubit.sendOtp('$_countryCode${phoneController.text.trim()}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text("Send OTP"),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
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
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text("Login with password"),
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

  Widget phoneNumberField({
    required String hint,
    required TextEditingController controller,
    required String initialCountryCode,
    required void Function(String) onCountryChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF25316D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
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
            child: TextFormField(
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
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }
}
