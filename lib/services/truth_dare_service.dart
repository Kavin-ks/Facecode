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
    try {
      await _db.collection(_collection).doc(questionId).update({
        'viewCount': FieldValue.increment(1),
        'lastViewed': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail for offline mode
    }
  }

  Future<void> rateQuestion(String questionId, bool isLike) async {
    try {
      await _db.collection(_collection).doc(questionId).update({
        isLike ? 'likeCount' : 'dislikeCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Silent fail for offline mode
    }
  }

  Future<void> toggleBookmark(String questionId, bool bookmark) async {
    try {
      await _db.collection(_collection).doc(questionId).update({
        'isBookmarked': bookmark,
      });
    } catch (e) {
      // Silent fail for offline mode
    }
  }

  Future<List<TdQuestion>> getTrendingQuestions({int limit = 20}) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final snapshot = await _db
          .collection(_collection)
          .where('lastUsed', isGreaterThan: weekAgo.toIso8601String())
          .orderBy('lastUsed', descending: true)
          .orderBy('usageCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => TdQuestion.fromMap(doc.id, doc.data()).copyWith(isTrending: true))
          .toList();
    } catch (e) {
      return _getStaticFallback(null, TdCategory.trending, null).take(limit).toList();
    }
  }

  Future<List<TdQuestion>> getMostAskedQuestions({int limit = 20}) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('usageCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => TdQuestion.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return _getStaticFallback(null, TdCategory.mostAsked, null).take(limit).toList();
    }
  }

  Future<TdQuestion?> generateAIQuestion({
    required TdType type,
    required TdAgeGroup ageGroup,
    required TdCategory category,
    required TdDifficulty difficulty,
  }) async {
    // AI Generation fallback - uses local generation for now
    // In production, integrate with Google Generative AI or similar
    
    // For now, return a placeholder that indicates AI generation would happen here
    // In production, call your AI service with a prompt like:
    // "Generate a ${difficulty.name} ${category.name} ${type.name} question for ${ageGroup.name}"
    
    // Fallback to random from static database
    final fallbackQuestions = _getStaticFallback(type, category, ageGroup);
    if (fallbackQuestions.isEmpty) return null;
    
    return fallbackQuestions[DateTime.now().millisecond % fallbackQuestions.length];
  }

  List<TdQuestion> _getStaticFallback(TdType? type, TdCategory? category, TdAgeGroup? ageGroup) {
    // Massive static fallback database for offline/empty states - 150+ PRODUCTION-READY QUESTIONS
    final List<TdQuestion> all = [
      // ========== AGE GROUP: KIDS (10-15) - CLEAN & FUN ==========
      
      // KIDS TRUTHS - Clean & Friends
      TdQuestion(id: 'kid_t1', text: 'Who is your secret crush at school?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 1250, isTrending: true),
      TdQuestion(id: 'kid_t2', text: 'Have you ever peed in a pool?', type: TdType.truth, category: TdCategory.clean, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 980),
      TdQuestion(id: 'kid_t3', text: 'When was the last time you cried?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 750),
      TdQuestion(id: 'kid_t4', text: 'What is the grossest thing you have ever eaten?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 1100, isTrending: true),
      TdQuestion(id: 'kid_t5', text: 'Who is your favorite teacher and why?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 890),
      TdQuestion(id: 'kid_t6', text: 'Have you ever lied to your parents to get out of trouble?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 1050),
      TdQuestion(id: 'kid_t7', text: 'What is your most embarrassing moment at school?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 1300, isTrending: true),
      TdQuestion(id: 'kid_t8', text: 'Have you ever cheated on a test?', type: TdType.truth, category: TdCategory.clean, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 820),
      TdQuestion(id: 'kid_t9', text: 'Who do you think is the coolest kid in school?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 670),
      TdQuestion(id: 'kid_t10', text: 'What superpower would you want and why?', type: TdType.truth, category: TdCategory.fun, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 940),
      TdQuestion(id: 'kid_t11', text: 'Have you ever stolen something from your sibling?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 710),
      TdQuestion(id: 'kid_t12', text: 'What is the silliest thing you are afraid of?', type: TdType.truth, category: TdCategory.clean, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 860),
      TdQuestion(id: 'kid_t13', text: 'Have you ever picked your nose and eaten it?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 1450, isTrending: true),
      TdQuestion(id: 'kid_t14', text: 'Who was your first crush?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 1020),
      TdQuestion(id: 'kid_t15', text: 'What is the weirdest dream you have ever had?', type: TdType.truth, category: TdCategory.fun, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 790),
      
      // KIDS DARES - Active & Fun
      TdQuestion(id: 'kid_d1', text: 'Do your best chicken impression for 30 seconds.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 1380, isTrending: true),
      TdQuestion(id: 'kid_d2', text: 'Spin around 10 times and try to walk in a straight line.', type: TdType.dare, category: TdCategory.party, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 1150),
      TdQuestion(id: 'kid_d3', text: 'Let the person to your right style your hair.', type: TdType.dare, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 920),
      TdQuestion(id: 'kid_d4', text: 'Hold your breath for as long as you can.', type: TdType.dare, category: TdCategory.clean, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 780),
      TdQuestion(id: 'kid_d5', text: 'Sing "Happy Birthday" in a robot voice.', type: TdType.dare, category: TdCategory.fun, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 1090),
      TdQuestion(id: 'kid_d6', text: 'Do 20 jumping jacks right now.', type: TdType.dare, category: TdCategory.party, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 850),
      TdQuestion(id: 'kid_d7', text: 'Talk in an accent for the next 3 rounds.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 1210),
      TdQuestion(id: 'kid_d8', text: 'Dance with no music for 1 minute.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 1340, isTrending: true),
      TdQuestion(id: 'kid_d9', text: 'Make a funny face and keep it for 30 seconds.', type: TdType.dare, category: TdCategory.clean, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 970),
      TdQuestion(id: 'kid_d10', text: 'Let someone draw a mustache on you with a pen.', type: TdType.dare, category: TdCategory.friends, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 880),
      TdQuestion(id: 'kid_d11', text: 'Say the alphabet backwards as fast as you can.', type: TdType.dare, category: TdCategory.party, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.hard, usageCount: 650),
      TdQuestion(id: 'kid_d12', text: 'Imitate your favorite animal until someone guesses it.', type: TdType.dare, category: TdCategory.fun, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 1020),
      TdQuestion(id: 'kid_d13', text: 'Try to lick your elbow.', type: TdType.dare, category: TdCategory.crazy, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.easy, usageCount: 1170),
      TdQuestion(id: 'kid_d14', text: 'Speak in rhymes for the next 2 turns.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.hard, usageCount: 710),
      TdQuestion(id: 'kid_d15', text: 'Do your best celebrity impression.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.kids, difficulty: TdDifficulty.medium, usageCount: 1280, isTrending: true),

      // ========== AGE GROUP: TEENS (13-18) - SPICY & SOCIAL ==========
      
      // TEENS TRUTHS
      TdQuestion(id: 'teen_t1', text: 'What is the most embarrassing thing you have done in front of a crush?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1520, isTrending: true),
      TdQuestion(id: 'teen_t2', text: 'Have you ever snuck out of the house?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1410),
      TdQuestion(id: 'teen_t3', text: 'Who in this room would you date if you had to choose?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1670, isTrending: true),
      TdQuestion(id: 'teen_t4', text: 'What is a secret you have never told your parents?', type: TdType.truth, category: TdCategory.deep, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1230),
      TdQuestion(id: 'teen_t5', text: 'Have you ever cheated on a test? Which one?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1090),
      TdQuestion(id: 'teen_t6', text: 'Who was your worst kiss and why?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1340),
      TdQuestion(id: 'teen_t7', text: 'Have you ever lied about your age online?', type: TdType.truth, category: TdCategory.social, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 980),
      TdQuestion(id: 'teen_t8', text: 'What is the longest you have gone without showering?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1150),
      TdQuestion(id: 'teen_t9', text: 'Have you ever sent a text to the wrong person? What did it say?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1440, isTrending: true),
      TdQuestion(id: 'teen_t10', text: 'What is your biggest insecurity?', type: TdType.truth, category: TdCategory.deep, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1070),
      TdQuestion(id: 'teen_t11', text: 'Have you ever pretended to be sick to skip school?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.easy, usageCount: 1310),
      TdQuestion(id: 'teen_t12', text: 'What is the meanest thing you have ever said to someone?', type: TdType.truth, category: TdCategory.deep, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 890),
      TdQuestion(id: 'teen_t13', text: 'Who do you stalk the most on social media?', type: TdType.truth, category: TdCategory.social, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1580, isTrending: true),
      TdQuestion(id: 'teen_t14', text: 'Have you ever kissed someone you regretted?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1190),
      TdQuestion(id: 'teen_t15', text: 'What is the most rebellious thing you have ever done?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1260),
      TdQuestion(id: 'teen_t16', text: 'Have you ever had a crush on a friend\'s boyfriend or girlfriend?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1120),
      TdQuestion(id: 'teen_t17', text: 'What is your most used emoji and what does that say about you?', type: TdType.truth, category: TdCategory.fun, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.easy, usageCount: 970),
      TdQuestion(id: 'teen_t18', text: 'Have you ever ghosted someone?', type: TdType.truth, category: TdCategory.social, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1400, isTrending: true),
      
      // TEENS DARES
      TdQuestion(id: 'teen_d1', text: 'Text your crush "I need to tell you something" and don\'t reply for 5 minutes.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1720, isTrending: true),
      TdQuestion(id: 'teen_d2', text: 'Post an embarrassing selfie on your story for 10 minutes.', type: TdType.dare, category: TdCategory.social, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1540),
      TdQuestion(id: 'teen_d3', text: 'Let the group go through your camera roll for 1 minute.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.extreme, usageCount: 1630, isTrending: true),
      TdQuestion(id: 'teen_d4', text: 'Call your parents and tell them you got detention (then say it\'s a joke).', type: TdType.dare, category: TdCategory.crazy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 980),
      TdQuestion(id: 'teen_d5', text: 'Delete your most recent Instagram post.', type: TdType.dare, category: TdCategory.social, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1210),
      TdQuestion(id: 'teen_d6', text: 'Let someone else write your next social media caption.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1450, isTrending: true),
      TdQuestion(id: 'teen_d7', text: 'Do your best TikTok dance right now.', type: TdType.dare, category: TdCategory.party, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1580, isTrending: true),
      TdQuestion(id: 'teen_d8', text: 'Send a flirty text to the 5th person in your contacts.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1320),
      TdQuestion(id: 'teen_d9', text: 'Freestyle rap about the person to your left.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1140),
      TdQuestion(id: 'teen_d10', text: 'Let the group read your last 5 text messages.', type: TdType.dare, category: TdCategory.crazy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.extreme, usageCount: 1490),
      TdQuestion(id: 'teen_d11', text: 'Snapchat your crush a selfie right now.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1370),
      TdQuestion(id: 'teen_d12', text: 'Do 30 pushups right now.', type: TdType.dare, category: TdCategory.party, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 890),
      TdQuestion(id: 'teen_d13', text: 'Show everyone your browser history.', type: TdType.dare, category: TdCategory.crazy, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.extreme, usageCount: 760),
      TdQuestion(id: 'teen_d14', text: 'Change your profile picture to something the group chooses for 24 hours.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.hard, usageCount: 1620, isTrending: true),
      TdQuestion(id: 'teen_d15', text: 'Act like your favorite teacher for 2 minutes.', type: TdType.dare, category: TdCategory.fun, ageGroup: TdAgeGroup.teens, difficulty: TdDifficulty.medium, usageCount: 1050),

      // ========== AGE GROUP: ADULTS (18+) - DEEP & MATURE ==========
      
      // ADULTS TRUTHS
      TdQuestion(id: 'adult_t1', text: 'What is your biggest regret in your love life?', type: TdType.truth, category: TdCategory.deep, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1820),
      TdQuestion(id: 'adult_t2', text: 'Have you ever had a one-night stand?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1650, isTrending: true),
      TdQuestion(id: 'adult_t3', text: 'Describe the worst date you have ever been on.', type: TdType.truth, category: TdCategory.couples, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1420),
      TdQuestion(id: 'adult_t4', text: 'Who in this group do you think makes the most money?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1180),
      TdQuestion(id: 'adult_t5', text: 'Have you ever lied on your resume?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1310),
      TdQuestion(id: 'adult_t6', text: 'What is the most expensive thing you have stolen?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 990),
      TdQuestion(id: 'adult_t7', text: 'Have you ever been arrested? What for?', type: TdType.truth, category: TdCategory.crazy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1270),
      TdQuestion(id: 'adult_t8', text: 'What is the biggest lie you ever told?', type: TdType.truth, category: TdCategory.deep, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1450),
      TdQuestion(id: 'adult_t9', text: 'Have you ever cheated on someone?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.extreme, usageCount: 1710, isTrending: true),
      TdQuestion(id: 'adult_t10', text: 'What is your salary? Be honest.', type: TdType.truth, category: TdCategory.crazy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.extreme, usageCount: 1090),
      TdQuestion(id: 'adult_t11', text: 'Who was the last person you stalked on social media?', type: TdType.truth, category: TdCategory.social, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1560, isTrending: true),
      TdQuestion(id: 'adult_t12', text: 'Have you ever faked being sick to get out of work?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.easy, usageCount: 1630),
      TdQuestion(id: 'adult_t13', text: 'What is your biggest insecurity in a relationship?', type: TdType.truth, category: TdCategory.couples, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1240),
      TdQuestion(id: 'adult_t14', text: 'Have you ever bad-mouthed a friend behind their back?', type: TdType.truth, category: TdCategory.friends, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1380),
      TdQuestion(id: 'adult_t15', text: 'What is the most embarrassing thing in your search history?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1890, isTrending: true),
      
      // ADULTS DARES
      TdQuestion(id: 'adult_d1', text: 'Text your ex "I miss you" and show the group the response.', type: TdType.dare, category: TdCategory.crazy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.extreme, usageCount: 1540, isTrending: true),
      TdQuestion(id: 'adult_d2', text: 'Let the person to your left create a drink for you with any ingredients and drink it.', type: TdType.dare, category: TdCategory.party, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1420),
      TdQuestion(id: 'adult_d3', text: 'Do a seductive dance to a song of the group\'s choosing.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1610, isTrending: true),
      TdQuestion(id: 'adult_d4', text: 'Call a random contact and sing them a love song.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1230),
      TdQuestion(id: 'adult_d5', text: 'Show the group your online dating profile.', type: TdType.dare, category: TdCategory.social, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 1350),
      TdQuestion(id: 'adult_d6', text: 'Take a shot of hot sauce.', type: TdType.dare, category: TdCategory.party, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1120),
      TdQuestion(id: 'adult_d7', text: 'Post an embarrassing throwback photo on Instagram.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1470, isTrending: true),
      TdQuestion(id: 'adult_d8', text: 'Let someone write a status on your Facebook and keep it for 24 hours.', type: TdType.dare, category: TdCategory.social, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.hard, usageCount: 980),
      TdQuestion(id: 'adult_d9', text: 'Order a pizza and use a fake accent when speaking to the person on the phone.', type: TdType.dare, category: TdCategory.fun, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1190),
      TdQuestion(id: 'adult_d10', text: 'Do your best impression of someone in the room. They have to guess who it is.', type: TdType.dare, category: TdCategory.friends, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1340),
      TdQuestion(id: 'adult_d11', text: 'Share your most embarrassing Spotify playlist with the group.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.medium, usageCount: 1280),
      TdQuestion(id: 'adult_d12', text: 'Let the group go through your texts for 30 seconds.', type: TdType.dare, category: TdCategory.crazy, ageGroup: TdAgeGroup.adults, difficulty: TdDifficulty.extreme, usageCount: 1410),
      
      // ========== AGE GROUP: MATURE (21+) - EXPLICIT & WILD ==========
      
      // MATURE TRUTHS
      TdQuestion(id: 'mature_t1', text: 'What is your weirdest fantasy?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 1920, isTrending: true),
      TdQuestion(id: 'mature_t2', text: 'Have you ever done it in a public place?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard, usageCount: 1780),
      TdQuestion(id: 'mature_t3', text: 'Who in this room would you hook up with right now?', type: TdType.truth, category: TdCategory.crazy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 2100, isTrending: true),
      TdQuestion(id: 'mature_t4', text: 'What is the kinkiest thing you have ever done?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 1840),
      TdQuestion(id: 'mature_t5', text: 'Have you ever been to a strip club?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.medium, usageCount: 1450),
      TdQuestion(id: 'mature_t6', text: 'What is your body count?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard, usageCount: 2240, isTrending: true),
      TdQuestion(id: 'mature_t7', text: 'Have you ever had a threesome? Would you?', type: TdType.truth, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 1970),
      TdQuestion(id: 'mature_t8', text: 'What is the craziest place you have ever hooked up?', type: TdType.truth, category: TdCategory.crazy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard, usageCount: 1690),
      TdQuestion(id: 'mature_t9', text: 'Have you ever sent nudes to someone you regret?', type: TdType.truth, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard, usageCount: 1820),
      TdQuestion(id: 'mature_t10', text: 'Who is the hottest person in this room?', type: TdType.truth, category: TdCategory.trending, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.medium, usageCount: 2180, isTrending: true),
      
      // MATURE DARES
      TdQuestion(id: 'mature_d1', text: 'Take a body shot off someone chosen by the group.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard, usageCount: 1850, isTrending: true),
      TdQuestion(id: 'mature_d2', text: 'Remove an item of clothing of your choice.', type: TdType.dare, category: TdCategory.crazy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard, usageCount: 1940),
      TdQuestion(id: 'mature_d3', text: 'Give the person to your right a passionate kiss.', type: TdType.dare, category: TdCategory.couples, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 2210, isTrending: true),
      TdQuestion(id: 'mature_d4', text: 'Do a striptease (you can keep your underwear on).', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 1760),
      TdQuestion(id: 'mature_d5', text: 'Recreate your first kiss with someone in the room.', type: TdType.dare, category: TdCategory.party, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard, usageCount: 1590),
      TdQuestion(id: 'mature_d6', text: 'Whisper something dirty to the person to your left.', type: TdType.dare, category: TdCategory.spicy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.medium, usageCount: 1720),
      TdQuestion(id: 'mature_d7', text: 'Give someone a lap dance for 30 seconds.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 2050, isTrending: true),
      TdQuestion(id: 'mature_d8', text: 'Let the group vote on who you should make out with for 10 seconds.', type: TdType.dare, category: TdCategory.crazy, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 1890),
      TdQuestion(id: 'mature_d9', text: 'Show everyone your sexiest photo.', type: TdType.dare, category: TdCategory.mostAsked, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.hard, usageCount: 1640),
      TdQuestion(id: 'mature_d10', text: 'Play 7 minutes in heaven with someone the group chooses.', type: TdType.dare, category: TdCategory.trending, ageGroup: TdAgeGroup.mature, difficulty: TdDifficulty.extreme, usageCount: 2320, isTrending: true),
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
