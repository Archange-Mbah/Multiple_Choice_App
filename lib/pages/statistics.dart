import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/learn_stats.dart';
import 'package:multiple_choice_trainer/services/service.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;
    _learnStatsFuture = SupabaseService().getLearnStatsForUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentLanguage == 'de' ? 'Lernverlauf' : 'Learning Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.deepPurple,
          ),
        ),
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
                child: Text(
                  currentLanguage == 'de'
                      ? 'Kein Lernverlauf verfügbar.'
                      : 'No learning progress available.',
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
    );
  }

  Map<String, List<LearnStats>> _groupStatsByDate(List<LearnStats> stats) {
    final Map<String, List<LearnStats>> groupedStats = {};
    for (var stat in stats) {
      // Konvertiere stat.createdAt (String) in DateTime
      final dateTime = _parseDate(stat.createdAt);
      final dateKey = _formatDateOnly(dateTime); // DateTime an _formatDateOnly übergeben

      if (!groupedStats.containsKey(dateKey)) {
        groupedStats[dateKey] = [];
      }
      groupedStats[dateKey]!.add(stat);
    }

    final sortedKeys = groupedStats.keys.toList()
      ..sort((a, b) {
        final dateA = _parseDate(a); // Konvertiere Key zurück zu DateTime
        final dateB = _parseDate(b);
        return dateB.compareTo(dateA);
      });
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
                        color: Colors.deepPurple,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.deepPurple,
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
              color: Colors.deepPurple,
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
              color: Colors.deepPurple,
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
        return DateTime.parse(date); // Versuche, den String als ISO-8601 zu parsen
      } catch (_) {
        final inputFormat = DateFormat('dd.MM.yyyy');
        return inputFormat.parse(date); // Falls das nicht funktioniert, verwende benutzerdefiniertes Format
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
