import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../auth/auth_modal.dart';
import 'ai_chat_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generateGame() async {
    if (_promptController.text.trim().isEmpty) return;

    // Check if user can generate (logged in OR has free trial)
    if (!ApiService().canGenerateGame()) {
      // Show auth modal - user has used their free trial
      final success = await AuthModal.show(context);
      if (!success) return; // User cancelled
    }

    HapticFeedback.mediumImpact();

    // Navigate to AI Chat screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AiChatScreen(initialPrompt: _promptController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: const Color(0xFF0F0F0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Create Game',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Divider
            Container(height: 0.5, color: const Color(0xFF1A1A1A)),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Describe your dream game',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI will instantly generate a playable game based on your description.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF888888),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Prompt Input Container
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _promptController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.5,
                        ),
                        cursorColor: AppColors.accentPrimary,
                        decoration: InputDecoration(
                          hintText:
                              'e.g., "A fast-paced endless runner where a neon cat dodges laser beams in a cyberpunk city..."',
                          hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFF555555),
                            fontSize: 18,
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                          filled: false,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    Text(
                      'Quick Ideas',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Prompts
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildQuickPrompt(
                          '🏎️ Racing',
                          'A fast racing game where you dodge traffic on a neon highway',
                        ),
                        _buildQuickPrompt(
                          '🧩 Puzzle',
                          'A relaxing puzzle game where you match colorful gems to score points',
                        ),
                        _buildQuickPrompt(
                          '🎯 Shooter',
                          'A space shooter where you destroy alien ships with laser beams',
                        ),
                        _buildQuickPrompt(
                          '🏃 Platformer',
                          'A jumping platformer where you collect coins and avoid obstacles',
                        ),
                        _buildQuickPrompt(
                          '🏰 RPG',
                          'A dungeon adventure where you fight monsters and find treasure',
                        ),
                        _buildQuickPrompt(
                          '🚀 Space',
                          'An asteroid dodging game in deep space with power-ups',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Area
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottomPadding + 16,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F0F),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show free trial badge for anonymous users
                  if (!ApiService().isLoggedIn && !ApiService().hasUsedFreeTrial)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFF25D366), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '1 Free Game - No account needed!',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF25D366),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: GestureDetector(
                      onTap: _isGenerating ? null : _generateGame,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: _isGenerating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Generate Game',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompt(String label, String prompt) {
    return GestureDetector(
      onTap: () {
        _promptController.text = prompt;
        _promptController.selection = TextSelection.fromPosition(
          TextPosition(offset: _promptController.text.length),
        );
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
