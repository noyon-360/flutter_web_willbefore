import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entities.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String role; // Add role field
  final String? displayName; // Add displayName for consistency
  final bool isEmailVerified; // Add email verification status

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.role = 'user', // Default role
    this.displayName,
    this.isEmailVerified = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      role: data['role'] ?? 'user',
      isEmailVerified: data['isEmailVerified'] ?? false,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String,
      email: data['email'] ?? '',
      name: data['name'],
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int),
      isActive: data['isActive'] ?? true,
      role: data['role'] ?? 'user',
      isEmailVerified: data['isEmailVerified'] ?? false,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      phoneNumber: user.phoneNumber,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isActive: user.isActive,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'role': role,
      'isEmailVerified': isEmailVerified,
    };
  }

  // Add the missing copyWith method
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? displayName,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? role,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  // Helper getter for display name
  String get displayNameOrEmail => displayName ?? name ?? email;

  // Helper getter for initials
  String get initials {
    final nameToUse = displayName ?? name;
    if (nameToUse != null && nameToUse.isNotEmpty) {
      final names = nameToUse.split(' ');
      if (names.length > 1) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return names[0][0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}
