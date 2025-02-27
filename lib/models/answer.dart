class Answer {
  final int id; // ID der Antwort
  final bool correct; // Gibt an, ob die Antwort korrekt ist (true/false)
  final String answerText; // Der Text der Antwort
  final int questionId; // ID der Frage, zu der diese Antwort gehört

  // Konstruktor, der die Felder der Klasse initialisiert
  Answer({
    required this.id,
    required this.correct,
    required this.answerText,
    required this.questionId,
  });

  // Factory-Methode, die ein Answer-Objekt aus einem JSON erstellt
  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as int, // 'id' aus dem JSON wird in das 'id' der Klasse umgewandelt
      correct: json['correct'] as bool, // 'correct' aus dem JSON wird in das 'correct' der Klasse umgewandelt
      // Hier wird der Schlüssel 'answerText' oder 'answer_text' aus dem JSON verwendet
      answerText: json['answerText'] ?? json['answer_text'] as String, 
      // Hier wird der Schlüssel 'questionId' oder 'question_id' aus dem JSON verwendet
      questionId: json['questionId'] ?? json['question_id'] as int, 
    );
  }
}

// wann machen wir map später verstehen