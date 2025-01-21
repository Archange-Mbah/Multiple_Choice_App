class Module {
  final int id; // Modul-ID
  final String name; // Modul-Name
  final String description; // Modul-Beschreibung
  final String englishName;

  // Konstruktor
  Module({
    required this.id,
    required this.name,
    required this.description,
    required this.englishName
  });

  // Factory-Methode zur Erstellung eines Moduls aus einer JSON-Darstellung (z. B. von Supabase)
 factory Module.fromJson(Map<String, dynamic> json) {
 return Module(
  id: json['module_id'] as int  , // Falls 'id' null ist, benutze 0 als Standardwert
  name: json['moduleName'] as String? ?? '', // Falls 'name' null ist, benutze einen leeren String
  description: json['description'] as String? ?? '', // Falls 'description' null ist, benutze einen leeren String
  englishName: json['englishName'] as String? ?? '', // Falls 'description' null ist, benutze einen leeren String
);
 }

  // Methode
  // zur Konvertierung des Moduls in eine JSON-Darstellung (z. B. für Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(), // ID des Moduls
      'moduleName': name, // Name des Moduls
      'description': description, // Beschreibung des Moduls
    };
  }
}
