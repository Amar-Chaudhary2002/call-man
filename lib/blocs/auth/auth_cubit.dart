import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/user_model.dart';
import 'auth_state.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  AuthCubit() : super(AuthInitial());

  // Register with email + password
  Future<void> register({
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      emit(AuthLoading());
      log('Attempting registration for email: $email');

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // optionally store phone as displayName
      await result.user?.updateDisplayName(phoneNumber);

      emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
    } on FirebaseAuthException catch (e) {
      log('Registration error: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      log('Unexpected registration error: $e');
      emit(AuthError('Registration failed: $e'));
    }
  }

  // Login with email + password
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      log('Attempting login for email: $email');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
    } on FirebaseAuthException catch (e) {
      log('Login error: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      log('Unexpected login error: $e');
      emit(AuthError('Login failed: $e'));
    }
  }

  // Send / Resend OTP
  Future<void> sendOtp(String phoneNumber, {bool forceResend = false}) async {
    try {
      emit(AuthLoading());
      log('Sending OTP to: $phoneNumber (forceResend=$forceResend)');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResend ? _resendToken : null,
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
          _resendToken = resendToken;
          log('OTP sent. verificationId: $verificationId, resendToken: $resendToken');
          emit(OtpSent(
            message: 'OTP sent successfully',
            verificationId: verificationId,
            phoneNumber: phoneNumber,
            resendToken: resendToken,
          ));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          log('Code auto retrieval timeout. VerificationId: $verificationId');
        },
      );
    } catch (e) {
      log('Send OTP error: $e');
      emit(AuthError('Failed to send OTP: $e'));
    }
  }

  // Verify OTP (verificationId is required)
  Future<void> verifyOtp(String otp, String verificationId) async {
    try {
      emit(AuthLoading());
      log('Verifying OTP: $otp with verificationId: $verificationId');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final result = await _auth.signInWithCredential(credential);
      emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
    } on FirebaseAuthException catch (e) {
      log('OTP verification failed: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      log('OTP verification error: $e');
      emit(AuthError('OTP verification failed: $e'));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    emit(AuthInitial());
  }

  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(AuthError('Google sign-in was cancelled'));
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
    } on FirebaseAuthException catch (e) {
      log('Google sign-in error: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      log('Google sign-in unexpected error: $e');
      emit(AuthError('Google sign-in failed: $e'));
    }
  }

  // --- Password reset ---
  Future<void> sendPasswordReset(String email) async {
    try {
      emit(AuthLoading());
      await _auth.sendPasswordResetEmail(email: email.trim());
      emit(AuthError('Password reset email sent to $email'));
      // Use AuthError to show a non-success snack without changing route;
      // or define a new state like PasswordResetSent if you prefer.
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError('Failed to send reset email: $e'));
    }
  }

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
