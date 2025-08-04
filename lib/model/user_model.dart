// models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? displayName;

  UserModel({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.displayName,
  });

  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      phoneNumber: firebaseUser.phoneNumber,
      displayName: firebaseUser.displayName,
    );
  }
}

