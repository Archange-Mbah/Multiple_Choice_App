import "answer.dart";

class Flashcard {
  final int id;
  final String question;
  final List<Answer> answers; // List of answers
  final int moduleId;
  final String language;

  Flashcard({
    required this.id,
    required this.question,
    required this.answers,
    required this.moduleId,
    required this.language,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    // First, access the 'answers' key, which is a map
    var answersListJson = json['answers']['answers'] as List;

    // Convert the list into a List of Answer objects
    List<Answer> answersList = answersListJson
        .map((answerJson) => Answer.fromJson(answerJson as Map<String, dynamic>))
        .toList();

    return Flashcard(
      id: json['id'] as int,
      question: json['question'] as String,
      answers: answersList,
      moduleId: json['module_id'] as int,
      language: json['language'] as String,
    );
  }
}

