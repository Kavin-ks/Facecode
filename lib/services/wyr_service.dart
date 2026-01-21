import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:facecode/models/wyr_question.dart';

class WyrService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'wyr_questions';
  final Map<String, WyrQuestion> _localCache = {};

  /// Initial seed data if database is empty
  final List<Map<String, dynamic>> _seedQuestions = [
    {'optionA': 'Have the ability to fly', 'optionB': 'Have the ability to be invisible', 'votesA': 120, 'votesB': 145},
    {'optionA': 'Always be 10 minutes late', 'optionB': 'Always be 20 minutes early', 'votesA': 85, 'votesB': 210},
    {'optionA': 'Lose your sight', 'optionB': 'Lose your memories', 'votesA': 45, 'votesB': 130},
    {'optionA': 'Be famous but poor', 'optionB': 'Be unknown but rich', 'votesA': 20, 'votesB': 450},
    {'optionA': 'Find true love', 'optionB': 'Find a suitcase with \$5 million', 'votesA': 180, 'votesB': 175},
    {'optionA': 'Never use social media again', 'optionB': 'Never watch movies again', 'votesA': 230, 'votesB': 90},
    {'optionA': 'Be able to speak all languages', 'optionB': 'Be able to speak with animals', 'votesA': 310, 'votesB': 290},
    {'optionA': 'Live in the Harry Potter universe', 'optionB': 'Live in the Star Wars universe', 'votesA': 200, 'votesB': 220},
    {'optionA': 'Have a rewind button for your life', 'optionB': 'Have a pause button for your life', 'votesA': 400, 'votesB': 150},
    {'optionA': 'Give up your smartphone', 'optionB': 'Give up your car', 'votesA': 60, 'votesB': 300},
    {'optionA': 'Be the smartest person in the world', 'optionB': 'Be the funniest person in the world', 'votesA': 190, 'votesB': 210},
    {'optionA': 'Only eat pizza for a year', 'optionB': 'Only eat burgers for a year', 'votesA': 150, 'votesB': 140},
    {'optionA': 'Explore space', 'optionB': 'Explore the ocean', 'votesA': 280, 'votesB': 160},
    {'optionA': 'Always say everything on your mind', 'optionB': 'Never be able to speak again', 'votesA': 180, 'votesB': 70},
    {'optionA': 'Have a personal chef', 'optionB': 'Have a personal massage therapist', 'votesA': 320, 'votesB': 110},
  ];

  /// Get a random question. Seeds DB if empty.
  Future<WyrQuestion?> getRandomQuestion() async {
    try {
      // 1. Check if we need to seed
      final countQuery = await _db.collection(_collection).count().get();
      if (countQuery.count == 0) {
        await _seedDatabase();
      }

      // 2. Optimized Random Fetch 
      // Generate a random AutoID-like string to jump to random spot
      // Or simple method: fetch limited batch and pick one
      // Since it's a demo app, simple client-side random from a batch is fine for <1000 docs
      
      final query = await _db.collection(_collection).limit(50).get();
      if (query.docs.isEmpty) return null;

      final docs = query.docs;
      final randomDoc = docs[Random().nextInt(docs.length)];
      
      return WyrQuestion.fromSnapshot(randomDoc);
    } catch (e) {
      debugPrint('Error getting question: $e');
      return _getLocalQuestion();
    }
  }

  Future<void> _seedDatabase() async {
    debugPrint('Seeding WYR database...');
    final batch = _db.batch();
    for (var data in _seedQuestions) {
      final docRef = _db.collection(_collection).doc();
      batch.set(docRef, data);
    }
    await batch.commit();
  }

  /// Vote for an option (A or B)
  Future<WyrQuestion?> vote(String questionId, bool isOptionA) async {
    if (questionId.startsWith('local_')) {
      final q = _localCache[questionId];
      if (q == null) return null;
      return voteLocal(q, isOptionA);
    }
    
    final docRef = _db.collection(_collection).doc(questionId);
    
    // Transaction ensures atomic updates
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Document does not exist!");

        final currentVotesA = snapshot.get('votesA') as int? ?? 0;
        final currentVotesB = snapshot.get('votesB') as int? ?? 0;

        transaction.update(docRef, {
          'votesA': isOptionA ? currentVotesA + 1 : currentVotesA,
          'votesB': !isOptionA ? currentVotesB + 1 : currentVotesB,
        });
      });
      
      // Return updated model
      final updatedSnapshot = await docRef.get();
      return WyrQuestion.fromSnapshot(updatedSnapshot);
    } catch (e) {
      debugPrint('Vote failed: $e');
      rethrow;
    }
  }

  WyrQuestion voteLocal(WyrQuestion question, bool isOptionA) {
    final updated = WyrQuestion(
      id: question.id.startsWith('local_') ? question.id : 'local_${question.id}',
      optionA: question.optionA,
      optionB: question.optionB,
      votesA: question.votesA + (isOptionA ? 1 : 0),
      votesB: question.votesB + (!isOptionA ? 1 : 0),
    );
    _localCache[updated.id] = updated;
    return updated;
  }

  WyrQuestion _getLocalQuestion() {
    final index = Random().nextInt(_seedQuestions.length);
    final data = _seedQuestions[index];
    final id = 'local_$index';
    if (_localCache.containsKey(id)) {
      return _localCache[id]!;
    }
    final q = WyrQuestion(
      id: id,
      optionA: data['optionA'] as String,
      optionB: data['optionB'] as String,
      votesA: data['votesA'] as int? ?? 0,
      votesB: data['votesB'] as int? ?? 0,
    );
    _localCache[id] = q;
    return q;
  }
}
