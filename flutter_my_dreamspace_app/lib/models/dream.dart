import 'package:uuid/uuid.dart';

enum DreamMood {
  happy,
  sad,
  neutral,
  excited,
  anxious,
  peaceful,
  confused,
  scared;

  String get emoji {
    switch (this) {
      case DreamMood.happy:
        return '😊';
      case DreamMood.sad:
        return '😢';
      case DreamMood.neutral:
        return '😐';
      case DreamMood.excited:
        return '🤩';
      case DreamMood.anxious:
        return '😰';
      case DreamMood.peaceful:
        return '😌';
      case DreamMood.confused:
        return '😕';
      case DreamMood.scared:
        return '😱';
    }
  }
}

class Dream {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DreamMood mood;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Dream({
    String? id,
    required this.userId,
    required this.title,
    required this.description,
    required this.mood,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'mood': mood.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Dream.fromJson(Map<String, dynamic> json) {
    return Dream(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      mood: DreamMood.values.firstWhere(
        (e) => e.toString().split('.').last == json['mood'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Dream copyWith({String? title, String? description, DreamMood? mood}) {
    return Dream(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      mood: mood ?? this.mood,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
