import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../models/transaction_model.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint("Firebase initialized successfully.");
    } catch (e) {
      debugPrint("Firebase initialization failed: $e. Operating in offline-only mode.");
      _isInitialized = false;
    }
  }

  // --- Auth Section ---
  User? get currentUser => _isInitialized ? auth.currentUser : null;

  Stream<User?> authStateChanges() {
    if (!_isInitialized) return Stream.value(null);
    return auth.authStateChanges();
  }

  Future<UserCredential?> signInAnonymously() async {
    if (!_isInitialized) return null;
    try {
      return await auth.signInAnonymously();
    } catch (e) {
      debugPrint("Anonymous Sign-in failed: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (!_isInitialized) return null;
    try {
      // Use the Web Client ID for Google Sign-In on Web
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '567192605663-rnk9ickstjoo42fd81fifvj8gjec60i2.apps.googleusercontent.com' : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      await _syncUserProfile(userCredential.user);
      return userCredential;
    } catch (e) {
      debugPrint("Google Sign-in failed: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized) return;
    await auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> _syncUserProfile(User? user) async {
    if (user == null || !_isInitialized) return;
    try {
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to sync user profile: $e");
    }
  }

  // --- Firestore Sync Section ---
  Future<void> syncTransactionToCloud(TransactionModel tx) async {
    final user = currentUser;
    if (user == null || !_isInitialized) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(tx.id)
          .set(tx.toFirestore());
    } catch (e) {
      debugPrint("Cloud sync failed for transaction ${tx.id}: $e");
      rethrow;
    }
  }

  Future<List<TransactionModel>> fetchTransactionsFromCloud() async {
    final user = currentUser;
    if (user == null || !_isInitialized) return [];

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return TransactionModel.fromFirestore(doc.id, doc.data());
      }).toList();
    } catch (e) {
      debugPrint("Failed to fetch cloud transactions: $e");
      return [];
    }
  }

  Future<void> syncBudgetsToCloud(String category, double limitAmount, String period) async {
    final user = currentUser;
    if (user == null || !_isInitialized) return;

    try {
      final budgetId = "${category}_$period";
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(budgetId)
          .set({
        'category': category,
        'limitAmount': limitAmount,
        'period': period,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Failed to sync budget: $e");
    }
  }

  Future<Map<String, double>> fetchBudgetsFromCloud(String period) async {
    final user = currentUser;
    if (user == null || !_isInitialized) return {};

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where('period', isEqualTo: period)
          .get();

      final Map<String, double> budgets = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        budgets[data['category'] as String] = (data['limitAmount'] as num).toDouble();
      }
      return budgets;
    } catch (e) {
      debugPrint("Failed to fetch budgets: $e");
      return {};
    }
  }
}
