import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/game_html_processor.dart';

class GameWebViewController {
  InAppWebViewController? _webViewController;

  void _attach(InAppWebViewController controller) {
    _webViewController = controller;
  }

  void _detach() {
    _webViewController = null;
  }

  void setControlState(String key, bool isPressed) {
    _webViewController?.evaluateJavascript(
      source:
          'window.setControlState && window.setControlState("$key", $isPressed)',
    );
  }
}

class GameWebView extends StatefulWidget {
  final bool isActive;
  final String? gameHtml; // The HTML content to load
  final ValueChanged<bool>? onInteractionChanged;
  final GameWebViewController? controller;

  const GameWebView({
    super.key,
    this.isActive = true,
    this.gameHtml,
    this.onInteractionChanged,
    this.controller,
  });

  @override
  State<GameWebView> createState() => _GameWebViewState();
}

class _GameWebViewState extends State<GameWebView> {
  InAppWebViewController? _controller;
  bool _isReady = false;

  // High-performance settings for game rendering
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
    transparentBackground: false,
    domStorageEnabled: true, // Enable LocalStorage
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
  );

  @override
  void didUpdateWidget(GameWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      if (_controller != null) {
        widget.controller?._attach(_controller!);
      }
    }
    if (widget.isActive != oldWidget.isActive &&
        _isReady &&
        _controller != null) {
      if (widget.isActive) {
        _controller!.evaluateJavascript(
          source: 'window.resumeGame && window.resumeGame();',
        );
      } else {
        _controller!.evaluateJavascript(
          source: 'window.pauseGame && window.pauseGame();',
        );
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  // Default demo game when no game HTML is provided
  static const String _defaultGameHtml = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body {
            width: 100%; height: 100%;
            overflow: hidden;
            background: linear-gradient(180deg, #1a1a2e 0%, #0f0f23 100%);
            font-family: -apple-system, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            flex-direction: column;
        }
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
            opacity: 0.5;
        }
        .text {
            color: rgba(255,255,255,0.5);
            font-size: 18px;
            text-align: center;
        }
        .subtext {
            color: rgba(255,255,255,0.3);
            font-size: 14px;
            margin-top: 8px;
        }
    </style>
</head>
<body>
    <div class="icon">🎮</div>
    <div class="text">No game loaded</div>
    <div class="subtext">Swipe to browse games</div>
</body>
</html>''';

  @override
  Widget build(BuildContext context) {
    final rawHtml = widget.gameHtml ?? _defaultGameHtml;
    // Process HTML to ensure it works on mobile
    final htmlToLoad = GameHtmlProcessor.process(rawHtml);

    return Listener(
      onPointerDown: (_) {
        widget.onInteractionChanged?.call(true);
      },
      onPointerUp: (_) {
        widget.onInteractionChanged?.call(false);
      },
      onPointerCancel: (_) {
        widget.onInteractionChanged?.call(false);
      },
      child: InAppWebView(
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
        initialSettings: _webViewSettings,
        initialData: InAppWebViewInitialData(
          data: htmlToLoad,
          mimeType: 'text/html',
          encoding: 'utf-8',
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
          widget.controller?._attach(controller);

          // Add JavaScript channel for game control
          controller.addJavaScriptHandler(
            handlerName: 'GameControl',
            callback: (args) {
              if (args.isNotEmpty) {
                final isPressed = args[0] == 'pressed';
                widget.onInteractionChanged?.call(isPressed);
              }
              return null;
            },
          );
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint('GAME JS: \${consoleMessage.message}');
        },
        onLoadStop: (controller, url) async {
          if (mounted) {
            setState(() => _isReady = true);
          }
          // Trigger resize for canvas games
          await controller.evaluateJavascript(
            source: '''
            (function() {
              if (typeof resize === 'function') {
                try { resize(); } catch(e) {}
              }
              window.dispatchEvent(new Event('resize'));
            })();
          ''',
          );
        },
      ),
    );
  }
}
