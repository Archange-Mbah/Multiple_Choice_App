import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/services/service.dart';

//Diese Seite zeigt detaillierte Statistiken für ein bestimmtes Modul an
class DetailedModuleStatisticsPage extends StatefulWidget {
  final String userId;
  final int moduleId; // Typ muss mit deiner Datenbank übereinstimmen
  final String language;
  final String moduleName;

  const DetailedModuleStatisticsPage({
    Key? key,
    required this.userId,
    required this.moduleId,
    required this.moduleName,
    required this.language,
  }) : super(key: key);


  @override
  _DetailedModuleStatisticsPageState createState() =>
      _DetailedModuleStatisticsPageState();
}

class _DetailedModuleStatisticsPageState
    extends State<DetailedModuleStatisticsPage> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = SupabaseService()
        .calculateModuleStatistics(widget.userId, widget.moduleId);
  }

  Widget _buildStatisticTile(
      {required IconData icon,
      required Color color,
      required String title,
      required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.language == 'de'
              ? 'Statistiken für Modul "${widget.moduleName}"'
              : 'Statistics for Module "${widget.moduleName}"',
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                widget.language == 'de'
                    ? 'Fehler: ${snapshot.error}'
                    : 'Error: ${snapshot.error}',
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                widget.language == 'de'
                    ? 'Keine Daten gefunden.'
                    : 'No data found.',
              ),
            );
          }

          var stats = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.language == 'de'
                      ? 'Statistiken für Modul "${widget.moduleId}"'
                      : 'Statistics for Module "${widget.moduleId}"',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatisticTile(
                  icon: Icons.score,
                  color: Colors.blue,
                  title: widget.language == 'de'
                      ? 'Durchschnittlicher Score als %'
                      : 'Average Score in %',
                  value: (stats['averageScore'] ?? 0).toStringAsFixed(2),
                ),
                _buildStatisticTile(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  title: widget.language == 'de'
                      ? 'Gesamtrichtige Antworten'
                      : 'Total Correct Answers',
                  value: (stats['totalCorrect'] ?? 0).toString(),
                ),
                _buildStatisticTile(
                  icon: Icons.loop,
                  color: Colors.orange,
                  title: widget.language == 'de'
                      ? 'Anzahl der Runden'
                      : 'Number of Rounds',
                  value: '${stats['roundsCount'] ?? 0}',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
