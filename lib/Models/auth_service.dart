import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Email/Password Sign Up
  Future<User?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (displayName != null) {
      await credential.user?.updateDisplayName(displayName);
    }
    
    return credential.user;
  }

  // Email/Password Sign In
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print("Error loading .env file: $e");
      return null;
    }

    final clientID = dotenv.env['GOOGLE_CLIENTID'];
    if (clientID == null || clientID.isEmpty) {
      print("GOOGLE_CLIENTID not found in .env");
      return null;
    }

    final googleSignIn = GoogleSignIn.instance;
    try {
      await googleSignIn.initialize(
        serverClientId: clientID,
      );
    } catch (e) {
      print("Error initializing GoogleSignIn: $e");
      return null;
    }


    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error during Google authentication: $e");
      return null;
    }
  }

  // Helpers
  User? get currentUser => _auth.currentUser;
  Stream<User?> get onAuthStateChange => _auth.authStateChanges();

  // Password reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign Out
  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn.instance;
    
    await googleSignIn.signOut();  
    await FirebaseAuth.instance.signOut();
  }
}