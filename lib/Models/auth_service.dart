import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleSignInInitialized = false;

  // Initialize Google Sign-In once — call this in main.dart after Firebase.initializeApp()
  Future<void> initGoogleSignIn() async {
    if (_googleSignInInitialized) return;

    final clientID = dotenv.env['GOOGLE_CLIENTID'];
    if (clientID == null || clientID.isEmpty) {
      print("⚠️ GOOGLE_CLIENTID not found in .env");
      return;
    }

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: clientID,
      );
      _googleSignInInitialized = true;
      print("✅ GoogleSignIn initialized");
    } catch (e) {
      print("❌ Error initializing GoogleSignIn: $e");
    }
  }

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
    // Guard: make sure initialized
    if (!_googleSignInInitialized) {
      await initGoogleSignIn();
    }

    if (!_googleSignInInitialized) {
      print("❌ GoogleSignIn not initialized, aborting");
      return null;
    }

    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        print("⚠️ Google Sign-In cancelled by user");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("❌ Error during Google authentication: $e");
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
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}