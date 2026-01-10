import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/mock_data.dart';
import '../../data/models/game_model.dart';
import '../../services/api_service.dart';
import '../../widgets/game_thumbnail.dart';
import '../main_scaffold.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<GameModel> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final games = await ApiService().getGames();
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log("Error loading discover data: $e");
      if (mounted) {
        setState(() {
          _games = MockData.games; // Fallback
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Discover',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ), // reduced padding
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical:
                        TextAlignVertical.center, // Center text vertically
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: const Color(0xFF5576F8),
                    decoration: InputDecoration(
                      hintText: 'Search games...',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF555555),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF555555),
                        size: 24, // slightly smaller icon
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Content
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom +
                        80, // Add padding for keyboard + nav
                  ),
                  children: [
                    // Trending Section
                    Text(
                      'Trending Now',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF5576F8),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _games.isNotEmpty ? _games.length : 0,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) =>
                                  _buildTrendingCard(_games[i % _games.length]),
                            ),
                    ),

                    const SizedBox(height: 28),

                    // Categories
                    Text(
                      'Categories',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: MockData.categories
                          .map((c) => _buildCategoryChip(c))
                          .toList(),
                    ),

                    const SizedBox(height: 28),

                    // New For You
                    Text(
                      'New For You',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF5576F8),
                          ),
                        ),
                      )
                    else if (_games.isEmpty)
                      const Text(
                        "No games found",
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ..._games.map((g) => _buildGameCard(g)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCard(GameModel game) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        MainScaffold.of(context)?.navigateToFeed(game);
      },
      child: Container(
      width: 112, // Width for 9:16 aspect ratio (200 / 16 * 9 = 112.5)
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1E1E1E),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Game thumbnail - use WebView if game HTML available, otherwise image
            if (game.gameUrl != null && game.gameUrl!.isNotEmpty)
              Positioned.fill(
                child: GameThumbnail(
                  gameHtml: game.gameUrl!,
                  width: 112,
                  height: 200,
                  borderRadius: 24,
                ),
              )
            else
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: game.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: const Color(0xFF2A2A2A)),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Center(
                      child: Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFF5576F8),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            // Gradient overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                  ),
                ),
              ),
            ),
            // Playtime badge
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_esports_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    game.formattedPlays,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(GameModel game) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        MainScaffold.of(context)?.navigateToFeed(game);
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: CachedNetworkImageProvider(game.thumbnailUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.sports_esports_rounded,
                      color: Color(0xFF5576F8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      game.formattedPlays,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF888888),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        game.gameType,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Play button
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF5576F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    ),
  );
  }
}
