import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_choice_trainer/models/learn_stats.dart';
import 'package:multiple_choice_trainer/models/module.dart';
import 'package:multiple_choice_trainer/models/user.dart';
import 'package:multiple_choice_trainer/services/service.dart';
import 'package:multiple_choice_trainer/models/flash_card.dart';

void main() {
  /*test('fetchFlashcards returns a list of flashcards and is not empty', () async {
    final supabaseService = SupabaseService();

    // Assuming that you have flashcards in your Supabase database
    final flashcards = await supabaseService.fetchFlashcards();

    // Print the results in the terminal
    print('Response data: '+  flashcards.toString());

    // Check that the list is not empty
    //expect(flashcards, isNotEmpty);

    // You can also check if it's a list of Flashcard objects
    expect(flashcards.first, isA<Flashcard>());
  });
*/
  /*test('updateFlashcardProgress updates the flashcard progress', () async {
    final supabaseService = SupabaseService();

    // Assuming that you have a user ID and flashcard ID
    const userId = 'f04d81c8-2475-4934-ba4c-f01eff88d2df';

    // Call the updateFlashcardProgress method
    await supabaseService.getFlashcardsForUser(userId);
  });
*/
 /* test('getFlashcardsDetailsForUser returns a list of flashcards and is not empty', () async {
    final supabaseService = SupabaseService();

    // Assuming that you have a user ID
    const userId = 'f04d81c8-2475-4934-ba4c-f01eff88d2df';

    // Call the getFlashcardsDetailsForUser method
    final flashcards = await supabaseService.getFlashcardsDetailsForUser(userId);

    // Print the results in the terminal
  

    // Check that the list is not empty
    expect(flashcards, isNotEmpty);

    // You can also check if it's a list of Flashcard objects
    expect(flashcards.first, isA<Map<String, dynamic>>());
  });
*/

test('getFlashcards for modules', () async{
final supabaseService = SupabaseService();
final List< dynamic> flashcards = await supabaseService.getFlashcardsForUser("0");

print(flashcards.first);
}
);
test('convertResponseToFlashcards converts the response to a list of Flashcard objects', () async {
    final supabaseService = SupabaseService();

    // Assuming that you have a list of maps

  
  final List<Flashcard> flashcards = await supabaseService.getFlashcards('f04d81c8-2475-4934-ba4c-f01eff88d2df',"1","de");

    // Print the results in the terminal
  
  print('Response data: ${flashcards.length}');

    expect(flashcards.last, isA<Flashcard>());
    expect(flashcards, isA<List<Flashcard>>());
    // Iterate through the response and convert it to a list of Flashcard objects
    //final flashcards = response.first.entries.map((e) => Flashcard.fromJson(e.value)).toList();


  });


  test("get all Modules", () async {
    final supabaseService = SupabaseService();
    final List<Module>modules = await supabaseService.getModules();
    print(modules[1].id);
    print(modules[1].name);
    print(modules[1].description);
    expect(modules[1].id, 1);
  });


  test("updateFlashcardStats", () async {
    final supabaseService = SupabaseService();
    await supabaseService.updateFlashcardStats('eaae1bef-44a0-43e8-a15c-c024874ed629','01',true,"0");
  });

  test("updateLearRound", () async {
    final supabaseService = SupabaseService();
    await supabaseService.includeLearnRound('eaae1bef-44a0-43e8-a15c-c024874ed629','1','Einführung in die IT-Sicherheit','1.2',4,'3');

  });

  test("getLearnallRoundstats for a User", () async {
    final supabaseService = SupabaseService();
    final List<LearnStats> learnRoundStats = await supabaseService.getLearnStatsForUser('eaae1bef-44a0-43e8-a15c-c024874ed629');
    print(learnRoundStats);
  });


 test("get the name of a Module using the moduleId",() async{
    final supabaseService = SupabaseService();
    final String moduleName = await supabaseService.getModuleName('1');
    print(moduleName);  
 });

 test("get currentUser", () async{
  final supabaseService= SupabaseService();
  final UserRepresenter userd= await supabaseService.getCurrentUserRepresentation('f7b7b633-1eba-467a-9b37-0f8bfd946fa0');
  print(userd.importedModulesIds);
 });



test("insert new User", () async{
  final supabaseService= SupabaseService();
  await supabaseService.insertUser('eaae1bef-44a0-43e8-a15c-c024874ed629', 'mbaharchange@yahoo.com');
});
test("update UserNickname", () async{
  final supabaseService= SupabaseService();
  await supabaseService.updateUserNickname('eaae1bef-44a0-43e8-a15c-c024874ed629', 'le petit prince');
});
test("imported Modules", () async{
  final supabaseService= SupabaseService();
  await supabaseService.updateUserImportedModulesId('eaae1bef-44a0-43e8-a15c-c024874ed629',List<int>.from([1,2]));
});
test("delete Flashcard", () async{
  final supabaseService= SupabaseService();
  await supabaseService.deleteFlashcardStats('eaae1bef-44a0-43e8-a15c-c024874ed629',0);
});
test("delete moduleStats", () async{
  final supabaseService= SupabaseService();
  await supabaseService.deleteLearnRoundStats('eaae1bef-44a0-43e8-a15c-c024874ed629',1);
});
}