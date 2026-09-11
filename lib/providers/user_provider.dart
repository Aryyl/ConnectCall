import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

/// Provides the [UserService] instance.
final userServiceProvider = Provider<UserService>((ref) {
  return UserService(FirebaseFirestore.instance);
});

/// Streams all registered users, excluding the currently logged in user.
/// If there is no authenticated user, it emits an empty list.
final contactsProvider = StreamProvider<List<AppUser>>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = authState.valueOrNull;

  if (currentUser == null) {
    return Stream.value([]);
  }

  final userService = ref.watch(userServiceProvider);
  return userService.streamUsers(currentUser.uid);
});
