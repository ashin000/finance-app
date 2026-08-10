import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/localization/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      _showError("Google Sign-In failed.");
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInAnonymously();
    } catch (e) {
      _showError("Guest Login failed.");
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter email/username and password.");
      return;
    }

    if (_isSignUp && name.isEmpty) {
      _showError("Please enter your name.");
      return;
    }

    try {
      if (_isSignUp) {
        await ref.read(authProvider.notifier).signUpWithEmail(email, password, name);
      } else {
        await ref.read(authProvider.notifier).signInWithEmail(email, password);
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      } else if (e is FirebaseAuthException) {
        msg = e.message ?? e.toString();
      }
      _showError(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final l10n = ref.watch(localizationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final accentColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFDBEAFE),
                    const Color(0xFFF8FAFC),
                    const Color(0xFFEFF6FF),
                  ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo / Visual
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 32,
                        spreadRadius: 8,
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.settings_voice_rounded,
                    size: 80,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  l10n.translate('app_title'),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "AI Financial Assistant & Real-time Voice Alerts",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),

                // Card Options
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration(context: context, opacity: 0.8),
                  child: Column(
                    children: [
                      Text(
                        l10n.translate('sign_in_continue'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (state.isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        if (_isSignUp) ...[
                          TextField(
                            controller: _nameController,
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              labelText: l10n.translate('name'),
                              prefixIcon: const Icon(Icons.person_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: l10n.translate('email'),
                            prefixIcon: const Icon(Icons.email_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: l10n.translate('password'),
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _handleEmailAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isSignUp ? l10n.translate('sign_up') : l10n.translate('sign_in'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up",
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(child: Divider(color: textSecondary.withOpacity(0.3))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text("OR", style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(child: Divider(color: textSecondary.withOpacity(0.3))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google Button
                        _AuthButton(
                          label: l10n.translate('continue_google'),
                          icon: Icons.g_mobiledata_rounded,
                          color: cardBg,
                          textColor: textPrimary,
                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          onPressed: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: 12),

                        // Guest/Anonymous Button
                        _AuthButton(
                          label: l10n.translate('continue_guest'),
                          icon: Icons.person_outline_rounded,
                          color: Colors.transparent,
                          textColor: accentColor,
                          onPressed: _handleAnonymousSignIn,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final BorderSide? borderSide;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    this.borderSide,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          side: borderSide ?? BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: color != Colors.transparent ? 1 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
