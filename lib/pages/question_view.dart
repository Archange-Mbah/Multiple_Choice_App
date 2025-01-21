import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/flash_card.dart';
import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/pages/set_question.dart';

import 'package:multiple_choice_trainer/services/auth_service.dart';
import 'package:multiple_choice_trainer/services/service.dart';

class QuestionView extends StatefulWidget {
  final List<Flashcard> flashcards;
  final String language; // Add language parameter

  QuestionView({required this.flashcards, required this.language});

  @override
  _QuestionViewState createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  int currentFlashcardIndex = 0;
  Set<int> selectedAnswerIds = {}; // IDs der ausgewählten Antworten
  bool showFeedback = false; // Steuert die Anzeige des Feedbacks
  int correctQuestionsCount = 0; // Anzahl korrekt beantworteter Fragen
  final supabaseService =
      SupabaseService(); // to make use of the methods in the service class
  final user = AuthService().getCurrentUser();
  late String language;

  // Timer-Variable und Zeitmesser
  late Timer _timer; // Timer
  int _elapsedTime = 0; // Zeit in Sekunden

  @override
  void initState() {
    super.initState();
    language = widget.language;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Timer stoppen
    super.dispose();
  }

  // Zeitformatierungsfunktion
  String _formatTime(int timeInSeconds) {
    int minutes = timeInSeconds ~/ 60;
    int seconds = timeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void toggleAnswerSelection(int answerId) {
    setState(() {
      if (selectedAnswerIds.contains(answerId)) {
        selectedAnswerIds.remove(answerId); // Antwort abwählen
      } else {
        selectedAnswerIds.add(answerId); // Antwort auswählen
      }
    });
  }

  void checkAnswers() {
    final currentFlashcard = widget.flashcards[currentFlashcardIndex];

    // Prüfen, ob ALLE richtigen Antworten ausgewählt sind und KEINE falschen Antworten gewählt wurden
    bool isCurrentQuestionCorrect = currentFlashcard.answers.every((answer) {
      if (answer.correct) {
        return selectedAnswerIds
            .contains(answer.id); // Alle richtigen Antworten gewählt?
      } else {
        return !selectedAnswerIds.contains(
            answer.id); // Prüfen, ob keine falschen Antworten gewählt wurden
      }
    });

    if (isCurrentQuestionCorrect) {
      correctQuestionsCount++; // Diese Frage ist korrekt beantwortet
      supabaseService.updateFlashcardStats(
        user?.id ?? 'f04d81c8-2475-4934-ba4c-f01eff88d2df',
        currentFlashcard.id.toString(),
        true,
        currentFlashcard.moduleId.toString(),
      );
      print("I was here 1");
    } else {
      supabaseService.updateFlashcardStats(
        user?.id ?? 'f04d81c8-2475-4934-ba4c-f01eff88d2df',
        currentFlashcard.id.toString(),
        false,
        currentFlashcard.moduleId.toString(),
      );
    }

    // Setzen von Feedback-Status
    setState(() {
      showFeedback =
          true; // Feedback anzeigen, bevor zur nächsten Frage gewechselt wird
    });
  }

  void goToNextQuestion() async {
    if (currentFlashcardIndex < widget.flashcards.length - 1) {
      setState(() {
        //checkAnswers(); // Antworten überprüfen
        //print("I was here");
        currentFlashcardIndex++; // Nächste Frage anzeigen
        selectedAnswerIds.clear(); // Auswahl zurücksetzen
        showFeedback = false; // Feedback deaktivieren
      });
    } else {
      showQuizResult(); // Quiz beendet, Ergebnis anzeigen
      String moduleName = await supabaseService
          .getModuleName(widget.flashcards[0].moduleId.toString());
      supabaseService.includeLearnRound(
        user?.id ?? 'f04d81c8-2475-4934-ba4c-f01eff88d2df',
        widget.flashcards[0].moduleId.toString(),
        moduleName,
        ((correctQuestionsCount / widget.flashcards.length) * 100).toString(),
        correctQuestionsCount,
        _elapsedTime.toString(),
      );
    }
  }

  void showQuizResult() {
    _timer.cancel(); // Timer stoppen, Lernrunde ist beendet
    String imagePath;

    int totalQuestions = widget.flashcards.length;
    double scorePercentage = (correctQuestionsCount / totalQuestions) * 100;

    String performanceLevel;
    if (scorePercentage >= 81) {
      performanceLevel = language == "de" ? "🔥 Wissensmeister" : "🔥expert";
      imagePath = 'assets/happy_robot.png';
    } else if (scorePercentage >= 61) {
      performanceLevel = language == "de" ? "🧠 Wissenssammler" : "🧠Goood";
      imagePath = 'assets/neutral_robot.png';
    } else if (scorePercentage >= 41) {
      performanceLevel = language == "de"
          ? "🌱 Fortschreitender Lernender"
          : "🌱you can do better";
      imagePath = 'assets/neutral_robot.png';
    } else {
      performanceLevel =
          language == "de" ? "🐣 Neuling" : "🐣you will do it next time";
      imagePath = 'assets/sad_robot.png';
    }

    String totalTime = _formatTime(_elapsedTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: language == "de"
            ? const Text("Quiz abgeschlossen", style: TextStyle(fontSize: 24))
            : const Text("Quiz completed", style: TextStyle(fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath, // Bild des Roboters basierend auf dem Ergebnis
              width: 150,
              height: 150,
            ),
            Text(
              language == "de"
                  ? "Du hast $correctQuestionsCount von $totalQuestions Fragen vollständig korrekt beantwortet."
                  : "You have answered $correctQuestionsCount out of $totalQuestions questions completely correctly.",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            language == "de"
                ? Text(
                    "Deine Punktzahl: ${scorePercentage.toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 18),
                  )
                : Text(
                    "Your score: ${scorePercentage.toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 18),
                  ),
            const SizedBox(height: 10),
            language == "de"
                ? Text(
                    "Rang: $performanceLevel",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  )
                : Text(
                    "Rank: $performanceLevel",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
            const SizedBox(height: 10),
            language == "de"
                ? Text(
                    "Gesamtzeit: $totalTime",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : Text(
                    "Total time: $totalTime",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModulPage(language: language),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: language == "de"
                      ? const Text("Beenden")
                      : const Text("End"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: language == "de"
                      ? const Text("Neue Runde")
                      : const Text("New Round"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFlashcard = widget.flashcards[currentFlashcardIndex];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: language == "de"
            ? const Text("Lernmodus")
            : const Text("Learning Mode"),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (currentFlashcardIndex + 1) / widget.flashcards.length,
            color: Colors.blue,
            backgroundColor: Colors.grey[300],
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer, // Timer-Icon
                  size: 20,
                ),
                const SizedBox(width: 8), // Abstand zwischen Icon und Text
                Text(
                  language == "de"
                      ? "Verstrichene Zeit: ${_formatTime(_elapsedTime)}"
                      : "Elapsed Time: ${_formatTime(_elapsedTime)}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              language == "de"
                  ? "Frage ${currentFlashcardIndex + 1}/${widget.flashcards.length}"
                  : "Question ${currentFlashcardIndex + 1}/${widget.flashcards.length}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              currentFlashcard.question,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: currentFlashcard.answers.length,
              itemBuilder: (context, index) {
                final answer = currentFlashcard.answers[index];
                final isSelected = selectedAnswerIds.contains(answer.id);
                final isCorrect = answer.correct;

                return Card(
                  color: showFeedback
                      ? (isCorrect
                          ? (isSelected ? Colors.green[100] : Colors.green[50])
                          : (isSelected ? Colors.red[100] : Colors.white))
                      : (isSelected ? Colors.blue[50] : Colors.white),
                  child: ListTile(
                    title: Text(
                      answer.answerText,
                      style: TextStyle(
                        color: showFeedback
                            ? (isCorrect ? Colors.green : Colors.red)
                            : (isSelected ? Colors.blue : Colors.black),
                      ),
                    ),
                    trailing: showFeedback
                        ? (isCorrect
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : (isSelected
                                ? const Icon(Icons.cancel, color: Colors.red)
                                : null))
                        : null,
                    onTap: !showFeedback
                        ? () => toggleAnswerSelection(answer.id)
                        : null,
                  ),
                );
              },
            ),
          ),
          // „Überprüfen“ / „Weiter“-Button direkt unter der Frage
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: !_timer.isActive
                    ? null
                    : selectedAnswerIds.isNotEmpty
                        ? (showFeedback ? goToNextQuestion : checkAnswers)
                        : null,
                child: language == "de"
                    ? Text(showFeedback ? "Weiter" : "Überprüfen")
                    : Text(showFeedback ? "Next" : "Check"),
              ),
            ),
          ),
          // Pausieren- und Abbrechen-Buttons unten
          Padding(
            padding: const EdgeInsets.all(16.0), // Abstand zum Rand
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Buttons nebeneinander
              children: [
                // Pausieren-Button mit Tooltip
                Tooltip(
                  message: _timer.isActive
                      ? 'Pausieren aktivieren'
                      : 'Pausieren deaktivieren',
                  child: IconButton(
                    icon:
                        Icon(_timer.isActive ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        if (_timer.isActive) {
                          _timer.cancel();
                        } else {
                          _timer = Timer.periodic(const Duration(seconds: 1),
                              (timer) {
                            setState(() {
                              _elapsedTime++;
                            });
                          });
                        }
                      });
                    },
                  ),
                ),
                // Abbrechen-Button mit Tooltip
                Tooltip(
                  message: language == "de" ? 'Abbrechen' : 'Cancel',
                  child: IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () async {
                      bool wasPaused = !_timer.isActive;
                      if (_timer.isActive) {
                        _timer.cancel();
                      }

                      bool? confirmExit = await showDialog<bool>(
                        context: context,
                        barrierDismissible:
                            false, // Verhindert das Schließen durch Tippen außerhalb des Dialogs
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: language == "de"
                                ? const Text("Lernrunde abbrechen")
                                : const Text("Cancel learning round"),
                            content: language == "de"
                                ? const Text(
                                    "Möchten Sie die Lernrunde wirklich abbrechen?")
                                : const Text(
                                    "Do you really want to cancel the learning round?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: language == "de"
                                    ? const Text("Nein")
                                    : const Text("No"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: language == "de"
                                    ? const Text("Ja")
                                    : const Text("Yes"),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmExit == null || confirmExit == false) {
                        if (!wasPaused) {
                          _timer = Timer.periodic(const Duration(seconds: 1),
                              (timer) {
                            setState(() {
                              _elapsedTime++;
                            });
                          });
                        }
                      } else {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => ModulPage(language: 'de'),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
