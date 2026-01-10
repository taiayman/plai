/// Utility class for building optimized prompts for HTML game generation.
class GamePromptBuilder {
  /// System prompt that instructs Gemini to generate playable HTML5 games.
  static String buildSystemPrompt({List<GameAsset>? assets}) {
    final assetsSection = assets != null && assets.isNotEmpty
        ? '''
Assets to use:
${assets.map((a) => '- ${a.type} ("${a.name}"): ${a.url}').join('\n')}
'''
        : '';

    return '''
HTML5 Game. Single File.
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<link href="https://fonts.googleapis.com/css2?family=Luckiest+Guy&display=swap" rel="stylesheet">

STYLE GUIDELINES (MANDATORY):
1. FONT: Use 'Luckiest Guy', cursive. WHITE text with BLACK outline (text-stroke: 2px black).
2. UI: Clean, flat, rounded. NO gradients, NO default buttons.
3. ART: High-quality emojis or crisp shapes. NO blurry/messy drawing.
4. SFX: Use AudioContext. CRITICAL: Wrap ALL audio calls in try-catch. Audio MUST NOT crash the game.
5. LIBS: Use cdnjs.com for Three.js (3D) or Matter.js (Physics) IF requested.
6. 3D: For Three.js, camera.fov must be ~75 but logic MUST handle aspect < 1 (Portrait) by moving camera BACK or widening FOV. Canvas must fill 100% height.
   - NO external textures (jpg/png). Use simple Colors or generated Canvas textures.
   - MUST add AmbientLight AND DirectionalLight.
7. GIFS: Async fetch url -> new Image() -> draw in loop only when loaded. API: `https://my-chat-helper.taiayman13-ed6.workers.dev/tenor/search?q=KEYWORD`.
8. 3D CONTROLS: Virtual Joystick (Left) + Jump (Right). SWIPE screen to rotate Camera/Look.
9. SPAWN: Disable player gravity for first 3s. Start Y=5 above ground. Prevent infinite fall loops.
10. UI LAYOUT: Keep all UI inside 90% width centered. Use `bottom: 100px` to clear home bar.

TECH SPECS:
- Body: margin:0, overflow:hidden. Canvas: 100vw/100vh.
- Resize: Update canvas.width/height on window resize.
- Input: touchstart/mousedown = ACTION. touchend/mouseup = END.
- Critical: preventDefault() on CANVAS touches only. Allow UI clicks.
- Logic: Relative positioning (w*0.5).
- Loop: NEVER stop the loop on errors. Log errors to console only.

$assetsSection
Output VALID HTML ONLY in ```html``` block.
''';
  }

  /// Builds a refinement prompt when user wants to modify an existing game.
  static String buildRefinementPrompt(
    String currentHtml,
    String userRequest, {
    List<GameAsset>? assets,
  }) {
    // Optimization: Don't send assets again if they are already in the HTML
    // We only attach new assets or if specifically needed.
    // For now, we'll keep it simple but the prompt below is shorter.

    return '''
Current Game:
```html
$currentHtml
```

Task: $userRequest
Output FULL updated HTML.
''';
  }

  /// Builds the initial game generation prompt from user's description.
  static String buildGamePrompt(
    String userDescription, {
    List<GameAsset>? assets,
  }) {
    return userDescription;
  }
}

/// Represents an asset provided by the user
class GameAsset {
  final String type; // 'image', 'gif', 'sound'
  final String name;
  final String url;

  const GameAsset({required this.type, required this.name, required this.url});
}
