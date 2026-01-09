import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/game_model.dart';
import '../data/models/user_model.dart';

class ApiService {
  static const String _baseUrl = 'https://my-chat-helper.taiayman13-ed6.workers.dev';
  static const String _appSecret = 'MySecretPassword123';

  // SharedPreferences keys
  static const String _keyUserId = 'user_id';
  static const String _keyUserData = 'user_data';
  static const String _keyIdToken = 'id_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyHasUsedFreeTrial = 'has_used_free_trial';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  UserModel? _currentUser;
  String? _idToken;
  String? _refreshToken;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Free trial tracking - anonymous users get 1 free game generation
  bool _hasUsedFreeTrial = false;
  bool get hasUsedFreeTrial => _hasUsedFreeTrial;

  void markFreeTrialUsed() {
    _hasUsedFreeTrial = true;
    _saveFreeTrial();
  }

  /// Check if user can generate a game (logged in OR hasn't used free trial)
  bool canGenerateGame() {
    return isLoggedIn || !_hasUsedFreeTrial;
  }

  /// Initialize service - call this on app startup
  Future<void> initialize() async {
    await _loadSavedSession();
  }

  /// Save session to persistent storage
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentUser != null) {
      await prefs.setString(_keyUserId, _currentUser!.id);
      await prefs.setString(_keyUserData, jsonEncode({
        'id': _currentUser!.id,
        'username': _currentUser!.username,
        'displayName': _currentUser!.displayName,
        'profilePicture': _currentUser!.profilePicture,
        'bio': _currentUser!.bio,
        'isVerified': _currentUser!.isVerified,
        'followerCount': _currentUser!.followerCount,
        'followingCount': _currentUser!.followingCount,
        'likesCount': _currentUser!.likesCount,
      }));
    }

    if (_idToken != null) {
      await prefs.setString(_keyIdToken, _idToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_keyRefreshToken, _refreshToken!);
    }
  }

  /// Save free trial status
  Future<void> _saveFreeTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasUsedFreeTrial, _hasUsedFreeTrial);
  }

  /// Load saved session from persistent storage
  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Load free trial status
    _hasUsedFreeTrial = prefs.getBool(_keyHasUsedFreeTrial) ?? false;

    // Load tokens
    _idToken = prefs.getString(_keyIdToken);
    _refreshToken = prefs.getString(_keyRefreshToken);

    // Load user data
    final userDataString = prefs.getString(_keyUserData);
    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        _currentUser = UserModel(
          id: userData['id'] ?? '',
          username: userData['username'] ?? '',
          displayName: userData['displayName'] ?? '',
          profilePicture: userData['profilePicture'] ?? '',
          bio: userData['bio'] ?? '',
          isVerified: userData['isVerified'] ?? false,
          followerCount: userData['followerCount'] ?? 0,
          followingCount: userData['followingCount'] ?? 0,
          likesCount: userData['likesCount'] ?? 0,
        );

        // Refresh user data from backend in background
        refreshCurrentUser();
      } catch (e) {
        print('Error loading saved session: $e');
        await _clearSession();
      }
    }
  }

  /// Clear saved session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyIdToken);
    await prefs.remove(_keyRefreshToken);
    _currentUser = null;
    _idToken = null;
    _refreshToken = null;
  }

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName ?? email.split('@')[0],
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens
        _idToken = data['idToken'];
        _refreshToken = data['refreshToken'];

        _currentUser = UserModel(
          id: data['uid'],
          username: (displayName ?? email.split('@')[0]).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
          displayName: displayName ?? email.split('@')[0],
          profilePicture: 'https://api.dicebear.com/7.x/avataaars/png?seed=${data['uid']}',
          isVerified: false,
        );

        // Save session
        await _saveSession();

        return _currentUser!;
      } else {
        throw Exception(data['message'] ?? 'Sign up failed');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error during sign up: $e');
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signin'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens
        _idToken = data['idToken'];
        _refreshToken = data['refreshToken'];

        final userData = data['user'];
        _currentUser = UserModel(
          id: data['uid'],
          username: userData?['username'] ?? email.split('@')[0],
          displayName: userData?['displayName'] ?? email.split('@')[0],
          profilePicture: userData?['profilePicture'] ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${data['uid']}',
          isVerified: userData?['isVerified'] ?? false,
          bio: userData?['bio'] ?? '',
          followerCount: userData?['followerCount'] ?? 0,
          followingCount: userData?['followingCount'] ?? 0,
          likesCount: userData?['likesCount'] ?? 0,
        );

        // Save session
        await _saveSession();

        return _currentUser!;
      } else {
        throw Exception(data['message'] ?? 'Sign in failed');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error during sign in: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    await _clearSession();
  }

  /// Fetch user profile from backend
  Future<UserModel?> fetchUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'App-Secret': _appSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel(
          id: data['id'] ?? userId,
          username: data['username'] ?? '',
          displayName: data['displayName'] ?? '',
          profilePicture: data['profilePicture'] ?? '',
          bio: data['bio'] ?? '',
          isVerified: data['isVerified'] ?? false,
          followerCount: data['followerCount'] ?? 0,
          followingCount: data['followingCount'] ?? 0,
          likesCount: data['likesCount'] ?? 0,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Refresh current user data from backend
  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;

    final updatedUser = await fetchUserProfile(_currentUser!.id);
    if (updatedUser != null) {
      _currentUser = updatedUser;
      await _saveSession(); // Save updated data
    }
  }

  /// Login as guest (anonymous auth)
  Future<UserModel> loginAsGuest() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/guest'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final uid = data['localId'];

        // Create user model from the response
        _currentUser = UserModel(
          id: uid,
          username: 'guest_${uid.substring(0, 6)}',
          displayName: 'Guest Player',
          profilePicture: 'https://api.dicebear.com/7.x/avataaars/png?seed=$uid',
          isVerified: false,
        );

        return _currentUser!;
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during login: $e');
    }
  }

  /// Create a new game
  Future<GameModel> createGame(GameModel game, String htmlContent) async {
    if (_currentUser == null) {
      throw Exception('User must be logged in to create a game');
    }

    // Debug logging
    print('DEBUG createGame: title = ${game.title}');
    print('DEBUG createGame: creator id = ${_currentUser!.id}');
    print('DEBUG createGame: creator username = ${_currentUser!.username}');
    print('DEBUG createGame: htmlContent length = ${htmlContent.length}');

    // Prepare game data
    final gameData = {
      'title': game.title,
      'description': game.description,
      'thumbnailUrl': game.thumbnailUrl,
      'gameUrl': htmlContent, // Storing HTML content directly
      'gameType': game.gameType,
      'creator': {
        'id': _currentUser!.id,
        'username': _currentUser!.username,
        'displayName': _currentUser!.displayName,
        'profilePicture': _currentUser!.profilePicture,
      },
      'likeCount': 0,
      'playCount': 0,
      'shareCount': 0,
      'commentCount': 0,
      'hashtags': game.hashtags,
      'createdAt': DateTime.now().toIso8601String(),
    };

    print('DEBUG createGame: sending data = ${gameData.keys}');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/games'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
        body: jsonEncode(gameData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Map back to GameModel
        return GameModel(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          thumbnailUrl: data['thumbnailUrl'],
          gameUrl: data['gameUrl'],
          gameType: data['gameType'],
          creator: UserModel(
              id: data['creator']['id'],
              username: data['creator']['username'],
              displayName: data['creator']['displayName'],
              profilePicture: data['creator']['profilePicture']
          ),
          createdAt: DateTime.parse(data['createdAt']),
          hashtags: List<String>.from(data['hashtags'] ?? []),
          likeCount: data['likeCount'] ?? 0,
          playCount: data['playCount'] ?? 0,
          shareCount: data['shareCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
        );
      } else {
        throw Exception('Failed to create game: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during game creation: $e');
    }
  }

  /// Get games feed
  Future<List<GameModel>> getGames() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/games'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> gamesJson = data['games'] ?? [];

        final List<GameModel> games = [];

        for (final json in gamesJson) {
          // Skip invalid game objects (some backend responses include stats objects in the array)
          if (json['creator'] == null || json['title'] == null) {
            continue;
          }

          try {
            games.add(GameModel(
              id: json['id'].toString(),
              title: json['title'] ?? 'Untitled Game',
              description: json['description'] ?? '',
              thumbnailUrl: json['thumbnailUrl'] ?? 'https://picsum.photos/400/600',
              gameUrl: json['gameUrl'],
              gameType: json['gameType'] ?? 'html5',
              creator: UserModel(
                  id: json['creator']?['id'] ?? '',
                  username: json['creator']?['username'] ?? 'unknown',
                  displayName: json['creator']?['displayName'] ?? 'Unknown',
                  profilePicture: json['creator']?['profilePicture'] ?? ''
              ),
              likeCount: json['likeCount'] ?? 0,
              playCount: json['playCount'] ?? 0,
              shareCount: json['shareCount'] ?? 0,
              commentCount: json['commentCount'] ?? 0,
              createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
              hashtags: List<String>.from(json['hashtags'] ?? []),
            ));
          } catch (e) {
            print('Error parsing game object: $e');
            // Continue to next item
          }
        }

        // Sort by newest first
        games.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return games;
      } else {
        throw Exception('Failed to fetch games: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error fetching games: $e');
    }
  }

  /// Get games by user ID
  Future<List<GameModel>> getUserGames(String userId) async {
    final allGames = await getGames();
    return allGames.where((g) => g.creator.id == userId).toList();
  }

  /// Update user profile
  Future<void> updateUser(Map<String, dynamic> data) async {
    if (_currentUser == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/${_currentUser!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        // Update local user model
        final updatedData = jsonDecode(response.body);
        _currentUser = _currentUser!.copyWith(
          displayName: data['displayName'] ?? _currentUser!.displayName,
          username: data['username'] ?? _currentUser!.username,
          bio: data['bio'] ?? _currentUser!.bio,
        );
        // Save updated session
        await _saveSession();
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error updating profile: $e');
    }
  }

  /// Like a game
  Future<void> likeGame(String gameId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/games/$gameId/like'),
        headers: {
          'App-Secret': _appSecret,
        },
      );
    } catch (e) {
      print('Error liking game: $e');
    }
  }

  /// Record a game view/play
  Future<void> viewGame(String gameId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/games/$gameId/view'),
        headers: {
          'App-Secret': _appSecret,
        },
      );
    } catch (e) {
      print('Error viewing game: $e');
    }
  }

  /// Get notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'App-Secret': _appSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get comments for a game
  Future<List<Map<String, dynamic>>> getComments(String gameId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/games/$gameId/comments'),
        headers: {
          'App-Secret': _appSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['comments'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  /// Post a comment
  Future<Map<String, dynamic>> postComment(String gameId, String text, {String? parentId}) async {
    if (_currentUser == null) {
      throw Exception('User must be logged in to comment');
    }

    try {
      final body = {
        'userId': _currentUser!.id,
        'text': text,
      };
      if (parentId != null) {
        body['parentId'] = parentId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/games/$gameId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to post comment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error posting comment: $e');
    }
  }

  /// Like a comment
  Future<void> likeComment(String gameId, String commentId) async {
    if (_currentUser == null) return;

    try {
      await http.post(
        Uri.parse('$_baseUrl/games/$gameId/comments/$commentId/like'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
        body: jsonEncode({
          'userId': _currentUser!.id,
        }),
      );
    } catch (e) {
      print('Error liking comment: $e');
    }
  }

  /// Unlike a comment
  Future<void> unlikeComment(String gameId, String commentId) async {
    if (_currentUser == null) return;

    try {
      await http.post(
        Uri.parse('$_baseUrl/games/$gameId/comments/$commentId/unlike'),
        headers: {
          'Content-Type': 'application/json',
          'App-Secret': _appSecret,
        },
        body: jsonEncode({
          'userId': _currentUser!.id,
        }),
      );
    } catch (e) {
      print('Error unliking comment: $e');
    }
  }
}
