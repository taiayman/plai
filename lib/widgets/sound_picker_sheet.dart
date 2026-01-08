import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundPickerSheet extends StatefulWidget {
  const SoundPickerSheet({super.key});

  static Future<Map<String, String>?> show(BuildContext context) async {
    return await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SoundPickerSheet(),
    );
  }

  @override
  State<SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<SoundPickerSheet> {
  String? _selectedCategory;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPreview(String url) async {
    try {
      if (_currentlyPlayingUrl == url && _isPlaying) {
        // Stop if same sound is playing
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
        });
      } else {
        // Play new sound
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _isPlaying = true;
          _currentlyPlayingUrl = url;
        });

        // Listen for completion
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentlyPlayingUrl = null;
            });
          }
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  // Free sound effects - verified working URLs from Mixkit
  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Retro & Arcade',
      'icon': Icons.sports_esports,
      'sounds': [
        {'name': 'Retro Jump', 'url': 'https://assets.mixkit.co/active_storage/sfx/223/223-preview.mp3'},
        {'name': 'Arcade Coin', 'url': 'https://assets.mixkit.co/active_storage/sfx/216/216-preview.mp3'},
        {'name': 'Winning Coin', 'url': 'https://assets.mixkit.co/active_storage/sfx/2069/2069-preview.mp3'},
        {'name': 'Coin Collect', 'url': 'https://assets.mixkit.co/active_storage/sfx/2015/2015-preview.mp3'},
        {'name': 'Arcade Bonus', 'url': 'https://assets.mixkit.co/active_storage/sfx/2044/2044-preview.mp3'},
        {'name': 'Retro Notify', 'url': 'https://assets.mixkit.co/active_storage/sfx/212/212-preview.mp3'},
        {'name': 'Casino Notify', 'url': 'https://assets.mixkit.co/active_storage/sfx/211/211-preview.mp3'},
        {'name': 'Level Complete', 'url': 'https://assets.mixkit.co/active_storage/sfx/2059/2059-preview.mp3'},
        {'name': 'Unlock', 'url': 'https://assets.mixkit.co/active_storage/sfx/253/253-preview.mp3'},
        {'name': 'Player Losing', 'url': 'https://assets.mixkit.co/active_storage/sfx/2042/2042-preview.mp3'},
        {'name': 'Game Over', 'url': 'https://assets.mixkit.co/active_storage/sfx/2157/2157-preview.mp3'},
        {'name': 'Arcade Game Over', 'url': 'https://assets.mixkit.co/active_storage/sfx/213/213-preview.mp3'},
      ],
    },
    {
      'name': 'Combat & Action',
      'icon': Icons.flash_on,
      'sounds': [
        {'name': 'Laser Shot', 'url': 'https://assets.mixkit.co/active_storage/sfx/1714/1714-preview.mp3'},
        {'name': 'Quick Laser', 'url': 'https://assets.mixkit.co/active_storage/sfx/1670/1670-preview.mp3'},
        {'name': 'Explosion', 'url': 'https://assets.mixkit.co/active_storage/sfx/1707/1707-preview.mp3'},
        {'name': 'Bomb Blast', 'url': 'https://assets.mixkit.co/active_storage/sfx/2811/2811-preview.mp3'},
        {'name': 'Heavy Stomp', 'url': 'https://assets.mixkit.co/active_storage/sfx/3049/3049-preview.mp3'},
        {'name': 'Blood Splatter', 'url': 'https://assets.mixkit.co/active_storage/sfx/2394/2394-preview.mp3'},
        {'name': 'Rocket Whoosh', 'url': 'https://assets.mixkit.co/active_storage/sfx/1718/1718-preview.mp3'},
      ],
    },
    {
      'name': 'UI Sounds',
      'icon': Icons.touch_app,
      'sounds': [
        {'name': 'Modern Click', 'url': 'https://assets.mixkit.co/active_storage/sfx/1120/1120-preview.mp3'},
        {'name': 'System Boot', 'url': 'https://assets.mixkit.co/active_storage/sfx/2574/2574-preview.mp3'},
        {'name': 'Success', 'url': 'https://assets.mixkit.co/active_storage/sfx/2019/2019-preview.mp3'},
        {'name': 'Success Bell', 'url': 'https://assets.mixkit.co/active_storage/sfx/266/266-preview.mp3'},
        {'name': 'Bubble Pop', 'url': 'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3'},
        {'name': 'Error Tone', 'url': 'https://assets.mixkit.co/active_storage/sfx/2572/2572-preview.mp3'},
        {'name': 'Glitch Buzz', 'url': 'https://assets.mixkit.co/active_storage/sfx/2594/2594-preview.mp3'},
        {'name': 'Toggle Switch', 'url': 'https://assets.mixkit.co/active_storage/sfx/2573/2573-preview.mp3'},
        {'name': 'Alarm Alert', 'url': 'https://assets.mixkit.co/active_storage/sfx/996/996-preview.mp3'},
      ],
    },
    {
      'name': 'Nature',
      'icon': Icons.park,
      'sounds': [
        {'name': 'Forest Birds', 'url': 'https://assets.mixkit.co/active_storage/sfx/2434/2434-preview.mp3'},
        {'name': 'Forest Night', 'url': 'https://assets.mixkit.co/active_storage/sfx/1224/1224-preview.mp3'},
        {'name': 'Night Crickets', 'url': 'https://assets.mixkit.co/active_storage/sfx/2443/2443-preview.mp3'},
        {'name': 'Light Rain', 'url': 'https://assets.mixkit.co/active_storage/sfx/2399/2399-preview.mp3'},
        {'name': 'Rain Loop', 'url': 'https://assets.mixkit.co/active_storage/sfx/1253/1253-preview.mp3'},
        {'name': 'River Flow', 'url': 'https://assets.mixkit.co/active_storage/sfx/2418/2418-preview.mp3'},
        {'name': 'Thunder', 'url': 'https://assets.mixkit.co/active_storage/sfx/2391/2391-preview.mp3'},
      ],
    },
    {
      'name': 'Music Loops',
      'icon': Icons.music_note,
      'sounds': [
        {'name': 'Chill Lo-Fi', 'url': 'https://assets.mixkit.co/music/preview/mixkit-tech-house-vibes-130.mp3'},
        {'name': 'Arcade Game', 'url': 'https://assets.mixkit.co/music/preview/mixkit-game-level-music-689.mp3'},
        {'name': 'Action Drive', 'url': 'https://assets.mixkit.co/music/preview/mixkit-driving-ambition-32.mp3'},
        {'name': 'Deep Space', 'url': 'https://assets.mixkit.co/music/preview/mixkit-slow-trail-71.mp3'},
        {'name': 'Deep Urban', 'url': 'https://assets.mixkit.co/music/preview/mixkit-deep-urban-132.mp3'},
        {'name': 'Relaxing Chill', 'url': 'https://assets.mixkit.co/music/preview/mixkit-relaxing-chill-145.mp3'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _selectedCategory != null
                      ? () => setState(() => _selectedCategory = null)
                      : null,
                  child: Row(
                    children: [
                      if (_selectedCategory != null) ...[
                        const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        _selectedCategory ?? 'Sound Effects',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedCategory == null
                ? _buildCategories()
                : _buildSounds(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = category['name'] as String);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5576F8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: const Color(0xFF5576F8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'] as String,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(category['sounds'] as List).length} sounds',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF888888),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF888888),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSounds() {
    final category = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => _categories[0],
    );
    final sounds = category['sounds'] as List;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: sounds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sound = sounds[index] as Map<String, String>;
        final soundUrl = sound['url']!;
        final isThisPlaying = _currentlyPlayingUrl == soundUrl && _isPlaying;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isThisPlaying
                ? const Color(0xFF25D366).withOpacity(0.1)
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            border: isThisPlaying
                ? Border.all(color: const Color(0xFF25D366).withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              // Play/Stop button
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _playPreview(soundUrl);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isThisPlaying
                        ? const Color(0xFF25D366)
                        : const Color(0xFF25D366).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isThisPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: isThisPlaying ? Colors.white : const Color(0xFF25D366),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound['name']!,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isThisPlaying)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Playing...',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF25D366),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Select button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _audioPlayer.stop();
                  Navigator.pop(context, sound);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5576F8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF5576F8),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Use',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF5576F8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
