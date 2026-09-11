import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/app_user.dart';

/// Manages user document CRUD operations in Firestore.
///
/// Phase 3: Full implementation (fetch users, search, get profile).
class UserService {
  UserService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Returns a stream of all registered users, excluding the user with [currentUserId].
  /// This allows the contacts list to update in real-time if new users register.
  Stream<List<AppUser>> streamUsers(String currentUserId) {
    try {
      return _firestore
          .collection(FirebaseConstants.usersCollection)
          .where(FirebaseConstants.fieldId, isNotEqualTo: currentUserId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw UnknownException('Failed to fetch users: $e');
    }
  }

  /// Updates the photo URL for the user with [userId].
  Future<void> updatePhotoUrl(String userId, String photoUrl) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({'photoUrl': photoUrl});
    } catch (e) {
      throw UnknownException('Failed to update photo URL: $e');
    }
  }

  /// Blocks a user by adding their ID to the blockedUsers array.
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId])
      });
    } catch (e) {
      throw UnknownException('Failed to block user: $e');
    }
  }

  /// Unblocks a user by removing their ID from the blockedUsers array.
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId])
      });
    } catch (e) {
      throw UnknownException('Failed to unblock user: $e');
    }
  }
}
