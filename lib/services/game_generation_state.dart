/// Game generation state enum for tracking the AI generation lifecycle.
enum GameGenerationState {
  /// Ready to accept user input
  idle,

  /// Currently streaming response from Gemini API
  generating,

  /// Game code ready, preview available
  preview,

  /// Error occurred during generation
  error,
}
