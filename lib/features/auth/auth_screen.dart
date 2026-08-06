import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  String _tempPhone = "";

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
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

  Future<void> _handleGoogleSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      _showError("Google Sign-In failed. Please try again.");
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInAnonymously();
    } catch (e) {
      _showError("Guest Login failed.");
    }
  }

  void _showPhoneLoginDialog() {
    setState(() {
      _isOtpSent = false;
      _phoneController.clear();
      _otpController.clear();
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              shape: Theme.of(context).cardTheme.shape,
              title: Text(
                _isOtpSent ? "Enter Verification Code" : "Phone Login",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isOtpSent) ...[
                    const Text(
                      "Enter your phone number to receive a verification OTP.",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "+1 123 456 7890",
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ] else ...[
                    Text(
                      "We sent a 6-digit OTP code to $_tempPhone.",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "6-digit OTP",
                        prefixIcon: Icon(Icons.lock_clock),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!_isOtpSent) {
                      if (_phoneController.text.trim().isEmpty) return;
                      setDialogState(() {
                        _tempPhone = _phoneController.text.trim();
                        _isOtpSent = true;
                      });
                      setState(() {
                        _isOtpSent = true;
                      });
                    } else {
                      // Perform mock/actual verification
                      Navigator.pop(context);
                      // Log in anonymously as a fallback if Firebase is not linked
                      ref.read(authProvider.notifier).signInAnonymously();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_isOtpSent ? "Verify" : "Send OTP"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFDBEAFE), // Light blue tint
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo / Visual
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryLight.withOpacity(0.15),
                        blurRadius: 32,
                        spreadRadius: 8,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_voice_rounded,
                    size: 80,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  "PayVoice AI",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "AI Financial Assistant & Real-time Voice Alerts",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryLight,
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
                      const Text(
                        "Sign In to Continue",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (state.isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        // Google Button
                        _AuthButton(
                          label: "Continue with Google",
                          icon: Icons.g_mobiledata_rounded,
                          color: Colors.white,
                          textColor: AppTheme.textPrimaryLight,
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          onPressed: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: 12),
                        
                        // Phone Button
                        _AuthButton(
                          label: "Login with Phone",
                          icon: Icons.phone_android_rounded,
                          color: AppTheme.primaryLight,
                          textColor: Colors.white,
                          onPressed: _showPhoneLoginDialog,
                        ),
                        const SizedBox(height: 12),
                        
                        // Guest/Anonymous Button
                        _AuthButton(
                          label: "Continue as Guest",
                          icon: Icons.person_outline_rounded,
                          color: Colors.transparent,
                          textColor: AppTheme.primaryLight,
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
