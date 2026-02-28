class Question {
  final String id;
  final String text;
  final String category;
  final double importance;
  final List<String> keywords;
  final List<Answer> answers;

  Question({
    required this.id,
    required this.text,
    required this.category,
    required this.importance,
    required this.keywords,
    required this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      category: json['category'],
      importance: json['importance']?.toDouble() ?? 0.5,
      keywords: List<String>.from(json['keywords'] ?? []),
      answers: (json['answers'] as List)
          .map((a) => Answer.fromJson(a))
          .toList(),
    );
  }

  // ✅ add this function (required)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'importance': importance,
      'keywords': keywords,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }

  List<String> get answerTexts => answers.map((a) => a.text).toList();

  int getScoreForAnswer(String answerText) {
    try {
      return answers.firstWhere((a) => a.text == answerText).score;
    } catch (e) {
      return 1;
    }
  }
}

class Answer {
  final String text;
  final int score;
  final double weight;

  Answer({
    required this.text,
    required this.score,
    required this.weight,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      text: json['text'],
      score: json['score'],
      weight: json['weight']?.toDouble() ?? 0.25,
    );
  }

  // ✅ add this function as well
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'score': score,
      'weight': weight,
    };
  }
}