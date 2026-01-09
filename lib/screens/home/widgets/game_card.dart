import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/game_model.dart';
import '../../../widgets/game_webview.dart';
import '../../../services/api_service.dart'; // Added import
import 'creator_info.dart';
import 'like_overlay.dart';
import 'comments_sheet.dart';

class GameCard extends StatefulWidget {
  final GameModel game;
  final bool isActive;
  final bool shouldLoadWebView;
  final ValueChanged<bool>? onLikeChanged;
  final ValueChanged<bool>? onSaveChanged;
  final ValueChanged<bool>? onInteractionChanged;
  final VoidCallback? onCommentAdded;

  const GameCard({
    super.key,
    required this.game,
    this.isActive = false,
    this.shouldLoadWebView = true,
    this.onLikeChanged,
    this.onSaveChanged,
    this.onInteractionChanged,
    this.onCommentAdded,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  bool _showLikeOverlay = false;
  late AnimationController _doubleTapController;
  late final GameWebViewController _gameController;

  @override
  void initState() {
    super.initState();
    _gameController = GameWebViewController();
    _doubleTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Record view if active
    if (widget.isActive) {
      // Small delay to ensure it's a real view
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && widget.isActive) {
          ApiService().viewGame(widget.game.id);
        }
      });
    }
  }

  @override
  void didUpdateWidget(GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
       // Record view when swiping into view
       ApiService().viewGame(widget.game.id);
    }
  }

  @override
  void dispose() {
    _doubleTapController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.game.isLiked) {
      widget.onLikeChanged?.call(true);
      ApiService().likeGame(widget.game.id); // API Call
    }
    setState(() {
      _showLikeOverlay = true;
    });
    HapticFeedback.mediumImpact();
    _doubleTapController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _showLikeOverlay = false;
        });
      }
    });
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        game: widget.game,
        onCommentAdded: widget.onCommentAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Game content - WebView or placeholder
        if (widget.shouldLoadWebView)
          GameWebView(
            key: const ValueKey('webview'),
            isActive: widget.isActive,
            gameHtml: widget.game.gameUrl, // Pass the game HTML content
            onInteractionChanged: widget.onInteractionChanged,
            controller: _gameController,
          )
        else
          const _GamePlaceholder(),

        // Creator Info + Action Buttons
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CreatorInfo(
            game: widget.game,
            onLikePressed: () {
              final newLikedState = !widget.game.isLiked;
              widget.onLikeChanged?.call(newLikedState);
              if (newLikedState) {
                 ApiService().likeGame(widget.game.id); // API Call
              }
              HapticFeedback.lightImpact();
              if (newLikedState) { // Fixed logic: show overlay only on like
                _handleDoubleTap();
              }
            },
            onCommentPressed: _openComments,
            onRemixPressed: () {
              HapticFeedback.lightImpact();
            },
          ),
        ),

        // Like overlay
        if (_showLikeOverlay)
          IgnorePointer(child: LikeOverlay(controller: _doubleTapController)),
      ],
    );
  }
}

class _GamePlaceholder extends StatelessWidget {
  const _GamePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading game...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
