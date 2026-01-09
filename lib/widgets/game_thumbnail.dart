import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A reusable widget that displays a game HTML as a scaled thumbnail preview.
/// Uses WebView to render the actual game content scaled down to fit the container.
class GameThumbnail extends StatefulWidget {
  /// The HTML content of the game to display
  final String gameHtml;

  /// Width of the thumbnail container (default: 160)
  final double width;

  /// Height of the thumbnail container (default: 284 for 9:16 aspect ratio)
  final double height;

  /// Border radius for the thumbnail
  final double borderRadius;

  const GameThumbnail({
    super.key,
    required this.gameHtml,
    this.width = 160,
    this.height = 284,
    this.borderRadius = 12,
  });

  @override
  State<GameThumbnail> createState() => _GameThumbnailState();
}

class _GameThumbnailState extends State<GameThumbnail> {
  WebViewController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    // Reference game dimensions (9:16 aspect ratio)
    const double gameWidth = 360;
    const double gameHeight = 640;

    // Inject CSS to ensure proper rendering and hide scrollbars
    final scaledHtml = widget.gameHtml.replaceFirst('<head>', '''<head>
    <meta name="viewport" content="width=$gameWidth, height=$gameHeight, initial-scale=1, user-scalable=no">
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body {
        width: ${gameWidth}px !important;
        height: ${gameHeight}px !important;
        overflow: hidden !important;
        background: #000 !important;
      }
      /* Hide scrollbars */
      ::-webkit-scrollbar { display: none !important; width: 0 !important; height: 0 !important; }
      * { scrollbar-width: none !important; -ms-overflow-style: none !important; }
      #game-container, .game-container, [class*="container"] {
        width: ${gameWidth}px !important;
        height: ${gameHeight}px !important;
      }
      canvas {
        display: block !important;
        max-width: ${gameWidth}px !important;
        max-height: ${gameHeight}px !important;
      }
    </style>''');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isReady = true);
            }
          },
        ),
      )
      ..loadHtmlString(scaledHtml);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    // Calculate scale factor based on container size
    // Reference game is 360x640, scale to fit container
    final double scale = widget.width / 360;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            ClipRect(
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
                      child: WebViewWidget(controller: _controller!),
                    ),
                  ),
                ),
              ),
            ),
            // Loading overlay
            if (!_isReady)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
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
              ),
          ],
        ),
      ),
    );
  }
}
