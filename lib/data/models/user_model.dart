/// User model for creators and app users
class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String profilePicture;
  final String bio;
  final bool isVerified;
  final int followerCount;
  final int followingCount;
  final int likesCount;
  final bool isFollowing;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.profilePicture,
    this.bio = '',
    this.isVerified = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.likesCount = 0,
    this.isFollowing = false,
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? profilePicture,
    String? bio,
    bool? isVerified,
    int? followerCount,
    int? followingCount,
    int? likesCount,
    bool? isFollowing,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      likesCount: likesCount ?? this.likesCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  /// Format follower count for display (e.g., 1.2M, 500K)
  String get formattedFollowers => _formatCount(followerCount);
  String get formattedFollowing => _formatCount(followingCount);
  String get formattedLikes => _formatCount(likesCount);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
