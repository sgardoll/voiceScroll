import 'package:flutter/material.dart';
import 'package:flowread/models/script.dart';
import 'package:flowread/services/storage_service.dart';
import 'package:flowread/screens/script_editor_page.dart';
import 'package:flowread/screens/autocue_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storageService = StorageService();
  List<Script> _scripts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    try {
      final scripts = await _storageService.getScripts();
      setState(() {
        _scripts = scripts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load scripts');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.tertiary),
    );
  }

  Future<void> _deleteScript(Script script) async {
    try {
      await _storageService.deleteScript(script.id);
      setState(() => _scripts.removeWhere((s) => s.id == script.id));
      _showSuccessSnackBar('Script deleted');
    } catch (e) {
      _showErrorSnackBar('Failed to delete script');
    }
  }

  void _navigateToEditor([Script? script]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScriptEditorPage(script: script),
      ),
    );
    
    if (result == true) {
      _loadScripts();
    }
  }

  void _navigateToAutocue(Script script) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutocuePage(script: script),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowRead'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scripts.isEmpty
              ? _buildEmptyState()
              : _buildScriptList(),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.text_snippet_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'No scripts yet',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the + button to create your first script',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );

  Widget _buildScriptList() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _scripts.length,
    itemBuilder: (context, index) {
      final script = _scripts[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            script.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                script.content.length > 100
                    ? '${script.content.substring(0, 100)}...'
                    : script.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Updated: ${_formatDate(script.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'play':
                  _navigateToAutocue(script);
                  break;
                case 'edit':
                  _navigateToEditor(script);
                  break;
                case 'delete':
                  _showDeleteDialog(script);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'play',
                child: ListTile(
                  leading: Icon(Icons.play_arrow),
                  title: Text('Run Autocue'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          onTap: () => _navigateToAutocue(script),
        ),
      );
    },
  );

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(Script script) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Script'),
        content: Text('Are you sure you want to delete "${script.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScript(script);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}