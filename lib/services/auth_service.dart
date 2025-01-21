import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Sign up
  Future<bool> signUp(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        print('Sign-up successful! Check your email for verification.');
        return true; // Indicate success
      } else {
        print('Sign-up failed: No user returned.');
        return false; // Indicate failure
      }
    } catch (e) {
      print('Error during sign-up: $e');
      return false; // Indicate failure
    }
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null) {
        print('Sign-in successful!');
        return true; // Indicate success
      } else {
        print('Sign-in failed: No session found.');
        return false; // Indicate failure
      }
    } catch (e) {
      print('Error during sign-in: $e');
      return false; // Indicate failure
    }
  }

  // Sign out
  Future<bool> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      print('Sign-out successful!');
      return true; // Indicate success
    } catch (e) {
      print('Error during sign-out: $e');
      return false; // Indicate failure
    }
  }

  // Get current user
  User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }

  String getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser!.id;
  }

/*return the email of the current user*/
  String getCurrentUserEmail() {
    return Supabase.instance.client.auth.currentUser?.email ?? 'No email';
  }
}
