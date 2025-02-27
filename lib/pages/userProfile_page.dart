import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/pages/statistics.dart'; // Importiere die Statistik-Seite
import 'package:multiple_choice_trainer/services/auth_service.dart';
import 'package:multiple_choice_trainer/services/service.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Hier wird die Profilseite erstellt
class UserProfilePage extends StatefulWidget {
  final String language;

  const UserProfilePage({super.key, required this.language});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  String _userId = '';
  String _selectedAvatar = 'assets/avatars/default.jpg'; // Standard-Avatar
  String _nickname = "Benutzer";
  String _email = "beispiel@email.com";
  bool _isLoading = true;
  bool _isNoteSaved =
      false; // Variable zur Überprüfung, ob die Notiz gespeichert ist

  late String currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    initialize();
    _loadNote();
  }

  Future<void> initialize() async {
    currentLanguage = widget.language;
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = AuthService().getCurrentUser();
      if (user == null) throw Exception('User nicht eingeloggt');
      _userId = user.id;

      final userRepresentation =
          await _supabaseService.getCurrentUserRepresentation(_userId);
      setState(() {
        _nickname = userRepresentation.nickName ?? "Benutzer";
        _email = userRepresentation.email ?? "Keine E-Mail verfügbar";
        _selectedAvatar =
            userRepresentation.avatar ?? 'assets/avatars/default.jpg';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden der Benutzerdaten: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  //hier wird das modul zur importierten liste hinzugefügt

  Future<void> _updateNickname() async {
    if (_nicknameController.text.isEmpty) return;
    try {
      await _supabaseService.updateUserNickname(
          _userId, _nicknameController.text);
      setState(() {
        _nickname = _nicknameController.text;
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentLanguage == 'de'
              ? 'Fehler beim Aktualisieren des Spitznamens:'
              : 'Error updating nickname: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

//hier wird der spitzname geändert
  void _showNicknameEditDialog() {
    _nicknameController.text = _nickname;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
              currentLanguage == 'de' ? 'Spitzname ändern' : 'Change nickname'),
          content: TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: currentLanguage == 'de'
                  ? 'Neuen Spitznamen eingeben'
                  : 'Enter new nickname',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(currentLanguage == 'de' ? 'Abbrechen' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: _updateNickname,
              child: Text(currentLanguage == 'de' ? 'Speichern' : 'Save'),
            ),
          ],
        );
      },
    );
  }

//hier wird der avatar geändert
  Future<void> _changeAvatar(String newAvatar) async {
    try {
      setState(() {
        _selectedAvatar = newAvatar; // Lokale Änderung für das UI
      });

      // Avatar-Name speichern
      await _supabaseService.updateUserAvatar(_userId, newAvatar);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentLanguage == 'de'
              ? 'Fehler beim Ändern des Avatars: $e'
              : 'Error changing the avatar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
              currentLanguage == 'de' ? 'Avatar auswählen' : 'Select avatar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () {
                      _changeAvatar('assets/avatars/avatar1.webp');
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      backgroundImage:
                          const AssetImage('assets/avatars/avatar1.webp'),
                      radius: 35,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _changeAvatar('assets/avatars/avatar2.webp');
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      backgroundImage:
                          const AssetImage('assets/avatars/avatar2.webp'),
                      radius: 35,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _changeAvatar('assets/avatars/avatar3.webp');
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      backgroundImage:
                          const AssetImage('assets/avatars/avatar3.webp'),
                      radius: 35,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToHomeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ModulPage(language: widget.language)),
    );
  }

  void _navigateToStatisticsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StatisticsPage(userId: _userId, initialLanguage: widget.language),
      ),
    );
  }

  // Lädt die gespeicherte Notiz
  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    String note = prefs.getString('note') ?? '';
    _goalController.text = note;
  }

  // Aktualisierung der _saveNote-Methode
  Future<void> _saveNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('note', _goalController.text);
    setState(() {
      _isNoteSaved = true; // Notiz wurde gespeichert, Textfeld wird nur-lesbar
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
        automaticallyImplyLeading: false,
        title: Text(
          currentLanguage == 'de' ? 'Profilseite' : 'Profile Page',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: AssetImage(_selectedAvatar),
                  radius: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nickname,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _showAvatarSelectionDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade100,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          currentLanguage == 'de'
                              ? 'Avatar ändern'
                              : 'Change avatar',
                          style: TextStyle(
                              color: const Color.fromRGBO(69, 39, 160, 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text('Name',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple)),
                subtitle: Text(_nickname, style: TextStyle(fontSize: 16)),
                trailing: IconButton(
                  icon: Icon(Icons.edit,
                      color: const Color.fromRGBO(69, 39, 160, 1)),
                  onPressed: _showNicknameEditDialog,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLanguage == 'de' ? 'Notizen' : 'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 150, // Fixed height to prevent resizing
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.deepPurple.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                                right: 40), // To prevent text behind the icon
                            child: TextField(
                              controller: _goalController,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: currentLanguage == 'de'
                                    ? 'Neue Notiz eingeben...'
                                    : 'Enter new note...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          child: IconButton(
                            icon: Icon(_isNoteSaved ? Icons.edit : Icons.clear,
                                color: _isNoteSaved
                                    ? Colors.deepPurple
                                    : Colors.red),
                            onPressed: () {
                              if (_isNoteSaved) {
                                setState(() {
                                  _isNoteSaved = false;
                                });
                              } else {
                                _goalController.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isNoteSaved ? null : _saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          currentLanguage == 'de' ? 'Speichern' : 'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color.fromRGBO(69, 39, 160, 1),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) _navigateToHomeScreen();
          if (index == 1) _navigateToStatisticsPage();
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: currentLanguage == 'de' ? 'Startseite' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: currentLanguage == 'de' ? 'Lernverlauf' : 'Learning Process',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
