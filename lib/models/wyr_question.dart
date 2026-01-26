import 'package:cloud_firestore/cloud_firestore.dart';

class WyrQuestion {
  final String id;
  final String optionA;
  final String optionB;
  final int votesA;
  final int votesB;
  final List<String> tags;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  WyrQuestion({
    required this.id,
    required this.optionA,
    required this.optionB,
    this.votesA = 0,
    this.votesB = 0,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get totalVotes => votesA + votesB;
  
  double get percentA {
    if (totalVotes == 0) return 50.0;
    return (votesA / totalVotes) * 100;
  }
  
  double get percentB {
    if (totalVotes == 0) return 50.0;
    return (votesB / totalVotes) * 100;
  }

  factory WyrQuestion.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WyrQuestion(
      id: doc.id,
      optionA: data['optionA'] ?? '',
      optionB: data['optionB'] ?? '',
      votesA: data['votesA'] ?? 0,
      votesB: data['votesB'] ?? 0,
      tags: (data['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optionA': optionA,
      'optionB': optionB,
      'votesA': votesA,
      'votesB': votesB,
      'totalVotes': totalVotes,
      'tags': tags,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
