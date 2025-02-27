import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/module.dart';
import 'package:multiple_choice_trainer/models/user.dart';
import 'package:multiple_choice_trainer/pages/Set_question.dart';

import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/services/auth_service.dart';
import 'package:multiple_choice_trainer/services/service.dart';


//hier werden modulen heruntergeladen
class AllModules extends StatefulWidget {
  final String language;

  AllModules({Key? key, required this.language}) : super(key: key);

  @override
  _ModulPageState createState() => _ModulPageState();
}

class _ModulPageState extends State<AllModules> {
  late String currentLanguage;
  final supabaseService = SupabaseService();
  final user = AuthService().getCurrentUser();
  late UserRepresenter userRef;
  List<Module> modules = [];
  List<Module> filteredModules = [];
  final TextEditingController searchController = TextEditingController();
  Set<int> downloadedModules = {};
  bool showSearchBar = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    currentLanguage = widget.language;
    userRef = await supabaseService.getCurrentUserRepresentation(user!.id);
    downloadedModules = Set.from(userRef.importedModulesIds);
    fetchModules();
    searchController.addListener(() {
      filterModules(searchController.text);
    });
  }
  //hier werden die module von der datenbank geholt
  void fetchModules() async {
    modules = await supabaseService.getModules();
    filteredModules = modules;
    setState(() {});
  }
   //hier wird das modul zur importierten liste hinzugefügt
  void addModuleToImportedList(Module module) async {
    if (downloadedModules.contains(module.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentLanguage == 'de'
              ? 'Modul bereits heruntergeladen'
              : 'Module already downloaded'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      userRef.importedModulesIds.add(module.id);
      await supabaseService.updateUserImportedModulesId(
          userRef.userId, userRef.importedModulesIds);
      setState(() {
        downloadedModules.add(module.id);
      });

      setState(() {});
    }
  }


//hier wird die suche nach modulen durchgeführt
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: Text(
                currentLanguage == 'de' ? 'Alle Module' : 'All Modules',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
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
                        icon: const Icon(Icons.close, color: Colors.white),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: filteredModules.isEmpty
            ? Center(
                child: Text(
                  currentLanguage == 'de'
                      ? 'Keine Module gefunden'
                      : 'No modules found',
                  style: const TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: filteredModules.length,
                itemBuilder: (context, index) {
                  final module = filteredModules[index];
                  final isDownloaded = downloadedModules.contains(module.id);
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      title: Text(
                        currentLanguage == 'de'
                            ? module.name
                            : module.englishName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: MediaQuery.of(context).size.width < 600
                          ? Text(
                              module.description,
                              style: TextStyle(color: Colors.grey.shade700),
                            )
                          : null,
                      trailing: IconButton(
                        icon: Icon(
                          isDownloaded ? Icons.check_circle : Icons.download,
                          color: isDownloaded
                              ? Colors.green
                              : const Color.fromRGBO(69, 39, 160, 1),
                          size: 28,
                        ),
                        onPressed: () => addModuleToImportedList(module),
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
            // Home Button
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModulPage(language: widget.language),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home,
                    size: 30,
                    color: Colors.grey,
                  ),
                  Text(
                    currentLanguage == 'de' ? 'Startseite' : 'Home',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Download Button
            InkWell(
              onTap: () {
                // Navigation zur Download-Seite, wenn notwendig
                MaterialPageRoute(
                  builder: (context) => AllModules(language: currentLanguage),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.download,
                    size: 30,
                    color: Color.fromRGBO(69, 39, 160, 1),
                  ),
                  Text(
                    currentLanguage == 'de' ? 'Download' : 'Download',
                    style: const TextStyle(
                        fontSize: 12, color: Color.fromRGBO(69, 39, 160, 1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
