//import 'dart:ffi';

import 'package:multiple_choice_trainer/models/learn_stats.dart';
import 'package:multiple_choice_trainer/models/module.dart';
import 'package:multiple_choice_trainer/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flash_card.dart';
import 'package:tuple/tuple.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class SupabaseService {
  // It's better to move the URL and Key to environment variables or configuration files
  final SupabaseClient _client = SupabaseClient(
      'https://uwroitbsjaodqvsdvdzr.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3cm9pdGJzamFvZHF2c2R2ZHpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE2NjQzNTgsImV4cCI6MjA0NzI0MDM1OH0.w2jhIgH38MuY2t8Jkl0nWs1KtDfELaNblHh-gPF6Zvc');

  // getting the flashcards ID for the user and filtering the flashcards that have been answered correctly less than 6 times
  Future<List<Map<String, dynamic>>> getFlashcardsForUser(
      String moduleId) async {
    final response = await _client
        .from('flashcards') // Direkt die 'flashcards'-Tabelle abfragen
        .select('id') // Nur die IDs der Flashcards auswählen
        .eq('module_id', moduleId); // Filtert nach dem angegebenen module_id

    List<Map<String, dynamic>> flashcards = [];
    for (var row in response) {
      flashcards.add(row);
    }

    //  print(flashcards);
    return flashcards;
  }

  // Fetching the flashcards from the database

//use module Id to get the flashcards that belong to the module
  Future<List<Flashcard>> getFlashcards(
      String userId, String moduleId, String language) async {
    try {
      // Schritt 1: Hole alle Flashcards aus der 'flashcards' Tabelle für das gegebene Modul
      final response = await _client
          .from('flashcards')
          .select()
          .eq('language',
              language) // Nur Flashcards für die spezifische Sprache
          .eq('module_id', moduleId); // Alle Flashcards für das Modul holen
      //print(language);

      if (response == null || response.isEmpty) {
        throw Exception('Keine Flashcards gefunden.');
      }

      // Schritt 2: Hole alle Flashcards aus der 'flashcard_stats' Tabelle, die für den Benutzer
      // und das Modul existieren und die korrekt beantwortet wurden
      final flashcardStatsResponse = await _client
          .from('flashcard_stats')
          .select('flashcard_id')
          .eq('user_id', userId) // Nur Flashcards für den spezifischen Benutzer
          .eq('module_id', moduleId) // Nur Flashcards für das spezifische Modul
          .eq('correct_count',
              6); // Flashcards, die 6 Mal korrekt beantwortet wurden

      // Schritt 3: Hole alle Flashcard IDs, die bereits 6 Mal korrekt beantwortet wurden
      Set<int> answeredFlashcardsIds = <int>{};
      for (var row in flashcardStatsResponse) {
        answeredFlashcardsIds.add(row['flashcard_id']);
      }

      // Schritt 4: Filtere die Flashcards aus der 'flashcards' Tabelle, um nur die anzuzeigen,
      // die nicht 6 Mal korrekt beantwortet wurden.
      List<dynamic> flashcardJsonList = response;

      List<Flashcard> flashcards = flashcardJsonList
          .where((flashcardJson) {
            final flashcardId = flashcardJson['id'];
            // Nur Flashcards, die nicht 6 Mal korrekt beantwortet wurden, behalten
            return !answeredFlashcardsIds.contains(flashcardId);
          })
          .map((flashcardJson) =>
              Flashcard.fromJson(flashcardJson as Map<String, dynamic>))
          .toList();

      // Rückgabe der gefilterten Flashcards
      return flashcards;
    } catch (e) {
      throw Exception('Fehler beim Abrufen der Flashcards: $e');
    }
  }

  //get Modules and convert them to a list of Module objects using the fromJson method
  Future<List<Module>> getModules() async {
    final response = await _client.from('modules').select();
    List<dynamic> moduleJsonList = response;
    List<Module> modules = moduleJsonList
        .map(
            (moduleJson) => Module.fromJson(moduleJson as Map<String, dynamic>))
        .toList();
    return modules;
  }

  //update the flashcard stats after the user answers a flashcard
  Future<void> updateFlashcardStats(
      String userId, String flashcardId, bool isCorrect, String module) async {
    print(flashcardId);
    print(userId);
    try {
      // Step 1: Reference the flashcard stats table
      final response = await _client
          .from('flashcard_stats')
          .select()
          .eq('user_id', userId)
          .eq('flashcard_id', flashcardId);
      print(response);
      if (response.isEmpty) {
        // Step 2: If the user has not answered the flashcard before, insert a new record
        await _client.from('flashcard_stats').insert([
          {
            'user_id': userId,
            'flashcard_id': flashcardId,
            'module_id': module, // Adding module_id to the table
            'correct_count': isCorrect ? 1 : 0,
            'total_attempts': 1,
            // First attempt
          }
        ]);
      } else {
        // Step 3: If the user has answered the flashcard before, update the record
        final flashcardStats = response[0];

        // Handle null values by using default values (0) if the count is null
        final correctCount =
            flashcardStats['correct_count'] ?? 0; // If null, default to 0
        final totalAttempts =
            flashcardStats['total_attempts'] ?? 0; // If null, default to 0

        // Step 4: Update the correct count and total attempts, regardless of correctness
        if (isCorrect) {
          await _client
              .from('flashcard_stats')
              .update({
                'correct_count': correctCount + 1,
                'total_attempts': totalAttempts + 1, // Increment total attempts
              })
              .eq('user_id', userId)
              .eq('flashcard_id', flashcardId)
              .eq('module_id', module); // Ensure the correct module is used
        } else {
          await _client
              .from('flashcard_stats')
              .update({
                'total_attempts': totalAttempts +
                    1, // Increment total attempts even if incorrect
              })
              .eq('user_id', userId)
              .eq('flashcard_id', flashcardId)
              .eq('module_id', module); // Ensure the correct module is used
        }
        print("I was hier");
      }
    } catch (e) {
      throw Exception('Error updating flashcard stats: $e');
    }
  }
//include tje learn round in the  LearnRound table for a specific user

  Future<void> includeLearnRound(
      String userId,
      String moduleId,
      String moduleName,
      String score,
      int correctCount,
      String duration) async {
    try {
      // Step 1: Insert a new record into the 'learn_rounds' table
      await _client.from('learnround_stats').insert([
        {
          'user_id': userId,
          'module_id': moduleId,
          'moduleName': moduleName,
          'score': score,
          'correct_count': correctCount,
          'duration': duration,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
    } catch (e) {
      throw Exception('Error including learn round: $e');
    }
  }

  //delete the learn round stats for a specific user and module
  Future<void> deleteLearnRoundStats(String userId, int moduleId) async {
    try {
      // Step 1: Delete all learn rounds for the user and module
      await _client
          .from('learnround_stats')
          .delete()
          .eq('user_id', userId)
          .eq('module_id', moduleId.toString());
    } catch (e) {
      throw Exception('Error deleting learn round stats: $e');
    }
  }

  //delete the flashcard stats for a specific user and flashcard
  Future<void> deleteFlashcardStats(String userId, int moduleId) async {
    try {
      // Step 1: Delete all flashcard stats for the user and module
      await _client
          .from('flashcard_stats')
          .delete()
          .eq('user_id', userId)
          .eq('module_id', moduleId);
      print("I was hier");
      print(userId);
      print(moduleId);
    } catch (e) {
      throw Exception('Error deleting flashcard stats: $e');
    }
  }

//get lernstats for the user for a specific module
  Future<List<Map<String, dynamic>>> getLearnStats(
      String userId, String moduleId) async {
    try {
      // Step 1: Get all learn rounds for the user and module
      final response = await _client
          .from('learnround_stats')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId);

      if (response.isEmpty) {
        throw Exception('No learn rounds found.');
      }

      // Step 2: Return the learn rounds
      return response;
    } catch (e) {
      throw Exception('Error getting learn stats: $e');
    }
  }

//get the learn stats for the user for all modules and convert them to a list of LearnStats objects
  Future<List<LearnStats>> getLearnStatsForUser(String userId) async {
    try {
      // Step 1: Check if the user_id exists in the table
      final userExists = await _client
          .from('learnround_stats')
          .select('user_id')
          .eq('user_id', userId)
          .limit(1);

      if (userExists == null || userExists.isEmpty) {
        // If user_id does not exist, return an empty list
        return [];
      }

      // Step 2: Get all learn rounds for the user
      final response =
          await _client.from('learnround_stats').select().eq('user_id', userId);

      if (response.isEmpty) {
        // If no learn rounds are found, return an empty list
        return [];
      }

      List<dynamic> learnStatsJsonList = response;

      // Step 3: Convert the response to a list of LearnStats objects
      List<LearnStats> learnStats = learnStatsJsonList
          .map((learnRoundJson) =>
              LearnStats.fromJson(learnRoundJson as Map<String, dynamic>))
          .toList();

      // Debugging: Print the stats
      print(learnStats);

      // Step 4: Return the learn stats
      return learnStats;
    } catch (e) {
      // Handle any unexpected errors
      throw Exception('Error getting learn stats for user: $e');
    }
  }

  //a method to get the name of a module using the module id
  Future<String> getModuleName(String moduleId) async {
    try {
      // Step 1: Get the module name for the given module ID
      final response = await _client
          .from('modules')
          .select('moduleName')
          .eq('module_id', moduleId)
          .limit(1);

      if (response.isEmpty) {
        throw Exception('No module found.');
      }

      // Step 2: Return the module name
      return response[0]['moduleName'];
    } catch (e) {
      throw Exception('Error getting module name: $e');
    }
  }
//get the user details for a specific user ID and convert them to a UserRepresenter object
  Future<UserRepresenter> getCurrentUserRepresentation(String userId) async {
    try {
      // Step 1: Get the user details for the given user ID
      final response =
          await _client.from('users').select().eq('userIds', userId).limit(1);
      print(response);

      if (response.isEmpty) {
        throw Exception('No user found.');
      }

      // Step 2: Return the user details
      return UserRepresenter.fromJson(response[0]);
    } catch (e) {
      throw Exception('Error getting user details: $e');
    }
  }

  Future<void> insertUser(String userId, String email) async {
// first check if the user exists
    try {
      final userExists = await _client
          .from('users')
          .select('userIds')
          .eq('userIds', userId)
          .limit(1);

      if (userExists == null || userExists.isEmpty) {
        // If user_id does not exist, insert a new record
        await _client.from('users').insert([
          {
            'userIds': userId,
            'email': email,
            'created_at': DateTime.now().toIso8601String(),
          }
        ]);
      }
    } catch (e) {
      throw Exception('Error inserting user: $e');
    }
  }

  Future<void> updateUserNickname(String userId, String nickname) async {
    try {
      // Step 1: Update the user's nickname
      await _client.from('users').update({
        'spritzenName': nickname,
      }).eq('userIds', userId);

      // Step 2: Print a success message
      print('User nickname updated successfully.');
    } catch (e) {
      throw Exception('Error updating user nickname: $e');
    }
  }

//if the user decides to import the modules, the module ids are stored in the user's record
  Future<void> updateUserImportedModulesId(
      String userId, List<int> importedModules) async {
    try {
      // Step 1: Update the user's imported modules
      await _client.from('users').update({
        'id_importedModules': importedModules,
      }).eq('userIds', userId);

      // Step 2: Print a success message
      print('User imported modules updated successfully.');
    } catch (e) {
      throw Exception('Error updating user imported modules: $e');
    }
  }

//Use the get Modules method to get the modules and then filter the modules that have been imported by the user

  Future<List<Module>> getUserModules(UserRepresenter user) async {
    List<int> importedModulesIds = user.importedModulesIds;
    List<Module> allModules = await getModules();
    List<Module> userModules = allModules
        .where((module) => importedModulesIds.contains(module.id))
        .toList(); // Filter the modules that have been imported by the user using the module ID list

    return userModules;
  }

// Methode zum Abrufen der allgemeinen Modulstatistiken für einen Benutzer
  Future<Map<String, Tuple2<double, int>>> getModuleStatsForUser(
      String userId, String moduleId) async {
    try {
      final response = await _client
          .from('learnround_stats')
          .select('module_id, score, correct_count')
          .eq('user_id', userId);

      if (response.error != null || response.data.isEmpty) {
        throw Exception('No data found.');
      }

      Map<String, List<Tuple2<double, int>>> scoresByModule = {};
      for (var round in response.data) {
        String moduleId = round['module_id'];
        double score = double.parse(round['score'].toString());
        int correctCount = int.parse(round['correct_count'].toString());
        scoresByModule
            .putIfAbsent(moduleId, () => [])
            .add(Tuple2(score, correctCount));
      }

      Map<String, Tuple2<double, int>> moduleStats = {};
      scoresByModule.forEach((moduleId, scores) {
        double averageScore =
            scores.map((e) => e.item1).reduce((a, b) => a + b) / scores.length;
        int totalCorrect = scores.map((e) => e.item2).reduce((a, b) => a + b);
        moduleStats[moduleId] = Tuple2(averageScore, totalCorrect);
      });

      return moduleStats;
    } catch (e) {
      print('Exception caught: $e');
      throw Exception('Error calculating module stats: $e');
    }
  }

 // Berechnet die allgemeinen Modulstatistiken für einen Benutzer
  Future<Map<String, dynamic>> calculateModuleStatistics(
      String userId, int moduleId) async {
    try {
      // Hole Daten für das spezifische Modul und Benutzer
      var response = await _client
          .from('learnround_stats')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId) // Filter nach moduleId
          .execute();

      if (response.status != 200 || response.data.isEmpty) {
        return {
          'averageScore': 0,
          'totalCorrect': 0,
          'roundsCount': 0,
        };
      }

      var data = response.data as List<dynamic>;
      double totalScore = 0;
      int totalCorrect = 0;
      int roundsCount = data.length;

      for (var round in data) {
        totalScore += double.parse(round['score'].toString());
        totalCorrect += int.parse(round['correct_count'].toString());
      }

      double averageScore = totalScore / roundsCount;

      return {
        'averageScore': averageScore,
        'totalCorrect': totalCorrect,
        'roundsCount': roundsCount,
      };
    } catch (e) {
      print('Exception caught: $e');
      return {
        'averageScore': 0,
        'totalCorrect': 0,
        'roundsCount': 0,
      };
    }
  }

// Holt die Lernstatistiken für ein Modul
  Future<List<LearnStats>> getLearnStatsForModule(
      String userId, String moduleId) async {
    try {
      // Führe die Anfrage aus und speichere das Ergebnis
      var moduleExistsResponse = await _client
          .from('learnround_stats')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .limit(1)
          .execute();

      // Überprüfe, ob die Anfrage erfolgreich war und Daten enthält
      if (moduleExistsResponse.status != 200 ||
          moduleExistsResponse.data.isEmpty) {
        // Wenn keine Daten gefunden oder ein Fehler aufgetreten ist, gib eine leere Liste zurück
        return [];
      }

      // Wenn Daten vorhanden sind, führe eine weitere Anfrage für detaillierte Statistiken aus
      var response = await _client
          .from('learnround_stats')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .execute();

      // Überprüfe auch hier, ob Daten vorhanden sind
      if (response.status != 200 || response.data.isEmpty) {
        return [];
      }

      // Verarbeite die Daten und erstelle eine Liste von LearnStats
      List<LearnStats> learnStats =
          (response.data as List<dynamic>).map<LearnStats>((learnRoundJson) {
        return LearnStats.fromJson(learnRoundJson);
      }).toList();

      return learnStats;
    } catch (e) {
      print('Exception caught: $e');
      throw Exception('Error fetching learn stats for module: $e');
    }
  }

  Future<void> updateUserAvatar(String userId, String avatarName) async {
    try {
      await _client.from('users').update({
        'avatar': avatarName, // Speichert den Bildnamen
      }).eq('userIds', userId);
      print('Avatar-Name erfolgreich gespeichert!');
    } catch (e) {
      throw Exception('Fehler beim Speichern des Avatars: $e');
    }
  }
}
