import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class GameWebViewController {
  WebViewController? _webViewController;

  void _attach(WebViewController controller) {
    _webViewController = controller;
  }

  void _detach() {
    _webViewController = null;
  }

  void setControlState(String key, bool isPressed) {
    _webViewController?.runJavaScript(
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
  late final WebViewController _controller;
  bool _isReady = false;
  bool _isControlPressed = false;

  @override
  void initState() {
    super.initState();
    _initController();
    widget.controller?._attach(_controller);
  }

  @override
  void didUpdateWidget(GameWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_controller);
    }
    if (widget.isActive != oldWidget.isActive && _isReady) {
      if (widget.isActive) {
        _controller.runJavaScript('window.resumeGame && window.resumeGame();');
      } else {
        _controller.runJavaScript('window.pauseGame && window.pauseGame();');
      }
    }
  }

  void _initController() {
    _controller = WebViewController();

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1a1a2e))
      ..addJavaScriptChannel(
        'GameControl',
        onMessageReceived: (message) {
          final isPressed = message.message == 'pressed';
          if (_isControlPressed != isPressed) {
            _isControlPressed = isPressed;
            widget.onInteractionChanged?.call(isPressed);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isReady = true);
            }
          },
        ),
      );

    if (Platform.isAndroid) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    // Enable gesture navigation to allow scrolling inside the game if needed
    // but the PageView handles vertical swipe for feed navigation.
    // To allow game interaction we rely on GameControl channel or tap events.

    // Create a wrapper to capture touches for the feed
    // In the future we might want to inject JS to capture touch start/end
    // and communicate with Flutter to disable feed scrolling.

    // Load the actual game HTML or fallback to demo
    final htmlToLoad = widget.gameHtml ?? _defaultGameHtml;
    _controller.loadHtmlString(htmlToLoad);
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the WebView in a GestureDetector to allow it to receive touches
    // The PageView in HomeScreen uses `_isGameInteracting` to decide whether to scroll.
    // Since we removed the overlay buttons, users interact directly with the WebView.
    // We need to ensure touches are passed to the WebView but we also might need
    // to detect when the user wants to scroll the feed.
    //
    // For now, we assume simple tap/drag games.
    // We can use a listener to detect touch down/up to lock the feed.

    return Listener(
      onPointerDown: (_) {
        widget.onInteractionChanged?.call(true);
      },
      onPointerUp: (_) {
         // Optional: delay releasing the lock or keep it until a specific action
         // For many games (flappy bird style), we might want to keep it locked
         // while the game is "active". But for simple taps, maybe not.
         // Let's keep it simple: Touch down locks, Touch up unlocks after a delay?
         // Actually, for "drag" games, we need it locked during the drag.

         // If we unlock immediately on up, swipe gestures might still trigger page view.
         // Let's just pass the interaction state.

         // A better UX might be:
         // 1. Long press to lock/unlock feed?
         // 2. Or just rely on the fact that if they are touching the game, they are playing.

         // Let's try unlocking on pointer up.
         widget.onInteractionChanged?.call(false);
      },
      onPointerCancel: (_) {
        widget.onInteractionChanged?.call(false);
      },
      child: WebViewWidget(controller: _controller),
    );
  }
}
