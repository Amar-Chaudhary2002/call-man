// auth_state.dart
import 'package:equatable/equatable.dart';
import '../../model/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserModel user;

  const AuthSuccess(this.user);

  @override
  List<Object> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class OtpSent extends AuthState {
  final String message;
  final String verificationId;
  final String phoneNumber;

  const OtpSent({
    required this.message,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [message, verificationId, phoneNumber];
}