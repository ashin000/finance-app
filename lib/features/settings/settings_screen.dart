import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../auth/auth_provider.dart';
import '../../services/native/method_channel_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = ref.watch(localizationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final accentColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('settings')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Appearance"),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.translate('dark_mode')),
                    subtitle: const Text("Use dark theme across the app"),
                    value: settings.isDarkMode,
                    activeColor: accentColor,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).toggleDarkMode(val);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.translate('language')),
                    subtitle: const Text("Change app display language"),
                    trailing: DropdownButton<String>(
                      value: settings.language,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text("English")),
                        DropdownMenuItem(value: 'hi', child: Text("Hindi")),
                        DropdownMenuItem(value: 'kn', child: Text("Kannada")),
                        DropdownMenuItem(value: 'ta', child: Text("Tamil")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsProvider.notifier).setLanguage(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Voice Announcements"),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.translate('enable_voice_alerts')),
                    subtitle: const Text("Announce transactions as they occur"),
                    value: settings.enableVoiceAlerts,
                    activeColor: accentColor,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setVoiceAlerts(val);
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.translate('speech_speed'), style: const TextStyle(fontSize: 14)),
                            Text("${settings.ttsSpeed.toStringAsFixed(1)}x", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: settings.ttsSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          activeColor: accentColor,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).setTtsSpeed(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Security & Privacy"),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(l10n.translate('biometric_lock')),
                    subtitle: const Text("Secure app with Fingerprint/FaceID"),
                    trailing: Switch(
                      value: settings.useBiometrics,
                      activeColor: accentColor,
                      onChanged: (val) async {
                        if (val) {
                          final LocalAuthentication localAuth = LocalAuthentication();
                          final bool isSupported = await localAuth.isDeviceSupported();
                          final bool canCheck = await localAuth.canCheckBiometrics;
                          final List<BiometricType> enrolled = await localAuth.getAvailableBiometrics();

                          if (!isSupported) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Biometrics are not supported on this device."),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }

                          if (!canCheck || enrolled.isEmpty) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  title: Text("Register Biometrics", style: TextStyle(color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)),
                                  content: Text(
                                    "No fingerprints/face biometrics are enrolled on this phone. Would you like to open your phone security settings to register one now?",
                                    style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text("Cancel", style: TextStyle(color: Colors.redAccent)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(dialogCtx);
                                        await MethodChannelService.instance.openBiometricSettings();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text("Open Settings"),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return;
                          }

                          try {
                            final bool didAuthenticate = await localAuth.authenticate(
                              localizedReason: 'Please verify your identity to enable biometric lock',
                              options: const AuthenticationOptions(
                                stickyAuth: true,
                                biometricOnly: true,
                              ),
                            );
                            if (!didAuthenticate) return;
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Biometric verification failed: $e"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }
                        }
                        ref.read(settingsProvider.notifier).setBiometrics(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Account"),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: Text(l10n.translate('logout'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                },
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "PayVoice AI v1.0.0",
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: textSecondary,
        letterSpacing: 1.1,
      ),
    );
  }
}
