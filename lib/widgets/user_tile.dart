import 'package:flutter/material.dart';

/// Contact list tile — Phase 3 & 5 full implementation.
/// Stub to satisfy imports during Phase 1.
class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.name, this.isOnline = false});
  final String name;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(name));
  }
}
