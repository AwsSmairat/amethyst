import 'package:equatable/equatable.dart';

final class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    required this.isActive,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final bool isActive;

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, email, fullName, role, phone, isActive];
}
