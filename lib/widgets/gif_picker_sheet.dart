import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class GifPickerSheet extends StatefulWidget {
  const GifPickerSheet({super.key});

  static Future<String?> show(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GifPickerSheet(),
    );
  }

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _gifs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Tenor API - free tier, no auth needed for basic usage
  static const String _tenorApiKey = 'AIzaSyAyimkuYQYF_FXVALexPuGQctUWRURdCYQ'; // Public API key
  static const String _tenorBaseUrl = 'https://tenor.googleapis.com/v2';

  @override
  void initState() {
    super.initState();
    _loadTrendingGifs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingGifs() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$_tenorBaseUrl/featured?key=$_tenorApiKey&limit=30&media_filter=gif'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _gifs = List<Map<String, dynamic>>.from(data['results'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading GIFs: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.isEmpty) {
      _loadTrendingGifs();
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final response = await http.get(
        Uri.parse('$_tenorBaseUrl/search?key=$_tenorApiKey&q=$query&limit=30&media_filter=gif'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _gifs = List<Map<String, dynamic>>.from(data['results'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching GIFs: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getGifUrl(Map<String, dynamic> gif) {
    try {
      return gif['media_formats']['gif']['url'] ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getPreviewUrl(Map<String, dynamic> gif) {
    try {
      return gif['media_formats']['tinygif']['url'] ?? _getGifUrl(gif);
    } catch (e) {
      return _getGifUrl(gif);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                Text(
                  'Choose a GIF',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                cursorColor: const Color(0xFF5576F8),
                decoration: InputDecoration(
                  hintText: 'Search GIFs...',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF555555)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF555555)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: _searchGifs,
                onChanged: (value) {
                  if (value.isEmpty) _loadTrendingGifs();
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Category chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildChip('Funny', Icons.sentiment_very_satisfied),
                _buildChip('Reactions', Icons.emoji_emotions),
                _buildChip('Gaming', Icons.sports_esports),
                _buildChip('Animals', Icons.pets),
                _buildChip('Anime', Icons.animation),
                _buildChip('Memes', Icons.mood),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // GIF grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5576F8)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _gifs.length,
                    itemBuilder: (context, index) {
                      final gif = _gifs[index];
                      final previewUrl = _getPreviewUrl(gif);
                      final fullUrl = _getGifUrl(gif);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context, fullUrl);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: previewUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF2A2A2A),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF5576F8),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFF2A2A2A),
                                child: const Icon(Icons.error, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Tenor attribution
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Powered by Tenor',
              style: GoogleFonts.outfit(
                color: const Color(0xFF555555),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    final isSelected = _searchQuery.toLowerCase() == label.toLowerCase();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _searchController.text = label;
        _searchGifs(label);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5576F8) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
