class LearnStats {
  String userId; // Die Benutzer-ID des Lernenden
  int moduleId; // Die Modul-ID, zu dem die Lernstatistik gehört
  String moduleName; // Der Name des Moduls
  String score; // Der Score, der als String gespeichert wird (z. B. "85.5")
  int correctCount; // Die Anzahl der richtigen Antworten
  String duration; // Die Dauer, wie lange der Lernende für das Modul benötigt hat (z. B. "15:30")
  DateTime createdAt; // Das Datum und die Uhrzeit, wann die Lernstatistik erstellt wurde

  // Konstruktor, der alle Felder der LearnStats-Klasse initialisiert
  LearnStats({
    required this.userId,
    required this.moduleId,
    required this.moduleName,
    required this.score,
    required this.correctCount,
    required this.duration,
    required this.createdAt,
  });

  // Factory-Methode, die ein LearnStats-Objekt aus einem JSON erstellt
  factory LearnStats.fromJson(Map<String, dynamic> json) {
    return LearnStats(
      userId: json['user_id'] as String, // Benutzer-ID aus dem JSON
      moduleId: json['module_id'] as int, // Modul-ID aus dem JSON
      moduleName: json['moduleName'] as String, // Modulname aus dem JSON
      score: json['score'] as String, // Score aus dem JSON
      correctCount: json['correct_count'] as int, // Anzahl der richtigen Antworten aus dem JSON
      duration: json['duration'] as String, // Dauer aus dem JSON
      // Konvertiert den 'created_at' Wert aus dem JSON in ein DateTime-Objekt
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Berechnet den Performance-Level basierend auf dem Score
  // Der Performance-Level wird je nach Sprache (de oder anders) unterschiedlich benannt
  String getPerformanceLevel(String language) {
    // Versuch, den Score als Zahl zu parsen. Wenn dies fehlschlägt, wird der Standardwert 0.0 verwendet.
    double scorePercentage = double.tryParse(score) ?? 0.0;

    // Bestimmt den Performance-Level basierend auf dem Score
    if (scorePercentage >= 81) {
      // Wenn der Score 81 oder höher ist
      return language == "de" ? "🔥 Wissensmeister" : "🔥 Expert";
    } else if (scorePercentage >= 61) {
      // Wenn der Score zwischen 61 und 80 liegt
      return language == "de" ? "🧠 Wissenssammler" : "🧠 Good";
    } else if (scorePercentage >= 41) {
      // Wenn der Score zwischen 41 und 60 liegt
      return language == "de"
          ? "🌱 Fortschreitender Lernender"
          : "🌱 You can do better";
    } else {
      // Wenn der Score unter 41 liegt
      return language == "de" ? "🐣 Neuling" : "🐣 You will do it next time";
    }
  }
}
