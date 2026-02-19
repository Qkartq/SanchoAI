import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/model_provider.dart';
import '../providers/history_provider.dart';
import '../../domain/entities/model_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final modelState = ref.watch(modelStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settings.when(
        data: (s) {
          if (_promptController.text != s.systemPrompt) {
            _promptController.text = s.systemPrompt;
          }
          return ListView(
            children: [
              _SectionHeader(title: 'AI Model'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.model_training),
                      title: const Text('Model File'),
                      subtitle: Text(s.modelPath.isEmpty ? 'Not selected' : s.modelPath.split('/').last),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            modelState.status == ModelStatus.ready
                                ? Icons.check_circle
                                : modelState.status == ModelStatus.error
                                    ? Icons.error
                                    : modelState.status == ModelStatus.generating
                                        ? Icons.auto_awesome
                                        : Icons.hourglass_empty,
                            size: 16,
                            color: modelState.status == ModelStatus.ready
                                ? Colors.green
                                : modelState.status == ModelStatus.error
                                    ? Colors.red
                                    : modelState.status == ModelStatus.generating
                                        ? Colors.blue
                                        : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(modelState.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: modelState.status == ModelStatus.ready
                                  ? Colors.green
                                  : modelState.status == ModelStatus.error
                                      ? Colors.red
                                      : modelState.status == ModelStatus.generating
                                          ? Colors.blue
                                          : Colors.orange,
                            ),
                          ),
                          const Spacer(),
                          if (modelState.status == ModelStatus.generating)
                            TextButton.icon(
                              onPressed: () => _cancelGeneration(ref),
                              icon: const Icon(Icons.stop, size: 16),
                              label: const Text('Stop'),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async { 
                            await _pickModelFile(context, ref); 
                          },
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Select Model'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              _SectionHeader(title: 'System Prompt'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter system prompt...',
                    ),
                    maxLines: 4,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setSystemPrompt(v),
                  ),
                ),
              ),
              
              _SectionHeader(title: 'Chat'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Clear Chat History'),
                      subtitle: const Text('Delete all messages'),
                      onTap: () => _showClearChatDialog(context, ref),
                    ),
                  ],
                ),
              ),
              
              _SectionHeader(title: 'Appearance'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  trailing: DropdownButton<String>(
                    value: s.theme,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (v) {
                      if (v != null) ref.read(settingsProvider.notifier).setTheme(v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _getStatusText(ModelStatus status) {
    switch (status) {
      case ModelStatus.idle:
        return 'Not loaded';
      case ModelStatus.loading:
        return 'Loading model...';
      case ModelStatus.ready:
        return 'Ready';
      case ModelStatus.generating:
        return 'Generating...';
      case ModelStatus.error:
        return 'Error';
    }
  }

  Future<void> _showClearChatDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to delete all messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(historyProvider.notifier).clearCurrentConversation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    }
  }

  Future<void> _pickModelFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null && file.path!.isNotEmpty) {
          await ref.read(settingsProvider.notifier).setModelPath(file.path!);
          
          final init = ref.read(initializeModelProvider);
          await init();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Model loaded: ${file.name}')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking model file: $e');
    }
  }

  Future<void> _reloadModel(WidgetRef ref) async {
    final init = ref.read(initializeModelProvider);
    await init();
  }

  Future<void> _cancelGeneration(WidgetRef ref) async {
    final service = ref.read(llamaServiceProvider);
    await service.stop();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
