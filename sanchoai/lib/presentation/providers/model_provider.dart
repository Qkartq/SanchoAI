import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/model_state.dart';
import '../../data/datasources/llama_service.dart';
import 'settings_provider.dart';

final llamaServiceProvider = Provider<LlamaService>((ref) {
  final service = LlamaService();
  
  ref.listen(settingsProvider, (previous, next) {
    final settings = next.valueOrNull;
    if (settings != null && previous?.valueOrNull?.systemPrompt != settings.systemPrompt) {
      service.setSystemPrompt(settings.systemPrompt);
    }
  });
  
  ref.onDispose(() => service.dispose());
  return service;
});

final modelStateProvider = StateNotifierProvider<ModelStateNotifier, ModelState>((ref) {
  final service = ref.watch(llamaServiceProvider);
  return ModelStateNotifier(service);
});

class ModelStateNotifier extends StateNotifier<ModelState> {
  final LlamaService _service;
  StreamSubscription? _subscription;

  ModelStateNotifier(this._service) : super(const ModelState()) {
    _subscription = _service.stateStream.listen((newState) {
      state = newState;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final initializeModelProvider = Provider<Future<void> Function()>((ref) {
  final service = ref.watch(llamaServiceProvider);
  final settings = ref.watch(settingsProvider);
  
  return () async {
    final s = settings.valueOrNull;
    debugPrint('Initializing model with path: ${s?.modelPath}');
    if (s == null || s.modelPath.isEmpty) {
      debugPrint('No model path set');
      return;
    }
    
    await service.initialize(
      modelPath: s.modelPath,
      mmprojPath: s.mmprojPath.isNotEmpty ? s.mmprojPath : null,
      contextWindow: s.contextWindow,
      systemPrompt: s.systemPrompt,
    );
  };
});

final autoLoadModelProvider = Provider<void>((ref) {
  final settings = ref.watch(settingsProvider);
  settings.whenData((s) {
    if (s.modelPath.isNotEmpty) {
      Future.microtask(() {
        final init = ref.read(initializeModelProvider);
        init();
      });
    }
  });
});
