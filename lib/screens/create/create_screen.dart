import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/gemini_service.dart';
import '../../services/game_prompt_builder.dart';
import '../../widgets/gif_picker_sheet.dart';
import '../../widgets/sound_picker_sheet.dart';
import '../auth/auth_modal.dart';
import 'ai_chat_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<GameAsset> _assets = [];
  bool _isGenerating = false;
  bool _hasText = false;
  bool _showInputOptions = false;

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      final hasText = _promptController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64 = 'data:image/png;base64,${base64Encode(bytes)}';

        setState(() {
          _assets.add(GameAsset(
            type: 'image',
            name: 'User Image ${_assets.length + 1}',
            url: base64,
          ));
          _showInputOptions = false;
        });

        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _pickGif() async {
    final gifUrl = await GifPickerSheet.show(context);

    if (gifUrl != null && gifUrl.isNotEmpty) {
      setState(() {
        _assets.add(GameAsset(
          type: 'gif',
          name: 'User GIF ${_assets.length + 1}',
          url: gifUrl,
        ));
        _showInputOptions = false;
      });

      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _pickSound() async {
    final sound = await SoundPickerSheet.show(context);

    if (sound != null) {
      setState(() {
        _assets.add(GameAsset(
          type: 'sound',
          name: sound['name']!,
          url: sound['url']!,
        ));
        _showInputOptions = false;
      });

      HapticFeedback.mediumImpact();
    }
  }

  void _removeAsset(int index) {
    setState(() {
      _assets.removeAt(index);
    });
    HapticFeedback.lightImpact();
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
        builder: (context) => AiChatScreen(
          initialPrompt: _promptController.text.trim(),
          initialAssets: _assets.isNotEmpty ? _assets : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

                    // Prompt Input Container with Send Button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 160,
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
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                                filled: false,
                              ),
                            ),
                          ),
                          // Input options row (Image, Sound, GIF) - same style as AI chat
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: _showInputOptions
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Row(
                                      children: [
                                        _buildThickOption(Icons.image_rounded, 'Image', onTap: _pickImage),
                                        const SizedBox(width: 10),
                                        _buildThickOption(Icons.music_note_rounded, 'Sound', onTap: _pickSound),
                                        const SizedBox(width: 10),
                                        _buildThickOption(Icons.gif_rounded, 'GIF', onTap: _pickGif),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Show added assets - same style as AI chat
                          if (_assets.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: SizedBox(
                                height: 40,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _assets.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final asset = _assets[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: asset.type == 'sound'
                                            ? const Color(0xFF5576F8).withOpacity(0.15)
                                            : const Color(0xFF25D366).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            asset.type == 'sound'
                                                ? Icons.music_note
                                                : asset.type == 'gif'
                                                    ? Icons.gif
                                                    : Icons.image,
                                            color: asset.type == 'sound'
                                                ? const Color(0xFF5576F8)
                                                : const Color(0xFF25D366),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            asset.name.length > 12
                                                ? '${asset.name.substring(0, 12)}...'
                                                : asset.name,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () => _removeAsset(index),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white.withOpacity(0.5),
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                          // Bottom row with add button and send button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              children: [
                                // Add button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _showInputOptions = !_showInputOptions;
                                    });
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF252525),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      _showInputOptions
                                          ? Icons.close_rounded
                                          : Icons.add_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Show free trial badge for anonymous users
                                if (!ApiService().isLoggedIn && !ApiService().hasUsedFreeTrial)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFF25D366), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '1 Free Game',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF25D366),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const Spacer(),
                                // Send button
                                GestureDetector(
                                  onTap: (_isGenerating || !_hasText) ? null : _generateGame,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _hasText
                                          ? AppColors.accentPrimary
                                          : const Color(0xFF333333),
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isGenerating
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            Icons.arrow_upward_rounded,
                                            color: _hasText
                                                ? Colors.white
                                                : const Color(0xFF666666),
                                            size: 24,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          '🎮 3D Runner',
                          'A 3D endless runner with dynamic camera angles, the player runs through a futuristic city with neon lights, can jump over obstacles, slide under barriers, and collect glowing orbs. Include smooth transitions between lanes, particle effects for speed boosts, and procedurally generated obstacles.',
                        ),
                        _buildQuickPrompt(
                          '🏎️ Drift Racer',
                          'A top-down drift racing game with realistic car physics, multiple race tracks, nitro boost system, and lap timing. Include skid marks, smoke particles, engine sounds, and a mini-map. Cars should have weight and momentum, with satisfying drift mechanics.',
                        ),
                        _buildQuickPrompt(
                          '⚔️ Hack & Slash',
                          'An isometric hack and slash action game with combo-based combat, multiple enemy types, and boss fights. Include a health bar, mana system for special attacks, dodge rolling, weapon variety, and satisfying hit effects with screen shake and particle explosions.',
                        ),
                        _buildQuickPrompt(
                          '🧠 Physics Puzzle',
                          'A physics-based puzzle game where you draw lines and shapes to guide a ball to the goal. Include realistic physics simulation, multiple levels with increasing difficulty, star rating system, and creative solutions. Add momentum, friction, and bouncy surfaces.',
                        ),
                        _buildQuickPrompt(
                          '🌌 Space Shooter',
                          'A vertical scrolling space shooter with upgradable weapons, shield powerups, and epic boss battles. Include bullet patterns, screen-clearing bombs, combo scoring system, and dynamic difficulty. Add particle explosions, laser beams, and satisfying enemy destruction effects.',
                        ),
                        _buildQuickPrompt(
                          '🏰 Tower Defense',
                          'A strategic tower defense game with multiple tower types, upgrade paths, and waves of enemies. Include a resource management system, special abilities, different enemy behaviors, and satisfying tower attack animations. Add path-finding enemies and strategic chokepoints.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThickOption(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5576F8), size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
