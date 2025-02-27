import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/learn_stats.dart';
import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/pages/userProfile_page.dart';
import 'package:multiple_choice_trainer/services/service.dart';
import 'package:intl/intl.dart';

// Diese Seite zeigt die Lernstatistiken des Benutzers an
class StatisticsPage extends StatefulWidget {
  final String userId;
  final String initialLanguage;

  const StatisticsPage(
      {Key? key, required this.userId, required this.initialLanguage})
      : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<List<LearnStats>> _learnStatsFuture;
  late String currentLanguage;
  int _currentIndex = 1; // Stelle sicher, dass Stats als aktiv markiert ist

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;
    _learnStatsFuture = SupabaseService().getLearnStatsForUser(widget.userId);
  }

//hier wird die navigation zur home seite gemacht
  void _navigateToHomeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ModulPage(language: currentLanguage)),
    );
  }
//hier wird die navigation zur user seite gemacht
  void _navigateToUserPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => UserProfilePage(
                language: currentLanguage,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          currentLanguage == 'de' ? 'Lernverlauf' : 'Learning Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<LearnStats>>(
          future: _learnStatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/nichts_da.png', // Stelle sicher, dass dieses Bild im assets Verzeichnis vorhanden ist
                      width: 200,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        currentLanguage == 'de'
                            ? 'Kein Lernverlauf verfügbar.'
                            : 'No learning progress available.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final learnStats = snapshot.data!;
            final groupedStats = _groupStatsByDate(learnStats);

            return ListView.builder(
              itemCount: groupedStats.keys.length,
              itemBuilder: (context, index) {
                final date = groupedStats.keys.elementAt(index);
                final statsForDate = groupedStats[date]!;
                return _buildExpandableCard(date, statsForDate);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            _navigateToHomeScreen();
          } else if (index == 2) {
            _navigateToUserPage();
          }
          // Nichts tun, wenn der aktuelle Index bereits '1' für Statistiken ist
          if (index != 1) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Map<String, List<LearnStats>> _groupStatsByDate(List<LearnStats> stats) {
    final Map<String, List<LearnStats>> groupedStats = {};

    for (var stat in stats) {
      final dateTime = _parseDate(stat.createdAt);
      final dateKey = _formatDateOnly(dateTime);

      if (!groupedStats.containsKey(dateKey)) {
        groupedStats[dateKey] = [];
      }
      groupedStats[dateKey]!.add(stat);
    }

    final sortedKeys = groupedStats.keys.toList()
      ..sort((a, b) {
        final dateA = _parseDate(a);
        final dateB = _parseDate(b);
        return dateB.compareTo(dateA); // Sortiere die Keys (Datum) absteigend
      });

    for (var key in groupedStats.keys) {
      groupedStats[key]!.sort((a, b) {
        final dateA = _parseDate(a.createdAt);
        final dateB = _parseDate(b.createdAt);
        return dateB.compareTo(
            dateA); // Sortiere die Module innerhalb jedes Datums absteigend
      });
    }

    return {for (var key in sortedKeys) key: groupedStats[key]!};
  }

  Widget _buildExpandableCard(String date, List<LearnStats> statsForDate) {
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color.fromRGBO(69, 39, 160, 1),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color.fromRGBO(69, 39, 160, 1),
                      ),
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  Divider(),
                  Column(
                    children: statsForDate.map((stats) {
                      return _buildModuleRow(stats);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuleRow(LearnStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.moduleName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color.fromRGBO(69, 39, 160, 1),
            ),
          ),
          _buildStatRow(
            currentLanguage == 'de' ? 'Punkte%:' : 'Score%:',
            (double.tryParse(stats.score)?.toStringAsFixed(0) ?? '0') + '%',
          ),
          _buildStatRow(
            currentLanguage == 'de' ? 'Richtig:' : 'Correct:',
            '${stats.correctCount}',
          ),
          _buildStatRow(
            currentLanguage == 'de' ? 'Dauer:' : 'Duration:',
            _formatDuration(stats.duration),
          ),
          _buildStatRow(
            currentLanguage == 'de' ? 'Rang:' : 'Performance:',
            stats.getPerformanceLevel(currentLanguage),
            textColor: _getPerformanceColor(stats),
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: const Color.fromRGBO(69, 39, 160, 1),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: textColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(String durationInSeconds) {
    int seconds = int.tryParse(durationInSeconds) ?? 0;
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(DateTime date) {
    if (currentLanguage == 'de') {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is DateTime) {
      return date; // Bereits ein DateTime, keine Umwandlung nötig
    }
    if (date is String) {
      try {
        return DateTime.parse(
            date); // Versuche, den String als ISO-8601 zu parsen
      } catch (_) {
        final inputFormat = DateFormat('dd.MM.yyyy');
        return inputFormat.parse(
            date); // Falls das nicht funktioniert, verwende benutzerdefiniertes Format
      }
    }
    throw ArgumentError('Unsupported date format: $date');
  }

  Color _getPerformanceColor(LearnStats stats) {
    double scorePercentage = double.tryParse(stats.score) ?? 0;
    if (scorePercentage >= 81) {
      return Colors.green;
    } else if (scorePercentage >= 61) {
      return Colors.blue;
    } else if (scorePercentage >= 41) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
