import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

      // Add debug logging
      if (kDebugMode) {
        print('Attempting registration for email: $email');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(phoneNumber);

        if (kDebugMode) {
          print('Registration successful for user: ${result.user!.uid}');
        }

        emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
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

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      emit(AuthError('Login failed: $e'));
    }
  }

  // Send OTP to phone
  Future<void> sendOtp(String phoneNumber) async {
    try {
      emit(AuthLoading());
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (_auth.currentUser != null) {
              emit(AuthSuccess(UserModel.fromFirebaseUser(_auth.currentUser!)));
            }
          } catch (e) {
            if (kDebugMode) {
              print('Auto verification error: $e');
            }
            emit(AuthError('Auto verification failed: $e'));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            print('Phone verification failed: ${e.code} - ${e.message}');
          }
          emit(AuthError(_getErrorMessage(e.code)));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          emit(OtpSent('OTP sent successfully'));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Send OTP error: $e');
      }
      emit(AuthError('Failed to send OTP: $e'));
    }
  }

  // Verify OTP
  Future<void> verifyOtp(String otp) async {
    try {
      emit(AuthLoading());

      if (_verificationId == null) {
        emit(AuthError('Please request OTP first'));
        return;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        emit(AuthSuccess(UserModel.fromFirebaseUser(result.user!)));
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('OTP verification failed: ${e.code} - ${e.message}');
      }
      emit(AuthError(_getErrorMessage(e.code)));
    } catch (e) {
      if (kDebugMode) {
        print('OTP verification error: $e');
      }
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
      emit(AuthSuccess(UserModel.fromFirebaseUser(user)));
    } else {
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
