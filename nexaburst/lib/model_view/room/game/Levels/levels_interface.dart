// nexaburst/lib/model_view/room/game/levels/levels_interface.dart

/// Defines the contract for a game stage:
/// provides an instruction string and a method to run the stage logic.
abstract class LevelLogic {
  /// Returns the localized instruction text for this level.
  String getInstruction();

  /// Executes the full stage loop, handling UI commands, server sync,
  /// scoring, and any mode-specific flows.
  Future<void> runLevel();
}
