import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/app_user.dart';
import '../../providers/call_history_provider.dart';
import '../../providers/calling_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }
    } catch (e) {
      debugPrint('ContactsScreen: permission request error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final presenceAsync = ref.watch(presenceMapProvider);
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final presenceMap = presenceAsync.valueOrNull ?? {};
    final currentUser = currentUserAsync.valueOrNull;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (contacts) {
          if (contacts.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group contacts alphabetically
          final sortedContacts = List<AppUser>.from(contacts)..sort((a, b) => a.name.compareTo(b.name));
          final Map<String, List<AppUser>> grouped = {};
          for (final user in sortedContacts) {
            final firstLetter = user.name.isNotEmpty ? user.name[0].toUpperCase() : '#';
            grouped.putIfAbsent(firstLetter, () => []).add(user);
          }

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ...grouped.entries.map((entry) {
                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildGroupHeader(context, entry.key, entry.value.length),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final user = entry.value[index];
                          final isOnline = presenceMap[user.id] ?? false;
                          final isBlocked = currentUser?.blockedUsers.contains(user.id) ?? false;
                          
                          return _ContactTile(
                            user: user,
                            isOnline: isOnline,
                            isBlocked: isBlocked,
                            onAudioCall: () => startAudioCall(user),
                            onVideoCall: () => startVideoCall(user),
                            onBlockToggle: () async {
                              if (currentUser == null) return;
                              final userService = ref.read(userServiceProvider);
                              try {
                                if (isBlocked) {
                                  await userService.unblockUser(currentUser.id, user.id);
                                } else {
                                  await userService.blockUser(currentUser.id, user.id);
                                }
                                ref.invalidate(currentUserProfileProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update block status: $e')),
                                  );
                                }
                              }
                            },
                          );
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ],
                );
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for FAB
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Contacts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }



  Widget _buildGroupHeader(BuildContext context, String letter, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 1),
          ),
          const SizedBox(width: 12),
          Text(
            '$count contacts',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Text('No contacts found.'),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.user,
    required this.isOnline,
    required this.isBlocked,
    required this.onAudioCall,
    required this.onVideoCall,
    required this.onBlockToggle,
  });

  final AppUser user;
  final bool isOnline;
  final bool isBlocked;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;
  final VoidCallback onBlockToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBlocked ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: user.photoUrl != null
                    ? _buildAvatarImageProvider(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(
                        user.initials,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isBlocked 
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBlocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Blocked',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isBlocked ? const Color(0xFF9CA3AF) : (isOnline ? const Color(0xFF10B981) : const Color(0xFF9CA3AF)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isBlocked ? 'Offline' : (isOnline ? 'Online' : 'Offline'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isBlocked ? const Color(0xFF9CA3AF) : (isOnline ? const Color(0xFF10B981) : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          if (!isBlocked) ...[
            _SmallIconButton(
              icon: Icons.videocam_outlined,
              onTap: onVideoCall,
            ),
            const SizedBox(width: 8),
            _CallButton(
              isExpanded: true,
              onTap: onAudioCall,
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
            onSelected: (value) {
              if (value == 'toggle_block') {
                onBlockToggle();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_block',
                child: Text(
                  isBlocked ? 'Unblock User' : 'Block User',
                  style: TextStyle(
                    color: isBlocked ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  /// Builds the right [ImageProvider] for a Base64 string or a URL.
  ImageProvider _buildAvatarImageProvider(String photoUrl) {
    if (photoUrl.startsWith('data:image')) {
      final base64Data = photoUrl.split(',').last;
      return MemoryImage(base64Decode(base64Data));
    }
    return NetworkImage(photoUrl);
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.isExpanded, required this.onTap});
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF4ADE80);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: isExpanded
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_outlined, size: 18, color: Color(0xFF16A34A)),
            if (isExpanded) ...[
              const SizedBox(width: 6),
              const Text(
                'Call',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
