import "answer.dart"; // Importiert die Answer-Klasse, um sie hier zu verwenden

class Flashcard {
  final int id; // Die ID der Flashcard
  final String question; // Die Frage auf der Flashcard
  final List<Answer> answers; // Liste der möglichen Antworten, die eine Liste von Answer-Objekten enthält
  final int moduleId; // Die Modul-ID, zu dem die Flashcard gehört
  final String language; // Die Sprache, in der die Flashcard erstellt wurde

  // Konstruktor, der die Felder der Flashcard initialisiert
  Flashcard({
    required this.id,
    required this.question,
    required this.answers,
    required this.moduleId,
    required this.language,
  });

  // Factory-Methode, die ein Flashcard-Objekt aus einem JSON erstellt
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    // Zunächst wird der 'answers' Schlüssel im JSON abgerufen, welcher eine Liste von Antworten enthält
    var answersListJson = json['answers']['answers'] as List;

    // Umwandlung der JSON-Liste in eine Liste von Answer-Objekten
    List<Answer> answersList = answersListJson
        .map((answerJson) => Answer.fromJson(answerJson as Map<String, dynamic>)) // Jedes Element wird in ein Answer-Objekt umgewandelt
        .toList(); // Die Liste wird in eine normale Dart-Liste umgewandelt

    // Rückgabe eines Flashcard-Objekts, das mit den Daten aus dem JSON initialisiert wird
    return Flashcard(
      id: json['id'] as int, // Die ID wird aus dem JSON extrahiert
      question: json['question'] as String, // Die Frage wird aus dem JSON extrahiert
      answers: answersList, // Die Liste der Antworten wird zugewiesen
      moduleId: json['module_id'] as int, // Die Modul-ID wird aus dem JSON extrahiert
      language: json['language'] as String, // Die Sprache wird aus dem JSON extrahiert
    );
  }
}

