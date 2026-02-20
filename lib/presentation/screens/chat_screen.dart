import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _continueMessage() async {
    final modelState = ref.read(modelStateProvider);
    final conv = ref.read(historyProvider).currentConversation;
    
    if (modelState.status != ModelStatus.ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model not loaded.')),
        );
      }
      return;
    }

    if (conv == null || conv.messages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No messages to continue.')),
        );
      }
      return;
    }

    final lastMessage = conv.messages.last;
    if (lastMessage.role != 'assistant') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last message must be from assistant.')),
        );
      }
      return;
    }

    setState(() => _isGenerating = true);
    _currentResponse = '';

    final llamaService = ref.read(llamaServiceProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final history = conv.messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    try {
      await for (final chunk in llamaService.continueGeneration(
        history,
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

  void _showConversationDrawer() {
    Scaffold.of(context).openDrawer();
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

    final canContinue = messages.isNotEmpty && 
        messages.last.role == 'assistant' && 
        modelState.status == ModelStatus.ready;

    return Scaffold(
      drawer: _buildConversationDrawer(context, historyState),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _showConversationDrawer,
        ),
        title: Column(
          children: [
            const Text('Sancho.AI'),
            CompactStatusIndicator(modelState: modelState),
          ],
        ),
        centerTitle: true,
        actions: [
          if (canContinue)
            IconButton(
              icon: const Icon(Icons.forward),
              onPressed: _isGenerating ? null : _continueMessage,
              tooltip: 'Continue',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final init = ref.read(initializeModelProvider);
              await init();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Model reloaded')),
                );
              }
            },
            tooltip: 'Reload Model',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
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
                            message: msg,
                            isUser: msg.role == 'user',
                            onDelete: () => _showDeleteMessageDialog(msg),
                            onDeleteSubsequent: msg.role == 'user' 
                                ? () => _showDeleteSubsequentDialog(msg)
                                : null,
                            onCopy: () => _copyMessage(msg.content),
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

  Widget _buildConversationDrawer(BuildContext context, HistoryState historyState) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Chats',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      ref.read(historyProvider.notifier).createNewConversation();
                      Navigator.pop(context);
                    },
                    tooltip: 'New Chat',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: historyState.conversations.length,
                itemBuilder: (context, index) {
                  final conv = historyState.conversations[index];
                  final isSelected = conv.id == historyState.currentConversationId;
                  
                  return ListTile(
                    selected: isSelected,
                    leading: Icon(
                      isSelected ? Icons.chat : Icons.chat_outlined,
                    ),
                    title: Text(
                      conv.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      conv.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      ref.read(historyProvider.notifier).selectConversation(conv.id);
                      Navigator.pop(context);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _showDeleteConversationDialog(conv),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConversationDialog(Conversation conv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Delete "${conv.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).deleteConversation(conv.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMessageDialog(Message msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Message'),
              onTap: () {
                ref.read(historyProvider.notifier).deleteMessage(msg.id);
                Navigator.pop(context);
              },
            ),
            if (msg.role == 'user')
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Delete This and Subsequent'),
                subtitle: const Text('Deletes this and all following messages'),
                onTap: () {
                  ref.read(historyProvider.notifier).deleteMessageAndSubsequent(msg.id);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                _copyMessage(msg.content);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSubsequentDialog(Message msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Messages'),
        content: const Text('Delete this message and all subsequent messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).deleteMessageAndSubsequent(msg.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isUser;
  final VoidCallback onDelete;
  final VoidCallback? onDeleteSubsequent;
  final VoidCallback onCopy;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.onDelete,
    this.onDeleteSubsequent,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Align(
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
              ? Text(message.content, style: TextStyle(color: theme.colorScheme.onPrimary))
              : MarkdownBody(
                  data: message.content,
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium,
                    code: theme.textTheme.bodySmall?.copyWith(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(isUser ? 'Delete Message' : 'Delete & Regenerate'),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            if (isUser && onDeleteSubsequent != null)
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Delete This and Subsequent'),
                subtitle: const Text('Deletes all following messages'),
                onTap: () {
                  Navigator.pop(context);
                  onDeleteSubsequent!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                onCopy();
              },
            ),
          ],
        ),
      ),
    );
  }
}
