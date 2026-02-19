import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/model_provider.dart';

void main() {
  runApp(const ProviderScope(child: SanchoApp()));
}

class SanchoApp extends ConsumerWidget {
  const SanchoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(autoLoadModelProvider);
    
    final settings = ref.watch(settingsProvider);
    
    final themeMode = settings.when(
      data: (s) => s.theme == 'light' ? ThemeMode.light : 
                    s.theme == 'dark' ? ThemeMode.dark : ThemeMode.system,
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );

    return MaterialApp(
      title: 'Sancho.AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: const ChatScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
