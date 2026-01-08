import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../services/api_service.dart';
import '../../data/models/game_model.dart';
import '../../data/models/user_model.dart';
import '../main_scaffold.dart';

class PostGameScreen extends StatefulWidget {
  final String? gameHtml;

  const PostGameScreen({super.key, this.gameHtml});

  @override
  State<PostGameScreen> createState() => _PostGameScreenState();
}

class _PostGameScreenState extends State<PostGameScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  bool _allowComments = true;
  bool _allowsRemix = true;
  String _privacyLevel = 'Everyone';
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'My Game'; // Default title
  }

  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#\w+');
    final matches = regex.allMatches(text);
    final hashtags = matches.map((m) => m.group(0)!).toList();
    // Add default hashtags if none found
    if (hashtags.isEmpty) {
      return ['#GameAI', '#MadeWithPlai'];
    }
    return hashtags;
  }

  void _showSuccessAndNavigate() {
    // Show success overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                  size: 48,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 20),
              Text(
                'Game Posted!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your game is now live',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF888888),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Navigate after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScaffold()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0F0F0F),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom Header
              _buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      // 1. Caption & Cover Row
                      _buildCaptionSection(),

                      const SizedBox(height: 32),

                      // 2. Settings Tiles
                      _buildSettingTile(
                        icon: Icons.public_rounded,
                        label: 'Who can watch',
                        value: _privacyLevel,
                        onTap: () {
                          // TODO: Privacy selector
                        },
                      ),

                      const SizedBox(height: 16),
                      _buildSwitchTile(
                        icon: Icons.comment_rounded,
                        label: 'Allow comments',
                        value: _allowComments,
                        onChanged: (v) => setState(() => _allowComments = v),
                      ),
                      const SizedBox(height: 16),
                      _buildSwitchTile(
                        icon: Icons.recycling_rounded,
                        label: 'Allow Remix',
                        value: _allowsRemix,
                        onChanged: (v) => setState(() => _allowsRemix = v),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Draft / Post Buttons (Sticky Bottom)
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        label: 'Drafts',
                        icon: Icons.inventory_2_outlined,
                        isPrimary: false,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildButton(
                        label: _isPosting ? 'Posting...' : 'Post',
                        icon: Icons.send_rounded,
                        isPrimary: true,
                        isLoading: _isPosting,
                        onTap: () async {
                          if (_isPosting) return;

                          // Validate title
                          if (_titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please add a title for your game',
                                  style: GoogleFonts.outfit(color: Colors.white),
                                ),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          HapticFeedback.heavyImpact();
                          setState(() => _isPosting = true);

                          try {
                            final currentUser = ApiService().currentUser;

                            // Debug: Check if user and gameHtml exist
                            print('DEBUG PostGame: currentUser = ${currentUser?.username}');
                            print('DEBUG PostGame: gameHtml length = ${widget.gameHtml?.length ?? 0}');
                            print('DEBUG PostGame: title = ${_titleController.text.trim()}');

                            if (currentUser == null) {
                              throw Exception('You must be logged in to post a game');
                            }

                            if (widget.gameHtml == null || widget.gameHtml!.isEmpty) {
                              throw Exception('No game content to post. Please generate a game first.');
                            }

                            final gameTitle = _titleController.text.trim();
                            if (gameTitle.isEmpty) {
                              throw Exception('Please enter a game title');
                            }

                            final gameToCreate = GameModel(
                              id: '', // Server assigns ID
                              title: gameTitle,
                              description: _captionController.text.trim(),
                              thumbnailUrl: 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/600',
                              gameUrl: widget.gameHtml!, // Store the HTML content
                              gameType: 'html5',
                              creator: currentUser,
                              createdAt: DateTime.now(),
                              hashtags: _extractHashtags(_captionController.text),
                            );

                            await ApiService().createGame(
                              gameToCreate,
                              widget.gameHtml!
                            );

                            if (mounted) {
                              // Show success animation
                              _showSuccessAndNavigate();
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isPosting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to post: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: Color(0xFF0F0F0F)),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                'Post Game',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Balance spacer
          const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }

  Widget _buildCaptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Preview (Mini Lava Lamp)
          Container(
            width: 80,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Blob
                  Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5576F8),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 2000.ms,
                      ),

                  // Blur
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title + Caption Field
          Expanded(
            child: SizedBox(
              height: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Game title',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF666666),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Add a description... #GameAI',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFF555555),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF888888), size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: const Color(0xFF666666),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF444444),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF888888), size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5576F8),
            activeTrackColor: const Color(0xFF5576F8).withOpacity(0.2),
            inactiveTrackColor: const Color(0xFF2C2C2C),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF5576F8) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: isLoading
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: isPrimary ? Colors.white : const Color(0xFF888888),
                  strokeWidth: 2,
                )
              )
            )
          : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : const Color(0xFF888888),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isPrimary ? Colors.white : const Color(0xFF888888),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
