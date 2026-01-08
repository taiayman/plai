import 'user_model.dart';

/// Notification types
enum NotificationType { like, follow, comment, milestone, mention, share }

/// Notification model for inbox
class NotificationModel {
  final String id;
  final NotificationType type;
  final UserModel? actor;
  final String content;
  final String? targetId;
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.type,
    this.actor,
    required this.content,
    this.targetId,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    UserModel? actor,
    String? content,
    String? targetId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      actor: actor ?? this.actor,
      content: content ?? this.content,
      targetId: targetId ?? this.targetId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Format timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
