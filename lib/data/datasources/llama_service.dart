import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import '../../domain/entities/model_state.dart';

class LlamaService {
  LlamaController? _controller;
  String _systemPrompt = 'You are a helpful AI assistant.';
  
  ModelState _state = const ModelState();
  final _stateController = StreamController<ModelState>.broadcast();
  
  Stream<ModelState> get stateStream => _stateController.stream;
  ModelState get currentState => _state;

  void setSystemPrompt(String prompt) {
    _systemPrompt = prompt;
  }

  void _updateState(ModelState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> initialize({
    required String modelPath,
    String? mmprojPath,
    int contextWindow = 2048,
    int nThreads = 4,
    String systemPrompt = 'You are a helpful AI assistant.',
  }) async {
    debugPrint('LlamaService: Starting initialization...');
    debugPrint('Model path: $modelPath');
    _systemPrompt = systemPrompt;
    _updateState(const ModelState(status: ModelStatus.loading));
    
    try {
      final modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        debugPrint('Model file not found!');
        _updateState(ModelState(
          status: ModelStatus.error,
          errorMessage: 'Model file not found: $modelPath',
        ));
        return;
      }
      
      debugPrint('Model file exists, creating controller...');
      _controller = LlamaController();
      
      bool hasMmproj = mmprojPath != null && mmprojPath.isNotEmpty;
      
      if (hasMmproj) {
        final mmprojFile = File(mmprojPath);
        if (!await mmprojFile.exists()) {
          debugPrint('Warning: mmproj file not found, disabling multimodal');
          hasMmproj = false;
        }
      }
      
      debugPrint('Loading model with $nThreads threads, context: $contextWindow');
      await _controller!.loadModel(
        modelPath: modelPath,
        threads: nThreads,
        contextSize: contextWindow,
      );
      
      debugPrint('Model loaded successfully! hasMultimodal: $hasMmproj');
      _updateState(ModelState(
        status: ModelStatus.ready,
        hasMultimodal: hasMmproj,
      ));
    } catch (e) {
      debugPrint('Error loading model: $e');
      _updateState(ModelState(
        status: ModelStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  String _buildPrompt(String message, List<Map<String, String>>? history) {
    final buffer = StringBuffer();
    
    buffer.writeln('<|system|>');
    buffer.writeln(_systemPrompt);
    buffer.writeln('</s>');
    buffer.writeln();
    
    if (history != null) {
      for (final msg in history) {
        final role = msg['role'] ?? 'user';
        final content = msg['content'] ?? '';
        if (content.isNotEmpty) {
          if (role == 'user') {
            buffer.writeln('<|user|>');
            buffer.writeln(content);
          } else if (role == 'assistant') {
            buffer.writeln('<|assistant|>');
            buffer.writeln(content);
            buffer.writeln('</s>');
          }
        }
      }
    }
    
    buffer.writeln('<|user|>');
    buffer.writeln(message);
    buffer.writeln('</s>');
    buffer.writeln('<|assistant|>');
    
    return buffer.toString();
  }

  String buildContinuePrompt(List<Map<String, String>>? history) {
    if (history == null || history.isEmpty) {
      return '';
    }
    
    final buffer = StringBuffer();
    
    buffer.writeln('<|system|>');
    buffer.writeln(_systemPrompt);
    buffer.writeln('</s>');
    buffer.writeln();
    
    for (final msg in history) {
      final role = msg['role'] ?? 'user';
      final content = msg['content'] ?? '';
      if (content.isNotEmpty) {
        if (role == 'user') {
          buffer.writeln('<|user|>');
          buffer.writeln(content);
        } else if (role == 'assistant') {
          buffer.writeln('<|assistant|>');
          buffer.writeln(content);
          buffer.writeln('</s>');
        }
      }
    }
    
    buffer.write('<|assistant|>');
    return buffer.toString();
  }

  Future<String> generate(String message, {List<Map<String, String>>? history, double? temperature, int? maxTokens}) async {
    if (_controller == null) {
      return 'Error: Model not loaded';
    }
    
    _updateState(_state.copyWith(status: ModelStatus.generating));
    
    try {
      final prompt = _buildPrompt(message, history);
      
      String result = '';
      
      await for (final token in _controller!.generate(
        prompt: prompt,
        temperature: temperature ?? 0.3,
        topP: 0.8,
        topK: 40,
        maxTokens: maxTokens ?? 512,
        repeatPenalty: 2.0,
        repeatLastN: 64,
      )) {
        result += token;
      }
      
      _updateState(_state.copyWith(status: ModelStatus.ready));
      return result.trim();
    } catch (e) {
      _updateState(_state.copyWith(status: ModelStatus.ready));
      return 'Error: $e';
    }
  }

  Stream<String> generateStream(String message, {List<Map<String, String>>? history, double? temperature, int? maxTokens}) async* {
    if (_controller == null) {
      yield 'Error: Model not loaded';
      return;
    }
    
    _updateState(_state.copyWith(status: ModelStatus.generating));
    
    try {
      final prompt = _buildPrompt(message, history);
      
      await for (final token in _controller!.generate(
        prompt: prompt,
        temperature: temperature ?? 0.3,
        topP: 0.8,
        topK: 40,
        maxTokens: maxTokens ?? 512,
        repeatPenalty: 2.0,
        repeatLastN: 64,
      )) {
        yield token;
      }
    } finally {
      _updateState(_state.copyWith(status: ModelStatus.ready));
    }
  }

  Stream<String> continueGeneration(List<Map<String, String>>? history, {double? temperature, int? maxTokens}) async* {
    if (_controller == null) {
      yield 'Error: Model not loaded';
      return;
    }
    
    _updateState(_state.copyWith(status: ModelStatus.generating));
    
    try {
      final prompt = buildContinuePrompt(history);
      if (prompt.isEmpty) {
        yield 'No conversation history';
        return;
      }
      
      await for (final token in _controller!.generate(
        prompt: prompt,
        temperature: temperature ?? 0.3,
        topP: 0.8,
        topK: 40,
        maxTokens: maxTokens ?? 512,
        repeatPenalty: 2.0,
        repeatLastN: 64,
      )) {
        yield token;
      }
    } finally {
      _updateState(_state.copyWith(status: ModelStatus.ready));
    }
  }

  Future<String> analyzeImage(String imagePath, String prompt) async {
    return 'Image analysis requires multimodal model. Please use a vision-enabled GGUF model.';
  }

  Future<void> stop() async {
    try {
      await _controller?.stop();
      _updateState(_state.copyWith(status: ModelStatus.ready));
    } catch (_) {}
  }

  Future<void> unload() async {
    try {
      await _controller?.dispose();
      _controller = null;
      _updateState(const ModelState(status: ModelStatus.idle));
    } catch (_) {}
  }

  void dispose() {
    _stateController.close();
    _controller?.dispose();
  }
}
