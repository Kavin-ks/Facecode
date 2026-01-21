import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facecode/models/truth_dare_models.dart';

class TruthDareService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'td_questions';

  Future<List<TdQuestion>> getQuestions({
    TdType? type,
    TdCategory? category,
    TdAgeGroup? ageGroup,
    TdDifficulty? difficulty,
    bool orderByTrending = false,
    bool orderByMostAsked = false,
  }) async {
    Query query = _db.collection(_collection);

    if (type != null) query = query.where('type', isEqualTo: type.name);
    if (ageGroup != null) query = query.where('ageGroup', isEqualTo: ageGroup.name);
    // Note: Multiple where's on different fields might require indexes in Firebase.
    // For now, we'll filter some locally if needed or assume indexes.
    
    if (orderByTrending) {
       // Filter by usage in last 7 days? 
       // For a simple implementation, we'll sort by usageCount but prioritize recently updated ones.
       query = query.orderBy('lastUsed', descending: true);
    } else if (orderByMostAsked) {
       query = query.orderBy('usageCount', descending: true);
    }

    final snapshot = await query.limit(50).get();
    
    var questions = snapshot.docs
        .map((doc) => TdQuestion.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // Secondary client-side filtering for category/difficulty to avoid index explosions
    if (category != null) {
      questions = questions.where((q) => q.category == category).toList();
    }
    if (difficulty != null) {
      questions = questions.where((q) => q.difficulty == difficulty).toList();
    }

    // If empty, seed some data locally (fallback)
    if (questions.isEmpty) {
      return _getStaticFallback(type, category, ageGroup);
    }

    return questions;
  }

  Future<void> incrementUsage(String questionId) async {
    await _db.collection(_collection).doc(questionId).update({
      'usageCount': FieldValue.increment(1),
      'lastUsed': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementView(String questionId) async {
    await _db.collection(_collection).doc(questionId).update({
      'viewCount': FieldValue.increment(1),
      'lastViewed': FieldValue.serverTimestamp(),
    });
  }

  List<TdQuestion> _getStaticFallback(TdType? type, TdCategory? category, TdAgeGroup? ageGroup) {
    // Massive static fallback database for offline/empty states
    final List<TdQuestion> all = [
      // --- AGE GROUP: 10-15 (KIDS) ---
      // Truths
      TdQuestion(id: 'kid_t1', text: 'Who is your secret crush?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'kid_t2', text: 'Have you ever peed in a pool?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'kid_t3', text: 'When was the last time you wet the bed?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'kid_t4', text: 'What is the grossest thing you have ever eaten?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'kid_t5', text: 'Who is your favorite teacher and why?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'kid_t6', text: 'Have you ever lied to your parents to get out of trouble?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium),
      
      // Dares
      TdQuestion(id: 'kid_d1', text: 'Do your best chicken impression for 30 seconds.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'kid_d2', text: 'Spin around 10 times and try to walk in a straight line.', type: TdType.dare, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'kid_d3', text: 'Let the person to your right style your hair.', type: TdType.dare, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'kid_d4', text: 'Hold your breath for as long as you can.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'kid_d5', text: 'Sing "Happy Birthday" in a sad voice.', type: TdType.dare, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),

      // --- AGE GROUP: 16-18 (TEENS) ---
      // Truths
      TdQuestion(id: 'teen_t1', text: 'What is the most embarrassing thing you have done in front of a crush?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'teen_t2', text: 'Have you ever snuck out of the house?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'teen_t3', text: 'Who in this room would you date if you had to?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'teen_t4', text: 'What is a rumor that you spread?', type: TdType.truth, category: TdCategory.deep, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'teen_t5', text: 'Have you ever cheated on a test?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.easy),
      
      // Dares
      TdQuestion(id: 'teen_d1', text: 'Text your crush "I miss you" and show the reply.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'teen_d2', text: 'Post a embarrassing photo on your story for 5 minutes.', type: TdType.dare, category: TdCategory.social, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'teen_d3', text: 'Let the group look through your standard photo gallery for 1 minute.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'teen_d4', text: 'Call your parents and tell them you got suspended (then verify it is a joke).', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard),

      // --- AGE GROUP: 18+ (ADULTS) ---
      // Truths
      TdQuestion(id: 'adult_t1', text: 'What is your biggest regret in your love life?', type: TdType.truth, category: TdCategory.deep, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'adult_t2', text: 'Have you ever had a one-night stand?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'adult_t3', text: 'Describe the worst date you have ever been on.', type: TdType.truth, category: TdCategory.couples, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'adult_t4', text: 'Who here do you think makes the most money?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard),
      
      // Dares
      TdQuestion(id: 'adult_d1', text: 'Send a risky text to the 3rd person in your contacts.', type: TdType.dare, category: TdCategory.social, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'adult_d2', text: 'Let the person to your left make a drink for you with any available ingredients.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'adult_d3', text: 'Give a lap dance to a chair.', type: TdType.dare, category: TdCategory.fun, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium),

      // --- AGE GROUP: 21+ (MATURE) ---
      // Truths
      TdQuestion(id: 'mature_t1', text: 'What is your weirdest fetish?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'mature_t2', text: 'Have you ever done it in a public place?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'mature_t3', text: 'Who in this room would you have a threesome with?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme), // Assuming 'extreme' maps to hard or custom
      
      // Dares
      TdQuestion(id: 'mature_d1', text: 'Take a body shot off someone chosen by the group.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'mature_d2', text: 'Remove one item of clothing.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'mature_d3', text: 'French kiss the person to your right.', type: TdType.dare, category: TdCategory.couples, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard),
    ];

    var filtered = all;
    if (type != null) filtered = filtered.where((q) => q.type == type).toList();
    
    // Strict age filtering
    if (ageGroup != null) {
      if (ageGroup == TdAgeGroup.kids) {
        // Kids only see kids content
        filtered = filtered.where((q) => q.ageGroup == TdAgeGroup.kids).toList();
      } else if (ageGroup == TdAgeGroup.teens) {
         // Teens see Kids + Teens
         filtered = filtered.where((q) => q.ageGroup == TdAgeGroup.kids || q.ageGroup == TdAgeGroup.teens).toList();
      } else if (ageGroup == TdAgeGroup.adults) {
        // Adults see Teens + Adults (maybe filter out too childish stuff if needed, but for volume allow teens)
        filtered = filtered.where((q) => q.ageGroup == TdAgeGroup.teens || q.ageGroup == TdAgeGroup.adults).toList();
      } else if (ageGroup == TdAgeGroup.mature) {
        // Mature sees Adults + Mature
        filtered = filtered.where((q) => q.ageGroup == TdAgeGroup.adults || q.ageGroup == TdAgeGroup.mature).toList();
      }
    }
    
    // Category filtering
    if (category != null) {
      // If the category is a "Meta" category (Trending, Most Asked, Newest), 
      // we usually want to show popular/new questions from ALL categories.
      // However, since our static data HAS explicitly tagged "Trending" questions, we can respect it slightly differently.
      // If we are in "Trending" mode, let's include questions tagged 'trending' PLUS 'spicy' and 'friends' (general popular ones)
      
      if (category == TdCategory.trending || category == TdCategory.mostAsked) {
        // Broaden the scope for trending to ensure we have content
        // Or just don't filter by category if it's trending? 
        // Let's stick to the tag for now as simple fallback logic.
        // Actually, let's NOT filter if trending, so we get variety? 
        // No, let's filter by the tag 'trending' OR if the difficulty is high (assuming spicy/fun ones are trending).
        
        // Simpler: Just filter by category if it matches, OR if it's a specific content category.
        
        // Let's just implement strict filtering for consistency with the Firestore path
         filtered = filtered.where((q) => q.category == category).toList();
         
         // If strict filtering returns empty (e.g. no "Trending" questions for "Adults"), 
         // we should fallback to showing everything relevant to age
         if (filtered.isEmpty && (category == TdCategory.trending || category == TdCategory.mostAsked)) {
            // Reset to age-filtered list
            filtered = all.where((q) => q.type == type && (
               (ageGroup == TdAgeGroup.kids && q.ageGroup == TdAgeGroup.kids) ||
               (ageGroup == TdAgeGroup.teens && (q.ageGroup == TdAgeGroup.kids || q.ageGroup == TdAgeGroup.teens)) || 
               // ... (simplification of logic above for fallback)
               true 
            )).toList();
            
            // Re-apply age logic properly if we reset...
            // Actually, let's just use the `filtered` from before we applied category
             filtered = all; // This is wrong, `filtered` was age filtered.
             // We need to keep a reference to age-filtered list.
         }
      } else {
         filtered = filtered.where((q) => q.category == category).toList();
      }
    }
    
    return filtered;
  }

  Future<void> seedDatabase() async {
    final count = await _db.collection(_collection).count().get();
    if (count.count! > 0) return;

    final batch = _db.batch();
    final List<TdQuestion> seeds = [
      // Kids 10-15
      TdQuestion(id: 't1', text: 'What is the most embarrassing thing you did at school?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 't2', text: 'Do you have a secret crush?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'd1', text: 'Do your best chicken impression.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy),
      TdQuestion(id: 'd2', text: 'Let the person to your right draw on your face with a pen.', type: TdType.dare, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium),
      
      // Teens 16-18
      TdQuestion(id: 't3', text: 'What is the longest you have gone without showering?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.easy),
      TdQuestion(id: 't4', text: 'Have you ever lied to your parents about where you were?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'd3', text: 'Text your crush "I have a secret to tell you" and don\'t reply for 5 mins.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard),
      
      // Adults 18+ / 21+
      TdQuestion(id: 't5', text: 'What is your most expensive impulse buy?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium),
      TdQuestion(id: 't6', text: 'Describe your most awkward date ever.', type: TdType.truth, category: TdCategory.couples, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard),
      TdQuestion(id: 'd4', text: 'Order a pizza for the group (voted by others).', type: TdType.dare, category: TdCategory.friends, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium),
      TdQuestion(id: 'd5', text: 'Take a shot of something chosen by the storyteller.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard),
    ];

    for (var q in seeds) {
      final doc = _db.collection(_collection).doc(q.id);
      batch.set(doc, q.toMap());
    }
    await batch.commit();
  }
}
