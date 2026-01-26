enum TwoTruthsPhase { intro, setup, input, voting, reveal, scoreboard }

class Statement {
  final String text;
  final bool isLie;

  Statement({required this.text, required this.isLie});
}

class TwoTruthsRound {
  final String storytellerId;
  final List<Statement> statements;
  final Map<String, int> votes; // voterId -> statementIndex

  TwoTruthsRound({
    required this.storytellerId,
    required this.statements,
    Map<String, int>? votes,
  }) : votes = votes ?? {};
}
