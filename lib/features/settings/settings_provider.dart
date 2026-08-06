import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isDarkMode;
  final String language;
  final bool enableVoiceAlerts;
  final double ttsSpeed;
  final bool useBiometrics;
  final Map<String, bool> enabledApps;

  SettingsState({
    required this.isDarkMode,
    required this.language,
    required this.enableVoiceAlerts,
    required this.ttsSpeed,
    required this.useBiometrics,
    required this.enabledApps,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? language,
    bool? enableVoiceAlerts,
    double? ttsSpeed,
    bool? useBiometrics,
    Map<String, bool>? enabledApps,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      enableVoiceAlerts: enableVoiceAlerts ?? this.enableVoiceAlerts,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      enabledApps: enabledApps ?? this.enabledApps,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const List<String> supportedPackages = [
    "com.google.android.apps.nbu.paisa.user",
    "com.phonepe.app",
    "net.one97.paytm",
    "in.org.npci.upiapp",
    "com.amazon.mShop.android.shopping",
    "co.cred.android",
    "com.sbi.upi",
    "com.snapwork.hdfc",
    "com.csg.icici",
    "com.axis.mobile",
    "com.msf.kbank.mobile",
    "com.canarabank.mobility",
    "com.indianbank.mobilebanking",
    "com.unionbank.corporate",
    "com.fedmobile"
  ];

  late SharedPreferences _prefs;

  SettingsNotifier()
      : super(SettingsState(
          isDarkMode: false,
          language: 'en',
          enableVoiceAlerts: true,
          ttsSpeed: 1.0,
          useBiometrics: false,
          enabledApps: {},
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    final appsMap = <String, bool>{};
    for (var pkg in supportedPackages) {
      appsMap[pkg] = _prefs.getBool('app_enabled_$pkg') ?? true;
    }

    state = SettingsState(
      isDarkMode: _prefs.getBool('is_dark_mode') ?? false,
      language: _prefs.getString('language') ?? 'en',
      enableVoiceAlerts: _prefs.getBool('enable_voice_alerts') ?? true,
      ttsSpeed: _prefs.getDouble('tts_speed') ?? 1.0,
      useBiometrics: _prefs.getBool('use_biometrics') ?? false,
      enabledApps: appsMap,
    );
  }

  Future<void> toggleDarkMode(bool value) async {
    await _prefs.setBool('is_dark_mode', value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> setLanguage(String value) async {
    await _prefs.setString('language', value);
    state = state.copyWith(language: value);
  }

  Future<void> setVoiceAlerts(bool value) async {
    await _prefs.setBool('enable_voice_alerts', value);
    state = state.copyWith(enableVoiceAlerts: value);
  }

  Future<void> setTtsSpeed(double value) async {
    await _prefs.setDouble('tts_speed', value);
    state = state.copyWith(ttsSpeed: value);
  }

  Future<void> setBiometrics(bool value) async {
    await _prefs.setBool('use_biometrics', value);
    state = state.copyWith(useBiometrics: value);
  }

  Future<void> toggleAppEnabled(String packageName, bool value) async {
    await _prefs.setBool('app_enabled_$packageName', value);
    final updatedApps = Map<String, bool>.from(state.enabledApps);
    updatedApps[packageName] = value;
    state = state.copyWith(enabledApps: updatedApps);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
