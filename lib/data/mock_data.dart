import 'dart:ui';
import 'models/user_model.dart';
import 'models/game_model.dart';
import 'models/comment_model.dart';
import 'models/notification_model.dart';

/// Mock data for the app
class MockData {
  MockData._();

  // Mock users
  static const List<UserModel> users = [
    UserModel(
      id: '1',
      username: 'gamemaster',
      displayName: 'Game Master',
      profilePicture: 'https://i.pravatar.cc/150?img=1',
      bio: '🎮 Creating viral games daily\n🔥 1M+ plays on my games',
      isVerified: true,
      followerCount: 1250000,
      followingCount: 342,
      likesCount: 5600000,
    ),
    UserModel(
      id: '2',
      username: 'pixelwizard',
      displayName: 'Pixel Wizard',
      profilePicture: 'https://i.pravatar.cc/150?img=2',
      bio: '✨ Pixel art game creator\n🕹️ Retro vibes only',
      isVerified: true,
      followerCount: 856000,
      followingCount: 128,
      likesCount: 3200000,
    ),
    UserModel(
      id: '3',
      username: 'arcadequeen',
      displayName: 'Arcade Queen',
      profilePicture: 'https://i.pravatar.cc/150?img=3',
      bio: '👾 Arcade game enthusiast\n🏆 Top creator 2024',
      isVerified: true,
      followerCount: 2100000,
      followingCount: 89,
      likesCount: 8900000,
    ),
    UserModel(
      id: '4',
      username: 'indiedev',
      displayName: 'Indie Dev',
      profilePicture: 'https://i.pravatar.cc/150?img=4',
      bio: '🎨 Making games for fun\n💜 Support indie devs!',
      isVerified: false,
      followerCount: 45000,
      followingCount: 234,
      likesCount: 89000,
    ),
    UserModel(
      id: '5',
      username: 'puzzleking',
      displayName: 'Puzzle King',
      profilePicture: 'https://i.pravatar.cc/150?img=5',
      bio: '🧩 Brain teasers & puzzles\n🧠 Challenge your mind',
      isVerified: true,
      followerCount: 678000,
      followingCount: 156,
      likesCount: 2100000,
    ),
    UserModel(
      id: '6',
      username: 'speedrunner',
      displayName: 'Speed Runner',
      profilePicture: 'https://i.pravatar.cc/150?img=6',
      bio: '⚡ Fast-paced action games\n🏎️ Racing enthusiast',
      isVerified: false,
      followerCount: 123000,
      followingCount: 567,
      likesCount: 456000,
    ),
  ];

  // Current user (you)
  static const UserModel currentUser = UserModel(
    id: 'current',
    username: 'you',
    displayName: 'Your Name',
    profilePicture: 'https://i.pravatar.cc/150?img=10',
    bio: '🚀 Game creator in training\n✨ Let\'s make something awesome',
    isVerified: false,
    followerCount: 1234,
    followingCount: 567,
    likesCount: 8901,
  );

  // Mock games
  static List<GameModel> games = [
    GameModel(
      id: '1',
      title: 'Neon Runner',
      description:
          'Endless runner through a neon city. Dodge obstacles and collect power-ups! 🌃',
      thumbnailUrl: 'https://picsum.photos/seed/game1/400/800',
      gameType: 'Endless Runner',
      creator: users[0],
      likeCount: 125000,
      commentCount: 3400,
      shareCount: 890,
      playCount: 2500000,
      hashtags: ['#endlessrunner', '#neon', '#arcade', '#addictive'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      backgroundColor: const Color(0xFF1a1a2e),
    ),
    GameModel(
      id: '2',
      title: 'Stack Tower',
      description:
          'Stack blocks as high as you can! How tall can your tower get? 🏗️',
      thumbnailUrl: 'https://picsum.photos/seed/game2/400/800',
      gameType: 'Arcade',
      creator: users[1],
      likeCount: 89000,
      commentCount: 1200,
      shareCount: 456,
      playCount: 1800000,
      hashtags: ['#stacking', '#arcade', '#casual', '#highscore'],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      backgroundColor: const Color(0xFF16213e),
    ),
    GameModel(
      id: '3',
      title: 'Color Match',
      description:
          'Match the falling colors before time runs out! Test your reflexes ⏱️',
      thumbnailUrl: 'https://picsum.photos/seed/game3/400/800',
      gameType: 'Puzzle',
      creator: users[2],
      likeCount: 234000,
      commentCount: 5600,
      shareCount: 1200,
      playCount: 4500000,
      hashtags: ['#puzzle', '#colors', '#reaction', '#viral'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      backgroundColor: const Color(0xFF0f3460),
    ),
    GameModel(
      id: '4',
      title: 'Bounce Ball',
      description: 'Tap to bounce through obstacles. Simple but addictive! 🏀',
      thumbnailUrl: 'https://picsum.photos/seed/game4/400/800',
      gameType: 'Arcade',
      creator: users[3],
      likeCount: 12000,
      commentCount: 890,
      shareCount: 234,
      playCount: 340000,
      hashtags: ['#bounce', '#taptap', '#casual', '#fun'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      backgroundColor: const Color(0xFF533483),
    ),
    GameModel(
      id: '5',
      title: 'Mind Bend',
      description: 'Optical illusion puzzles that will blow your mind 🤯',
      thumbnailUrl: 'https://picsum.photos/seed/game5/400/800',
      gameType: 'Puzzle',
      creator: users[4],
      likeCount: 167000,
      commentCount: 4500,
      shareCount: 2300,
      playCount: 3200000,
      hashtags: ['#puzzle', '#illusion', '#brain', '#mindgames'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      backgroundColor: const Color(0xFF4a0e4e),
    ),
    GameModel(
      id: '6',
      title: 'Drift King',
      description: 'Master the art of drifting through impossible tracks 🏎️',
      thumbnailUrl: 'https://picsum.photos/seed/game6/400/800',
      gameType: 'Racing',
      creator: users[5],
      likeCount: 45000,
      commentCount: 1100,
      shareCount: 567,
      playCount: 890000,
      hashtags: ['#racing', '#drift', '#cars', '#speed'],
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      backgroundColor: const Color(0xFF1a1a2e),
    ),
    GameModel(
      id: '7',
      title: 'Space Shooter',
      description: 'Defend Earth from alien invasion! Classic arcade action 👾',
      thumbnailUrl: 'https://picsum.photos/seed/game7/400/800',
      gameType: 'Arcade',
      creator: users[0],
      likeCount: 98000,
      commentCount: 2300,
      shareCount: 678,
      playCount: 1900000,
      hashtags: ['#shooter', '#space', '#retro', '#aliens'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      backgroundColor: const Color(0xFF0a0a0a),
    ),
    GameModel(
      id: '8',
      title: 'Flip Jump',
      description: 'Flip and jump through challenging obstacle courses 🤸',
      thumbnailUrl: 'https://picsum.photos/seed/game8/400/800',
      gameType: 'Platformer',
      creator: users[1],
      likeCount: 56000,
      commentCount: 890,
      shareCount: 345,
      playCount: 1200000,
      hashtags: ['#platformer', '#jump', '#flip', '#challenge'],
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      backgroundColor: const Color(0xFF2d132c),
    ),
  ];

  // Mock comments
  static List<CommentModel> getCommentsForGame(String gameId) {
    return [
      CommentModel(
        id: '1',
        user: users[1],
        text: 'This game is so addictive! Been playing for hours 🔥',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        likeCount: 234,
        replies: [
          CommentModel(
            id: '1-1',
            user: users[2],
            text: 'Same here! Can\'t stop playing 😂',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            likeCount: 45,
          ),
          CommentModel(
            id: '1-2',
            user: users[3],
            text: 'It\'s literally the best game on here',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
            likeCount: 23,
          ),
        ],
      ),
      CommentModel(
        id: '2',
        user: users[3],
        text: 'How do you come up with these ideas? Teach me! 🙏',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        likeCount: 89,
      ),
      CommentModel(
        id: '3',
        user: users[4],
        text: 'My high score is 1,234,567! Try to beat that 💪',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likeCount: 156,
        replies: [
          CommentModel(
            id: '3-1',
            user: users[5],
            text: 'Challenge accepted! 🎯',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            likeCount: 34,
          ),
        ],
      ),
      CommentModel(
        id: '4',
        user: users[5],
        text: 'The graphics are insane for a mini game! 🎨',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        likeCount: 67,
      ),
      CommentModel(
        id: '5',
        user: users[0],
        text: 'Thanks everyone for playing! New update coming soon 🚀',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        likeCount: 890,
      ),
    ];
  }

  // Mock notifications
  static List<NotificationModel> notifications = [
    NotificationModel(
      id: '1',
      type: NotificationType.like,
      actor: users[0],
      content: 'liked your game "My First Game"',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    NotificationModel(
      id: '2',
      type: NotificationType.follow,
      actor: users[1],
      content: 'started following you',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    NotificationModel(
      id: '3',
      type: NotificationType.comment,
      actor: users[2],
      content: 'commented: "This is amazing! 🔥"',
      targetId: '1',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: '4',
      type: NotificationType.milestone,
      content: 'Your game reached 1,000 plays! 🎉',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: '5',
      type: NotificationType.like,
      actor: users[3],
      content: 'liked your game "My First Game"',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    NotificationModel(
      id: '6',
      type: NotificationType.follow,
      actor: users[4],
      content: 'started following you',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    NotificationModel(
      id: '7',
      type: NotificationType.share,
      actor: users[5],
      content: 'shared your game',
      targetId: '1',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationModel(
      id: '8',
      type: NotificationType.milestone,
      content: 'You gained 100 new followers this week! 🚀',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  // Game categories
  static const List<String> categories = [
    'Trending',
    'New',
    'Arcade',
    'Puzzle',
    'Action',
    'Racing',
    'For You',
  ];

  // Creation prompt suggestions
  static const List<String> promptSuggestions = [
    'endless runner',
    'avoid obstacles',
    'collect coins',
    'tap to jump',
    'puzzle game',
    'racing game',
    'match colors',
    'stack blocks',
    'shoot enemies',
    'dodge bullets',
    'flip gravity',
    'time trial',
  ];
}
