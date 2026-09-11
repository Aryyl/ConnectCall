import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/enums/call_direction.dart';
import '../../core/enums/call_status.dart';
import '../../models/call_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_history_provider.dart';
import '../../providers/calling_provider.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(callHistoryProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      appBar: _buildAppBar(context),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          // Distinguish missing-index errors from other failures so the user
          // gets an understandable message rather than raw Firestore exception text.
          final isMissingIndex = e is FirebaseException &&
              e.code == 'failed-precondition';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMissingIndex
                        ? Icons.build_circle_outlined
                        : Icons.error_outline_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMissingIndex
                        ? 'Setting up Recent Calls…'
                        : 'Could not load recent calls',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMissingIndex
                        ? 'A database index is being built. This takes a minute or two on first use. Please wait and try again.'
                        : 'Something went wrong. Please check your connection and try again.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('No recent calls.'));
          }

          // Group by date
          final Map<String, List<CallRecord>> grouped = {};
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          for (final record in records) {
            final date = DateTime(record.startedAt.year, record.startedAt.month, record.startedAt.day);
            String groupKey;
            if (date == today) {
              groupKey = 'TODAY';
            } else if (date == yesterday) {
              groupKey = 'YESTERDAY';
            } else {
              groupKey = DateFormat('MMM d, yyyy').format(date).toUpperCase();
            }
            grouped.putIfAbsent(groupKey, () => []).add(record);
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
                          return _CallHistoryTile(
                            record: entry.value[index],
                            currentUserId: currentUserId,
                            ref: ref,
                          );
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ],
                );
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
            'Recents',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '$count Calls',
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
}

class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({
    required this.record,
    required this.currentUserId,
    required this.ref,
  });

  final CallRecord record;
  final String currentUserId;
  final WidgetRef ref;

  String get _otherPartyName {
    if (record.callerId == currentUserId) {
      return record.receiverName ?? record.receiverId;
    }
    return record.callerName ?? record.callerId;
  }

  String get _otherPartyInitials {
    final name = _otherPartyName;
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final isMissed = record.status == CallStatus.missed || record.status == CallStatus.rejected;
    final isIncoming = record.direction == CallDirection.incoming;

    IconData statusIcon;
    String statusText;

    if (isMissed) {
      statusIcon = Icons.call_missed_rounded;
      statusText = 'Missed';
    } else if (isIncoming) {
      statusIcon = Icons.call_received_rounded;
      statusText = 'Incoming ${_formatDuration(record.duration)}';
    } else {
      statusIcon = Icons.call_made_rounded;
      statusText = 'Outgoing ${_formatDuration(record.duration)}';
    }

    final timeStr = DateFormat('h:mm a').format(record.startedAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
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
                child: Text(
                  _otherPartyInitials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isMissed ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon,
                      size: 10,
                      color: isMissed ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherPartyName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isMissed ? const Color(0xFFEF4444) : Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMissed ? const Color(0xFFEF4444) : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('•', style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Container(
            decoration: BoxDecoration(
              color: isMissed ? const Color(0xFF059669) : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: isMissed ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: InkWell(
              onTap: () => callBack(ref, record, currentUserId),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.call_rounded,
                  size: 20,
                  color: isMissed ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
