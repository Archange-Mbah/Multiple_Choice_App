import 'package:flutter/material.dart';
import 'package:multiple_choice_trainer/services/auth_service.dart';
import 'auth_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _emailFieldError = false;
  bool _passwordFieldError = false;
  bool _isGerman = true; // Sprachwahl
  bool _isTypingPassword =
      false; // Zeigt an, ob der Benutzer im Passwortfeld tippt

  // Status der Passwortanforderungen
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialCharacter = false;
  bool _hasMinLength = false;

  // Überprüfung der Passwortanforderungen
  void _validatePassword(String value) {
    setState(() {
      _isTypingPassword =
          true; // Anforderungen werden direkt angezeigt, sobald das Feld fokussiert ist
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialCharacter =
          value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>\[\]\\/\-_+=;~`]'));
      _hasMinLength = value.length >= 8;
    });
  }

  // Überprüfung des E-Mail-Formats
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  void _checkEmailField() {
    setState(() {
      _emailFieldError = _emailController.text.isEmpty ||
          !_validateEmail(_emailController.text);
    });
  }

  void _checkPasswordField() {
    setState(() {
      _passwordFieldError = _passwordController.text.isEmpty ||
          !_hasUppercase ||
          !_hasLowercase ||
          !_hasNumber ||
          !_hasSpecialCharacter ||
          !_hasMinLength;
    });
  }

  // Methode zur Registrierung
  Future<void> _handleSignUp() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    _checkEmailField();
    _checkPasswordField();

    if (_emailFieldError || _passwordFieldError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isGerman
                ? 'Bitte stellen Sie sicher, dass alle Felder korrekt ausgefüllt sind.'
                : 'Please make sure all fields are filled out correctly.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _authService.signUp(email, password);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isGerman
              ? 'Ein Bestätigungslink wurde an Ihre E-Mail-Adresse gesendet. Nach der Bestätigung können Sie sich mit Ihren Daten anmelden.'
              : 'A confirmation link has been sent to your email address. After confirming, you can log in with your credentials.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Umschalten der Passwortsichtbarkeit
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 238, 233, 244), // Background color
      body: Column(
        children: [
          // Fester Bereich oben für Überschrift
          AppBar(
            automaticallyImplyLeading:
                false, // Verhindert das Anzeigen des Zurückpfeils
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.school, color: Colors.white, size: 30),
                const SizedBox(width: 8),
                Text(
                  _isGerman
                      ? 'Multiple Choice Trainer'
                      : 'Multiple Choice Trainer',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color.fromRGBO(69, 39, 160, 1),
          ),

          const SizedBox(height: 80),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isGerman ? 'Legen Sie los' : 'Get started',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(69, 39, 160, 1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isGerman
                          ? 'Erstellen Sie ein neues Konto'
                          : 'Create a new account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: screenWidth > 500 ? 500 : screenWidth * 0.9,
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            onChanged: (value) => _checkEmailField(),
                            decoration: InputDecoration(
                              labelText: _isGerman ? 'E-Mail' : 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              errorText: _emailFieldError
                                  ? (_isGerman
                                      ? 'Bitte geben Sie eine gültige E-Mail ein'
                                      : 'Please enter a valid email')
                                  : null,
                              prefixIcon: const Icon(Icons.email,
                                  color: const Color.fromRGBO(69, 39, 160, 1)),
                              suffixIcon: _emailController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: const Color.fromRGBO(
                                              69, 39, 160, 1)),
                                      onPressed: () {
                                        setState(() {
                                          _emailController.clear();
                                          _checkEmailField();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) =>
                                _handleSignUp(), // Enter aktiviert Registrierung
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: _passwordController,
                            onChanged: (value) => _validatePassword(value),
                            decoration: InputDecoration(
                              labelText: _isGerman ? 'Passwort' : 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              errorText: _passwordFieldError
                                  ? (_isGerman
                                      ? 'Passwort erfüllt nicht die Anforderungen'
                                      : 'Password does not meet the requirements')
                                  : null,
                              prefixIcon: const Icon(Icons.lock,
                                  color: const Color.fromRGBO(69, 39, 160, 1)),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color:
                                          const Color.fromRGBO(69, 39, 160, 1),
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  ),
                                  if (_passwordController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: const Color.fromRGBO(
                                              69, 39, 160, 1)),
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
                            onTap: () => _validatePassword(_passwordController
                                .text), // Anforderungen erscheinen beim Klick
                            onSubmitted: (_) =>
                                _handleSignUp(), // Enter aktiviert Registrierung
                          ),
                          const SizedBox(height: 30),

                          if (_isTypingPassword)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRequirementItem(
                                    _isGerman
                                        ? 'Großbuchstabe'
                                        : 'Uppercase letter',
                                    _hasUppercase),
                                _buildRequirementItem(
                                    _isGerman
                                        ? 'Kleinbuchstabe'
                                        : 'Lowercase letter',
                                    _hasLowercase),
                                _buildRequirementItem(
                                    _isGerman ? 'Zahl' : 'Number', _hasNumber),
                                _buildRequirementItem(
                                    _isGerman
                                        ? 'Sonderzeichen (z. B. !?<>@#\$%)'
                                        : 'Special character (e.g. !?<>@#\$%)',
                                    _hasSpecialCharacter),
                                _buildRequirementItem(
                                    _isGerman
                                        ? 'Mindestens 8 Zeichen'
                                        : '8 characters or more',
                                    _hasMinLength),
                              ],
                            ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: screenWidth > 500 ? 500 : screenWidth * 0.9,
                            child: ElevatedButton(
                              onPressed: _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                backgroundColor:
                                    const Color.fromRGBO(69, 39, 160, 1),
                              ),
                              child: Text(
                                _isGerman ? 'Registrieren' : 'Sign Up',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isGerman
                                    ? 'Haben Sie ein Konto? '
                                    : 'Have an account? ',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 16),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => const AuthPage()),
                                  );
                                },
                                child: Text(
                                  _isGerman ? 'Anmelden' : ' Sign in',
                                  style: const TextStyle(
                                    color: const Color.fromRGBO(69, 39, 160, 1),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                              height: 30), // Abstand zu Sprachumschalter

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _isGerman = true),
                                child: Text(
                                  'Deutsch',
                                  style: TextStyle(
                                    fontWeight: _isGerman
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _isGerman
                                        ? const Color.fromRGBO(69, 39, 160, 1)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              const Text(' | ',
                                  style: TextStyle(color: Colors.grey)),
                              GestureDetector(
                                onTap: () => setState(() => _isGerman = false),
                                child: Text(
                                  'English',
                                  style: TextStyle(
                                    fontWeight: !_isGerman
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !_isGerman
                                        ? const Color.fromRGBO(69, 39, 160, 1)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
