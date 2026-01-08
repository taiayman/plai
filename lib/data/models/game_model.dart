import 'dart:ui';
import 'user_model.dart';

/// Game content model for feed items
class GameModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? gameUrl;
  final String gameType;
  final UserModel creator;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int playCount;
  final List<String> hashtags;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;
  final Color? backgroundColor;

  const GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.gameUrl,
    required this.gameType,
    required this.creator,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.playCount = 0,
    this.hashtags = const [],
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
    this.backgroundColor,
  });

  GameModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? gameUrl,
    String? gameType,
    UserModel? creator,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? playCount,
    List<String>? hashtags,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
    Color? backgroundColor,
  }) {
    return GameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gameUrl: gameUrl ?? this.gameUrl,
      gameType: gameType ?? this.gameType,
      creator: creator ?? this.creator,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      playCount: playCount ?? this.playCount,
      hashtags: hashtags ?? this.hashtags,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  /// Format counts for display
  String get formattedLikes => _formatCount(likeCount);
  String get formattedComments => _formatCount(commentCount);
  String get formattedShares => _formatCount(shareCount);
  String get formattedPlays => _formatCount(playCount);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
