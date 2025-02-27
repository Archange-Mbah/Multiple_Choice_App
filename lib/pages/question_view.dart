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
    widget.flashcards.forEach((flashcard) {
      flashcard.answers.shuffle(); // Antworten durcheinander bringen
    });
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
        widget.flashcards[currentFlashcardIndex].answers
            .shuffle(); // Antworten mischen
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

    if (scorePercentage >= 81) {
      imagePath = 'assets/happy_robot.png';
    } else if (scorePercentage >= 61) {
      imagePath = 'assets/neutral_robot.png';
    } else if (scorePercentage >= 41) {
      imagePath = 'assets/neutral_robot.png';
    } else {
      imagePath = 'assets/sad_robot.png';
    }

    String totalTime = _formatTime(_elapsedTime);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxHeight = constraints.maxHeight * 0.5; // max. 80% der Höhe
            double maxWidth = constraints.maxWidth * 0.6; // max. 90% der Breite

            return Container(
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Image.asset(
                      imagePath,
                      width: MediaQuery.of(context).size.width * 0.4,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    language == "de" ? "Quiz abgeschlossen" : "Quiz completed",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(69, 39, 160, 1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    language == "de"
                        ? "Du hast $correctQuestionsCount von $totalQuestions Fragen vollständig korrekt beantwortet."
                        : "You answered $correctQuestionsCount out of $totalQuestions questions correctly.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    language == "de"
                        ? "Deine Punktzahl: ${scorePercentage.toStringAsFixed(0)}%"
                        : "Your score: ${scorePercentage.toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    language == "de"
                        ? "Gesamtzeit: $totalTime"
                        : "Total time: $totalTime",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ModulPage(language: language),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          language == "de" ? "Beenden" : "End",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          language == "de" ? "Neue Runde" : "New Round",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
        backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
        title: Text(
          language == "de" ? "Lernmodus" : "Learning Mode",
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: LinearProgressIndicator(
                value: (currentFlashcardIndex + 1) / widget.flashcards.length,
                backgroundColor: Colors.purple.shade50,
                valueColor: AlwaysStoppedAnimation(
                    const Color.fromRGBO(69, 39, 160, 1)!),
              ),
            ),

            // Elapsed Time Display
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time,
                      color: const Color.fromRGBO(69, 39, 160, 1), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    language == "de"
                        ? "Verstrichene Zeit: ${_formatTime(_elapsedTime)}"
                        : "Elapsed Time: ${_formatTime(_elapsedTime)}",
                    style: const TextStyle(
                        fontSize: 16,
                        color: const Color.fromRGBO(69, 39, 160, 1),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Current Flashcard Index Display
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                language == "de"
                    ? "Frage ${currentFlashcardIndex + 1}/${widget.flashcards.length}"
                    : "Question ${currentFlashcardIndex + 1}/${widget.flashcards.length}",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(69, 39, 160, 1)),
              ),
            ),

            // Flashcard Question Text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                currentFlashcard.question,
                style: const TextStyle(
                    fontSize: 18,
                    color: const Color.fromRGBO(69, 39, 160, 1),
                    fontWeight: FontWeight.w500),
              ),
            ),

            // Answers List
            Expanded(
              child: Column(
                children: [
                  // Spacing für Flexibilität der Inhalte
                  for (var answer in currentFlashcard.answers)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: showFeedback
                              ? (answer.correct
                                  ? (selectedAnswerIds.contains(answer.id)
                                      ? Colors.green[100]
                                      : Colors.green[50])
                                  : (selectedAnswerIds.contains(answer.id)
                                      ? Colors.red[100]
                                      : Colors.white))
                              : (selectedAnswerIds.contains(answer.id)
                                  ? Colors.deepPurple.shade50
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          title: Text(
                            answer.answerText,
                            style: TextStyle(
                              fontSize: 16,
                              color: showFeedback
                                  ? (answer.correct ? Colors.green : Colors.red)
                                  : (selectedAnswerIds.contains(answer.id)
                                      ? Colors.deepPurple
                                      : Colors.black),
                            ),
                            textAlign:
                                TextAlign.left, // Text bleibt linksbündig
                          ),
                          trailing: showFeedback
                              ? (answer.correct
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : (selectedAnswerIds.contains(answer.id)
                                      ? const Icon(Icons.cancel,
                                          color: Colors.red)
                                      : null))
                              : null,
                          onTap: !showFeedback
                              ? () => toggleAnswerSelection(answer.id)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Action Button (Next or Check)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: !_timer.isActive
                      ? null
                      : selectedAnswerIds.isNotEmpty
                          ? (showFeedback ? goToNextQuestion : checkAnswers)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: language == "de"
                      ? Text(showFeedback ? "Weiter" : "Überprüfen",
                          style: const TextStyle(color: Colors.white))
                      : Text(showFeedback ? "Next" : "Check",
                          style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),

            // Pause/Play & Cancel Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tooltip(
                    message: _timer.isActive
                        ? 'Pausieren aktivieren'
                        : 'Pausieren deaktivieren',
                    child: IconButton(
                      icon: Icon(
                        _timer.isActive ? Icons.pause : Icons.play_arrow,
                        color: const Color.fromRGBO(69, 39, 160, 1),
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_timer.isActive) {
                            _timer.cancel();
                            _showTemporaryMessage(language == "de"
                                ? "Lernrunde pausiert"
                                : "Learning round paused");
                          } else {
                            _timer = Timer.periodic(const Duration(seconds: 1),
                                (timer) {
                              setState(() {
                                _elapsedTime++;
                              });
                            });
                            _showTemporaryMessage(language == "de"
                                ? "Lernrunde wird fortgesetzt"
                                : "Learning round resumed");
                          }
                        });
                      },
                    ),
                  ),
                  Tooltip(
                    message: language == "de" ? 'Abbrechen' : 'Cancel',
                    child: IconButton(
                      icon: Icon(
                        Icons.exit_to_app,
                        color: const Color.fromRGBO(69, 39, 160, 1),
                        size: 24,
                      ),
                      onPressed: () async {
                        bool wasPaused = !_timer.isActive;
                        if (_timer.isActive) {
                          _timer.cancel();
                        }

                        bool? confirmExit = await showDialog<bool>(
                          context: context,
                          barrierDismissible:
                              false, // Dialog nicht schließen durch Tippen außerhalb
                          builder: (BuildContext context) {
                            final mediaWidth =
                                MediaQuery.of(context).size.width;

                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    16), // Runde Ecken des Dialogs
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                width: mediaWidth *
                                    0.7, // 70% der Bildschirmbreite

                                decoration: BoxDecoration(
                                  color: Colors.grey
                                      .shade100, // Hintergrundfarbe des Dialogs
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26, // Schattenfarbe
                                      blurRadius: 10,
                                      offset: const Offset(2, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.deepPurple, // Iconfarbe
                                      size: mediaWidth *
                                          0.1, // 10% der Bildschirmbreite
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      language == "de"
                                          ? "Möchten Sie die Lernrunde wirklich abbrechen?"
                                          : "Do you really want to cancel the learning round?",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color.fromRGBO(
                                            69, 39, 160, 1),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Flexible(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              //backgroundColor: Colors.white,
                                              backgroundColor:
                                                  Colors.deepPurple.shade50,
                                              foregroundColor:
                                                  Colors.deepPurple,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: Text(
                                              language == "de" ? "Nein" : "No",
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors
                                                  .deepPurple, // Lila für "Ja"
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),

                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: Text(
                                              language == "de" ? "Ja" : "Yes",
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        if (confirmExit == true) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ModulPage(language: language),
                            ),
                            (route) => false,
                          );
                        } else {
                          if (!wasPaused) {
                            _timer = Timer.periodic(const Duration(seconds: 1),
                                (timer) {
                              setState(() {
                                _elapsedTime++;
                              });
                            });
                          }
                        }
                      },
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

// Funktion für temporäre Nachrichten
  void _showTemporaryMessage(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
