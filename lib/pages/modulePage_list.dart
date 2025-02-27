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

//hier werden die module angezeigt
class ModulPage extends StatefulWidget {
  final String language;

  ModulPage({Key? key, required this.language}) : super(key: key);

  @override
  _ModulPageState createState() => _ModulPageState();
}

class _ModulPageState extends State<ModulPage> {
  late String currentLanguage;
  final supabaseService = SupabaseService();
  final user = AuthService().getCurrentUser();
  late UserRepresenter userRef;
  List<Module> modules = [];
  List<Module> filteredModules = [];
  final TextEditingController searchController = TextEditingController();
  final AuthService _authService = AuthService();
  bool showSearchBar = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    currentLanguage = widget.language;
    userRef = await supabaseService.getCurrentUserRepresentation(user!.id);
    fetchModules();
    searchController.addListener(() {
      filterModules(searchController.text);
    });
  }

//hier werden die module von der datenbank geholt
  void fetchModules() async {
    modules = await supabaseService.getUserModules(userRef);
    filteredModules = modules;
    setState(() {});
  }
     //hier  wird das modul entfernt von der importierten liste
  void removeModuleFromImportedList(Module module) async {
    List<int> importedModulesIds = userRef.importedModulesIds;
    if (importedModulesIds.contains(module.id)) {
      importedModulesIds.remove(module.id);
      await supabaseService.updateUserImportedModulesId(
          userRef.userId, importedModulesIds);
      fetchModules();
    }
  }

 //hier werden die flashcardstats für ein bestimmtes modul gelöscht
  void deleteFlashcardStats(String userId, int moduleId) async {
    await supabaseService.deleteFlashcardStats(userId, moduleId);
  }

  //hier werden die modulstats für ein bestimmtes modul gelöscht
  void deleteModuleStats(String userId, int moduleId) async {
    await supabaseService.deleteLearnRoundStats(userId, moduleId);
  }
//hier werden die module gefiltert
  void filterModules(String query) {
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      filteredModules = modules.where((module) {
        final nameMatch = module.name.toLowerCase().contains(lowercaseQuery);
        final descriptionMatch =
            module.description.toLowerCase().contains(lowercaseQuery);
        return nameMatch || descriptionMatch;
      }).toList();
    });
  }

  //hier wird die farbe des moduls bestimmt
  Color getColorFromId(int moduleId) {
    Map<int, Color> moduleColorMap = {
      0: Color(0xFFF8BBD0), // Red 100 angepasst zu etwas dunkler
      1: Color(0xFF90CAF9), // Blue 100 angepasst zu etwas dunkler
      2: Color(0xFFA5D6A7), // Green 100 angepasst zu etwas dunkler
      3: Color.fromARGB(
          255, 255, 186, 140), // Yellow 100 angepasst zu etwas dunkler
    };

    return moduleColorMap[moduleId % moduleColorMap.length] ?? Colors.grey;
  }
// hier wird der benutzer abgemeldet
  Future<void> _confirmSignOut() async {
    bool? shouldSignOut = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              currentLanguage == 'de' ? 'Abmelden' : 'Sign Out',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              currentLanguage == 'de'
                  ? 'Möchtest du dich wirklich abmelden?'
                  : 'Do you really want to sign out?',
              style: const TextStyle(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple, // Button text color
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    currentLanguage == 'de' ? 'Abbrechen' : 'Cancel',
                    style: const TextStyle(color: Colors.deepPurple),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    currentLanguage == 'de' ? 'Abmelden' : 'Sign Out',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          ],
          actionsPadding: EdgeInsets.only(
              bottom: 20), // Vergrößert den Abstand zum unteren Rand
        );
      },
    );

    if (shouldSignOut == true) {
      _authService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
    }
  }

  void searchAndNavigate(String query) {
    final matchingModules = modules
        .where(
          (module) => module.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    if (matchingModules.isNotEmpty) {
      final foundModule = matchingModules.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetQuestion(
            flashcards: [],
            language: currentLanguage,
            moduleName: foundModule.name,
            englishName: foundModule.englishName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kein Modul mit diesem Namen gefunden!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Reagiert nur auf spezifische Bereiche

      onTap: () {
        if (showSearchBar) {
          setState(() {
            showSearchBar = false;
            searchController.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  currentLanguage == 'de' ? 'Deine Module' : 'Your Modules',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
              ),
              if (showSearchBar)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          searchAndNavigate(value.trim());
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        prefixIcon: const Icon(Icons.search,
                            color: const Color.fromRGBO(69, 39, 160, 1)),
                        hintText: currentLanguage == 'de'
                            ? 'Module durchsuchen...'
                            : 'Search modules...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close,
                              color: const Color.fromRGBO(69, 39, 160, 1)),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              showSearchBar = false;
                              filterModules('');
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      showSearchBar = true;
                    });
                  },
                ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (String result) {
                if (result == 'profile') {
                  _navigateToUserProfile();
                } else if (result == 'language') {
                  _selectLanguage();
                } else if (result == 'logout') {
                  _confirmSignOut();
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: const Icon(Icons.person,
                          color: const Color.fromRGBO(69, 39, 160, 1)),
                      title: Text(
                        currentLanguage == 'de'
                            ? 'Profil anzeigen'
                            : 'View Profile',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'language',
                    child: ListTile(
                      leading: const Icon(Icons.language,
                          color: const Color.fromRGBO(69, 39, 160, 1)),
                      title: Text(
                        currentLanguage == 'de'
                            ? 'Sprache ändern'
                            : 'Change Language',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(
                        currentLanguage == 'de' ? 'Abmelden' : 'Sign Out',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: filteredModules.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Zentriere die Inhalte horizontal
                  children: [
                    Image.asset('assets/nichts_da.png', width: 200),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 20,
                          left: 20,
                          right: 20), // Erhöhtes Padding für bessere Optik
                      child: Text(
                        currentLanguage == 'de'
                            ? 'Du hast noch keine Module. Drücke auf Plus um welche zu importieren'
                            : 'You have no modules yet. Press the plus button to import some. ',
                        textAlign: TextAlign.center, // Text zentrieren

                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                //physics: AlwaysScrollableScrollPhysics(),

                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width < 800 ? 2 : 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredModules.length,
                  itemBuilder: (context, index) {
                    final module = filteredModules[index];
                    return Card(
                      color: getColorFromId(module.id),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.book,
                                        size: 40, color: Colors.white),
                                    Text(
                                      currentLanguage == 'de'
                                          ? module.name
                                          : module.englishName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: PopupMenuButton<int>(
                                onSelected: (item) =>
                                    _handleMenuItemClick(item, module),
                                itemBuilder: (context) => [
                                  PopupMenuItem<int>(
                                    value: 1,
                                    child: Text(currentLanguage == 'de'
                                        ? 'Löschen'
                                        : 'Delete'),
                                  ),
                                ],
                                icon:
                                    Icon(Icons.more_vert, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home button with icon and label
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ModulPage(language: widget.language),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home,
                      size: 30,
                      color: Color.fromRGBO(69, 39, 160, 1),
                    ),
                    Text(
                      currentLanguage == 'de' ? 'Startseite' : 'Home',
                      style: const TextStyle(
                          fontSize: 12, color: Color.fromRGBO(69, 39, 160, 1)),
                    ),
                  ],
                ),
              ),
              // Statistics button with icon and label
              InkWell(
                onTap: () {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 30,
                      color: Colors.grey,
                    ),
                    Text(
                      currentLanguage == 'de' ? 'Statistik' : 'Statistics',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllModules(language: currentLanguage),
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  void _handleMenuItemClick(int item, Module module) {
    if (item == 1) {
      _confirmDelete(module);
    }
  }

  Future<void> _confirmDelete(Module module) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              Colors.deepPurple.shade50, // Hintergrundfarbe des Dialogs
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Eckenradius
          ),
          title: Text(
            currentLanguage == "de" ? 'Modul löschen' : 'Delete Module',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          content: Text(
            currentLanguage == "de"
                ? 'Möchten Sie das Modul wirklich löschen? Es werden alle zum Modul gehörigen Daten gelöscht.'
                : 'Do you really want to delete the module? This will erase all data associated with it.',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple, // Button text color
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(currentLanguage == 'de' ? 'Nein' : 'No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Farbe des Buttons
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12), // Eckenradius des Buttons
                ),
              ),
              onPressed: () {
                removeModuleFromImportedList(module);
                deleteFlashcardStats(user!.id, module.id);
                deleteModuleStats(user!.id, module.id);
                Navigator.of(context).pop(true);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    currentLanguage == 'de' ? 'Löschen' : 'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete ?? false) {
      setState(() {
        modules.removeWhere((m) => m.id == module.id);
        filteredModules.removeWhere((m) => m.id == module.id);
      });
    }
  }

  void _navigateToUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(language: currentLanguage),
      ),
    );
  }

  _selectLanguage() async {
    String? newLanguage = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              currentLanguage == 'de' ? 'Sprache auswählen' : 'Select Language',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromRGBO(69, 39, 160, 1),
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                tileColor: currentLanguage == 'de'
                    ? Colors.deepPurple.shade50
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  Icons.language,
                  color: currentLanguage == 'de'
                      ? const Color.fromRGBO(69, 39, 160, 1)
                      : Colors.grey.shade700,
                ),
                title: const Text('Deutsch'),
                trailing: currentLanguage == 'de'
                    ? const Icon(Icons.check,
                        color: const Color.fromRGBO(69, 39, 160, 1))
                    : null,
                onTap: () {
                  Navigator.of(context).pop('de');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: currentLanguage == 'en'
                    ? Colors.deepPurple.shade50
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  Icons.language,
                  color: currentLanguage == 'en'
                      ? const Color.fromRGBO(69, 39, 160, 1)
                      : Colors.grey.shade700,
                ),
                title: const Text('English'),
                trailing: currentLanguage == 'en'
                    ? const Icon(Icons.check,
                        color: const Color.fromRGBO(69, 39, 160, 1))
                    : null,
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
