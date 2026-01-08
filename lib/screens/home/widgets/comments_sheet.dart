import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/game_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/mock_data.dart';

class CommentsSheet extends StatefulWidget {
  final GameModel game;

  const CommentsSheet({super.key, required this.game});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<CommentModel> _comments;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _comments = List.from(MockData.getCommentsForGame(widget.game.id));
  }

  CommentModel? _replyingTo;
  final FocusNode _inputFocusNode = FocusNode();

  void _handleCommentSubmit(String text) {
    if (text.trim().isEmpty) return;

    // Haptic feedback for premium feel
    HapticFeedback.lightImpact();

    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      user: MockData.currentUser,
      text: text.trim(),
      timestamp: DateTime.now(),
      likeCount: 0,
      isLiked: false,
    );

    setState(() {
      _comments.insert(0, newComment);
      _replyingTo = null; // Clear reply state
    });

    // Animate the new item in
    _listKey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 300),
    );

    // Scroll to top to ensure visibility
    if (_scrollController != null && _scrollController!.hasClients) {
      _scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleLike(int index) {
    setState(() {
      final comment = _comments[index];
      final newIsLiked = !comment.isLiked;
      final newLikeCount = newIsLiked
          ? comment.likeCount + 1
          : comment.likeCount - 1;

      _comments[index] = comment.copyWith(
        isLiked: newIsLiked,
        likeCount: newLikeCount,
      );
    });
    HapticFeedback.selectionClick();
  }

  void _handleReply(CommentModel comment) {
    setState(() {
      _replyingTo = comment;
    });
    _inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        _scrollController = scrollController;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _comments.isEmpty
                    ? _buildEmptyState()
                    : AnimatedList(
                        key: _listKey,
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        initialItemCount: _comments.length,
                        itemBuilder: (context, index, animation) {
                          return _buildAnimatedCommentItem(
                            _comments[index],
                            animation,
                          );
                        },
                      ),
              ),
              _CommentInput(
                onSubmitted: _handleCommentSubmit,
                focusNode: _inputFocusNode,
                replyingTo: _replyingTo,
                onCancelReply: () {
                  setState(() {
                    _replyingTo = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedCommentItem(
    CommentModel comment,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _CommentItem(
          comment: comment,
          onLike: () => _handleLike(_comments.indexOf(comment)),
          onReply: () => _handleReply(comment),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 32,
              color: Color(0xFF5576F8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No comments yet',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts!',
            style: GoogleFonts.outfit(
              color: const Color(0xFF888888),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${widget.game.commentCount} comments',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Positioned(
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          // Drag handle
          Positioned(
            top: -8,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatefulWidget {
  final Function(String) onSubmitted;
  final FocusNode? focusNode;
  final CommentModel? replyingTo;
  final VoidCallback? onCancelReply;

  const _CommentInput({
    required this.onSubmitted,
    this.focusNode,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (_hasText != hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmitted(_controller.text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Row(
                children: [
                  Text(
                    'Replying to ',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF888888),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '@${widget.replyingTo!.user.username}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onCancelReply,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // User Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF333333)),
                  image: const DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://api.dicebear.com/7.x/avataaars/png?seed=currentUser',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _hasText ? const Color(0xFF5576F8).withOpacity(0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          focusNode: widget.focusNode,
                          controller: _controller,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          cursorColor: const Color(0xFF5576F8),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: GoogleFonts.outfit(
                              color: const Color(0xFF666666),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_hasText)
                        GestureDetector(
                          onTap: _submit,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5576F8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      else ...[
                        const Icon(
                          Icons.alternate_email_rounded,
                          color: Color(0xFF666666),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.sentiment_satisfied_rounded,
                          color: Color(0xFF666666),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  const _CommentItem({required this.comment, this.onLike, this.onReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF333333)),
              image: DecorationImage(
                image: CachedNetworkImageProvider(comment.user.profilePicture),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user.username,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFAAAAAA),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (comment.user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Color(0xFF5576F8),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _shortTime(comment.formattedTime),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onReply,
                  child: Text(
                    'Reply',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF666666),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Icon(
                  comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: comment.isLiked
                      ? const Color(0xFFFF2C55)
                      : const Color(0xFF666666),
                ),
              ),
              if (comment.likeCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  comment.formattedLikes,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _shortTime(String time) {
    if (time.endsWith('ago')) return time.replaceAll(' ago', '');
    return time;
  }
}
