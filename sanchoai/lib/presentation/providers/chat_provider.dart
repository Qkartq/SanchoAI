import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'] ?? 'user',
    content: json['content'] ?? '',
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
  );
}

class ChatConversation {
  final String id;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatConversation({
    required this.id,
    required this.messages,
    required this.createdAt,
  });

  ChatConversation copyWith({
    String? id,
    List<ChatMessage>? messages,
    DateTime? createdAt,
  }) => ChatConversation(
    id: id ?? this.id,
    messages: messages ?? this.messages,
    createdAt: createdAt ?? this.createdAt,
  );
}

class ChatStorage {
  static const String _conversationsKey = 'chat_conversations';
  static const String _currentConvKey = 'current_conversation_id';

  final SharedPreferences _prefs;

  ChatStorage(this._prefs);

  List<ChatConversation> getConversations() {
    final data = _prefs.getString(_conversationsKey);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => _conversationFromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  ChatConversation? getConversation(String id) {
    final convs = getConversations();
    try {
      return convs.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveConversation(ChatConversation conv) async {
    final convs = getConversations();
    final index = convs.indexWhere((c) => c.id == conv.id);
    
    if (index >= 0) {
      convs[index] = conv;
    } else {
      convs.add(conv);
    }

    await _prefs.setString(_conversationsKey, jsonEncode(convs.map((c) => _conversationToJson(c)).toList()));
  }

  Future<void> deleteConversation(String id) async {
    final convs = getConversations();
    convs.removeWhere((c) => c.id == id);
    await _prefs.setString(_conversationsKey, jsonEncode(convs.map((c) => _conversationToJson(c)).toList()));
  }

  Future<void> clearAll() async {
    await _prefs.remove(_conversationsKey);
    await _prefs.remove(_currentConvKey);
  }

  String? getCurrentConversationId() {
    return _prefs.getString(_currentConvKey);
  }

  Future<void> setCurrentConversationId(String id) async {
    await _prefs.setString(_currentConvKey, id);
  }

  Map<String, dynamic> _conversationToJson(ChatConversation conv) => {
    'id': conv.id,
    'messages': conv.messages.map((m) => m.toJson()).toList(),
    'createdAt': conv.createdAt.toIso8601String(),
  };

  ChatConversation _conversationFromJson(Map<String, dynamic> json) => ChatConversation(
    id: json['id'] ?? '',
    messages: (json['messages'] as List<dynamic>?)
        ?.map((m) => ChatMessage.fromJson(m))
        .toList() ?? [],
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
  );
}

final chatStorageProvider = Provider<ChatStorage>((ref) {
  throw UnimplementedError('Must be overridden');
});

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

class ChatState {
  final List<ChatConversation> conversations;
  final String? currentConversationId;
  final bool isLoading;

  ChatState({
    this.conversations = const [],
    this.currentConversationId,
    this.isLoading = false,
  });

  ChatConversation? get currentConversation {
    if (currentConversationId == null) return null;
    try {
      return conversations.firstWhere((c) => c.id == currentConversationId);
    } catch (e) {
      return null;
    }
  }

  ChatState copyWith({
    List<ChatConversation>? conversations,
    String? currentConversationId,
    bool? isLoading,
  }) => ChatState(
    conversations: conversations ?? this.conversations,
    currentConversationId: currentConversationId ?? this.currentConversationId,
    isLoading: isLoading ?? this.isLoading,
  );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatNotifier(this._ref) : super(ChatState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await _ref.read(sharedPrefsProvider.future);
      final storage = ChatStorage(prefs);
      
      final convs = storage.getConversations();
      final currentId = storage.getCurrentConversationId();
      
      if (convs.isEmpty) {
        final newConv = ChatConversation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          messages: [],
          createdAt: DateTime.now(),
        );
        await storage.saveConversation(newConv);
        await storage.setCurrentConversationId(newConv.id);
        
        state = ChatState(
          conversations: [newConv],
          currentConversationId: newConv.id,
          isLoading: false,
        );
      } else {
        state = ChatState(
          conversations: convs,
          currentConversationId: currentId ?? convs.first.id,
          isLoading: false,
        );
      }
    } catch (e) {
      state = ChatState(isLoading: false);
    }
  }

  Future<void> _save() async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final storage = ChatStorage(prefs);
    
    for (final conv in state.conversations) {
      await storage.saveConversation(conv);
    }
    if (state.currentConversationId != null) {
      await storage.setCurrentConversationId(state.currentConversationId!);
    }
  }

  void addMessage(String role, String content) {
    if (state.currentConversationId == null) return;

    final convIndex = state.conversations.indexWhere((c) => c.id == state.currentConversationId);
    if (convIndex < 0) return;

    final conv = state.conversations[convIndex];
    final newMessage = ChatMessage(
      role: role,
      content: content,
      timestamp: DateTime.now(),
    );

    final updatedConv = conv.copyWith(
      messages: [...conv.messages, newMessage],
    );

    final updatedConvs = [...state.conversations];
    updatedConvs[convIndex] = updatedConv;

    state = state.copyWith(conversations: updatedConvs);
    _save();
  }

  void clearCurrentConversation() {
    if (state.currentConversationId == null) return;

    final convIndex = state.conversations.indexWhere((c) => c.id == state.currentConversationId);
    if (convIndex < 0) return;

    final conv = state.conversations[convIndex];
    final updatedConv = conv.copyWith(messages: []);

    final updatedConvs = [...state.conversations];
    updatedConvs[convIndex] = updatedConv;

    state = state.copyWith(conversations: updatedConvs);
    _save();
  }

  Future<void> deleteAll() async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final storage = ChatStorage(prefs);
    await storage.clearAll();
    
    final newConv = ChatConversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messages: [],
      createdAt: DateTime.now(),
    );
    
    state = ChatState(
      conversations: [newConv],
      currentConversationId: newConv.id,
      isLoading: false,
    );
    
    await _save();
  }
}
