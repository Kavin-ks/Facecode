enum TDDifficulty { easy, medium, hard, extreme }
enum TDCategory { fun, spicy, couples, deep, social }

class TDQuestion {
  final String text;
  final bool isTruth; // true = truth, false = dare
  final TDCategory category;
  final TDDifficulty difficulty;

  const TDQuestion({
    required this.text,
    required this.isTruth,
    required this.category,
    this.difficulty = TDDifficulty.medium,
  });
}

class TDData {
  static final List<TDQuestion> questions = [
    // --- FUN TRUTHS ---
    const TDQuestion(text: "What is your weirdest talent?", isTruth: true, category: TDCategory.fun, difficulty: TDDifficulty.easy),
    const TDQuestion(text: "Have you ever peed in a pool?", isTruth: true, category: TDCategory.fun, difficulty: TDDifficulty.easy),
    const TDQuestion(text: "What is the grossest thing you've ever eaten?", isTruth: true, category: TDCategory.fun, difficulty: TDDifficulty.medium),
    const TDQuestion(text: "If you could swap lives with anyone here for a day, who would it be?", isTruth: true, category: TDCategory.fun, difficulty: TDDifficulty.easy),
    const TDQuestion(text: "What is the most embarrassing photo on your phone?", isTruth: true, category: TDCategory.fun, difficulty: TDDifficulty.medium),
    
    // --- FUN DARES ---
    const TDQuestion(text: "Do your best celebrity impression.", isTruth: false, category: TDCategory.fun, difficulty: TDDifficulty.easy),
    const TDQuestion(text: "Speak in an accent for the next 2 rounds.", isTruth: false, category: TDCategory.fun, difficulty: TDDifficulty.medium),
    const TDQuestion(text: "Let the group pose you for a photo.", isTruth: false, category: TDCategory.fun, difficulty: TDDifficulty.easy),
    const TDQuestion(text: "Start every sentence with 'According to the prophecy...'", isTruth: false, category: TDCategory.fun, difficulty: TDDifficulty.medium),
    const TDQuestion(text: "Act like a chicken until your next turn.", isTruth: false, category: TDCategory.fun, difficulty: TDDifficulty.hard),

    // --- SPICY TRUTHS ---
    const TDQuestion(text: "Who in this room do you think is the best kisser?", isTruth: true, category: TDCategory.spicy, difficulty: TDDifficulty.hard),
    const TDQuestion(text: "Have you ever sent a dirty text to the wrong person?", isTruth: true, category: TDCategory.spicy, difficulty: TDDifficulty.medium),
    const TDQuestion(text: "What is your biggest turn-on?", isTruth: true, category: TDCategory.spicy, difficulty: TDDifficulty.medium),
    const TDQuestion(text: "Have you ever had a crush on a friend's partner?", isTruth: true, category: TDCategory.spicy, difficulty: TDDifficulty.extreme),

    // --- SPICY DARES ---
    const TDQuestion(text: "Send a flirty text to the last person in your DMs.", isTruth: false, category: TDCategory.spicy, difficulty: TDDifficulty.hard),
    const TDQuestion(text: "Kiss the person to your left on the cheek.", isTruth: false, category: TDCategory.spicy, difficulty: TDDifficulty.medium),
    const TDQuestion(text: "Let the person to your right check your browser history.", isTruth: false, category: TDCategory.spicy, difficulty: TDDifficulty.extreme),

    // --- DEEP TRUTHS ---
    const TDQuestion(text: "What is your biggest fear?", isTruth: true, category: TDCategory.deep, difficulty: TDDifficulty.medium),
    const TDQuestion(text: "What is a regret you have from the past year?", isTruth: true, category: TDCategory.deep, difficulty: TDDifficulty.hard),
    const TDQuestion(text: "When was the last time you cried and why?", isTruth: true, category: TDCategory.deep, difficulty: TDDifficulty.medium),

    // --- SOCIAL DARES ---
    const TDQuestion(text: "Like the first 5 posts on your Instagram feed.", isTruth: false, category: TDCategory.social, difficulty: TDDifficulty.easy),
    const TDQuestion(text: "Call a pizza place and ask for a 'boneless pizza'.", isTruth: false, category: TDCategory.social, difficulty: TDDifficulty.hard),
  ];

  static List<TDQuestion> getQuestions({
    required Set<TDCategory> categories,
    bool safeMode = false,
  }) {
    return questions.where((q) {
      if (safeMode && (q.category == TDCategory.spicy || q.category == TDCategory.couples)) return false;
      return categories.contains(q.category);
    }).toList();
  }
}
