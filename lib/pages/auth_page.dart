import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Für RawKeyboardListener
import 'package:multiple_choice_trainer/pages/modulePage_list.dart';
import 'package:multiple_choice_trainer/services/auth_service.dart';
import '../services/service.dart';

import 'signup_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final supabase = SupabaseService();

  final FocusNode _keyboardFocusNode = FocusNode(); // Globaler Fokus für Enter-Taste
  bool _isPasswordVisible = false;
  String _currentLanguage = 'de';
  bool _emailFieldError = false;
  bool _passwordFieldError = false;
  bool _isEmailValid = true;
  bool _emailValidationTriggered = false;
  bool _isSubmitting = false;

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'title': 'Multiple Choice Trainer',
      'email': 'Email',
      'password': 'Password',
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'signUpMessage': "Don't have an account?",
      'invalidEmail': 'Please enter a valid email address',
      'emptyFieldError': 'Field cannot be empty',
      'invalidData': 'Invalid email or password',
      'welcomeBack': 'Welcome Back',
      'signInToAccount': 'Sign in to your account',
      'emailT' : 'Enter your email',
      'passwordT': 'Enter your password',
    },
    'de': {
      'title': 'Multiple Choice Trainer',
      'email': 'E-Mail',
      'password': 'Passwort',
      'signIn': 'Anmelden',
      'signUp': 'Registrieren',
      'signUpMessage': 'Noch kein Konto?',
      'invalidEmail': 'Bitte geben Sie eine gültige E-Mail-Adresse ein',
      'emptyFieldError': 'Feld darf nicht leer sein',
      'invalidData': 'Ungültige E-Mail oder Passwort',
      'welcomeBack': 'Willkommen zurück',
      'signInToAccount': 'Melden Sie sich bei Ihrem Konto an',
      'emailT' : 'Geben Sie Ihre Emailadresse ein',
      'passwordT': 'Geben Sie Ihr Passwort ein',
    },
  };

  String getTranslation(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  void _validateFields() {
    setState(() {
      _emailFieldError = _emailController.text.isEmpty;
      _passwordFieldError = _passwordController.text.isEmpty;
    });
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
      if (_isEmailValid) {
        _emailFieldError = false; // Fehlerstatus zurücksetzen
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _passwordFieldError = value.isEmpty;
    });
  }

  void _triggerEmailValidation() {
    setState(() {
      _emailValidationTriggered = true;
      _isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text);
    });
  }

  Future<void> _handleSignIn() async {
    if (_isSubmitting) return; // Verhindert mehrfaches Auslösen der Anmeldung

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    _validateFields();
    if (email.isEmpty || password.isEmpty || !_isEmailValid) return;

    setState(() {
      _isSubmitting = true;
    });

    final success = await _authService.signIn(email, password);
    if (success) {
      supabase.insertUser(_authService.getCurrentUser()!.id, email);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ModulPage(language: _currentLanguage),
        ),
      );
    } else {
      // Zeigt eine Snackbar an, wenn die Anmeldung fehlschlägt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslation('invalidData')), // Fehlernachricht hier
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    // Fokus sofort auf den RawKeyboardListener setzen
    _keyboardFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.purple.shade50, // Hintergrundfarbe angepasst
      body: Column(
        children: [

          // Fester Bereich oben für Überschrift
          AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.school, color: Colors.white, size: 40),
                const SizedBox(width: 8),
                Text(
                  getTranslation('title'),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold ,   color: Colors.white),

                ),
              ],
            ),
            backgroundColor: Colors.deepPurple,
          ),


          const SizedBox(height: 80),

          // Flexibler Bereich für den Rest der Inhalte
          Expanded(
            child: RawKeyboardListener(
              focusNode: _keyboardFocusNode, // Globale Tastenerkennung
              onKey: (event) {
                if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  _handleSignIn(); // Anmelden bei Enter-Taste
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Willkommensnachricht
                      Text(
                        getTranslation('welcomeBack'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        getTranslation('signInToAccount'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Dynamische Breite der Eingabefelder
                      Container(
                        width: screenWidth > 500 ? 500 : screenWidth * 0.9,
                        child: Column(
                          children: [
                            // Emailfeld
                            TextField(
                              controller: _emailController,
                              onChanged: (value) {
                                _validateEmail(value);
                              },
                              onEditingComplete: () => _triggerEmailValidation(),
                              decoration: InputDecoration(
                                labelText: getTranslation('email'),
                                hintText: getTranslation('emailT'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                errorText: !_isEmailValid
                                    ? getTranslation('invalidEmail')
                                    : (_emailFieldError
                                    ? getTranslation('emptyFieldError')
                                    : null),
                                prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                                suffixIcon: _emailController.text.isNotEmpty
                                    ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.deepPurple),
                                  onPressed: () {
                                    setState(() {
                                      _emailController.clear();
                                      _validateEmail('');
                                    });
                                  },
                                )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Passwortfeld
                            TextField(
                              controller: _passwordController,
                              onChanged: (value) {
                                _validatePassword(value);
                              },
                              decoration: InputDecoration(
                                labelText: getTranslation('password'),
                                hintText: getTranslation('passwordT'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                errorText: _passwordFieldError
                                    ? getTranslation('emptyFieldError')
                                    : null,
                                prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0), // Abstand zum rechten Rand
                                      child: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.deepPurple,
                                        ),
                                        onPressed: _togglePasswordVisibility,
                                      ),
                                    ),
                                    if (_passwordController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.deepPurple),
                                        onPressed: () {
                                          setState(() {
                                            _passwordController.clear();
                                            _validatePassword('');
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                            ),
                            const SizedBox(height: 30),

                            // Anmelden Button (gleiche Breite)
                            SizedBox(
                              width: screenWidth > 500 ? 500 : screenWidth * 0.9,
                              child: ElevatedButton(
                                onPressed: _handleSignIn,
                                child: _isSubmitting
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  getTranslation('signIn'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Registrieren-Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            getTranslation('signUpMessage'),
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => const SignUpPage()),
                              );
                            },
                            child: Text(
                              getTranslation('signUp'),
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30), // Abstand zur Sprachwahl

                      // Sprachwahl nach unten verschieben
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _currentLanguage = 'de'),
                            child: Text(
                              'Deutsch',
                              style: TextStyle(
                                fontWeight: _currentLanguage == 'de'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _currentLanguage == 'de'
                                    ? Colors.deepPurple
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          const Text(' | ', style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () => setState(() => _currentLanguage = 'en'),
                            child: Text(
                              'English',
                              style: TextStyle(
                                fontWeight: _currentLanguage == 'en'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _currentLanguage == 'en'
                                    ? Colors.deepPurple
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
