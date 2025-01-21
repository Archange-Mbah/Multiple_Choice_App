import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/flash_card.dart';
import 'package:multiple_choice_trainer/models/module.dart';
import 'package:multiple_choice_trainer/models/user.dart';
import 'package:multiple_choice_trainer/pages/Set_question.dart';
import 'package:multiple_choice_trainer/pages/auth_page.dart';
import 'package:multiple_choice_trainer/pages/downloadModules.dart';
import 'package:multiple_choice_trainer/pages/module_statistics_page.dart';
import 'package:multiple_choice_trainer/pages/userProfile_page.dart';
import 'package:multiple_choice_trainer/services/auth_service.dart';
import 'package:multiple_choice_trainer/services/service.dart';

class ModulPage extends StatefulWidget {
  final String language; // Sprache als Konstruktorparameter

  ModulPage({Key? key, required this.language}) : super(key: key);

  @override
  _ModulPageState createState() => _ModulPageState();
}

class _ModulPageState extends State<ModulPage> {
  late String currentLanguage;
  final supabaseService = SupabaseService(); // Zugriff auf die Service-Methoden
  final user = AuthService().getCurrentUser();
  late UserRepresenter userRef;
  List<Module> modules = [];
  List<Module> filteredModules = [];
  final TextEditingController searchController = TextEditingController();
  final AuthService _authService = AuthService(); // AuthService-Instanz

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    currentLanguage = widget.language; // Sprache aus dem Konstruktor
    userRef = await supabaseService.getCurrentUserRepresentation(user!.id);
    fetchModules();
    // Listen for changes in the search bar and filter modules
    searchController.addListener(() {
      filterModules(searchController.text);
    });
  }

  void fetchModules() async {
    modules = await supabaseService.getUserModules(userRef);
    filteredModules = modules;
    setState(() {}); // Update the UI with the new module list
  }

  // Entferne ein Modul aus der Liste
  void removeModuleFromImportedList(Module module) async {
    List<int> importedModulesIds = userRef.importedModulesIds;
    if (importedModulesIds.contains(module.id)) {
      importedModulesIds.remove(module.id); // Entferne das Modul aus der Liste
      await supabaseService.updateUserImportedModulesId(
          userRef.userId, importedModulesIds);
      fetchModules(); // Aktualisiere die Modul-Liste
    }
  }

  void deleteFlashcardStats(String userId, int moduleId) async {
    await supabaseService.deleteFlashcardStats(userId, moduleId);
  }

  void deleteModuleStats(String userId, int moduleId) async {
    await supabaseService.deleteLearnRoundStats(userId, moduleId);
  }

  // Filter modules based on search query
  void filterModules(String query) {
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      filteredModules = modules.where((module) {
        final nameMatch = module.name.toLowerCase().startsWith(lowercaseQuery);
        final descriptionMatch =
            module.description.toLowerCase().startsWith(lowercaseQuery);
        return nameMatch || descriptionMatch;
      }).toList();
    });
  }

  // Sprache ändern
  void _changeLanguage(String newLanguage) {
    setState(() {
      currentLanguage = newLanguage;
    });
  }

  // Methode zur Anzeige der Bestätigungsmeldung beim Abmelden
  Future<void> _confirmSignOut() async {
    bool? shouldSignOut = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(currentLanguage == 'de' ? 'Abmelden' : 'Sign Out'),
          content: Text(currentLanguage == 'de'
              ? 'Möchtest du dich wirklich abmelden?'
              : 'Do you really want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Wenn "Abbrechen" gedrückt wird
              },
              child: Text(currentLanguage == 'de' ? 'Abbrechen' : 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context)
                    .pop(true); // Wenn "Abmelden" gedrückt wird
              },
              child: Text(currentLanguage == 'de' ? 'Abmelden' : 'Sign Out'),
            ),
          ],
        );
      },
    );

    // Wenn der Benutzer "Abmelden" bestätigt hat, führe die Abmeldung durch
    if (shouldSignOut == true) {
      _authService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
    }
  }

// Definiere eine Liste von Farben für die Module
  Map<int, Color> moduleColorMap = {
    0: const Color.fromARGB(255, 255, 150, 59), // Modul mit ID 0 erhält Gelb
    1: Colors.blue, // Modul mit ID 1 erhält Blau
    2: Colors.green, // Modul mit ID 2 erhält Grün
    3: const Color.fromARGB(255, 249, 112, 157), // Modul mit ID 3 erhält Lila
  };
  Color getColorFromId(int moduleId) {
    // Gibt die zugeordnete Farbe zurück, oder eine Standardfarbe, wenn die ID nicht gefunden wird
    return moduleColorMap[moduleId] ??
        Colors
            .grey; // 'Colors.grey' ist ein Fallback, falls die ID nicht definiert ist
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentLanguage == 'de' ? 'Deine Module' : 'Your Modules'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart), // Statistik-Icon
            tooltip: currentLanguage == 'de' ? 'Statistik' : 'Statistics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModuleStatisticsPage(
                    userId: user!.id,
                    language: currentLanguage,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert), // Options-Symbol
            onSelected: (value) async {
              if (value == 'language') {
                _selectLanguage();
              } else if (value == 'logout') {
                _confirmSignOut();
              } else if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                          language:
                              currentLanguage)), // Navigation zur UserProfilePage
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'language',
                child: Row(
                  children: [
                    Icon(Icons.language),
                    SizedBox(width: 10),
                    Text(currentLanguage == 'de' ? 'Sprache' : 'Language'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 10),
                    Text(currentLanguage == 'de'
                        ? 'Benutzerprofil'
                        : 'User Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text(currentLanguage == 'de' ? 'Abmelden' : 'Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          filterModules(''); // Reset filter
                        },
                      )
                    : null,
                hintText: currentLanguage == 'de'
                    ? 'Module durchsuchen...'
                    : 'Search modules...',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          filteredModules.isEmpty
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/robotTraurig.png',
                          width: MediaQuery.of(context).size.width *
                              0.6, // 60% der Breite des Bildschirms
                          height: MediaQuery.of(context).size.height *
                              0.3, // 30% der Höhe des Bildschirms
                          fit: BoxFit.contain, // Passt das Bild proportional an
                        ),
                        SizedBox(height: 16),
                        Text(
                          currentLanguage == 'de'
                              ? 'Keine Module gefunden. Drücke auf das Plus-Symbol unten, um Module hinzuzufügen.'
                              : 'No modules found. Please press the plus icon below to add modules.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250, // Maximale Breite der Karte
                          mainAxisExtent: 200, // Höhe der Karte
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredModules.length,
                        itemBuilder: (context, index) {
                          final module = filteredModules[index];
                          return Card(
                            color: getColorFromId(
                                module.id), // Hier wird die Farbe gesetzt

                            elevation: 4, // Schatten hinzufügen
                            margin: EdgeInsets.all(8),

                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10) // Abgerundete Ecken
                                ),
                            child: InkWell(
                              onTap: () async {
                                List<Flashcard> flashcards =
                                    await supabaseService.getFlashcards(
                                  user?.id ?? '',
                                  module.id.toString(),
                                  currentLanguage,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SetQuestion(
                                      flashcards: flashcards,
                                      language: currentLanguage,
                                      moduleName: module.name,
                                      englishName: module.englishName,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceEvenly, // Besseres Spacing
                                children: [
                                  Spacer(),
                                  Icon(Icons.book,
                                      size: 40,
                                      color: Colors
                                          .white), // Icon mit Farbe und Größe
                                  Text(
                                    currentLanguage=='de' ? module.name : module.englishName , // Modulname
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  Spacer(),
                                  Tooltip(
                                    message: module
                                        .description, // Beschreibung nur im Tooltip
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      removeModuleFromImportedList(module);
                                      deleteFlashcardStats(user!.id, module.id);
                                      deleteModuleStats(user!.id, module.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllModules(language: currentLanguage),
            ),
          );
        },
        child: Icon(Icons.add), // Plus icon for adding modules
        tooltip: 'Add Module',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Methode, um die Sprache zu ändern
  _selectLanguage() async {
    String? newLanguage = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(currentLanguage == 'de'
              ? 'Sprache auswählen'
              : 'Select Language'), // Dynamischer Titel
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Deutsch',
                  style: TextStyle(
                    fontWeight: currentLanguage == 'de'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop('de');
                },
              ),
              ListTile(
                title: Text(
                  'English',
                  style: TextStyle(
                    fontWeight: currentLanguage == 'en'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop('en');
                },
              ),
            ],
          ),
        );
      },
    );

    if (newLanguage != null) {
      setState(() {
        currentLanguage = newLanguage;
      });
    }
  }
}
