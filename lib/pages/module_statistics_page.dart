import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/learn_stats.dart';
import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/services/service.dart';
import 'package:fl_chart/fl_chart.dart';


// Diese Seite zeigt die Gesamtstatistiken für alle Module an
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
  late List<LearnStats> stats;
  int? selectedBarIndex; // Um den ausgewählten Balken zu verfolgen
  int _currentIndex = 1; // Statistik-Icon ist standardmäßig ausgewählt

  @override
  void initState() {
    super.initState();
    _allStatsFuture = SupabaseService().getLearnStatsForUser(widget.userId);
  }
     // Diese Methode gibt das entsprechende Badge-Symbol für die Leistung zurück
  String getPerformanceLevel(String language, String score) {
    double scorePercentage = double.tryParse(score) ?? 0;
    int scorePercentageWithoutDecimal = scorePercentage.toInt();

    if (scorePercentageWithoutDecimal >= 81) {
      return language == "de" ? "🔥" : "🔥";
    } else if (scorePercentageWithoutDecimal >= 61) {
      return language == "de" ? "🧠" : "🧠";
    } else if (scorePercentageWithoutDecimal >= 41) {
      return language == "de" ? "🌱" : "🌱";
    } else {
      return language == "de" ? "🐣" : "🐣";
    }
  }

  // Diese Methode erstellt die aggregierten Daten für das Balkendiagramm
  List<PieChartSectionData> _createAggregatedChartData(
      List<LearnStats> stats,
      List<String> moduleNames,
      List<int> moduleIds,
      List<String> badgeSymbols) {
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

      moduleNames.add(moduleName);
      moduleIds.add(moduleStats.first.moduleId);

      badgeSymbols
          .add(getPerformanceLevel(widget.language, averageScore.toString()));

      return PieChartSectionData(
        value: averageScore,
        title: '',
        color: Colors.primaries[
            moduleNames.indexOf(moduleName) % Colors.primaries.length],
        radius: 60,
        badgeWidget: Text(
          badgeSymbols.last,
          style: const TextStyle(fontSize: 30, color: Colors.white),
        ),
      );
    }).toList();
  }


  // Diese Methode wird aufgerufen, wenn auf ein Element in der BottomNavigationBar getippt wird
  void _onBottomNavTapped(int index) {
    if (index == 0) {
      // Navigiere zur ModulPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ModulPage(language: widget.language),
        ),
      );
    } else {
      // Bleibe auf der Statistik-Seite
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildBadgeCard({
    required String badgeIcon,
    required String badgeTitle,
    required String badgeDescription,
    required Color badgeColor,
  }) {
    return Card(
      color: badgeColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Text(
          badgeIcon,
          style: const TextStyle(fontSize: 30),
        ),
        title: Text(
          badgeTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          badgeDescription,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

   // Diese Methode zeigt ein Dialogfeld mit Informationen zu den Abzeichen an
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              style: const TextStyle(
                  fontSize: 30, color: const Color.fromRGBO(69, 39, 160, 1)),
              widget.language == 'de'
                  ? 'Abzeichenerklärung'
                  : 'Badge Explanation'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildBadgeCard(
                  badgeIcon: '🔥',
                  badgeTitle:
                      widget.language == 'de' ? 'Wissensmeister' : 'Expert',
                  badgeDescription: widget.language == 'de'
                      ? 'Du hast außergewöhnliches Wissen.'
                      : 'You have exceptional knowledge.',
                  badgeColor: Colors.orange.shade500,
                ),
                _buildBadgeCard(
                  badgeIcon: '🧠',
                  badgeTitle:
                      widget.language == 'de' ? 'Wissenssammler' : 'Good',
                  badgeDescription: widget.language == 'de'
                      ? 'Du hast sehr gutes Wissen.'
                      : 'You have very good knowledge.',
                  badgeColor: Colors.blue.shade700,
                ),
                _buildBadgeCard(
                  badgeIcon: '🌱',
                  badgeTitle: widget.language == 'de'
                      ? 'Fortschreitender Lernender'
                      : 'You can do better',
                  badgeDescription: widget.language == 'de'
                      ? 'Du machst Fortschritte, aber es gibt noch Raum zur Verbesserung.'
                      : 'You are making progress, but there\'s room to improve.',
                  badgeColor: Colors.green.shade700,
                ),
                _buildBadgeCard(
                  badgeIcon: '🐣',
                  badgeTitle: widget.language == 'de' ? 'Neuling' : 'Newbie',
                  badgeDescription: widget.language == 'de'
                      ? 'Du bist am Anfang deiner Lernreise.'
                      : 'You are just beginning your learning journey.',
                  badgeColor: Colors.yellow.shade600,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                  style: const TextStyle(
                      fontSize: 15,
                      color: const Color.fromRGBO(69, 39, 160, 1)),
                  widget.language == 'de' ? 'Schließen' : 'Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
        title: Text(
          widget.language == 'de' ? 'Gesamtstatistiken' : 'Overall Statistics',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 30),
            onPressed: _showInfoDialog,
          ),
        ],
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/nichts_da.png', // Pfad zum Bild, das angezeigt wird, wenn keine Daten vorhanden sind
                    width: 200,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      widget.language == 'de'
                          ? 'Keine Statistiken gefunden.'
                          : 'No statistics found.',
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

          stats = snapshot.data!;
          List<String> moduleNames = [];
          List<int> moduleIds = [];
          List<String> badgeSymbols = [];
          var chartData = _createAggregatedChartData(
              stats, moduleNames, moduleIds, badgeSymbols);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.language == 'de'
                        ? 'Tippen Sie auf ein Diagrammsegment, um Details zu sehen.'
                        : 'Tap on a chart section to view detailed statistics.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        BarChart(
                          BarChartData(
                            barGroups: chartData
                                .map((PieChartSectionData sectionData) {
                              final index = chartData.indexOf(sectionData);
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: sectionData.value!,
                                    color: sectionData.color,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                                showingTooltipIndicators:
                                    selectedBarIndex == index ? [0] : [],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 20,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 8,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final badgeSymbol = badgeSymbols[groupIndex];
                                  final moduleStats = stats
                                      .where((stat) =>
                                          stat.moduleId ==
                                          moduleIds[groupIndex])
                                      .toList();
                                  double averageScore = moduleStats.fold<
                                              double>(
                                          0,
                                          (sum, stat) =>
                                              sum +
                                              (double.tryParse(stat.score) ??
                                                  0)) /
                                      moduleStats.length;
                                  String averageText = widget.language == 'de'
                                      ? 'Durchschnitt'
                                      : 'Average';
                                  String roundsText = widget.language == 'de'
                                      ? 'Runden'
                                      : 'Rounds';

                                  return BarTooltipItem(
                                    "$badgeSymbol\n$averageText: ${averageScore.toStringAsFixed(0)}\n"
                                    "$roundsText: ${moduleStats.length}",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipBorder: const BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              touchCallback: (FlTouchEvent event,
                                  BarTouchResponse? response) {
                                if (response?.spot != null) {
                                  final touchedIndex =
                                      response!.spot!.touchedBarGroupIndex;

                                  // Toggle selection logic
                                  setState(() {
                                    if (selectedBarIndex == touchedIndex) {
                                      selectedBarIndex =
                                          null; // Deselect if already selected
                                    } else {
                                      selectedBarIndex =
                                          touchedIndex; // Select new bar
                                    }
                                  });
                                }
                              },
                            ),
                            maxY: 100,
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Modul-Liste
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: moduleNames.length,
                    itemBuilder: (context, index) {
                      final moduleName = moduleNames[index];
                      final color =
                          Colors.primaries[index % Colors.primaries.length];

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
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: widget.language == 'de' ? 'Startseite' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: widget.language == 'de' ? 'Statistik' : 'Statistics',
          ),
        ],
        selectedItemColor: const Color.fromRGBO(69, 39, 160, 1),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
