class LearnStats {
  String userId;
  int moduleId;
  String moduleName;
  String score;
  int correctCount;
  String duration;
  DateTime createdAt;

  LearnStats({
    required this.userId,
    required this.moduleId,
    required this.moduleName,
    required this.score,
    required this.correctCount,
    required this.duration,
    required this.createdAt,
  });

  factory LearnStats.fromJson(Map<String, dynamic> json) {
    return LearnStats(
      userId: json['user_id'] as String,
      moduleId: json['module_id'] as int,
      moduleName: json['moduleName'] as String,
      score: json['score'] as String,
      correctCount: json['correct_count'] as int,
      duration: json['duration'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  // Berechne Performance-Level basierend auf dem Score
  String getPerformanceLevel(String language) {
    double scorePercentage = double.tryParse(score) ?? 0.0;
    if (scorePercentage >= 81) {
      return language == "de" ? "🔥 Wissensmeister" : "🔥 Expert";
    } else if (scorePercentage >= 61) {
      return language == "de" ? "🧠 Wissenssammler" : "🧠 Good";
    } else if (scorePercentage >= 41) {
      return language == "de"
          ? "🌱 Fortschreitender Lernender"
          : "🌱 You can do better";
    } else {
      return language == "de" ? "🐣 Neuling" : "🐣 You will do it next time";
    }
  }
}
