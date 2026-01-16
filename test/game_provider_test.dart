import 'package:flutter_test/flutter_test.dart';

import 'package:facecode/models/game_error.dart';
import 'package:facecode/models/game_room.dart';
import 'package:facecode/providers/game_provider.dart';

void main() {
  test('create room initializes lobby with host', () {
    final provider = GameProvider(now: () => DateTime(2026, 1, 1));
    addTearDown(provider.dispose);

    provider.createRoom('Host');

    expect(provider.currentRoom, isNotNull);
    expect(provider.currentRoom!.state, GameState.lobby);
    expect(provider.currentRoom!.players.length, 1);
    expect(provider.currentPlayer, isNotNull);
    expect(provider.currentPlayer!.isHost, true);
  });

  test('emoji player cannot submit text guess', () {
    final time = _TestTime();
    final provider = GameProvider(now: () => time.now);
    addTearDown(provider.dispose);

    provider.createRoom('Host');
    provider.addPlayer('P2');
    provider.startGame();
    provider.onAppPaused();

    final emojiPlayer = provider.currentRoom!.currentEmojiPlayer!;
    provider.setActivePlayer(emojiPlayer.id);

    final ok = provider.submitGuess('anything', emojiPlayer.id);

    expect(ok, false);
    expect(provider.uiError, isNotNull);
    expect(provider.uiError!.type, GameErrorType.validation);
  });

  test('guess validation: empty + repeated + cooldown', () {
    final time = _TestTime();
    final provider = GameProvider(now: () => time.now);
    addTearDown(provider.dispose);

    provider.createRoom('Host');
    provider.addPlayer('P2');
    provider.startGame();
    provider.onAppPaused();

    final room = provider.currentRoom!;
    final emojiPlayer = room.currentEmojiPlayer!;
    final guesser = room.players.firstWhere((p) => p.id != emojiPlayer.id);

    // Empty
    expect(provider.submitGuess('   ', guesser.id), false);
    expect(provider.uiError?.type, GameErrorType.validation);

    provider.clearError();

    // First wrong guess sets last guess
    expect(provider.submitGuess('wrong', guesser.id), false);

    // Same repeated
    expect(provider.submitGuess('wrong', guesser.id), false);
    expect(provider.uiError?.type, GameErrorType.validation);

    provider.clearError();

    // Cooldown blocks rapid second guess
    time.advance(const Duration(seconds: 1));
    expect(provider.submitGuess('wrong2', guesser.id), false);
    expect(provider.uiError?.type, GameErrorType.validation);

    provider.clearError();

    // After cooldown, guess accepted (still likely wrong)
    time.advance(const Duration(seconds: 2));
    expect(provider.submitGuess('wrong3', guesser.id), false);
  });

  test('correct guess awards points and ends round', () {
    final time = _TestTime();
    final provider = GameProvider(now: () => time.now);
    addTearDown(provider.dispose);

    provider.createRoom('Host');
    provider.addPlayer('P2');
    provider.startGame();
    provider.onAppPaused();

    final room = provider.currentRoom!;
    final answer = room.currentPrompt!.text;

    final emojiPlayer = room.currentEmojiPlayer!;
    final guesser = room.players.firstWhere((p) => p.id != emojiPlayer.id);

    final ok = provider.submitGuess(answer, guesser.id);

    expect(ok, true);
    expect(provider.currentRoom!.state, GameState.results);
    expect(provider.lastRoundWasCorrect, true);

    final updatedGuesser = provider.currentRoom!.players
        .firstWhere((p) => p.id == guesser.id);
    expect(updatedGuesser.score, greaterThan(0));
  });

  test('nextRound rotates emoji player', () {
    final provider = GameProvider(now: () => DateTime(2026, 1, 1));
    addTearDown(provider.dispose);

    provider.createRoom('Host');
    provider.addPlayer('P2');
    provider.addPlayer('P3');
    provider.startGame();
    provider.onAppPaused();

    final firstEmojiId = provider.currentRoom!.currentEmojiPlayer!.id;

    provider.nextRound();
    provider.onAppPaused();

    final secondEmojiId = provider.currentRoom!.currentEmojiPlayer!.id;
    expect(secondEmojiId, isNot(equals(firstEmojiId)));
  });
}

class _TestTime {
  DateTime now = DateTime(2026, 1, 1, 0, 0, 0);

  void advance(Duration d) {
    now = now.add(d);
  }
}
