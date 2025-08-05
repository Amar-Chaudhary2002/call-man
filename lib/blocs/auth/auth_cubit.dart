// auth_cubit.dart
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  AuthCubit() : super(AuthInitial());

  // Register with email and password
  Future<void> register({
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      emit(AuthLoading());
      log('Attempting registration for email: $email'); // Added logging

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(phoneNumber);
        log('Registration successful for user: ${result.user!.uid}');
        emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
      }
    } on FirebaseAuthException catch (e) {
      log('Registration error: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      log('Unexpected error: $e');
      emit(AuthError('Registration failed: $e'));
    }
  }

  // Login with email and password
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      log('Attempting login for email: $email'); // Added logging

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        log('Login successful for user: ${result.user!.uid}');

        emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
      }
    } on FirebaseAuthException catch (e) {
      log('Login error: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      log('Unexpected error: $e');
      emit(AuthError('Login failed: $e'));
    }
  }

  // Send OTP to phone
  Future<void> sendOtp(String phoneNumber) async {
    try {
      emit(AuthLoading());
      log('Sending OTP to: $phoneNumber'); // Added logging

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (_auth.currentUser != null) {
              log('Auto verification successful');
              emit(AuthSuccess(UserModel.fromFirebaseUser(_auth.currentUser!)));
            }
          } catch (e) {
            log('Auto verification error: $e');
            emit(AuthError('Auto verification failed: $e'));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          log('Phone verification failed: ${e.code} - ${e.message}');
          emit(AuthError(_getErrorMessage(e.code)));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          log('OTP sent successfully. VerificationId: $verificationId');
          emit(
            OtpSent(
              message: 'OTP sent successfully',
              verificationId: verificationId,
              phoneNumber: phoneNumber,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          log('Code auto retrieval timeout. VerificationId: $verificationId');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      log('Send OTP error: $e');
      emit(AuthError('Failed to send OTP: $e'));
    }
  }

  // Verify OTP
  Future<void> verifyOtp(String otp, String verificationId) async {
    try {
      emit(AuthLoading());

      final vId = verificationId ?? _verificationId;

      if (vId == null) {
        log('No verificationId found');
        emit(AuthError('Please request OTP first'));
        return;
      }

      log('Verifying OTP: $otp with verificationId: $vId'); // Added logging

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: vId,
        smsCode: otp,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        log('OTP verification successful for user: ${result.user!.uid}');
        emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
      }
    } on FirebaseAuthException catch (e) {
      log('OTP verification failed: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      log('OTP verification error: $e');
      emit(AuthError('OTP verification failed: $e'));
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    emit(AuthInitial());
  }

  // Check if user is already logged in
  void checkAuthStatus() {
    final user = _auth.currentUser;
    if (user != null) {
      log('User already logged in: ${user.uid}');
      emit(AuthSuccess(UserModel.fromFirebaseUser(user)));
    } else {
      log('No user logged in');
      emit(AuthInitial());
    }
  }

  // Error message helper
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'invalid-phone-number':
        return 'Invalid phone number';
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      case 'configuration-not-found':
        return 'Firebase configuration error. Please check your setup';
      case 'app-not-authorized':
        return 'App not authorized. Please check Firebase configuration';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again';
      default:
        return 'Authentication failed: $code';
    }
  }
}
