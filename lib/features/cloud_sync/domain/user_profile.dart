import 'package:flutter/foundation.dart';

/// Model data profil akun pengguna BayHifi Cloud
@immutable
class UserProfile {
  final String id;
  final String username;
  final String? email;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      username: map['username'] as String? ?? 'Audiophile',
      email: map['email'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
