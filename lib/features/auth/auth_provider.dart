import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/database/database_service.dart';

class PayVoiceUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;

  PayVoiceUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.isAnonymous,
  });

  factory PayVoiceUser.fromFirebase(User user) {
    return PayVoiceUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayVoiceUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          isAnonymous == other.isAnonymous;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      isAnonymous.hashCode;
}

class AuthState {
  final PayVoiceUser? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    PayVoiceUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _fb = FirebaseService.instance;

  AuthNotifier() : super(AuthState(
          user: FirebaseService.instance.currentUser != null
              ? PayVoiceUser.fromFirebase(FirebaseService.instance.currentUser!)
              : null,
        )) {
    // If a user is already logged in on startup, open their box
    final currentFbUser = FirebaseService.instance.currentUser;
    if (currentFbUser != null) {
      DatabaseService.instance.openUserBox(currentFbUser.uid);
    }

    // Listen for auth changes
    _fb.authStateChanges().listen((user) async {
      if (user != null) {
        await DatabaseService.instance.openUserBox(user.uid);
      }
      state = AuthState(
        user: user != null ? PayVoiceUser.fromFirebase(user) : null,
        isLoading: false,
      );
    });
  }

  bool _isAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      final authErrorCodes = {
        'invalid-email',
        'user-disabled',
        'user-not-found',
        'wrong-password',
        'email-already-in-use',
        'invalid-credential',
        'account-exists-with-different-credential',
        'weak-password',
      };
      return authErrorCodes.contains(e.code);
    }
    return false;
  }

  Future<void> signInAnonymously() async {
    print("signInAnonymously called in AuthNotifier");
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      print("Calling Firebase signInAnonymously...");
      final cred = await _fb.signInAnonymously();
      print("Firebase signInAnonymously completed. User: ${cred?.user?.uid}");
      state = AuthState(
        user: cred?.user != null ? PayVoiceUser.fromFirebase(cred!.user!) : null,
        isLoading: false,
      );
    } catch (e) {
      print("Firebase signInAnonymously failed with error: $e");
      print("Using local guest fallback PayVoiceUser...");
      await DatabaseService.instance.openUserBox('mock_guest_user_id');
      state = AuthState(
        user: PayVoiceUser(
          uid: 'mock_guest_user_id',
          displayName: 'Guest User',
          email: 'guest@payvoice.local',
          photoUrl: null,
          isAnonymous: true,
        ),
        isLoading: false,
      );
      print("New state.user set: ${state.user?.uid}");
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cred = await _fb.signInWithGoogle();
      state = AuthState(
        user: cred?.user != null ? PayVoiceUser.fromFirebase(cred!.user!) : null,
        isLoading: false,
      );
    } catch (e) {
      print("Firebase Google Sign-in failed: $e. Falling back to mock user.");
      await DatabaseService.instance.openUserBox('mock_google_user');
      state = AuthState(
        user: PayVoiceUser(
          uid: 'mock_google_user',
          email: 'google@payvoice.local',
          displayName: 'Google User (Mock)',
          photoUrl: null,
          isAnonymous: false,
        ),
        isLoading: false,
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (!_fb.isInitialized) {
        throw FirebaseAuthException(code: 'network-request-failed', message: 'Firebase not initialized');
      }
      final cred = await _fb.signInWithEmail(email, password);
      if (cred == null) {
        throw FirebaseAuthException(code: 'network-request-failed', message: 'Firebase not initialized');
      }
      state = AuthState(
        user: cred.user != null ? PayVoiceUser.fromFirebase(cred.user!) : null,
        isLoading: false,
      );
    } catch (e) {
      if (_isAuthError(e)) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
        rethrow;
      }

      print("Firebase Email Sign-in failed: $e. Falling back to local offline user auth.");
      
      // Local authentication check
      final localUser = DatabaseService.instance.getLocalUser(email);
      if (localUser == null) {
        final errorMsg = "No account found with this email. Please register first.";
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        throw Exception(errorMsg);
      }
      
      final storedPassword = localUser['password'] as String?;
      if (storedPassword != password) {
        final errorMsg = "Incorrect password. Please try again.";
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        throw Exception(errorMsg);
      }
      
      final mockUid = localUser['uid'] as String? ?? 'mock_email_${email.split('@')[0]}';
      final displayName = localUser['name'] as String? ?? email.split('@')[0].toUpperCase();
      
      await DatabaseService.instance.openUserBox(mockUid);
      state = AuthState(
        user: PayVoiceUser(
          uid: mockUid,
          email: email,
          displayName: displayName,
          photoUrl: null,
          isAnonymous: false,
        ),
        isLoading: false,
      );
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (!_fb.isInitialized) {
        throw FirebaseAuthException(code: 'network-request-failed', message: 'Firebase not initialized');
      }
      final cred = await _fb.signUpWithEmail(email, password, name);
      if (cred == null) {
        throw FirebaseAuthException(code: 'network-request-failed', message: 'Firebase not initialized');
      }
      state = AuthState(
        user: cred.user != null ? PayVoiceUser.fromFirebase(cred.user!) : null,
        isLoading: false,
      );
    } catch (e) {
      if (_isAuthError(e)) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
        rethrow;
      }

      print("Firebase Email Sign-up failed: $e. Falling back to local offline user registry.");
      final mockUid = 'mock_email_${email.split('@')[0]}';
      
      // Local authentication check - check if already registered
      final existingUser = DatabaseService.instance.getLocalUser(email);
      if (existingUser != null) {
        final errorMsg = "Email is already registered. Please sign in.";
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        throw Exception(errorMsg);
      }
      
      // Register locally
      await DatabaseService.instance.registerLocalUser(email, password, name, mockUid);
      
      await DatabaseService.instance.openUserBox(mockUid);
      state = AuthState(
        user: PayVoiceUser(
          uid: mockUid,
          email: email,
          displayName: name.isNotEmpty ? name : email.split('@')[0].toUpperCase(),
          photoUrl: null,
          isAnonymous: false,
        ),
        isLoading: false,
      );
    }
  }

  Future<void> verifyPhoneNumber(String phone, Function(String verificationId) onCodeSent) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _fb.verifyPhoneNumber(
        phoneNumber: phone,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(isLoading: false);
          onCodeSent(verificationId);
        },
        onVerificationFailed: (e) {
          throw e;
        },
        onVerificationCompleted: (userCredential) {
          state = AuthState(
            user: userCredential.user != null ? PayVoiceUser.fromFirebase(userCredential.user!) : null,
            isLoading: false,
          );
        },
      );
    } catch (e) {
      print("Firebase Phone verification initiation failed: $e. Transitioning to mock verification.");
      state = state.copyWith(isLoading: false);
      // Call code sent with a mock verification ID
      onCodeSent("mock_verification_id");
    }
  }

  Future<void> signInWithPhoneNumber(String verificationId, String smsCode, String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (verificationId == "mock_verification_id") {
        throw Exception("Mock verification mode active");
      }
      final cred = await _fb.signInWithPhoneNumber(verificationId, smsCode);
      state = AuthState(
        user: cred?.user != null ? PayVoiceUser.fromFirebase(cred!.user!) : null,
        isLoading: false,
      );
    } catch (e) {
      print("Firebase Phone sign-in failed: $e. Falling back to mock user.");
      final mockUid = 'mock_phone_${phone.replaceAll('+', '')}';
      await DatabaseService.instance.openUserBox(mockUid);
      state = AuthState(
        user: PayVoiceUser(
          uid: mockUid,
          email: 'phone@payvoice.local',
          displayName: 'User $phone',
          photoUrl: null,
          isAnonymous: false,
        ),
        isLoading: false,
      );
    }
  }


  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _fb.signOut();
      await DatabaseService.instance.openUserBox('default');
      state = AuthState(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
