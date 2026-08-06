import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase/firebase_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
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

  AuthNotifier() : super(AuthState(user: FirebaseService.instance.currentUser)) {
    // Listen for auth changes
    _fb.authStateChanges().listen((user) {
      state = AuthState(user: user, isLoading: false);
    });
  }

  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cred = await _fb.signInAnonymously();
      state = AuthState(user: cred?.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cred = await _fb.signInWithGoogle();
      state = AuthState(user: cred?.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _fb.signOut();
      state = AuthState(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
