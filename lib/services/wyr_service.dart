import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:facecode/models/wyr_question.dart';

class WyrService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'wyr_questions';
  final String _votesCollection = 'wyr_votes';
  final Map<String, WyrQuestion> _localCache = {};

  static const _prefsUserId = 'wyr_user_id';
  static const _prefsVotedMap = 'wyr_voted_map';
  static const _prefsVoteHistory = 'wyr_vote_history';
  static const _prefsPendingVotes = 'wyr_pending_votes';

  /// Initial seed data if database is empty
  final List<Map<String, dynamic>> _seedQuestions = [
    {
      'optionA': 'Have the ability to fly',
      'optionB': 'Have the ability to be invisible',
      'votesA': 120,
      'votesB': 145,
      'tags': ['funny', 'superpower'],
    },
    {
      'optionA': 'Always be 10 minutes late',
      'optionB': 'Always be 20 minutes early',
      'votesA': 85,
      'votesB': 210,
      'tags': ['life', 'work'],
    },
    {
      'optionA': 'Lose your sight',
      'optionB': 'Lose your memories',
      'votesA': 45,
      'votesB': 130,
      'tags': ['deep'],
    },
    {
      'optionA': 'Be famous but poor',
      'optionB': 'Be unknown but rich',
      'votesA': 20,
      'votesB': 450,
      'tags': ['money', 'fame'],
    },
    {
      'optionA': 'Find true love',
      'optionB': 'Find a suitcase with \$5 million',
      'votesA': 180,
      'votesB': 175,
      'tags': ['love', 'money'],
    },
    {
      'optionA': 'Never use social media again',
      'optionB': 'Never watch movies again',
      'votesA': 230,
      'votesB': 90,
      'tags': ['modern', 'lifestyle'],
    },
    {
      'optionA': 'Be able to speak all languages',
      'optionB': 'Be able to speak with animals',
      'votesA': 310,
      'votesB': 290,
      'tags': ['superpower', 'skills'],
    },
    {
      'optionA': 'Live in the Harry Potter universe',
      'optionB': 'Live in the Star Wars universe',
      'votesA': 200,
      'votesB': 220,
      'tags': ['movies', 'fantasy'],
    },
    {
      'optionA': 'Have a rewind button for your life',
      'optionB': 'Have a pause button for your life',
      'votesA': 400,
      'votesB': 150,
      'tags': ['deep', 'life'],
    },
    {
      'optionA': 'Give up your smartphone',
      'optionB': 'Give up your car',
      'votesA': 60,
      'votesB': 300,
      'tags': ['modern', 'life'],
    },
    {
      'optionA': 'Be the smartest person in the world',
      'optionB': 'Be the funniest person in the world',
      'votesA': 190,
      'votesB': 210,
      'tags': ['personality'],
    },
    {
      'optionA': 'Only eat pizza for a year',
      'optionB': 'Only eat burgers for a year',
      'votesA': 150,
      'votesB': 140,
      'tags': ['food'],
    },
    {
      'optionA': 'Explore space',
      'optionB': 'Explore the ocean',
      'votesA': 280,
      'votesB': 160,
      'tags': ['adventure'],
    },
    {
      'optionA': 'Always say everything on your mind',
      'optionB': 'Never be able to speak again',
      'votesA': 180,
      'votesB': 70,
      'tags': ['deep', 'communication'],
    },
    {
      'optionA': 'Have a personal chef',
      'optionB': 'Have a personal massage therapist',
      'votesA': 320,
      'votesB': 110,
      'tags': ['luxury', 'funny'],
    },
  ];

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<String> getUserId() async {
    final prefs = await _prefs();
    final existing = prefs.getString(_prefsUserId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await prefs.setString(_prefsUserId, id);
    return id;
  }

  Future<Map<String, String>> _getVotedMap() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_prefsVotedMap);
    if (raw == null || raw.isEmpty) return {};
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> _setVotedMap(Map<String, String> map) async {
    final prefs = await _prefs();
    await prefs.setString(_prefsVotedMap, jsonEncode(map));
  }

  Future<bool> hasVoted(String questionId) async {
    final map = await _getVotedMap();
    return map.containsKey(questionId);
  }

  Future<String?> getVotedChoice(String questionId) async {
    final map = await _getVotedMap();
    return map[questionId];
  }

  Future<void> recordVoteLocal(String questionId, String choice) async {
    final map = await _getVotedMap();
    map[questionId] = choice;
    await _setVotedMap(map);
    await _appendHistory(questionId, choice);
  }

  Future<void> _appendHistory(String questionId, String choice) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_prefsVoteHistory);
    final List<dynamic> list = raw == null ? [] : (jsonDecode(raw) as List<dynamic>);
    list.insert(0, {
      'questionId': questionId,
      'choice': choice,
      'ts': DateTime.now().toIso8601String(),
    });
    if (list.length > 200) list.removeRange(200, list.length);
    await prefs.setString(_prefsVoteHistory, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> getVoteHistory() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_prefsVoteHistory);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> queuePendingVote(String questionId, bool isOptionA) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_prefsPendingVotes);
    final List<dynamic> list = raw == null ? [] : (jsonDecode(raw) as List<dynamic>);
    list.add({'id': questionId, 'choice': isOptionA ? 'A' : 'B'});
    await prefs.setString(_prefsPendingVotes, jsonEncode(list));
  }

  Future<void> flushPendingVotes() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_prefsPendingVotes);
    if (raw == null || raw.isEmpty) return;
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    if (list.isEmpty) return;
    final remaining = <dynamic>[];
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final id = map['id']?.toString();
      final choice = map['choice']?.toString();
      if (id == null || choice == null) continue;
      try {
        await vote(id, choice == 'A');
      } catch (_) {
        remaining.add(item);
      }
    }
    await prefs.setString(_prefsPendingVotes, jsonEncode(remaining));
  }

  /// Get a random question. Optionally filter by tag. Seeds DB if empty.
  Future<WyrQuestion?> getRandomQuestion({String? tag}) async {
    try {
      await flushPendingVotes();
      // 1. Check if we need to seed
      final countQuery = await _db.collection(_collection).count().get();
      if (countQuery.count == 0) {
        await _seedDatabase();
      }

      // 2. Optimized Random Fetch with optional tag filter
      Query queryRef = _db.collection(_collection);
      if (tag != null && tag.isNotEmpty) {
        queryRef = queryRef.where('tags', arrayContains: tag);
      }
      final query = await queryRef.limit(50).get();
      if (query.docs.isEmpty) return null;

      final docs = query.docs;
      final randomDoc = docs[Random().nextInt(docs.length)];

      return WyrQuestion.fromSnapshot(randomDoc);
    } catch (e) {
      debugPrint('Error getting question: $e');
      return _getLocalQuestion(tag: tag);
    }
  }

  Future<WyrQuestion?> getQuestionById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return WyrQuestion.fromSnapshot(doc);
    } catch (e) {
      debugPrint('Error getting question by id: $e');
      return _localCache[id];
    }
  }

  Stream<WyrQuestion> watchQuestion(String id) {
    return _db.collection(_collection).doc(id).snapshots().map(WyrQuestion.fromSnapshot);
  }

  Future<List<WyrQuestion>> getTrending({String? tag, int limit = 10}) async {
    try {
      Query query = _db.collection(_collection);
      if (tag != null && tag.isNotEmpty) {
        query = query.where('tags', arrayContains: tag);
      }
      query = query.orderBy('totalVotes', descending: true).orderBy('updatedAt', descending: true).limit(limit);
      final snap = await query.get();
      return snap.docs.map(WyrQuestion.fromSnapshot).toList();
    } catch (e) {
      debugPrint('Trending fetch failed: $e');
      return _localCache.values.toList();
    }
  }

  /// Return the most controversial questions (closest to 50/50 split).
  Future<List<WyrQuestion>> getMostControversial({String? tag, int limit = 5}) async {
    try {
      Query query = _db.collection(_collection);
      if (tag != null && tag.isNotEmpty) query = query.where('tags', arrayContains: tag);
      // fetch a larger sample and compute closeness client-side
      final snap = await query.orderBy('totalVotes', descending: true).limit(200).get();
      final list = snap.docs.map(WyrQuestion.fromSnapshot).toList();
      list.sort((a, b) {
        final da = (a.percentA - 50).abs();
        final db = (b.percentA - 50).abs();
        return da.compareTo(db);
      });
      return list.take(limit).toList();
    } catch (e) {
      debugPrint('Most controversial fetch failed: $e');
      // fall back to seeded/local data
      final local = _localCache.values.toList();
      if (local.isEmpty) {
        // build from seed
        final built = _seedQuestions.map((data) => WyrQuestion(
          id: 'seed_${_seedQuestions.indexOf(data)}',
          optionA: data['optionA'] as String,
          optionB: data['optionB'] as String,
          votesA: data['votesA'] as int? ?? 0,
          votesB: data['votesB'] as int? ?? 0,
          tags: (data['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        )).toList();
        built.sort((a,b) => (a.percentA - 50).abs().compareTo((b.percentA - 50).abs()));
        return built.take(limit).toList();
      }
      local.sort((a,b) => (a.percentA - 50).abs().compareTo((b.percentA - 50).abs()));
      return local.take(limit).toList();
    }
  }

  Future<void> _seedDatabase() async {
    debugPrint('Seeding WYR database...');
    final batch = _db.batch();
    for (var data in _seedQuestions) {
      final votesA = data['votesA'] as int? ?? 0;
      final votesB = data['votesB'] as int? ?? 0;
      final docRef = _db.collection(_collection).doc();
      batch.set(docRef, {
        ...data,
        'totalVotes': votesA + votesB,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

    final userId = await getUserId();
    final voteDoc = _db.collection(_votesCollection).doc(questionId).collection('votes').doc(userId);
    
    final docRef = _db.collection(_collection).doc(questionId);
    
    // Transaction ensures atomic updates
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Document does not exist!");

        final existingVote = await transaction.get(voteDoc);
        if (existingVote.exists) {
          return;
        }

        final currentVotesA = snapshot.get('votesA') as int? ?? 0;
        final currentVotesB = snapshot.get('votesB') as int? ?? 0;

        transaction.update(docRef, {
          'votesA': isOptionA ? currentVotesA + 1 : currentVotesA,
          'votesB': !isOptionA ? currentVotesB + 1 : currentVotesB,
          'totalVotes': currentVotesA + currentVotesB + 1,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastVoteAt': FieldValue.serverTimestamp(),
        });

        transaction.set(voteDoc, {
          'choice': isOptionA ? 'A' : 'B',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Return updated model
      final updatedSnapshot = await docRef.get();
      await recordVoteLocal(questionId, isOptionA ? 'A' : 'B');
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
      tags: question.tags,
      createdAt: question.createdAt,
      updatedAt: Timestamp.now(),
    );
    _localCache[updated.id] = updated;
    return updated;
  }

  WyrQuestion _getLocalQuestion({String? tag}) {
    final candidates = _seedQuestions.where((s) {
      final tags = (s['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (tag == null || tag.isEmpty) return true;
      return tags.contains(tag);
    }).toList();

    final index = Random().nextInt(candidates.length);
    final data = candidates[index];
    final id = 'local_${_seedQuestions.indexOf(data)}';
    if (_localCache.containsKey(id)) {
      return _localCache[id]!;
    }
    final q = WyrQuestion(
      id: id,
      optionA: data['optionA'] as String,
      optionB: data['optionB'] as String,
      votesA: data['votesA'] as int? ?? 0,
      votesB: data['votesB'] as int? ?? 0,
      tags: (data['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
    _localCache[id] = q;
    return q;
  }
}
