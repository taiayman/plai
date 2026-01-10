import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_picker/image_picker.dart';
import 'post_game_screen.dart';
import '../../services/gemini_service.dart';
import '../../services/game_prompt_builder.dart';
import '../../services/game_generation_state.dart';
import '../../services/api_service.dart';
import '../../widgets/gif_picker_sheet.dart';
import '../../widgets/sound_picker_sheet.dart';
import '../../utils/game_html_processor.dart';

import '../auth/auth_modal.dart';

class AiChatScreen extends StatefulWidget {
  final String initialPrompt;
  final List<GameAsset>? initialAssets;

  const AiChatScreen({
    super.key,
    required this.initialPrompt,
    this.initialAssets,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _imagePicker = ImagePicker();

  final List<ChatMessage> _messages = [];
  final List<GameAsset> _assets = []; // User-provided assets
  bool _isPreviewMode = false;
  bool _showInputOptions = false;
  GameGenerationState _generationState = GameGenerationState.idle;

  String _currentStreamingText = '';
  String _currentThinkingText = '';
  String _generatedHtml = '';

  // Fake thinking steps for loading animation
  final List<String> _fakeCreationSteps = [
    'Analyzing game concept...',
    'Designing game mechanics...',
    'Setting up canvas...',
    'Creating player controls...',
    'Adding game physics...',
    'Generating sprites...',
    'Building game loop...',
    'Adding visual effects...',
    'Optimizing performance...',
    'Polishing gameplay...',
    'Finalizing game...',
  ];

  final List<String> _fakeRefinementSteps = [
    'Reading your feedback...',
    'Analyzing changes needed...',
    'Modifying game logic...',
    'Updating visuals...',
    'Adjusting mechanics...',
    'Refining controls...',
    'Tweaking parameters...',
    'Testing changes...',
    'Applying polish...',
    'Finalizing updates...',
  ];

  int _currentFakeStepIndex = 0;
  Timer? _fakeThinkingTimer;
  bool _isRefining = false;

  List<String> get _currentFakeSteps =>
      _isRefining ? _fakeRefinementSteps : _fakeCreationSteps;

  void _startFakeThinking() {
    _currentFakeStepIndex = 0;
    _fakeThinkingTimer?.cancel();
    _fakeThinkingTimer = Timer.periodic(const Duration(milliseconds: 2000), (
      timer,
    ) {
      if (!mounted || _generationState != GameGenerationState.generating) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentFakeStepIndex =
            (_currentFakeStepIndex + 1) % _currentFakeSteps.length;
      });
    });
  }

  void _stopFakeThinking() {
    _fakeThinkingTimer?.cancel();
    _fakeThinkingTimer = null;
  }

  // InAppWebView settings for high-performance game rendering
  final InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useHybridComposition: true,
    hardwareAcceleration: true,
    supportZoom: false,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    disableContextMenu: true,
    useWideViewPort: false,
    loadWithOverviewMode: false,
    builtInZoomControls: false,
    displayZoomControls: false,
    useShouldOverrideUrlLoading: false,
    transparentBackground: true,
  );

  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    // Initialize with assets from create screen if provided
    if (widget.initialAssets != null && widget.initialAssets!.isNotEmpty) {
      _assets.addAll(widget.initialAssets!);
    }
    _initializeAndGenerate();
  }

  Future<void> _initializeAndGenerate() async {
    // Add initial prompt as first message
    _messages.add(ChatMessage(text: widget.initialPrompt, isUser: true));

    try {
      // Initialize Gemini service
      await _geminiService.initialize();
      _geminiService.startNewSession(
        assets: _assets.isNotEmpty ? _assets : null,
      );

      // Start generating
      _generateGame(widget.initialPrompt);
    } catch (e) {
      setState(() {
        _generationState = GameGenerationState.error;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _stopFakeThinking();
    super.dispose();
  }

  Future<void> _generateGame(String prompt) async {
    _isRefining = false;
    setState(() {
      _generationState = GameGenerationState.generating;
      _currentStreamingText = '';
      _currentThinkingText = '';
    });

    // Start fake thinking animation
    _startFakeThinking();

    try {
      final gamePrompt = GamePromptBuilder.buildGamePrompt(prompt);

      await for (final response in _geminiService.generateGameStream(
        gamePrompt,
      )) {
        if (!mounted) return;

        setState(() {
          _currentThinkingText = response.thinkingText;
          _currentStreamingText = response.outputText;
        });

        // Auto-scroll to bottom
        _scrollToBottom();
      }

      // Stop fake thinking
      _stopFakeThinking();

      // Generation complete - extract HTML
      final html = GeminiService.extractHtmlFromResponse(_currentStreamingText);

      setState(() {
        _generatedHtml = html;
        _messages.add(
          ChatMessage(
            text: html.isNotEmpty ? "🎮 Game created!" : _currentStreamingText,
            isUser: false,
            gameHtml: html.isNotEmpty ? html : null,
          ),
        );
        _generationState = html.isNotEmpty
            ? GameGenerationState.preview
            : GameGenerationState.idle;
        _currentStreamingText = '';
        _currentThinkingText = '';

        // Auto-switch to preview if game is generated
        if (html.isNotEmpty) {
          _isPreviewMode = true;
        }
      });

      // Initialize WebView controller if HTML is ready
      if (html.isNotEmpty) {
        _initWebViewController(html);

        // Mark free trial as used for anonymous users
        if (!ApiService().isLoggedIn) {
          ApiService().markFreeTrialUsed();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generationState = GameGenerationState.error;
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an error: ${e.toString()}",
            isUser: false,
          ),
        );
      });
    }
  }

  /// Wrap HTML to ensure it works properly in WebView
  String _wrapHtmlForWebView(String html) {
    return GameHtmlProcessor.process(html);
  }

  void _initWebViewController(String html) {
    // We used to wrap HTML here, but now we keep _generatedHtml RAW
    // and only wrap it when passing to the WebView in _buildGamePreview.
    // This ensures we don't send injected scripts back to the AI during refinement.
    setState(() {});
  }

  Future<void> _refineGame(String request) async {
    if (_generatedHtml.isEmpty) {
      _generateGame(request);
      return;
    }

    _isRefining = true;
    setState(() {
      _generationState = GameGenerationState.generating;
      _currentStreamingText = '';
      _currentThinkingText = '';
    });

    // Start fake thinking animation
    _startFakeThinking();

    try {
      await for (final response in _geminiService.refineGameStream(
        _generatedHtml,
        request,
        assets: _assets.isNotEmpty ? _assets : null,
      )) {
        if (!mounted) return;

        setState(() {
          _currentThinkingText = response.thinkingText;
          _currentStreamingText = response.outputText;
        });

        _scrollToBottom();
      }

      // Stop fake thinking
      _stopFakeThinking();

      final html = GeminiService.extractHtmlFromResponse(_currentStreamingText);

      setState(() {
        if (html.isNotEmpty) {
          _generatedHtml = html;
          _initWebViewController(html);
        }
        _messages.add(
          ChatMessage(
            text: html.isNotEmpty ? "✨ Game updated!" : _currentStreamingText,
            isUser: false,
            gameHtml: html.isNotEmpty ? html : null,
          ),
        );
        _generationState = html.isNotEmpty
            ? GameGenerationState.preview
            : GameGenerationState.idle;
        _currentStreamingText = '';
        _currentThinkingText = '';

        // Auto-switch to preview if game is generated
        if (html.isNotEmpty) {
          _isPreviewMode = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generationState = GameGenerationState.error;
      });
    }
  }

  // Asset picker methods
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // For now, we'll use a placeholder approach
        // In production, you'd upload to Firebase Storage or imgbb
        // and get a real URL back
        HapticFeedback.mediumImpact();

        // Show a snackbar that image was added
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image feature coming soon! Use GIFs for now.',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF1E1E1E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _pickGif() async {
    final gifUrl = await GifPickerSheet.show(context);

    if (gifUrl != null && gifUrl.isNotEmpty) {
      setState(() {
        _assets.add(
          GameAsset(
            type: 'gif',
            name: 'User GIF ${_assets.length + 1}',
            url: gifUrl,
          ),
        );
        _showInputOptions = false;
      });

      HapticFeedback.mediumImpact();

      // Reinitialize session with new assets
      _geminiService.startNewSession(assets: _assets);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'GIF added! AI will use it in the game.',
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickSound() async {
    final sound = await SoundPickerSheet.show(context);

    if (sound != null) {
      setState(() {
        _assets.add(
          GameAsset(type: 'sound', name: sound['name']!, url: sound['url']!),
        );
        _showInputOptions = false;
      });

      HapticFeedback.mediumImpact();

      // Reinitialize session with new assets
      _geminiService.startNewSession(assets: _assets);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.music_note,
                  color: Color(0xFF5576F8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '"${sound['name']}" added!',
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeAsset(int index) {
    setState(() {
      _assets.removeAt(index);
    });
    _geminiService.startNewSession(assets: _assets.isNotEmpty ? _assets : null);
    HapticFeedback.lightImpact();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
    });

    _messageController.clear();
    HapticFeedback.lightImpact();
    _scrollToBottom();

    // Refine or generate based on current state
    _refineGame(message);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0F0F0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isPreviewMode
                      ? _buildGamePreview()
                      : _buildChatList(),
                ),
              ),
              if (!_isPreviewMode) _buildThickInputArea(bottomPadding),
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
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _buildToggleTab('Chat', !_isPreviewMode),
                _buildToggleTab('Preview', _isPreviewMode),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              if (_generatedHtml.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Generate a game first!',
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF1E1E1E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              // Check if user is logged in
              if (!ApiService().isLoggedIn) {
                // Show auth modal
                final success = await AuthModal.show(context);
                if (!success) return; // User cancelled auth
              }

              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PostGameScreen(gameHtml: _generatedHtml),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _generatedHtml.isNotEmpty
                      ? [const Color(0xFF5576F8), const Color(0xFF3B5BDB)]
                      : [const Color(0xFF333333), const Color(0xFF222222)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Post',
                style: GoogleFonts.outfit(
                  color: _generatedHtml.isNotEmpty
                      ? Colors.white
                      : const Color(0xFF666666),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(String label, bool isActive) {
    final isLocked =
        label == 'Preview' &&
        _generationState == GameGenerationState.generating;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() {
                _isPreviewMode = label == 'Preview';
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2C2C2C) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isLocked
                    ? const Color(0xFF555555)
                    : isActive
                    ? Colors.white
                    : const Color(0xFF888888),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final isGenerating = _generationState == GameGenerationState.generating;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: _messages.length + (isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        // Show thinking/generating UI when generating
        if (index == _messages.length && isGenerating) {
          return _buildThinkingUI();
        }

        if (index >= _messages.length) return const SizedBox.shrink();

        return _buildThickMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildThinkingUI() {
    // Use fake thinking steps for smooth animation
    final steps = _currentFakeSteps;
    final thinkingLabel = steps[_currentFakeStepIndex % steps.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thinking header with dynamic step title
          Row(
            children: [
              _buildAvatar(isUser: false),
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5576F8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF5576F8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            thinkingLabel,
                            key: ValueKey<String>(thinkingLabel),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF5576F8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // GTA V-style blurred preview animation
          Transform.translate(
            offset: const Offset(0, -8),
            child: Padding(
              padding: const EdgeInsets.only(left: 56, top: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 160,
                  height: 284,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Container(color: Colors.black),
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 60,
                                left: 20,
                                child:
                                    Container(
                                          width: 100,
                                          height: 100,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF5576F8),
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .moveY(
                                          begin: 0,
                                          end: 60,
                                          duration: 2500.ms,
                                          curve: Curves.easeInOut,
                                        )
                                        .then()
                                        .moveY(
                                          begin: 60,
                                          end: 0,
                                          duration: 2500.ms,
                                          curve: Curves.easeInOut,
                                        ),
                              ),
                              Positioned(
                                bottom: 80,
                                right: 10,
                                child:
                                    Container(
                                          width: 120,
                                          height: 120,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF2C55),
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .moveX(
                                          begin: 0,
                                          end: -40,
                                          duration: 3500.ms,
                                          curve: Curves.easeInOut,
                                        )
                                        .then()
                                        .moveX(
                                          begin: -40,
                                          end: 0,
                                          duration: 3500.ms,
                                          curve: Curves.easeInOut,
                                        ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child:
                              Text(
                                    'Creating...',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(
                                    duration: const Duration(seconds: 2),
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingMessage() {
    final cleanText = GeminiService.getConversationalText(
      _currentStreamingText,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(isUser: false),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Game AI",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFAAAAAA),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5576F8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Generating...',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF5576F8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cleanText.isNotEmpty
                        ? (cleanText.length > 500
                              ? '${cleanText.substring(0, 500)}...'
                              : cleanText)
                        : "Thinking...",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
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

  Widget _buildThickMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isGameCreatedMessage =
        !isUser &&
        (message.text.contains('Game created') ||
            message.text.contains('Game updated'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildAvatar(isUser: false),
                const SizedBox(width: 12),
              ],
              if (isUser) const Spacer(flex: 1),
              Flexible(
                flex: 3,
                child: isUser
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(6),
                            bottomLeft: const Radius.circular(20),
                            bottomRight: const Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          // Show 9:16 preview card for game created messages
          if (isGameCreatedMessage &&
              message.gameHtml != null &&
              message.gameHtml!.isNotEmpty)
            Transform.translate(
              offset: const Offset(0, -8),
              child: Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // Load this message's game into preview
                      _generatedHtml = message.gameHtml!;
                      _initWebViewController(message.gameHtml!);
                      setState(() {
                        _isPreviewMode = true;
                      });
                    },
                    child: Container(
                      width: 160,
                      height: 284, // 9:16 aspect ratio
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _GameThumbnail(html: message.gameHtml!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF333333) : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser
              ? const Color(0xFF444444)
              : const Color(0xFF5576F8).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        color: isUser ? const Color(0xFFDDDDDD) : const Color(0xFF5576F8),
        size: 20,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(isUser: false),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 6),
                _buildDot(1),
                const SizedBox(width: 6),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF555555),
              const Color(0xFF999999),
              value,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildGamePreview() {
    if (_generatedHtml.isEmpty) {
      return _buildEmptyPreview();
    }

    return Column(
      children: [
        // Action bar with hint and copy button
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Row(
            children: [
              // Hint to ask AI
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isPreviewMode = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF5576F8).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_fix_high_rounded,
                          color: const Color(0xFF5576F8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ask AI to modify',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFAAAAAA),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: const Color(0xFF666666),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Copy code button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _generatedHtml));
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF25D366),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'HTML copied to clipboard!',
                            style: GoogleFonts.outfit(color: Colors.white),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1E1E1E),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.code_rounded,
                    color: const Color(0xFFAAAAAA),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Game preview
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 80),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: InAppWebView(
                key: ValueKey(_generatedHtml.hashCode),
                initialSettings: _webViewSettings,
                initialData: InAppWebViewInitialData(
                  data: _wrapHtmlForWebView(_generatedHtml), // Process it here for display
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onConsoleMessage: (controller, consoleMessage) {
                  // Debug: print JS console messages
                  print('WebView Console: ${consoleMessage.message}');
                },
                onLoadStart: (controller, url) {
                  print('WebView: Load started');
                },
                onLoadStop: (controller, url) async {
                  print('WebView: Load finished');
                  // Just log dimensions - the polyfill should have fixed them
                  final result = await controller.evaluateJavascript(
                    source: '''
                    (function() {
                      var canvas = document.querySelector('canvas');
                      return 'Window: ' + window.innerWidth + 'x' + window.innerHeight +
                             ', Canvas: ' + (canvas ? canvas.width + 'x' + canvas.height : 'none');
                    })();
                  ''',
                  );
                  print('WebView: $result');
                },
                onLoadError: (controller, url, code, message) {
                  print('WebView Error: $code - $message');
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 80),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: Colors.black),
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Stack(
                children: [
                  Positioned(
                    top: 100,
                    left: 50,
                    child:
                        Container(
                              width: 180,
                              height: 180,
                              decoration: const BoxDecoration(
                                color: Color(0xFF5576F8),
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .moveY(
                              begin: 0,
                              end: 80,
                              duration: 5.seconds,
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .moveY(
                              begin: 80,
                              end: 0,
                              duration: 5.seconds,
                              curve: Curves.easeInOut,
                            ),
                  ),
                  Positioned(
                    bottom: 120,
                    right: 40,
                    child:
                        Container(
                              width: 200,
                              height: 200,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8945FF),
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .moveX(
                              begin: 0,
                              end: -50,
                              duration: 6.seconds,
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .moveX(
                              begin: -50,
                              end: 0,
                              duration: 6.seconds,
                              curve: Curves.easeInOut,
                            ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _generationState == GameGenerationState.generating
                      ? Icons.hourglass_empty_rounded
                      : Icons.sports_esports_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _generationState == GameGenerationState.generating
                      ? 'Generating your game...'
                      : 'No game yet',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_generationState != GameGenerationState.generating)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Describe your game idea in the chat',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThickInputArea(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showInputOptions)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _buildThickOption(
                    Icons.image_rounded,
                    'Image',
                    onTap: _pickImage,
                  ),
                  const SizedBox(width: 10),
                  _buildThickOption(
                    Icons.music_note_rounded,
                    'Sound',
                    onTap: _pickSound,
                  ),
                  const SizedBox(width: 10),
                  _buildThickOption(Icons.gif_rounded, 'GIF', onTap: _pickGif),
                ],
              ),
            ),

          // Show added assets
          if (_assets.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _assets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final asset = _assets[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                          asset.type == 'sound' ? Icons.music_note : Icons.gif,
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

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _messageController,
                  maxLines: null,
                  minLines: 2,
                  enabled: _generationState != GameGenerationState.generating,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: const Color(0xFF5576F8),
                  decoration: InputDecoration(
                    hintText: _generatedHtml.isEmpty
                        ? 'Describe your game idea...'
                        : 'Ask to modify your game...',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF555555),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showInputOptions = !_showInputOptions);
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
                    const Spacer(),
                    GestureDetector(
                      onTap: _generationState == GameGenerationState.generating
                          ? null
                          : _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              _generationState == GameGenerationState.generating
                              ? const Color(0xFF333333)
                              : const Color(0xFF5576F8),
                          shape: BoxShape.circle,
                        ),
                        child:
                            _generationState == GameGenerationState.generating
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? gameHtml; // Store HTML for game created messages

  ChatMessage({required this.text, required this.isUser, this.gameHtml});
}

/// Stateful widget to manage its own InAppWebView for each thumbnail
class _GameThumbnail extends StatelessWidget {
  final String html;

  const _GameThumbnail({required this.html});

  String _prepareHtmlForThumbnail() {
    // Inject CSS for fixed 360x640 rendering
    if (!html.contains('<head>')) return html;

    return html.replaceFirst('<head>', '''<head>
    <meta name="viewport" content="width=360, height=640, initial-scale=1, user-scalable=no">
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body {
        width: 360px !important;
        height: 640px !important;
        overflow: hidden !important;
        background: #000 !important;
      }
      ::-webkit-scrollbar { display: none !important; }
      canvas { display: block !important; }
    </style>''');
  }

  @override
  Widget build(BuildContext context) {
    // Scale factor: thumbnail is 160x284, game is 360x640
    const double scale = 0.444;

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: 360,
        maxHeight: 640,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            height: 640,
            child: IgnorePointer(
              child: InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _prepareHtmlForThumbnail(),
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  hardwareAcceleration: true,
                  useHybridComposition: true,
                  supportZoom: false,
                  verticalScrollBarEnabled: false,
                  horizontalScrollBarEnabled: false,
                  disableContextMenu: true,
                  transparentBackground: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
