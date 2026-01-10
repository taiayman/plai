class GameHtmlProcessor {
  /// Processes the raw HTML to ensure it works correctly in WebViews.
  ///
  /// [html]: The raw HTML content of the game.
  /// [showDebugOverlay]: Whether to show the green debug overlay (default: true).
  /// [forceFullScreen]: Whether to inject CSS to force full screen (default: true).
  static String process(
    String html, {
    bool showDebugOverlay = false,
    bool forceFullScreen = true,
  }) {
    // Inject a script that runs BEFORE the game to fix window dimensions and show debug info
    final fixScript =
        '''
    <script>
      (function() {
        // ${showDebugOverlay ? _getDebugScript() : ''}

        function updateStatus(msg) {
          // Debug status overlay removed for production
          // We still log errors to console for Flutter debugging
          console.log('[GAME ERROR]: ' + msg);
        }

        window.onerror = function(msg, url, line) {
          updateStatus("JS Error: " + msg + " (Line " + line + ")");
          return false; // Let default handler run too
        };

        function forceResize() {
          ${forceFullScreen ? _getFullScreenScript() : ''}
          
          var w = window.innerWidth;
          var h = window.innerHeight;
          var c = document.querySelector('canvas');
          
          if (c) {
             // Explicitly set canvas size to match window
             c.width = w;
             c.height = h;
             c.style.width = w + 'px';
             c.style.height = h + 'px';
             // updateStatus("Canvas: " + w + "x" + h);
          } else {
             // updateStatus("No Canvas Found! Win: " + w + "x" + h);
          }
          // window.dispatchEvent(new Event('resize')); // CAUSES INFINITE LOOP
        }

        window.addEventListener('load', forceResize);
        window.addEventListener('resize', forceResize);
        document.addEventListener('DOMContentLoaded', forceResize);
        setInterval(forceResize, 1000);

        // --- AUDIO CONTEXT UNLOCKER ---
        // Mobile browsers suspend AudioContext until user interaction.
        // We automatically resume it on the first touch/click.
        function unlockAudio() {
          var contexts = [];
          // Check standard names
          if (window.audioCtx) contexts.push(window.audioCtx);
          if (window.audioContext) contexts.push(window.audioContext);
          if (window.SFX && window.SFX.ctx) contexts.push(window.SFX.ctx);

          // Brute force search for any AudioContext in global scope
          for (var key in window) {
            try {
              if (window[key] instanceof AudioContext) {
                contexts.push(window[key]);
              }
            } catch(e) {}
          }

          // Resume all found contexts
          contexts.forEach(function(ctx) {
            if (ctx && ctx.state === 'suspended') {
              ctx.resume();
            }
          });
        }
        document.addEventListener('touchstart', unlockAudio, {passive: true});
        document.addEventListener('click', unlockAudio, {passive: true});
        document.addEventListener('keydown', unlockAudio, {passive: true});

      })();
    </script>
    ''';

    String result = html;

    // If generic HTML without basic tags (sometimes happens with weak models), wrap it
    if (!result.contains('<!DOCTYPE html>')) {
      result = '<!DOCTYPE html><html><head></head><body>$result</body></html>';
    }

    // --- SAFE STORAGE POLYFILL ---
    // Prevent SecurityError when accessing localStorage in data: URI
    // Must be injected in HEAD to run before game scripts
    final safeStorageScript = '''
    <script>
      (function() {
        try {
          var x = '__storage_test__';
          localStorage.setItem(x, x);
          localStorage.removeItem(x);
        } catch (e) {
          console.warn('LocalStorage blocked, using memory fallback');
          var memoryStorage = {};
          var fakeStorage = {
            getItem: function(key) { return memoryStorage[key] || null; },
            setItem: function(key, value) { memoryStorage[key] = String(value); },
            removeItem: function(key) { delete memoryStorage[key]; },
            clear: function() { memoryStorage = {}; },
            key: function(i) { return Object.keys(memoryStorage)[i]; },
            get length() { return Object.keys(memoryStorage).length; }
          };
          try {
            Object.defineProperty(window, 'localStorage', {
              value: fakeStorage,
              configurable: true,
              enumerable: true,
              writable: true
            });
          } catch(e2) {
             try { window.localStorage = fakeStorage; } catch(e3) {}
          }
        }
      })();
    </script>
    ''';

    if (result.contains('<head>')) {
      result = result.replaceFirst('<head>', '<head>$safeStorageScript');
    } else if (result.contains('<html>')) {
      result = result.replaceFirst('<html>', '<html><head>$safeStorageScript</head>');
    } else {
      result = '$safeStorageScript$result';
    }

    // --- CRITICAL: INJECT CSS FOR VIEWPORT STABILITY ---
    // We inject this directly into <head> to ensure it applies immediately,
    // rather than waiting for JS to run.
    final cssReset = '''
    <style>
      html, body {
        width: 100vw !important;
        height: 100vh !important;
        margin: 0 !important;
        padding: 0 !important;
        overflow: hidden !important;
        /* Removed touch-action: none from body to allow UI clicks if any */
      }
      canvas {
        display: block !important;
        width: 100vw !important;
        height: 100vh !important;
        touch-action: none !important; /* Keep on canvas for game control */
        user-select: none !important;
        -webkit-user-select: none !important;
      }
    </style>
    ''';

    if (result.contains('</head>')) {
      result = result.replaceFirst('</head>', '$cssReset</head>');
    } else if (result.contains('<head>')) {
      result = result.replaceFirst('<head>', '<head>$cssReset');
    } else {
      // If no head, inject at start of html or body
      if (result.contains('<html>')) {
        result = result.replaceFirst('<html>', '<html><head>$cssReset</head>');
      } else {
        result = '<head>$cssReset</head>$result';
      }
    }

    // Ensure Viewport exists
    if (!result.contains('viewport')) {
      const viewportParam =
          'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
      if (result.contains('<head>')) {
        result = result.replaceFirst(
          '<head>',
          '<head><meta name="viewport" content="\$viewportParam">',
        );
      } else {
        result =
            '<head><meta name="viewport" content="\$viewportParam"></head>$result';
      }
    }

    // Inject fix script
    // We inject at the END of body to ensure body exists for appendChild
    if (result.contains('</body>')) {
      result = result.replaceFirst('</body>', '$fixScript</body>');
    } else {
      result = '$result$fixScript';
    }

    return result;
  }

  static String _getDebugScript() {
    return '''
        var d=document.createElement('div');
        d.id='debug-status';
        d.style.cssText='position:fixed;top:0;left:0;background:rgba(255,0,0,0.8);color:white;font-size:12px;z-index:99999;padding:4px;pointer-events:none;';
        document.body.appendChild(d);
    ''';
  }

  static String _getFullScreenScript() {
    return '''
          // Force body/html to full viewport
          document.documentElement.style.width = '100vw';
          document.documentElement.style.height = '100vh';
          document.body.style.width = '100vw';
          document.body.style.height = '100vh';
          document.body.style.margin = '0';
          document.body.style.padding = '0';
          document.body.style.overflow = 'hidden';
    ''';
  }
}
