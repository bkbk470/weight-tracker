import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';
import '../utils/safe_dialog_helpers.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(String, [Map<String, dynamic>?]) onNavigate;
  final bool hasActiveWorkout;
  final int activeWorkoutTime;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    this.hasActiveWorkout = false,
    this.activeWorkoutTime = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoadingWorkouts = true;
  bool _isLoadingRecentWorkouts = true;
  List<Map<String, dynamic>> _folders = [];
  Map<String?, List<Map<String, dynamic>>> _workoutsByFolder = {};
  Map<String, DateTime?> _workoutLastCompletedDates = {}; // Track last completed dates
  List<Map<String, dynamic>> _recentWorkoutLogs = [];
  Set<String> _expandedFolderIds = {}; // Track multiple expanded folders
  String _userName = 'there'; // Default greeting name

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadExpandedState();
    _loadFoldersAndWorkouts();
    _loadRecentWorkouts();
  }

  Future<void> _loadUserName() async {
    try {
      // Try loading from local storage first for immediate display
      final localProfile = LocalStorageService.instance.getUserProfile();
      if (localProfile != null && localProfile['full_name'] != null) {
        final name = localProfile['full_name'] as String;
        final firstName = name.split(' ').first;
        if (mounted && firstName.isNotEmpty) {
          setState(() {
            _userName = firstName;
          });
        }
      }

      // Then try loading from Supabase
      final profile = await _supabaseService.getProfile();
      if (profile != null && profile['full_name'] != null) {
        final name = profile['full_name'] as String;
        final firstName = name.split(' ').first;
        if (mounted && firstName.isNotEmpty) {
          setState(() {
            _userName = firstName;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
      // Keep default greeting
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Future<void> _loadExpandedState() async {
    try {
      final localStorage = LocalStorageService.instance;
      final saved = localStorage.getExpandedFolders();
      if (saved != null) {
        setState(() {
          _expandedFolderIds = Set<String>.from(saved);
        });
      }
    } catch (e) {
      debugPrint('Error loading expanded state: $e');
    }
  }

  Future<void> _saveExpandedState() async {
    try {
      final localStorage = LocalStorageService.instance;
      await localStorage.saveExpandedFolders(_expandedFolderIds.toList());
    } catch (e) {
      debugPrint('Error saving expanded state: $e');
    }
  }

  String? _normalizeId(dynamic value) {
    if (value == null) return null;
    final idStr = value.toString();
    if (idStr.isEmpty) return null;
    return idStr;
  }

  Future<void> _loadFoldersAndWorkouts() async {
    setState(() => _isLoadingWorkouts = true);

    try {
      // Load folders
      final rawFolders = await _supabaseService.getWorkoutFolders();
      final folders = rawFolders
          .where((folder) => folder['id'] != null)
          .map((folder) {
            final normalized = Map<String, dynamic>.from(folder);
            normalized['id'] = folder['id'].toString();
            return normalized;
          })
          .toList();

      // Extract folder IDs for batch loading
      final folderIds = folders
          .map((f) => f['id'] as String?)
          .whereType<String>()
          .toList();

      // OPTIMIZED: Batch load all workouts for all folders in parallel
      final results = await Future.wait([
        // Load all workouts for all folders in one query
        folderIds.isEmpty
            ? Future.value(<String, List<Map<String, dynamic>>>{})
            : _supabaseService.getAllWorkoutsByFolders(folderIds),
        // Load unorganized workouts
        _supabaseService.getWorkoutsByFolder(null),
      ]);

      final Map<String, List<Map<String, dynamic>>> workoutsByFolderId = results[0] as Map<String, List<Map<String, dynamic>>>;
      final List<Map<String, dynamic>> unorganizedWorkouts = results[1] as List<Map<String, dynamic>>;

      // Build grouped map
      final Map<String?, List<Map<String, dynamic>>> grouped = {};
      grouped[null] = unorganizedWorkouts;

      // Initialize empty lists for each folder and populate with loaded workouts
      for (var folder in folders) {
        final folderId = folder['id'] as String;
        grouped[folderId] = workoutsByFolderId[folderId] ?? [];
      }

      // OPTIMIZED: Collect all workout IDs and batch load last dates
      final allWorkoutIds = <String>[];
      for (var workoutsList in grouped.values) {
        for (var workout in workoutsList) {
          final workoutId = _normalizeId(workout['id']);
          if (workoutId != null) {
            allWorkoutIds.add(workoutId);
          }
        }
      }

      // Batch load all last workout dates in one query
      final lastDates = allWorkoutIds.isEmpty
          ? <String, DateTime?>{}
          : await _supabaseService.getLastWorkoutDates(allWorkoutIds);

      if (!mounted) return;
      setState(() {
        _folders = folders;
        _workoutsByFolder = grouped;
        _workoutLastCompletedDates = lastDates;
        _isLoadingWorkouts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _folders = [];
        _workoutsByFolder = {null: []};
        _workoutLastCompletedDates = {};
        _isLoadingWorkouts = false;
      });
      debugPrint('Failed to load folders and workouts: $e');
    }
  }

  /// Get the last completed date for a workout by checking workout_logs
  Future<DateTime?> _getLastWorkoutDate(String workoutId) async {
    try {
      final response = await _supabaseService.client
          .from('workout_logs')
          .select('start_time')
          .eq('workout_id', workoutId)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['start_time'] != null) {
        return DateTime.parse(response['start_time'] as String);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last workout date: $e');
      return null;
    }
  }

  /// Format the "last completed" text (e.g., "2 days ago at 3:45 PM")
  String _formatLastCompleted(DateTime? date) {
    if (date == null) return 'Never completed';

    final now = DateTime.now();
    final difference = now.difference(date);

    String timeAgo;
    if (difference.inDays == 0) {
      timeAgo = 'Today';
    } else if (difference.inDays == 1) {
      timeAgo = 'Yesterday';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      timeAgo = weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      timeAgo = months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      timeAgo = years == 1 ? '1 year ago' : '$years years ago';
    }

    final timeFormat = DateFormat('h:mm a');
    final timeStr = timeFormat.format(date);

    return '$timeAgo at $timeStr';
  }

  String _formatTimeOnlyFromLabel(String label) {
    // label is produced by _formatLastCompleted (e.g., 'Today at 3:56 PM')
    final parts = label.split(' at ');
    if (parts.length == 2) {
      return parts[1];
    }
    return label;
  }

  Future<void> _loadRecentWorkouts() async {
    try {
      final logs = await _supabaseService.getWorkoutLogs(limit: 3);
      if (!mounted) return;
      setState(() {
        _recentWorkoutLogs = logs;
        _isLoadingRecentWorkouts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recentWorkoutLogs = [];
        _isLoadingRecentWorkouts = false;
      });
      debugPrint('Failed to load recent workouts: $e');
    }
  }

  void _showCreatePlanDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedColor = 'blue';

    showSafeDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Create Workout Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: const InputDecoration(
                    labelText: 'Plan Name',
                    hintText: 'e.g., Strength Training, Cardio Mix',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of this plan',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Plan Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['blue', 'green', 'orange', 'purple', 'red']
                      .map((color) => ChoiceChip(
                            label: Text(color),
                            selected: selectedColor == color,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              }
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a plan name')),
                  );
                  return;
                }

                try {
                  await _supabaseService.createFolder(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    color: selectedColor,
                    icon: 'folder',
                  );

                  Navigator.pop(dialogContext);
                  _loadFoldersAndWorkouts();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout plan created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWorkoutToPlanDialog(String planId, String planName) async {
    // Get all workouts
    final allWorkouts = await _supabaseService.getWorkouts();
    
    // Get workouts already in this plan
    final workoutsInPlan = await _supabaseService.getWorkoutsByFolder(planId);
    final workoutIdsInPlan = workoutsInPlan
        .map((w) => _normalizeId(w['id']))
        .whereType<String>()
        .toSet();
    
    // Filter to show only workouts not yet in this plan
    final availableWorkouts = allWorkouts.where((workout) {
      final workoutId = _normalizeId(workout['id']);
      if (workoutId == null) {
        return false;
      }
      return !workoutIdsInPlan.contains(workoutId);
    }).toList();

    if (!mounted) return;

    if (availableWorkouts.isEmpty) {
      showSafeDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Workouts Available'),
          content: const Text(
            'All your workouts are already in this plan, or you don\'t have any workouts yet. Create a new workout to add it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onNavigate('workout-builder');
              },
              child: const Text('Create Workout'),
            ),
          ],
        ),
      );
      return;
    }

    showSafeDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Workout to $planName'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableWorkouts.length,
            itemBuilder: (context, index) {
                  final workout = availableWorkouts[index];
                  final workoutId = _normalizeId(workout['id']);
                  final exercises = workout['workout_exercises'] as List? ?? [];
              
              return ListTile(
                leading: Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text((workout['name'] as String?) ?? 'Workout'),
                subtitle: Text('${exercises.length} exercises'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: workoutId == null
                      ? null
                      : () async {
                    try {
                      await _supabaseService.addWorkoutToPlan(
                        workoutId,
                        planId,
                      );
                      
                      Navigator.pop(context);
                      _loadFoldersAndWorkouts();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${workout['name']}" to plan'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigate('workout-builder');
            },
            child: const Text('Create New'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlanReorder(int oldIndex, int newIndex) async {
    if (_folders.length < 2 || oldIndex == newIndex) {
      return;
    }

    if (oldIndex < 0 || oldIndex >= _folders.length) {
      return;
    }

    if (newIndex > _folders.length) {
      newIndex = _folders.length;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final previousOrder = List<Map<String, dynamic>>.from(_folders);

    setState(() {
      final plan = _folders.removeAt(oldIndex);
      _folders.insert(newIndex, plan);
    });

    try {
      final reorderablePlans = _folders.where((plan) => plan['id'] != null).toList();
      await _supabaseService.reorderPlans(reorderablePlans);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _folders = previousOrder;
      });
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving plan order: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  Color _getColorFromString(String? colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
        children: [
          // Background gradients
          Positioned(
            top: MediaQuery.of(context).size.height / 4,
            right: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 3,
            left: -100,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              // Header with greeting and stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        '${_getGreeting()}, $_userName',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let\'s keep your streak alive!',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Start Workout',
                              icon: Icons.add,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                              onTap: () => widget.onNavigate('workout'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'Templates',
                              icon: Icons.list_alt,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                              onTap: () => widget.onNavigate('workout', {'selectedTab': 'Templates'}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Workout Plans Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Workout Plans',
                          style: textTheme.titleLarge,
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _showCreatePlanDialog,
                              icon: const Icon(Icons.create_new_folder, size: 18),
                              label: const Text('New Plan'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => widget.onNavigate('workout-folders'),
                              icon: const Icon(Icons.folder, size: 18),
                              label: const Text('Manage'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildWorkoutsFolders(colorScheme, textTheme),
                    const SizedBox(height: 32),

                    // Recent Workouts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Workouts',
                          style: textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate('workout-history'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentWorkoutsSection(colorScheme, textTheme),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildWorkoutsFolders(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoadingWorkouts) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading your workouts...',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final plansList = _folders.isEmpty
        ? Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No workout plans yet',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a plan to organize your workouts.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        : ReorderableListView.builder(
            key: const PageStorageKey('dashboard-plan-order'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                builder: (context, childWidget) {
                  return Transform.scale(
                    scale: 1.02,
                    child: childWidget,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  shadowColor: Colors.transparent,
                  child: child,
                ),
              );
            },
            onReorder: _handlePlanReorder,
            itemCount: _folders.length,
            itemBuilder: (context, index) {
              final folder = _folders[index];
              final dynamic rawFolderId = folder['id'];
              final String? folderId = rawFolderId?.toString();
              final workouts = folderId != null ? (_workoutsByFolder[folderId] ?? []) : const <Map<String, dynamic>>[];
              final isExpanded = folderId != null && _expandedFolderIds.contains(folderId);
              final color = _getColorFromString(folder['color'] as String?);

              return Card(
                key: ValueKey(folderId ?? 'plan-$index'),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        if (folderId == null) return;
                        setState(() {
                          if (_expandedFolderIds.contains(folderId)) {
                            _expandedFolderIds.remove(folderId);
                          } else {
                            _expandedFolderIds.add(folderId);
                          }
                        });
                        _saveExpandedState();
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: SizedBox(
                        height: 72, // Fixed height to prevent layout issues during drag
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(Icons.folder, color: color, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (folder['name'] as String?) ?? 'Workout Plan',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${workouts.length} workout${workouts.length != 1 ? 's' : ''}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: folderId == null
                                  ? Icon(
                                      Icons.drag_indicator,
                                      size: 24,
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                                    )
                                  : ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        Icons.drag_indicator,
                                        size: 24,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.expand_more, size: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: isExpanded
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Divider(height: 1),
                                if (workouts.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _EmptyPlanIllustration(
                                      colorScheme: colorScheme,
                                      textTheme: textTheme,
                                      onAddWorkout: folderId == null
                                          ? null
                                          : () => _showAddWorkoutToPlanDialog(
                                                folderId,
                                                (folder['name'] as String?) ?? 'Workout Plan',
                                              ),
                                    ),
                                  ),
                                if (workouts.isNotEmpty)
                                  ...workouts.take(5).map((workout) {
                                  final workoutId = _normalizeId(workout['id']);
                                  final lastDate = workoutId != null ? _workoutLastCompletedDates[workoutId] : null;
                                  final isLastItem = workouts.take(5).toList().last == workout;

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _CompactPlanWorkoutTile(
                                        workout: workout,
                                        lastCompleted: _formatLastCompleted(lastDate),
                                        hasBeenCompleted: lastDate != null,
                                        colorScheme: colorScheme,
                                        textTheme: textTheme,
                                        onTap: () => widget.onNavigate('workout-detail', {
                                          'workout': workout,
                                        }),
                                      ),
                                    ],
                                  );
                                }),
                                if (workouts.length > 5)
                                  ListTile(
                                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                                    title: Text(
                                      '+ ${workouts.length - 5} more',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    onTap: () => widget.onNavigate('workout-folders'),
                                  ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        plansList,
        const SizedBox(height: 16),

        // My Workouts default section
        if (_workoutsByFolder[null]?.isNotEmpty ?? false) ...[
          () {
            final unorganizedWorkouts = _workoutsByFolder[null] ?? const <Map<String, dynamic>>[];
            final isMyWorkoutsExpanded = _expandedFolderIds.contains('my_workouts');
            return Card(
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_expandedFolderIds.contains('my_workouts')) {
                          _expandedFolderIds.remove('my_workouts');
                        } else {
                          _expandedFolderIds.add('my_workouts');
                        }
                      });
                      _saveExpandedState();
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.folder_open, size: 28),
                      title: Text(
                        'My Workouts',
                        style: textTheme.titleMedium,
                      ),
                      subtitle: Text('${unorganizedWorkouts.length} workout${unorganizedWorkouts.length != 1 ? 's' : ''}'),
                      trailing: AnimatedRotation(
                        turns: isMyWorkoutsExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: isMyWorkoutsExpanded
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Divider(height: 1),
                              ...unorganizedWorkouts.take(5).map((workout) {
                                final workoutId = _normalizeId(workout['id']);
                                final lastDate = workoutId != null ? _workoutLastCompletedDates[workoutId] : null;
                                final isLastItem = unorganizedWorkouts.take(5).toList().last == workout;

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _MyWorkoutTile(
                                      workout: workout,
                                      lastCompleted: _formatLastCompleted(lastDate),
                                      hasBeenCompleted: lastDate != null,
                                      colorScheme: colorScheme,
                                      textTheme: textTheme,
                                      isInFolder: true,
                                      onTap: () => widget.onNavigate('workout-detail', {
                                        'workout': workout,
                                      }),
                                    ),
                                    if (!isLastItem)
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        indent: 56,
                                        endIndent: 16,
                                        color: colorScheme.outlineVariant.withOpacity(0.5),
                                      ),
                                  ],
                                );
                              }),
                              if (unorganizedWorkouts.length > 5)
                                ListTile(
                                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                                  title: Text(
                                    '+ ${unorganizedWorkouts.length - 5} more',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  onTap: () => widget.onNavigate('workout-folders'),
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }(),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No workouts yet',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Build your first custom workout to see it here.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => widget.onNavigate('workout-builder'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Workout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return 'N/A';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  String _formatTime24Hour(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildRecentWorkoutsSection(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoadingRecentWorkouts) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        ),
      );
    }

    if (_recentWorkoutLogs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No workouts yet',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Start your first workout to see it here',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentWorkoutLogs.map((log) {
        final startTimeStr = log['start_time'] as String?;
        final durationSeconds = log['duration_seconds'] as int?;
        final sets = log['exercise_sets'] as List?;
        final workoutName = log['workout_name'] as String? ?? 'Workout';

        DateTime? startTime;
        if (startTimeStr != null) {
          startTime = DateTime.tryParse(startTimeStr);
        }

        final relativeDate = startTime != null ? _formatRelativeDate(startTime) : 'Unknown';
        final timeOfDay = startTime != null ? _formatTime24Hour(startTime) : '';
        final duration = _formatDuration(durationSeconds);
        final exerciseCount = sets?.length ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _WorkoutCard(
            name: workoutName,
            date: relativeDate,
            time: timeOfDay,
            duration: duration,
            exercises: exerciseCount,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        );
      }).toList(),
    );
  }
}

// New Action Button Widget
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactPlanWorkoutTile extends StatelessWidget {
  final Map<String, dynamic> workout;
  final String lastCompleted;
  final bool hasBeenCompleted;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _CompactPlanWorkoutTile({
    required this.workout,
    required this.lastCompleted,
    required this.hasBeenCompleted,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final exercises = (workout['workout_exercises'] as List?) ?? const [];
    final durationValue = workout['estimated_duration_minutes'];
    final int? durationMinutes = durationValue is int
        ? durationValue
        : durationValue is double
            ? durationValue.round()
            : int.tryParse('$durationValue');

    String? _formatTimeOnlyFromLabel(String label) {
      final parts = label.split(' at ');
      if (parts.length == 2) {
        return parts[1];
      }
      return null;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.75),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          (workout['name'] as String?) ?? 'Workout',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasBeenCompleted)
                        Text(
                          _formatTimeOnlyFromLabel(lastCompleted) ?? lastCompleted,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercises.length} exercise${exercises.length == 1 ? '' : 's'} • ${hasBeenCompleted ? lastCompleted : 'Never completed'}',
                    style: textTheme.bodySmall?.copyWith(
                      color: hasBeenCompleted
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlanIllustration extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onAddWorkout;

  const _EmptyPlanIllustration({
    required this.colorScheme,
    required this.textTheme,
    this.onAddWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.fitness_center_outlined,
            size: 42,
            color: colorScheme.onSurfaceVariant.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No workouts yet',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Add workouts to fill this plan.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (onAddWorkout != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddWorkout,
            icon: const Icon(Icons.add),
            label: const Text('Add Workout'),
          ),
        ],
      ],
    );
  }
}

class _MyWorkoutTile extends StatelessWidget {
  final Map<String, dynamic> workout;
  final String lastCompleted;
  final bool hasBeenCompleted;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final bool isInFolder;

  const _MyWorkoutTile({
    required this.workout,
    required this.lastCompleted,
    required this.hasBeenCompleted,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
    this.isInFolder = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> exercises = workout['workout_exercises'] as List<dynamic>? ?? [];
    final durationValue = workout['estimated_duration_minutes'];
    final int? durationMinutes = durationValue is int
        ? durationValue
        : durationValue is double
            ? durationValue.round()
            : int.tryParse('$durationValue');

    final subtitleParts = <String>[];
    if (exercises.isNotEmpty) {
      subtitleParts.add('${exercises.length} exercises');
    }
    if (durationMinutes != null && durationMinutes > 0) {
      subtitleParts.add('$durationMinutes min');
    }

    final subtitle = subtitleParts.isNotEmpty ? subtitleParts.join(' • ') : 'Custom workout';

    return ListTile(
      contentPadding: isInFolder
          ? const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        Icons.fitness_center,
        size: 24,
        color: colorScheme.primary,
      ),
      title: Text(
        (workout['name'] ?? 'Workout') as String,
        style: textTheme.titleSmall,
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasBeenCompleted) ...[
              TextSpan(
                text: ' • ',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  Icons.check_circle,
                  size: 12,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
              ),
              TextSpan(
                text: ' $lastCompleted',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String name;
  final String date;
  final String time;
  final String duration;
  final int exercises;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _WorkoutCard({
    required this.name,
    required this.date,
    required this.time,
    required this.duration,
    required this.exercises,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$date${time.isNotEmpty ? " • $time" : ""}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
