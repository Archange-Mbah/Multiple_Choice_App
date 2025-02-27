import 'dart:math'; // To shuffle the list
import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/flash_card.dart';
import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/pages/question_view.dart';

//Hier werden die Anzahl der Fragen für das Quiz festgelegt
class SetQuestion extends StatefulWidget {
  final String language; // Language passed via constructor
  final List<Flashcard> flashcards;
  final String moduleName; // Module name passed via constructor
  final String englishName; // English module name passed via constructor

  const SetQuestion({
    super.key,
    required this.flashcards,
    required this.language,
    required this.moduleName,
    required this.englishName,
  });

  @override
  _SetQuestionState createState() => _SetQuestionState();
}

class _SetQuestionState extends State<SetQuestion> {
  late String currentLanguage;
  int selectedCount = 5; // Standardmäßig 5 Fragen

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.language; // Initialize language from constructor
  }

  //Diese Funktion wird aufgerufen, wenn die Sprache geändert wird
  void updateLanguage(String newLanguage) {
    setState(() {
      currentLanguage = newLanguage; // Update the current language
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor:
            const Color.fromRGBO(69, 39, 160, 1), // Lila Hintergrund
        title: Text(
          currentLanguage == 'de' ? widget.moduleName : '${widget.englishName}',
          style: TextStyle(
              color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.deepPurple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentLanguage == "de"
                                  ? "Bereit für deine Lernrunde?"
                                  : "Ready for your Quiz?",
                              style: TextStyle(
                                fontSize: screenWidth * 0.045 > 22
                                    ? 22
                                    : screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromRGBO(69, 39, 160, 1),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentLanguage == "de"
                                  ? "Wähle die Anzahl an Fragen aus:"
                                  : "Choose the number of questions:",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04 > 18
                                    ? 18
                                    : screenWidth * 0.04,
                                color: const Color.fromRGBO(69, 39, 160, 1),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              constraints: BoxConstraints(
                                  maxWidth: screenWidth *
                                      0.5), // 50% der Bildschirmbreite
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color.fromRGBO(69, 39, 160, 1),
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButton<int>(
                                value: selectedCount,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                iconSize: 24,
                                elevation: 16,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: const Color.fromRGBO(69, 39, 160, 1),
                                ),
                                underline: const SizedBox(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    selectedCount = newValue ?? 5;
                                  });
                                },
                                items: <int>[5, 10, 15, 20]
                                    .map<DropdownMenuItem<int>>((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(
                                      currentLanguage == "de"
                                          ? "$value Fragen"
                                          : "$value Questions",
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 30.0),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromRGBO(69, 39, 160, 1),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth *
                                          0.03, // Reduziertes Padding
                                      vertical: screenHeight * 0.015,
                                    ),
                                    minimumSize: Size(screenWidth * 0.3,
                                        40), // Erhöhte minimale Breite
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    int maxQuestions = widget.flashcards.length;
                                    int count = (selectedCount <= maxQuestions)
                                        ? selectedCount
                                        : maxQuestions;

                                    List<Flashcard> shuffledFlashcards =
                                        List.from(widget.flashcards);
                                    shuffledFlashcards.shuffle(Random());

                                    List<Flashcard> selectedFlashcards =
                                        shuffledFlashcards.take(count).toList();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuestionView(
                                          flashcards: selectedFlashcards,
                                          language: currentLanguage,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow,
                                      color: Colors.white),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          currentLanguage == 'de'
                                              ? "Los "
                                              : "Get ",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          currentLanguage == 'de'
                                              ? "geht's"
                                              : "started",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Image.asset(
                            'assets/robot_set.png',
                            height: screenHeight * 0.20,
                            width: screenHeight * 0.20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.home, size: 30, color: Colors.grey),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModulPage(
                          language: currentLanguage,
                        ),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                Text(
                  currentLanguage == "de" ? "Startseite" : "Home",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
