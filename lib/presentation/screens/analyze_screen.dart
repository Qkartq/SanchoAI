import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/model_provider.dart';
import '../../data/datasources/document_service.dart';
import '../../domain/entities/model_state.dart';

final documentServiceProvider = Provider<DocumentService>((ref) => DocumentService());

class AnalyzeScreen extends ConsumerStatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  ConsumerState<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends ConsumerState<AnalyzeScreen> {
  final _promptController = TextEditingController(text: 'Describe this image in detail.');
  String? _selectedImagePath;
  String? _selectedDocumentPath;
  String? _result;
  bool _isProcessing = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image analysis is not yet supported. Coming soon!')),
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedDocumentPath = result.files.single.path;
        _selectedImagePath = null;
        _result = null;
      });
    }
  }

  Future<void> _analyze() async {
    final modelState = ref.read(modelStateProvider);
    if (modelState.status != ModelStatus.ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model not loaded. Configure in Settings first.')),
        );
      }
      return;
    }

    if (_selectedImagePath == null && _selectedDocumentPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an image or document first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    final llamaService = ref.read(llamaServiceProvider);
    final docService = ref.read(documentServiceProvider);

    try {
      String response;
      
      if (_selectedImagePath != null) {
        if (!modelState.hasMultimodal) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image analysis requires a multimodal (vision) model. Please configure mmproj in Settings.')),
            );
          }
          return;
        }
        response = await llamaService.analyzeImage(_selectedImagePath!, _promptController.text);
      } else if (_selectedDocumentPath != null) {
        final content = await docService.extractText(_selectedDocumentPath!);
        final prompt = '${_promptController.text}\n\nDocument content:\n${content.substring(0, content.length > 5000 ? 5000 : content.length)}';
        response = await llamaService.generate(prompt);
      } else {
        response = 'No input selected';
      }

      setState(() {
        _result = response;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelState = ref.watch(modelStateProvider);
    final hasMultimodal = modelState.hasMultimodal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasMultimodal)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Configure mmproj in Settings to enable image analysis',
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Select Input',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.image),
                    label: const Text('Image (Coming Soon)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.description),
                    label: const Text('Document'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: _selectedDocumentPath != null
                          ? theme.colorScheme.primaryContainer
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedDocumentPath != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDocumentPath!.split('/').last,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'What would you like to know?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_selectedImagePath != null || _selectedDocumentPath != null) && !_isProcessing
                  ? _analyze
                  : null,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.analytics),
              label: Text(_isProcessing ? 'Processing...' : 'Analyze'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              Text(
                'Result',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MarkdownBody(
                  data: _result!,
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
