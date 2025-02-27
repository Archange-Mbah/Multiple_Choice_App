class UserRepresenter {
  final String userId; // Die Benutzer-ID des Nutzers
  final String email; // Die E-Mail-Adresse des Nutzers
  final String nickName; // Der Nickname des Nutzers
  final String avatar; // Der Avatar des Nutzers (URL oder Pfad zum Bild)
  final List<int> importedModulesIds; // Eine Liste der IDs der importierten Module

  // Konstruktor, der alle Felder der UserRepresenter-Klasse initialisiert
  UserRepresenter({
    required this.userId,
    required this.email,
    required this.nickName,
    required this.avatar,
    required this.importedModulesIds,
  });

  // Factory-Methode, die ein UserRepresenter-Objekt aus einem JSON erstellt
  factory UserRepresenter.fromJson(Map<String, dynamic> json) {
    return UserRepresenter(
      // 'userIds' im JSON wird in 'userId' der Klasse umgewandelt
      userId: json['userIds'] as String, 
      // 'email' im JSON wird in 'email' der Klasse umgewandelt
      email: json['email'] as String,
      // 'spritzenName' im JSON wird in 'nickName' der Klasse umgewandelt
      nickName: json['spritzenName'] as String, 
      // 'avatar' im JSON wird in 'avatar' der Klasse umgewandelt
      avatar: json['avatar'] as String,
      // Die Liste 'id_importedModules' im JSON wird in eine Liste von Integern umgewandelt
      importedModulesIds: (json['id_importedModules'] as List<dynamic>)
          .map((e) => e as int) // Jeder Wert in der Liste wird in einen Integer umgewandelt
          .toList(), // Die Liste wird anschließend als Dart-Liste zurückgegeben
    );
  }
}
