import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/pages/statistics.dart'; // Importiere die Statistik-Seite // Importiere HomeScreen
import 'package:multiple_choice_trainer/services/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  final String language;

  const UserProfilePage({super.key, required this.language});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int _currentIndex = 0; // Um den Index der unteren Navigation zu verfolgen

  late String currentLanguage;
  String _selectedAvatar = 'assets/study.webp';
  String _nickname = "Benutzer";
  String _userGoal = "Kein Ziel festgelegt.";
  String _email = "";

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.language;
    // Deine init-Methoden hier
  }

  // Statistik-Seite Navigation
  void _navigateToStatisticsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsPage(
          userId:
              AuthService().getCurrentUser()!.id, // Hier den userId übergeben
          initialLanguage: currentLanguage,
        ),
      ),
    );
  }

  // Navigation zur HomeScreen-Seite
  void _navigateToHomeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ModulPage(language: currentLanguage), // HomeScreen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.language == 'de' ? 'Profilseite' : 'Profile Page'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 99, 171, 249),
        automaticallyImplyLeading: false, // Entfernt den Zurück-Pfeil
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar anzeigen
            CircleAvatar(
              backgroundImage: _selectedAvatar.startsWith('assets/')
                  ? AssetImage(_selectedAvatar)
                  : NetworkImage(_selectedAvatar) as ImageProvider,
              radius: 60,
            ),
            const SizedBox(height: 20),

            // Avatar ändern Button
            TextButton(
              onPressed: () {
                // Deine Avatar ändern Logik
              },
              child: Text(
                  widget.language == 'de' ? 'Avatar ändern' : 'Change Avatar'),
            ),
            const SizedBox(height: 20),

            // Spitzname
            ListTile(
              title: Text(widget.language == 'de'
                  ? 'Spitzname: $_nickname'
                  : 'Nickname: $_nickname'),
            ),

            const SizedBox(height: 20),
            ListTile(
              title: Text(widget.language == 'de'
                  ? 'E-Mail: $_email'
                  : 'Email: $_email'),
            ),

            const SizedBox(height: 20),

            // Ziel Card
            Card(
              color: Colors.blue.shade50,
              shadowColor: Colors.blueAccent,
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      widget.language == 'de' ? 'Dein Ziel:' : 'Your Goal:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userGoal,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Hier fügen wir die BottomNavigationBar hinzu
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Der aktuelle Index der Navigation
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Navigation zum entsprechenden Index
          if (index == 0) {
            // Wenn der Benutzer auf das Home-Symbol klickt
            _navigateToHomeScreen();
          } else if (index == 1) {
            // Navigation zu Statistik-Seite
            _navigateToStatisticsPage();
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: widget.language == 'de' ? 'Startseite' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: widget.language == 'de' ? 'Lernverlauf' : 'learning process',
          ),
        ],
      ),
    );
  }
}
