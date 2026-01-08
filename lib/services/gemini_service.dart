import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'game_prompt_builder.dart';

/// Message model for chat history
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Convert to Gemini API format
  Map<String, dynamic> toGeminiFormat() {
    return {
      'role': isUser ? 'user' : 'model',
      'parts': [
        {'text': text},
      ],
    };
  }
}

/// Production-ready Gemini API service via Cloudflare Worker proxy.
class GeminiService {
  // Cloudflare Worker URL
  static const String _workerUrl =
      'https://my-chat-helper.taiayman13-ed6.workers.dev/';
  static const String _appSecret = 'MySecretPassword123';

  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isInitialized = false;

  /// Singleton instance
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  /// Initialize the Gemini service.
  Future<void> initialize() async {
    _isInitialized = true;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Start a new chat session for game generation.
  void startNewSession({List<GameAsset>? assets}) {
    _chatHistory.clear();

    // Add system prompt as first message (with assets if provided)
    final systemPrompt = GamePromptBuilder.buildSystemPrompt(assets: assets);
    _chatHistory.add({
      'role': 'user',
      'parts': [
        {'text': systemPrompt},
      ],
    });
    _chatHistory.add({
      'role': 'model',
      'parts': [
        {
          'text':
              'I understand. I will generate complete HTML5 games as requested.',
        },
      ],
    });
  }

  /// Generate game code (non-streaming, returns complete response).
  Stream<String> generateGameStream(String prompt) async* {
    if (!_isInitialized) {
      throw Exception(
        'GeminiService not initialized. Call initialize() first.',
      );
    }

    // Add user message to history
    _chatHistory.add({
      'role': 'user',
      'parts': [
        {'text': prompt},
      ],
    });

    try {
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json', 'App-Secret': _appSecret},
        body: jsonEncode({'history': _chatHistory}),
      );

      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid App-Secret');
      }

      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);

      // Check for API errors
      if (data['error'] != null) {
        throw Exception('Gemini Error: ${data['error']}');
      }

      // Extract text from response
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

      if (text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      // Add model response to history
      _chatHistory.add({
        'role': 'model',
        'parts': [
          {'text': text},
        ],
      });

      // Yield the complete response (simulating stream for compatibility)
      yield text;
    } catch (e) {
      // Remove failed user message from history
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      rethrow;
    }
  }

  /// Generate game code synchronously (non-streaming).
  Future<String> generateGame(String prompt) async {
    final buffer = StringBuffer();
    await for (final chunk in generateGameStream(prompt)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  /// Refine an existing game based on user feedback.
  Stream<String> refineGameStream(
    String currentHtml,
    String userRequest, {
    List<GameAsset>? assets,
  }) async* {
    final prompt = GamePromptBuilder.buildRefinementPrompt(
      currentHtml,
      userRequest,
      assets: assets,
    );
    yield* generateGameStream(prompt);
  }

  /// Extract HTML code from a markdown response.
  static String extractHtmlFromResponse(String response) {
    // Try to find HTML code block
    final htmlBlockRegex = RegExp(
      r'```html\s*([\s\S]*?)\s*```',
      multiLine: true,
    );

    final match = htmlBlockRegex.firstMatch(response);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }

    // Try generic code block
    final genericBlockRegex = RegExp(
      r'```\s*([\s\S]*?)\s*```',
      multiLine: true,
    );

    final genericMatch = genericBlockRegex.firstMatch(response);
    if (genericMatch != null && genericMatch.group(1) != null) {
      final content = genericMatch.group(1)!.trim();
      if (content.contains('<!DOCTYPE') || content.contains('<html')) {
        return content;
      }
    }

    // If response starts with <!DOCTYPE or <html, assume it's raw HTML
    final trimmed = response.trim();
    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html')) {
      return trimmed;
    }

    return '';
  }

  /// Extract the conversational text (everything outside the code blocks).
  static String getConversationalText(String response) {
    // Remove HTML code block
    final htmlBlockRegex = RegExp(
      r'```html\s*[\s\S]*?```',
      multiLine: true,
    );
    var cleanText = response.replaceAll(htmlBlockRegex, '').trim();

    // Remove generic code block if it looks like HTML
    final genericBlockRegex = RegExp(
      r'```\s*[\s\S]*?```',
      multiLine: true,
    );

    // Check if we still have code blocks that might be the game
    final matches = genericBlockRegex.allMatches(cleanText);
    for (final match in matches) {
      final content = match.group(0) ?? '';
      if (content.contains('<!DOCTYPE') || content.contains('<html')) {
        cleanText = cleanText.replaceAll(content, '');
      }
    }

    // Handle unclosed code blocks (for streaming)
    // If there's an opening backtick sequence that isn't closed, strip everything after it
    if (cleanText.contains('```')) {
      cleanText = cleanText.substring(0, cleanText.indexOf('```'));
    }

    // Also remove raw HTML if it starts with doctype (fallback)
    if (cleanText.trim().startsWith('<!DOCTYPE') || cleanText.trim().startsWith('<html')) {
      return "Game generated.";
    }

    return cleanText.trim();
  }

  /// Clean up resources
  void dispose() {
    _chatHistory.clear();
    _isInitialized = false;
  }
}
