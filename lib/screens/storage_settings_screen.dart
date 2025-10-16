import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class StorageSettingsScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const StorageSettingsScreen({super.key, this.onNavigate});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  final _localStorage = LocalStorageService.instance;
  final _syncService = SyncService.instance;
  
  bool _isSyncing = false;
  Map<String, dynamic>? _syncStatus;
  Map<String, int>? _storageStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _syncStatus = _syncService.getSyncStatus();
      _storageStats = _localStorage.getStorageStats();
    });
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);

    final result = await _syncService.forceSync();
    
    setState(() => _isSyncing = false);
    _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Sync completed'),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all synced data from local storage. '
          'Unsynced data will be kept. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _localStorage.clearSyncedData();
      _loadData();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage & Sync'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!('profile');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Sync Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_sync,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sync Status',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'Last Sync',
                    _syncStatus?['lastSync'] != null
                        ? _formatDateTime(_syncStatus!['lastSync'])
                        : 'Never',
                    colorScheme,
                    textTheme,
                  ),
                  const Divider(height: 24),
                  _buildStatusRow(
                    'Pending Items',
                    '${_syncStatus?['pendingItems'] ?? 0}',
                    colorScheme,
                    textTheme,
                  ),
                  const Divider(height: 24),
                  _buildStatusRow(
                    'Status',
                    _syncStatus?['isSyncing'] == true
                        ? 'Syncing...'
                        : (_syncStatus?['needsSync'] == true
                            ? 'Needs Sync'
                            : 'Up to Date'),
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSyncing ? null : _syncNow,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync),
                      label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Storage Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Local Storage',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'Workouts',
                    '${_storageStats?['workouts'] ?? 0} items',
                    colorScheme,
                    textTheme,
                  ),
                  const Divider(height: 24),
                  _buildStatusRow(
                    'Exercises',
                    '${_storageStats?['exercises'] ?? 0} items',
                    colorScheme,
                    textTheme,
                  ),
                  const Divider(height: 24),
                  _buildStatusRow(
                    'Measurements',
                    '${_storageStats?['measurements'] ?? 0} items',
                    colorScheme,
                    textTheme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info Card
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your data is saved locally and syncs automatically when online',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Actions
          Text(
            'Actions',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _clearCache,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Synced Cache'),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
