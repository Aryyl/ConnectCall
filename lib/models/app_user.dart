import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_constants.dart';

/// Represents a ConnectCall user stored in Firestore.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.createdAt,
    this.blockedUsers = const [],
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime? createdAt;
  final List<String> blockedUsers;

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data[FirebaseConstants.fieldName] as String? ?? '',
      email: data[FirebaseConstants.fieldEmail] as String? ?? '',
      photoUrl: data[FirebaseConstants.fieldPhotoUrl] as String?,
      createdAt: (data[FirebaseConstants.fieldCreatedAt] as Timestamp?)
          ?.toDate(),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
    );
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data[FirebaseConstants.fieldName] as String? ?? '',
      email: data[FirebaseConstants.fieldEmail] as String? ?? '',
      photoUrl: data[FirebaseConstants.fieldPhotoUrl] as String?,
      createdAt: (data[FirebaseConstants.fieldCreatedAt] as Timestamp?)
          ?.toDate(),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirebaseConstants.fieldId: id,
      FirebaseConstants.fieldName: name,
      FirebaseConstants.fieldEmail: email,
      FirebaseConstants.fieldPhotoUrl: photoUrl,
      FirebaseConstants.fieldCreatedAt: createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'blockedUsers': blockedUsers,
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns initials for avatar fallback (e.g. "John Doe" → "JD").
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    List<String>? blockedUsers,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppUser && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppUser(id: $id, name: $name, email: $email)';
}
