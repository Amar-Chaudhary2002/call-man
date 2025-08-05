import 'package:call_app/model/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserModel user;
  AuthSuccess(this.user);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class OtpSent extends AuthState {
  final String message;
  final String verificationId;
  final String phoneNumber;

  OtpSent({
    required this.message,
    required this.verificationId,
    required this.phoneNumber,
  });
}
