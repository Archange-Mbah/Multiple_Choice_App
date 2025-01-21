import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/learn_stats.dart';
import 'package:multiple_choice_trainer/pages/detailed_module_statistics_page.dart';
import 'package:multiple_choice_trainer/services/service.dart';
import 'package:fl_chart/fl_chart.dart';

class ModuleStatisticsPage extends StatefulWidget {
  final String userId;
  final String language;

  const ModuleStatisticsPage({
    Key? key,
    required this.userId,
    required this.language,
  }) : super(key: key);

  @override
  _ModuleStatisticsPageState createState() => _ModuleStatisticsPageState();
}

class _ModuleStatisticsPageState extends State<ModuleStatisticsPage> {
  late Future<List<LearnStats>> _allStatsFuture;

  @override
  void initState() {
    super.initState();
    _allStatsFuture = SupabaseService().getLearnStatsForUser(widget.userId);
  }

  String getPerformanceLevel(String language, String score) {
    double scorePercentage = double.tryParse(score) ?? 0.0;
    if (scorePercentage >= 81) {
      return language == "de" ? "🔥" : "🔥";
    } else if (scorePercentage >= 61) {
      return language == "de" ? "🧠" : "🧠";
    } else if (scorePercentage >= 41) {
      return language == "de" ? "🌱" : "🌱";
    } else {
      return language == "de" ? "🐣" : "🐣";
    }
  }

  List<PieChartSectionData> _createAggregatedChartData(
      List<LearnStats> stats, List<String> moduleNames, List<int> moduleIds, List<String> badgeSymbols) {
    final Map<String, List<LearnStats>> groupedStats = {};
    for (var stat in stats) {
      if (!groupedStats.containsKey(stat.moduleName)) {
        groupedStats[stat.moduleName] = [];
      }
      groupedStats[stat.moduleName]!.add(stat);
    }

    return groupedStats.entries.map((entry) {
      final moduleName = entry.key;
      final moduleStats = entry.value;

      final totalScore = moduleStats.fold<double>(
          0, (sum, stat) => sum + (double.tryParse(stat.score) ?? 0));
      final averageScore = totalScore / moduleStats.length;

      // Add module name and module ID
      moduleNames.add(moduleName);
      moduleIds.add(moduleStats.first.moduleId);

      // Get the badge symbol for the module based on the average score
      badgeSymbols.add(getPerformanceLevel(widget.language, averageScore.toString()));

      return PieChartSectionData(
        value: averageScore,
        title: '',
        color: Colors.primaries[
        moduleNames.indexOf(moduleName) % Colors.primaries.length],
        radius: 60,
        badgeWidget: Text(
          badgeSymbols.last, // Display the badge symbol inside the chart section
          style: const TextStyle(fontSize: 30, color: Colors.white),
        ),
      );
    }).toList();
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.language == 'de' ? 'Gesamtstatistiken' : 'Overall Statistics'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ),
    body: FutureBuilder<List<LearnStats>>(
      future: _allStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              widget.language == 'de' ? 'Keine Statistiken gefunden.' : 'No statistics found.',
            ),
          );
        }

        var stats = snapshot.data!;
        List<String> moduleNames = [];
        List<int> moduleIds = [];
        List<String> badgeSymbols = [];
        var chartData = _createAggregatedChartData(stats, moduleNames, moduleIds, badgeSymbols);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),  // Der Abstand bleibt gleich
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hinweistext
                Text(
                  widget.language == 'de'
                      ? 'Tippen Sie auf ein Diagrammsegment, um Details zu sehen.'
                      : 'Tap on a chart section to view detailed statistics.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,  // Die Textgröße bleibt gleich
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),  // Fester Abstand

                // Dynamisches Kreisdiagramm mit flexibler Größe
                Container(
                  width: double.infinity,  // Stellen Sie sicher, dass das Diagramm immer die volle Breite einnimmt
                  height: 250,  // Geben Sie eine feste Höhe an, um den Abstand zu kontrollieren
                  child: PieChart(
                    PieChartData(
                      sections: chartData,
                      centerSpaceRadius: 70,
                      sectionsSpace: 3,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                          if (event is FlTapUpEvent && response?.touchedSection != null) {
                            final touchedIndex = response!.touchedSection!.touchedSectionIndex;

                            if (touchedIndex != null && touchedIndex >= 0 && touchedIndex < moduleNames.length) {
                              final moduleName = moduleNames[touchedIndex];
                              final moduleId = moduleIds[touchedIndex];

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailedModuleStatisticsPage(
                                    userId: widget.userId,
                                    moduleId: moduleId,
                                    moduleName: moduleName,
                                    language: widget.language,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),  // Fester Abstand

                // Modul-Liste
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: moduleNames.length,
                  itemBuilder: (context, index) {
                    final moduleName = moduleNames[index];
                    final color = Colors.primaries[index % Colors.primaries.length];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            moduleName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),  // Fester Abstand

                // Abzeichensektion
                Column(
                  children: [
                    _buildBadgeCard(
                      badgeIcon: '🔥',
                      badgeTitle: widget.language == 'de' ? 'Wissensmeister' : 'Expert',
                      badgeDescription: widget.language == 'de' ? 'Du hast außergewöhnliches Wissen.' : 'You have exceptional knowledge.',
                      badgeColor: Colors.orange.shade500,
                    ),
                    _buildBadgeCard(
                      badgeIcon: '🧠',
                      badgeTitle: widget.language == 'de' ? 'Wissenssammler' : 'Good',
                      badgeDescription: widget.language == 'de' ? 'Du hast sehr gutes Wissen.' : 'You have very good knowledge.',
                      badgeColor: Colors.blue.shade700,
                    ),
                    _buildBadgeCard(
                      badgeIcon: '🌱',
                      badgeTitle: widget.language == 'de' ? 'Fortschreitender Lernender' : 'You can do better',
                      badgeDescription: widget.language == 'de' ? 'Du machst Fortschritte, aber es gibt noch Raum zur Verbesserung.' : 'You are making progress, but there\'s room to improve.',
                      badgeColor: Colors.green.shade700,
                    ),
                    _buildBadgeCard(
                      badgeIcon: '🐣',
                      badgeTitle: widget.language == 'de' ? 'Neuling' : 'Newbie',
                      badgeDescription: widget.language == 'de' ? 'Du bist am Anfang deiner Lernreise.' : 'You are just beginning your learning journey.',
                      badgeColor: Colors.yellow.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}



  // Custom widget for each badge
  Widget _buildBadgeCard({
    required String badgeIcon,
    required String badgeTitle,
    required String badgeDescription,
    required Color badgeColor,
  }) {
    return Card(
      color: badgeColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              badgeIcon,
              style: const TextStyle(fontSize: 30, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badgeTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badgeDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
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
