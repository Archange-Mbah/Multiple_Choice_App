import 'dart:math'; // To shuffle the list

import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/models/flash_card.dart';
import 'package:multiple_choice_trainer/pages/question_view.dart';

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

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.language; // Initialize language from constructor
  }

  void updateLanguage(String newLanguage) {
    setState(() {
      currentLanguage = newLanguage; // Update the current language
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentLanguage == 'de'
            ? widget.moduleName
            : 'Module: ${widget.englishName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              // Toggle language and update state
              updateLanguage(currentLanguage == 'de' ? 'en' : 'de');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Illustration (optional)
            Expanded(
              flex: 2,
              child: Center(
                child: Image.asset(
                  'assets/study.webp', // Path to the image
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Motivational Text
            Text(
              currentLanguage == "de"
                  ? "Bereit für deine Lernrunde?"
                  : "Ready for your Quiz?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              currentLanguage == "de"
                  ? "Wähle die Anzahl an Fragen aus und verbessere dein Wissen!"
                  : "Choose the number of questions and improve your knowledge!",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Question Count Selection
            Expanded(
              flex: 3,
              child: ListView(
                children: [
                  for (int count in [5, 10, 20]) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          int maxQuestions = widget.flashcards.length;
                          int selectedCount =
                              (count <= maxQuestions) ? count : maxQuestions;

                          // Shuffle the list
                          List<Flashcard> shuffledFlashcards =
                              List.from(widget.flashcards);
                          shuffledFlashcards.shuffle(Random());

                          // Select the first 'count' flashcards
                          List<Flashcard> selectedFlashcards =
                              shuffledFlashcards.take(selectedCount).toList();

                          // Navigate to the question view
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
                        icon: const Icon(Icons.quiz, size: 24),
                        label: Text(
                          currentLanguage == "de"
                              ? "$count Fragen"
                              : "$count Questions",
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
