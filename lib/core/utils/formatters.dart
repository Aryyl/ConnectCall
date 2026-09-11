/// Formatting utilities for ConnectCall — dates, durations, etc.
library;

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Formats call duration in seconds to MM:SS string.
  static String formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats a DateTime to a human-readable call history date.
  /// Returns "Today", "Yesterday", or a formatted date.
  static String formatCallDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (callDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (callDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  /// Formats a DateTime to a short time string (e.g. "2:35 PM").
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats a DateTime to a date string (e.g. "Sep 6, 2026").
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  /// Returns "Online" or "Last seen [time]" string.
  static String formatPresence({
    required bool isOnline,
    DateTime? lastSeen,
  }) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';
    return 'Last seen ${formatCallDate(lastSeen)}';
  }
}
