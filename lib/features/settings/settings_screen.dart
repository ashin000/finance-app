import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../auth/auth_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Appearance"),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Dark Mode"),
                    subtitle: const Text("Use dark theme across the app"),
                    value: settings.isDarkMode,
                    activeColor: AppTheme.primaryLight,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).toggleDarkMode(val);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text("Language"),
                    subtitle: const Text("Change app display language"),
                    trailing: DropdownButton<String>(
                      value: settings.language,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text("English")),
                        DropdownMenuItem(value: 'hi', child: Text("Hindi")),
                        DropdownMenuItem(value: 'kn', child: Text("Kannada")),
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
            _buildSectionHeader("Voice Announcements"),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Enable Voice Alerts"),
                    subtitle: const Text("Announce transactions as they occur"),
                    value: settings.enableVoiceAlerts,
                    activeColor: AppTheme.primaryLight,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setVoiceAlerts(val);
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Speech Speed", style: TextStyle(fontSize: 14)),
                            Text("${settings.ttsSpeed.toStringAsFixed(1)}x", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: settings.ttsSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          activeColor: AppTheme.primaryLight,
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
            _buildSectionHeader("Security & Privacy"),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text("Biometric Lock"),
                    subtitle: const Text("Secure app with Fingerprint/FaceID"),
                    trailing: Switch(
                      value: settings.useBiometrics,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).setBiometrics(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Account"),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                },
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "PayVoice AI v1.0.0",
                style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondaryLight,
        letterSpacing: 1.1,
      ),
    );
  }
}
