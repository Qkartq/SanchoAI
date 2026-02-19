import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_settings.dart';
import '../../data/datasources/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _service.saveSettings(settings);
    state = AsyncValue.data(settings);
  }

  Future<void> setModelPath(String path) async {
    final current = state.valueOrNull ?? AppSettings();
    await updateSettings(current..modelPath = path);
  }

  Future<void> setMmprojPath(String path) async {
    final current = state.valueOrNull ?? AppSettings();
    await updateSettings(current..mmprojPath = path);
  }

  Future<void> setSystemPrompt(String prompt) async {
    final current = state.valueOrNull ?? AppSettings();
    await updateSettings(current..systemPrompt = prompt);
  }

  Future<void> setTemperature(double temp) async {
    final current = state.valueOrNull ?? AppSettings();
    final clampedTemp = temp.clamp(0.1, 2.0);
    await updateSettings(current..temperature = clampedTemp);
  }

  Future<void> setMaxTokens(int tokens) async {
    final current = state.valueOrNull ?? AppSettings();
    await updateSettings(current..maxTokens = tokens);
  }

  Future<void> setContextWindow(int ctx) async {
    final current = state.valueOrNull ?? AppSettings();
    await updateSettings(current..contextWindow = ctx);
  }

  Future<void> setTheme(String theme) async {
    final current = state.valueOrNull ?? AppSettings();
    await updateSettings(current..theme = theme);
  }

  Future<void> setLanguage(String lang) async {
    final current = state.valueOrNull ?? AppSettings();
    await updateSettings(current..language = lang);
  }
}
