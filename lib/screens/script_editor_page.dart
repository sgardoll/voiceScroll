import 'package:flutter/material.dart';
import 'package:flowread/models/script.dart';
import 'package:flowread/services/storage_service.dart';

class ScriptEditorPage extends StatefulWidget {
  final Script? script;

  const ScriptEditorPage({super.key, this.script});

  @override
  State<ScriptEditorPage> createState() => _ScriptEditorPageState();
}

class _ScriptEditorPageState extends State<ScriptEditorPage> {
  final StorageService _storageService = StorageService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.script != null) {
      _titleController.text = widget.script!.title;
      _contentController.text = widget.script!.content;
    }
    
    _titleController.addListener(() => setState(() => _hasChanges = true));
    _contentController.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveScript() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter some content');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final script = widget.script?.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        updatedAt: now,
      ) ?? Script(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await _storageService.saveScript(script);
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
      
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to save script');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  void _insertSampleText() {
    const sampleText = '''Good morning everyone, and welcome to today's presentation. 

Today we'll be exploring the fascinating world of artificial intelligence and its impact on modern communication. As we stand at the threshold of a new technological era, it's important to understand how these advancements are shaping our daily interactions.

Artificial intelligence has revolutionized the way we process information, analyze data, and make decisions. From simple voice assistants to complex machine learning algorithms, AI has become an integral part of our digital landscape.

In this session, we'll examine three key areas: the current state of AI technology, its practical applications in various industries, and the potential challenges and opportunities that lie ahead.

Let's begin our journey into this exciting field and discover how AI is transforming the way we communicate, work, and live.

Thank you for your attention, and let's make this an engaging and informative discussion.''';

    _contentController.text = sampleText;
    setState(() => _hasChanges = true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.script == null ? 'New Script' : 'Edit Script'),
          actions: [
            if (_contentController.text.isEmpty)
              TextButton(
                onPressed: _insertSampleText,
                child: const Text('Sample'),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _saveScript,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Script Title',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _contentFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Script Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    hintText: 'Enter your script content here...',
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for better speech recognition:',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Write in natural, conversational language\n'
                      '• Use shorter sentences for better tracking\n'
                      '• Avoid complex punctuation and symbols\n'
                      '• Speak clearly and at a steady pace',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}