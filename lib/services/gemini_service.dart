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

/// Response containing both thinking and output text
class GeminiResponse {
  final String thinkingText;
  final String outputText;

  GeminiResponse({required this.thinkingText, required this.outputText});
}

/// Production-ready Gemini API service via Cloudflare Worker proxy with streaming.
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
    // Optimization: Removed redundant model confirmation ("I understand") to save tokens.
  }

  /// Generate game code with real-time streaming of thoughts.
  Stream<GeminiResponse> generateGameStream(String prompt) async* {
    if (!_isInitialized) {
      throw Exception(
        'GeminiService not initialized. Call initialize() first.',
      );
    }

    // Add user message to history
    // Check if the last message was also from the user (e.g. system prompt)
    // If so, merge them to avoid "User, User" sequence which some API versions reject.
    if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
      final lastParts = _chatHistory.last['parts'] as List<dynamic>;
      lastParts.add({'text': "\n\n" + prompt});
    } else {
      _chatHistory.add({
        'role': 'user',
        'parts': [
          {'text': prompt},
        ],
      });
    }

    final client = http.Client();

    try {
      final request = http.Request('POST', Uri.parse(_workerUrl));
      request.headers['Content-Type'] = 'application/json';
      request.headers['App-Secret'] = _appSecret;
      request.body = jsonEncode({'history': _chatHistory});

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 401) {
        throw Exception('Unauthorized: Invalid App-Secret');
      }

      if (streamedResponse.statusCode != 200) {
        throw Exception('API Error: ${streamedResponse.statusCode}');
      }

      String thinkingText = '';
      String outputText = '';
      String buffer = '';

      // Process the SSE stream
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // Parse SSE events (each event is "data: {...}\n\n")
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex);
          buffer = buffer.substring(newlineIndex + 1);

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final data = jsonDecode(jsonStr);

              // Check for API errors
              if (data['error'] != null) {
                throw Exception('Gemini Error: ${data['error']}');
              }

              final parts = data['candidates']?[0]?['content']?['parts'] as List<dynamic>?;

              if (parts != null) {
                for (final part in parts) {
                  if (part['thought'] == true) {
                    // This is a thinking part
                    thinkingText += part['text'] ?? '';
                  } else {
                    // This is the output part
                    outputText += part['text'] ?? '';
                  }
                }

                // Yield updated response
                yield GeminiResponse(
                  thinkingText: thinkingText,
                  outputText: outputText,
                );
              }
            } catch (e) {
              // Skip invalid JSON lines
              if (e is FormatException) continue;
              rethrow;
            }
          }
        }
      }

      // Ensure we have some output
      if (outputText.isEmpty && thinkingText.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      // Add model response to history (only the output, not thinking)
      _chatHistory.add({
        'role': 'model',
        'parts': [
          {'text': outputText},
        ],
      });
    } catch (e) {
      // Remove failed user message from history
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Generate game code synchronously (non-streaming).
  Future<GeminiResponse> generateGame(String prompt) async {
    GeminiResponse? result;
    await for (final response in generateGameStream(prompt)) {
      result = response;
    }
    return result ?? GeminiResponse(thinkingText: '', outputText: '');
  }

  /// Refine an existing game based on user feedback.
  Stream<GeminiResponse> refineGameStream(
    String currentHtml,
    String userRequest, {
    List<GameAsset>? assets,
  }) async* {
    // Optimization: Reset history to avoid token bloat.
    // The refinement prompt already contains the full current state (HTML).
    _chatHistory.clear();

    // Add system prompt again to ensure the model knows its role/constraints
    final systemPrompt = GamePromptBuilder.buildSystemPrompt(assets: assets);
    _chatHistory.add({
      'role': 'user',
      'parts': [
        {'text': systemPrompt},
      ],
    });

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
