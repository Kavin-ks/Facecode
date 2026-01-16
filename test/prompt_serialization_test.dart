import 'package:flutter_test/flutter_test.dart';
import 'package:facecode/models/game_prompt.dart';

void main() {
  test('GamePrompt toJson/fromJson roundtrip', () {
    final prompt = GamePrompt(category: 'Animals', text: 'Penguin', difficulty: PromptDifficulty.easy);
    final json = prompt.toJson();
    final from = GamePrompt.fromJson(json);
    expect(from.category, prompt.category);
    expect(from.text, prompt.text);
    expect(from.difficulty, prompt.difficulty);
  });
}
