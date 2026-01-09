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
You are an HTML5 game developer. Output a complete playable game in a single HTML file.

HTML5 Canvas. requestAnimationFrame. Include SFX (Web Audio API or Audio elements). Full screen: body{margin:0;overflow:hidden;background:#000;touch-action:none}canvas{display:block;width:100%;height:100%}
$assetsSection
\`\`\`html
<!DOCTYPE html>
<html>
</html>
\`\`\`
''';
  }

  /// Builds a refinement prompt when user wants to modify an existing game.
  static String buildRefinementPrompt(
    String currentHtml,
    String userRequest, {
    List<GameAsset>? assets,
  }) {
    final assetsSection = assets != null && assets.isNotEmpty
        ? '''

AVAILABLE ASSETS (use these if relevant to the request):
${assets.map((a) => '- ${a.type.toUpperCase()}: "${a.name}" - URL: ${a.url}').join('\n')}
'''
        : '';

    return '''
Modify this game:

\`\`\`html
$currentHtml
\`\`\`
$assetsSection
$userRequest
''';
  }

  /// Builds the initial game generation prompt from user's description.
  static String buildGamePrompt(
    String userDescription, {
    List<GameAsset>? assets,
  }) {
    final assetsNote = assets != null && assets.isNotEmpty
        ? '\n\nThe user has provided assets to use. Make sure to incorporate them into the game.'
        : '';

    return '''"$userDescription"$assetsNote
''';
  }
}

/// Represents an asset provided by the user
class GameAsset {
  final String type; // 'image', 'gif', 'sound'
  final String name;
  final String url;

  const GameAsset({required this.type, required this.name, required this.url});
}
