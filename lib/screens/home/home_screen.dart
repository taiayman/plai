import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/mock_data.dart';
import '../../data/models/game_model.dart';
import '../../services/api_service.dart';
import 'widgets/game_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  List<GameModel> _games = [];
  int _currentPage = 0;
  bool _isGameInteracting = false;
  bool _isScrolling = false;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final games = await ApiService().getGames();

      setState(() {
        _games = games;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _games = [];
        _isLoading = false;
        _isRefreshing = false;
      });
      print("Error loading games: $e");
    }
  }

  Future<void> _refreshGames() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();
    await _loadGames();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading && _games.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5576F8)),
        ),
      );
    }

    // Empty state
    if (_games.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                if (!_isScrolling) {
                  _isScrolling = true;
                  setState(() {});
                }
              } else if (notification is ScrollEndNotification) {
                if (_isScrolling) {
                  _isScrolling = false;
                  setState(() {});
                }
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: _isGameInteracting
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              onPageChanged: (index) {
                _currentPage = index;
                setState(() {});
                HapticFeedback.selectionClick();
              },
              itemCount: _games.length,
              itemBuilder: (context, index) {
                // Keep WebView loaded for current page to avoid flickering and frame errors
                // We only unmount when the page actually changes
                final isCurrentPage = index == _currentPage;

                return GameCard(
                  key: ValueKey(_games[index].id),
                  game: _games[index],
                  isActive: isCurrentPage,
                  shouldLoadWebView: isCurrentPage,
                  onInteractionChanged: (isInteracting) {
                    _isGameInteracting = isInteracting;
                    setState(() {});
                  },
                  onLikeChanged: (isLiked) {
                    _games[index] = _games[index].copyWith(
                      isLiked: isLiked,
                      likeCount: _games[index].likeCount + (isLiked ? 1 : -1),
                    );
                    setState(() {});
                  },
                  onSaveChanged: (isSaved) {
                    _games[index] = _games[index].copyWith(isSaved: isSaved);
                    setState(() {});
                  },
                );
              },
            ),
          ),

          // Refresh button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _refreshGames,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isRefreshing
                        ? const Color(0xFF5576F8).withOpacity(0.2)
                        : Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF5576F8),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Refresh',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Color(0xFF5576F8),
                  size: 56,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: const Duration(seconds: 2),
                  ),
              const SizedBox(height: 32),
              Text(
                'No games yet',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Be the first to create a game!\nUse AI to build amazing games in seconds.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF888888),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _refreshGames,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF5576F8),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF5576F8),
                              size: 20,
                            ),
                      const SizedBox(width: 10),
                      Text(
                        'Refresh',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
