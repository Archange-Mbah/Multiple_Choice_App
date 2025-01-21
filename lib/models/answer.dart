class Answer {
  final int id;
  final bool correct;
  final String answerText;
  final int questionId;

  Answer({
    required this.id,
    required this.correct,
    required this.answerText,
    required this.questionId,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as int,
      correct: json['correct'] as bool,
      answerText: json['answerText'] ?? json['answer_text'] as String,  // Account for both possible key names
      questionId: json['questionId'] ?? json['question_id'] as int,  // Account for both possible key names
    );
  }
}

// wann machen wir map später verstehen