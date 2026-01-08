/// Utility class for building optimized prompts for HTML game generation.
class GamePromptBuilder {
  /// System prompt that instructs Gemini to generate playable HTML5 games.
  static String buildSystemPrompt({List<GameAsset>? assets}) {
    final assetsSection = assets != null && assets.isNotEmpty
        ? '''

USER-PROVIDED ASSETS:
The user has provided the following assets to use in the game. You MUST incorporate them:
${assets.map((a) => '- ${a.type.toUpperCase()}: "${a.name}" - URL: ${a.url}').join('\n')}

For IMAGES/GIFs: Use them as sprites, backgrounds, or game elements with <img> tags or by drawing on canvas.
For SOUNDS: Use the Audio API to play them at appropriate moments (e.g., collect sound, jump, game over).

Example for loading an image:
const img = new Image();
img.src = 'THE_URL_HERE';
img.onload = () => { /* use in game */ };

Example for playing sound:
const sound = new Audio('THE_URL_HERE');
sound.play();
'''
        : '';

    return '''
You are an expert HTML5 game developer. Your task is to generate complete, playable games in a single HTML file.

STRICT RULES:
1. First, provide a VERY SHORT, simple status message (max 1 sentence).
   Example: "I've created a platformer for you. Let me know if you'd like any changes."
2. Then, output ONLY a single HTML file with embedded CSS and JavaScript in a markdown code block.
3. Use HTML5 Canvas for rendering (preferred) or DOM-based for simple games
4. Games MUST work on mobile devices with touch controls
5. Include a proper game loop using requestAnimationFrame
6. Ensure smooth animations and responsive controls
7. Keep the game fun and engaging
8. Include score tracking, game over state, and restart functionality
9. Optimize for performance - smooth 60fps gameplay
10. CRITICAL: Game canvas MUST fill the entire screen. Use CSS:
    body { margin: 0; overflow: hidden; touch-action: none; }
    canvas { display: block; width: 100vw; height: 100vh; }
$assetsSection
GAME STRUCTURE:
- Start screen with "Tap to Play" instruction
- Active gameplay with clear objectives
- Score display during gameplay
- Game over screen with final score and restart option

OUTPUT FORMAT:
Start with the short status message, then provide the code block:

I've created your game based on the description. Feel free to ask for modifications.

\`\`\`html
<!DOCTYPE html>
<html>
<!-- Complete game code here -->
</html>
\`\`\`
''';
  }

  /// Builds a refinement prompt when user wants to modify an existing game.
  static String buildRefinementPrompt(String currentHtml, String userRequest, {List<GameAsset>? assets}) {
    final assetsSection = assets != null && assets.isNotEmpty
        ? '''

AVAILABLE ASSETS (use these if relevant to the request):
${assets.map((a) => '- ${a.type.toUpperCase()}: "${a.name}" - URL: ${a.url}').join('\n')}
'''
        : '';

    return '''
The user wants to modify their existing game. Here is the current game code:

\`\`\`html
$currentHtml
\`\`\`
$assetsSection
USER REQUEST: $userRequest

Modify the game according to the user's request.
First, provide a VERY SHORT, simple confirmation (e.g., "I've updated the jump height for you.").
Then, output the complete updated HTML file in a code block.
''';
  }

  /// Builds the initial game generation prompt from user's description.
  static String buildGamePrompt(String userDescription, {List<GameAsset>? assets}) {
    final assetsNote = assets != null && assets.isNotEmpty
        ? '\n\nThe user has provided assets to use. Make sure to incorporate them into the game.'
        : '';

    return '''
Create a complete HTML5 game based on this description:

"$userDescription"

Make it with smooth animations and satisfying gameplay.
The game should be immediately playable and fun.
Remember: Keep your response text very short and simple.$assetsNote
''';
  }
}

/// Represents an asset provided by the user
class GameAsset {
  final String type; // 'image', 'gif', 'sound'
  final String name;
  final String url;

  const GameAsset({
    required this.type,
    required this.name,
    required this.url,
  });
}
