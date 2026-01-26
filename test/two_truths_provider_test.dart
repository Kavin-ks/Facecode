import 'package:flutter_test/flutter_test.dart';
import 'package:facecode/models/player.dart';
import 'package:facecode/providers/two_truths_provider.dart';

void main() {
  TwoTruthsProvider buildProvider(List<Player> players, {int totalRounds = 3}) {
    final provider = TwoTruthsProvider();
    provider.startSetup();
    provider.setupGame(players, totalRounds: totalRounds);
    return provider;
  }

  test('setup starts input phase with round 1', () {
    final provider = buildProvider([
      Player(id: 'p1', name: 'A'),
      Player(id: 'p2', name: 'B'),
    ]);
    addTearDown(provider.dispose);

    expect(provider.phase.name, 'input');
    expect(provider.currentRoundNumber, 1);
    expect(provider.currentRound, isNotNull);
  });

  test('submitStatements shuffles and keeps one lie', () {
    final provider = buildProvider([
      Player(id: 'p1', name: 'A'),
      Player(id: 'p2', name: 'B'),
    ]);
    addTearDown(provider.dispose);

    provider.submitStatements(['Truth 1', 'Truth 2'], 'Lie');

    final round = provider.currentRound!;
    expect(round.statements.length, 3);
    expect(round.statements.where((s) => s.isLie).length, 1);
    final texts = round.statements.map((s) => s.text).toSet();
    expect(texts.contains('Truth 1'), true);
    expect(texts.contains('Truth 2'), true);
    expect(texts.contains('Lie'), true);
    expect(provider.phase.name, 'voting');
  });

  test('vote locking prevents duplicate vote', () {
    final provider = buildProvider([
      Player(id: 'p1', name: 'A'),
      Player(id: 'p2', name: 'B'),
      Player(id: 'p3', name: 'C'),
    ]);
    addTearDown(provider.dispose);

    provider.submitStatements(['Truth 1', 'Truth 2'], 'Lie');
    provider.submitVote('p2', 0);
    provider.submitVote('p2', 1);

    expect(provider.currentRound!.votes['p2'], 0);
  });

  test('scoring awards +1 per correct and +2 storyteller when majority wrong', () {
    final provider = buildProvider([
      Player(id: 'p1', name: 'A'),
      Player(id: 'p2', name: 'B'),
      Player(id: 'p3', name: 'C'),
    ]);
    addTearDown(provider.dispose);

    provider.submitStatements(['Truth 1', 'Truth 2'], 'Lie');
    final correctIndex = provider.currentRound!.statements.indexWhere((s) => s.isLie);
    final wrongIndex = (correctIndex + 1) % 3;

    provider.submitVote('p2', wrongIndex);
    provider.submitVote('p3', wrongIndex);

    final storyteller = provider.currentStoryteller!;
    final updatedStoryteller = provider.players.firstWhere((p) => p.id == storyteller.id);
    expect(updatedStoryteller.score, 2);
  });

  test('turn rotation advances storyteller order', () {
    final players = [
      Player(id: 'p1', name: 'A'),
      Player(id: 'p2', name: 'B'),
      Player(id: 'p3', name: 'C'),
    ];
    final provider = buildProvider(players, totalRounds: 3);
    addTearDown(provider.dispose);

    final first = provider.currentStoryteller!.id;
    provider.submitStatements(['Truth 1', 'Truth 2'], 'Lie');
    provider.submitVote('p2', 0);
    provider.submitVote('p3', 0);
    provider.nextRound();

    final second = provider.currentStoryteller!.id;
    expect(second, isNot(equals(first)));
  });

  test('phase transitions to scoreboard after final round', () {
    final provider = buildProvider([
      Player(id: 'p1', name: 'A'),
      Player(id: 'p2', name: 'B'),
    ], totalRounds: 1);
    addTearDown(provider.dispose);

    provider.submitStatements(['Truth 1', 'Truth 2'], 'Lie');
    provider.submitVote('p2', 0);
    provider.nextRound();

    expect(provider.phase.name, 'scoreboard');
  });
}
