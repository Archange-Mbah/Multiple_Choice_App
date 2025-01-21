import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/flash_card.dart';
import 'package:multiple_choice_trainer/models/module.dart';
import 'package:multiple_choice_trainer/models/user.dart';
import 'package:multiple_choice_trainer/pages/Set_question.dart';
import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/services/auth_service.dart';
import 'package:multiple_choice_trainer/services/service.dart';

class AllModules extends StatefulWidget {
  final String language; // Sprache als Konstruktorparameter

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
  Set<int> downloadedModules = {}; // Set to keep track of downloaded module IDs

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    currentLanguage = widget.language;
    userRef = await supabaseService.getCurrentUserRepresentation(user!.id);

    // Initialize downloadedModules set based on the user's importedModulesIds
    downloadedModules = userRef.importedModulesIds.toSet();

    fetchModules();
    searchController.addListener(() {
      filterModules(searchController.text);
    });
  }

  void fetchModules() async {
    modules = await supabaseService.getModules();
    filteredModules = modules;
    setState(() {});
  }

  // Add module to the importedModulesIds list
  void addModuleToImportedList(Module module) async {
    if (downloadedModules.contains(module.id)) {
      // Already imported, do nothing
      print('Module already imported');
    } else {
      userRef.importedModulesIds.add(module.id); // Add to userRef's list
      await supabaseService.updateUserImportedModulesId(
          userRef.userId, userRef.importedModulesIds);

      setState(() {
        downloadedModules.add(module.id); // Track the module as downloaded
      });

      print('Module imported');
    }
  }

  // Filter modules
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentLanguage == 'de'
            ? 'Lade Modulen herunter'
            : 'Download Modules'),
        automaticallyImplyLeading: false,
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
                          filterModules('');
                        },
                      )
                    : null,
                hintText: currentLanguage == 'de'
                    ? 'Module durchsuchen...'
                    : 'Search modules...',
                border: const OutlineInputBorder(),
              ),
              onTap: () {
                setState(() {
                  searchController.text = '';
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredModules.length,
              itemBuilder: (context, index) {
                final module = filteredModules[index];
                final isDownloaded = downloadedModules.contains(module.id);

                return ListTile(
                  title: Tooltip(
                    message: module.description,
                    child: currentLanguage == 'de'
                        ? Text(module.name)
                        : Text(module.englishName),
                  ),
                  subtitle: MediaQuery.of(context).size.width < 600
                      ? Text(module.description)
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      isDownloaded ? Icons.check_circle : Icons.download,
                      color: isDownloaded ? Colors.green : null,
                    ),
                    onPressed: () => addModuleToImportedList(module),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 30, color: Colors.deepPurple),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ModulPage(
                            language: currentLanguage,
                          )), // Navigiere zur HomePage
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
