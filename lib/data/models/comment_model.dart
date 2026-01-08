import 'user_model.dart';

/// Comment model for game comments
class CommentModel {
  final String id;
  final UserModel user;
  final String text;
  final DateTime timestamp;
  final int likeCount;
  final bool isLiked;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
    this.likeCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  CommentModel copyWith({
    String? id,
    UserModel? user,
    String? text,
    DateTime? timestamp,
    int? likeCount,
    bool? isLiked,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      user: user ?? this.user,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }

  /// Format timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String get formattedLikes {
    if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}K';
    }
    return likeCount.toString();
  }
}
