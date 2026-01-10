import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/game_html_processor.dart';

/// A reusable widget that displays a game HTML as a scaled thumbnail preview.
/// Uses InAppWebView to render the actual game content scaled down to fit the container.
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
  bool _isReady = false;

  // Reference game dimensions (9:16 aspect ratio)
  static const double gameWidth = 360;
  static const double gameHeight = 640;

  final InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    hardwareAcceleration: true,
    useHybridComposition: true,
    supportZoom: false,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    disableContextMenu: true,
    transparentBackground: true,
  );

  String _prepareHtml() {
    // Inject CSS to ensure proper rendering and hide scrollbars
    // Also use the processor but maybe disable the BIG debug overlay for thumbnails
    // or keep it if we want to debug thumbnails too. Let's disable it for clean look.
    String processed = GameHtmlProcessor.process(
      widget.gameHtml,
      showDebugOverlay: false,
    );

    // Additional thumbnail-specific styles
    return processed.replaceFirst('<head>', '''<head>
    <style>
      ::-webkit-scrollbar { display: none !important; }
    </style>''');
  }

  @override
  Widget build(BuildContext context) {
    // Calculate scale factor based on container size
    final double scale = widget.width / gameWidth;

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
                maxWidth: gameWidth,
                maxHeight: gameHeight,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: gameWidth,
                    height: gameHeight,
                    child: IgnorePointer(
                      child: InAppWebView(
                        initialSettings: _webViewSettings,
                        initialData: InAppWebViewInitialData(
                          data: _prepareHtml(),
                          mimeType: 'text/html',
                          encoding: 'utf-8',
                        ),
                        onLoadStop: (controller, url) {
                          if (mounted) {
                            setState(() => _isReady = true);
                          }
                        },
                      ),
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
