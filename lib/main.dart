
import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/pages/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url:
        'https://uwroitbsjaodqvsdvdzr.supabase.co', // Ersetze mit deiner Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3cm9pdGJzamFvZHF2c2R2ZHpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE2NjQzNTgsImV4cCI6MjA0NzI0MDM1OH0.w2jhIgH38MuY2t8Jkl0nWs1KtDfELaNblHh-gPF6Zvc', // Ersetze mit deinem API Key
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Name',
      theme: ThemeData(
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthPage(),
      //home: const HomeScreen(initialLanguage: 'de'), // Startseite
      debugShowCheckedModeBanner: false, // Entfernt das Debug-Banner
    );
  }
}
