import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class StorageBrowserScreen extends StatefulWidget {
  const StorageBrowserScreen({super.key});

  @override
  State<StorageBrowserScreen> createState() => _StorageBrowserScreenState();
}

class _StorageBrowserScreenState extends State<StorageBrowserScreen> {
  List<dynamic>? _files;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // List files in the Exercises bucket (capital E)
      final files = await SupabaseService.instance.client.storage
          .from('Exercises')
          .list();
      
      print('📁 Files found in Exercises bucket:');
      for (var file in files) {
        print('  - ${file.name} (ID: ${file.id})');
      }
      
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error listing files: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFiles,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _files == null || _files!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No files found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text('The exercises bucket is empty'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _files!.length,
                      itemBuilder: (context, index) {
                        final file = _files![index];
                        final fileName = file.name ?? 'Unknown';
                        final isImage = fileName.toLowerCase().endsWith('.gif') ||
                            fileName.toLowerCase().endsWith('.jpg') ||
                            fileName.toLowerCase().endsWith('.jpeg') ||
                            fileName.toLowerCase().endsWith('.png');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              isImage ? Icons.image : Icons.insert_drive_file,
                              color: isImage ? Colors.blue : Colors.grey,
                            ),
                            title: Text(fileName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (file.id != null)
                                  Text('ID: ${file.id}', style: const TextStyle(fontSize: 11)),
                                if (file.metadata != null)
                                  Text(
                                    'Size: ${_formatBytes(file.metadata['size'])}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                              ],
                            ),
                            trailing: isImage
                                ? IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _showImagePreview(context, fileName),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatBytes(dynamic bytes) {
    if (bytes == null) return 'Unknown';
    final int size = bytes is int ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showImagePreview(BuildContext context, String fileName) async {
    try {
      final url = await SupabaseService.instance.client.storage
          .from('Exercises')
          .createSignedUrl(fileName, 3600);

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(fileName),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Image.network(
                  url,
                  errorBuilder: (context, error, stackTrace) => Column(
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Failed to load image: $error'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
