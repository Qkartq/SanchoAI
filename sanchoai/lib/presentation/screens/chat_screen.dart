import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/history_provider.dart';
import '../providers/model_provider.dart';
import '../providers/settings_provider.dart';
import '../../domain/entities/model_state.dart';
import '../widgets/status_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isGenerating = false;
  String _currentResponse = '';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final historyState = ref.read(historyProvider);
    final modelState = ref.read(modelStateProvider);
    
    if (modelState.status != ModelStatus.ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model not loaded. Go to Settings.')),
        );
      }
      return;
    }

    _controller.clear();
    setState(() => _isGenerating = true);
    _currentResponse = '';

    ref.read(historyProvider.notifier).addMessage('user', text);

    final llamaService = ref.read(llamaServiceProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final conv = ref.read(historyProvider).currentConversation;
    final history = conv?.messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList() ?? [];

    try {
      await for (final chunk in llamaService.generateStream(
        text, 
        history: history,
        temperature: settings?.temperature,
        maxTokens: settings?.maxTokens,
      )) {
        if (mounted) {
          setState(() {
            _currentResponse += chunk;
          });
          _scrollToBottom();
        }
      }
      
      if (_currentResponse.isNotEmpty) {
        ref.read(historyProvider.notifier).addMessage('assistant', _currentResponse);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _currentResponse = '';
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final modelState = ref.watch(modelStateProvider);
    final theme = Theme.of(context);

    final messages = historyState.currentConversation?.messages ?? [];
    final allMessages = [...messages];
    if (_currentResponse.isNotEmpty) {
      allMessages.add(Message(
        id: 'temp',
        role: 'assistant',
        content: _currentResponse,
        timestamp: DateTime.now(),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StatusIndicator(modelState: modelState),
        ),
        title: const Text('Sancho.AI'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : allMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation',
                              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configure your model in Settings first',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: allMessages.length,
                        itemBuilder: (context, index) {
                          final msg = allMessages[index];
                          return _MessageBubble(
                            content: msg.content,
                            isUser: msg.role == 'user',
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isGenerating ? null : _sendMessage,
                  child: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const _MessageBubble({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isUser
            ? Text(content, style: TextStyle(color: theme.colorScheme.onPrimary))
            : MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyMedium,
                  code: theme.textTheme.bodySmall?.copyWith(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
      ),
    );
  }
}
