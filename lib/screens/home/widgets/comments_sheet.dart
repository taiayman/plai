import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/models/game_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/user_model.dart';
import '../../../services/api_service.dart';
import '../../auth/auth_modal.dart';

class CommentsSheet extends StatefulWidget {
  final GameModel game;
  final VoidCallback? onCommentAdded;

  const CommentsSheet({super.key, required this.game, this.onCommentAdded});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<CommentModel> _comments = [];
  ScrollController? _scrollController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final commentsData = await ApiService().getComments(widget.game.id);
      final currentUserId = ApiService().currentUser?.id;

      if (mounted) {
        setState(() {
          // Parse all comments
          final allComments = commentsData.map((data) {
            final likedBy = List<String>.from(data['likedBy'] ?? []);
            final isLiked = currentUserId != null && likedBy.contains(currentUserId);

            return CommentModel(
              id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              user: UserModel(
                id: data['userId'] ?? 'unknown',
                username: data['username'] ?? 'User',
                displayName: data['displayName'] ?? 'User',
                profilePicture: data['profilePicture'] ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${data['userId']}',
              ),
              text: data['text'] ?? '',
              parentId: data['parentId'],
              timestamp: data['createdAt'] != null
                  ? DateTime.parse(data['createdAt'])
                  : DateTime.now(),
              likeCount: data['likeCount'] ?? 0,
              isLiked: isLiked,
            );
          }).toList();

          // Organize into parent comments with nested replies
          _comments = _organizeComments(allComments);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Organize flat list into nested structure
  List<CommentModel> _organizeComments(List<CommentModel> allComments) {
    // Separate parent comments and replies
    final parentComments = allComments.where((c) => c.parentId == null).toList();
    final replies = allComments.where((c) => c.parentId != null).toList();

    // Group replies by parent ID
    final repliesByParent = <String, List<CommentModel>>{};
    for (final reply in replies) {
      repliesByParent.putIfAbsent(reply.parentId!, () => []).add(reply);
    }

    // Attach replies to parent comments
    final organized = parentComments.map((parent) {
      final parentReplies = repliesByParent[parent.id] ?? [];
      // Sort replies by oldest first (chronological order)
      parentReplies.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return parent.copyWith(replies: parentReplies);
    }).toList();

    // Sort parent comments by newest first
    organized.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return organized;
  }

  CommentModel? _replyingTo;
  final FocusNode _inputFocusNode = FocusNode();

  Future<void> _handleCommentSubmit(String text) async {
    if (text.trim().isEmpty) return;

    // Haptic feedback for premium feel
    HapticFeedback.lightImpact();

    final currentUser = ApiService().currentUser;
    if (currentUser == null) {
      final success = await AuthModal.show(context);
      if (!success) return;

      if (ApiService().currentUser != null) {
        _handleCommentSubmit(text);
      }
      return;
    }

    final parentComment = _replyingTo;
    final parentId = parentComment?.id;

    // Create the new comment
    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      user: currentUser,
      text: text.trim(),
      timestamp: DateTime.now(),
      likeCount: 0,
      isLiked: false,
      parentId: parentId,
    );

    setState(() {
      if (parentId != null) {
        // Add as a reply to the parent comment
        final parentIndex = _comments.indexWhere((c) => c.id == parentId);
        if (parentIndex != -1) {
          final parent = _comments[parentIndex];
          final updatedReplies = [...parent.replies, newComment];
          _comments[parentIndex] = parent.copyWith(replies: updatedReplies);
        }
      } else {
        // Add as a new top-level comment
        _comments.insert(0, newComment);
        _listKey.currentState?.insertItem(
          0,
          duration: const Duration(milliseconds: 300),
        );
      }
      _replyingTo = null; // Clear reply state
    });

    // Scroll to show the new comment
    if (parentId == null && _scrollController != null && _scrollController!.hasClients) {
      _scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // Send to backend
    try {
      await ApiService().postComment(widget.game.id, text.trim(), parentId: parentId);
      // Notify parent that a comment was added
      widget.onCommentAdded?.call();
    } catch (e) {
      // Handle error (maybe show toast and remove comment)
      print('Error posting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    }
  }

  void _handleLike(int index) {
    final comment = _comments[index];
    final newIsLiked = !comment.isLiked;
    final newLikeCount = newIsLiked
        ? comment.likeCount + 1
        : comment.likeCount - 1;

    setState(() {
      _comments[index] = comment.copyWith(
        isLiked: newIsLiked,
        likeCount: newLikeCount < 0 ? 0 : newLikeCount,
      );
    });
    HapticFeedback.selectionClick();

    // Call API to persist the like/unlike
    if (newIsLiked) {
      ApiService().likeComment(widget.game.id, comment.id);
    } else {
      ApiService().unlikeComment(widget.game.id, comment.id);
    }
  }

  void _handleLikeReply(CommentModel parentComment, CommentModel reply) {
    final parentIndex = _comments.indexOf(parentComment);
    if (parentIndex == -1) return;

    final replyIndex = parentComment.replies.indexWhere((r) => r.id == reply.id);
    if (replyIndex == -1) return;

    final newIsLiked = !reply.isLiked;
    final newLikeCount = newIsLiked
        ? reply.likeCount + 1
        : reply.likeCount - 1;

    final updatedReply = reply.copyWith(
      isLiked: newIsLiked,
      likeCount: newLikeCount < 0 ? 0 : newLikeCount,
    );

    final updatedReplies = List<CommentModel>.from(parentComment.replies);
    updatedReplies[replyIndex] = updatedReply;

    setState(() {
      _comments[parentIndex] = parentComment.copyWith(replies: updatedReplies);
    });
    HapticFeedback.selectionClick();

    // Call API to persist the like/unlike
    if (newIsLiked) {
      ApiService().likeComment(widget.game.id, reply.id);
    } else {
      ApiService().unlikeComment(widget.game.id, reply.id);
    }
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
                child: _isLoading
                    ? _buildShimmerLoading()
                    : _comments.isEmpty
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
          onReplyToReply: (parentComment) => _handleReply(parentComment),
          onLikeReply: (reply) => _handleLikeReply(comment, reply),
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E1E1E),
      highlightColor: const Color(0xFF2A2A2A),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: 5,
        itemBuilder: (context, index) => _buildShimmerCommentItem(),
      ),
    );
  }

  Widget _buildShimmerCommentItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar shimmer
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username shimmer
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Comment text shimmer - line 1
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                // Comment text shimmer - line 2
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                // Reply button shimmer
                Container(
                  width: 40,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Like button shimmer
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 16,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Show loaded count if available, otherwise show game's count
    final commentCount = _isLoading ? widget.game.commentCount : _comments.length;
    final countText = _formatCount(commentCount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        // Title row with close button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 24), // Balance for close button
              Expanded(
                child: Text(
                  '$countText comments',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFF1E1E1E), height: 1),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _CommentInput extends StatefulWidget {
  final Future<void> Function(String) onSubmitted;
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
  bool _isSubmitting = false;

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

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmitted(_controller.text);
      if (mounted) {
        _controller.clear();
        // Keep focus to allow posting multiple comments if desired
        // FocusScope.of(context).unfocus();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      ApiService().currentUser?.profilePicture ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=guest',
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
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          focusNode: widget.focusNode,
                          controller: _controller,
                          enabled: !_isSubmitting,
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
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_isSubmitting)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF5576F8),
                            ),
                          ),
                        )
                      else if (_hasText)
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
                      else
                        const SizedBox(width: 12),
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

class _CommentItem extends StatefulWidget {
  final CommentModel comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final Function(CommentModel)? onReplyToReply;
  final Function(CommentModel)? onLikeReply;
  final bool isReply;

  const _CommentItem({
    required this.comment,
    this.onLike,
    this.onReply,
    this.onReplyToReply,
    this.onLikeReply,
    this.isReply = false,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _showReplies = true;

  @override
  Widget build(BuildContext context) {
    final avatarSize = widget.isReply ? 32.0 : 40.0;
    final fontSize = widget.isReply ? 13.0 : 14.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.isReply ? 16 : 20,
        left: widget.isReply ? 52 : 0, // Indent replies
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF333333)),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(widget.comment.user.profilePicture),
                    fit: BoxFit.cover,
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
                          widget.comment.user.username,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFAAAAAA),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.comment.user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Color(0xFF5576F8),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          _shortTime(widget.comment.formattedTime),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF666666),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.comment.text,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: fontSize,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onReply,
                          child: Text(
                            'Reply',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF666666),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Show replies toggle for parent comments with replies
                        if (!widget.isReply && widget.comment.replies.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showReplies = !_showReplies;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _showReplies
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: const Color(0xFF5576F8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showReplies
                                      ? 'Hide replies'
                                      : 'View ${widget.comment.replies.length} ${widget.comment.replies.length == 1 ? 'reply' : 'replies'}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF5576F8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  GestureDetector(
                    onTap: widget.onLike,
                    child: Icon(
                      widget.comment.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: widget.isReply ? 16 : 20,
                      color: widget.comment.isLiked
                          ? const Color(0xFFFF2C55)
                          : const Color(0xFF666666),
                    ),
                  ),
                  if (widget.comment.likeCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.comment.formattedLikes,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF666666),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          // Show nested replies
          if (!widget.isReply && _showReplies && widget.comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: widget.comment.replies.map((reply) {
                  return _CommentItem(
                    comment: reply,
                    isReply: true,
                    onReply: () => widget.onReplyToReply?.call(widget.comment),
                    onLike: () => widget.onLikeReply?.call(reply),
                  );
                }).toList(),
              ),
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
