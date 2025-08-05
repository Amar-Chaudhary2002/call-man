import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? displayName;

  UserModel({required this.id, this.email, this.phoneNumber, this.displayName});

  static UserModel fromFirebaseUser(User user) {
    log('🔥 UserModel.fromFirebaseUser called');
    log('🔥 UserModel - User UID: ${user.uid}');
    log('🔥 UserModel - User email: ${user.email}');
    log('🔥 UserModel - User phone: ${user.phoneNumber}');

    return UserModel(
      id: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
    );
  }
}
