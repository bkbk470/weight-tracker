import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/safe_dialog_helpers.dart';

class WorkoutFoldersScreen extends StatefulWidget {
  final void Function(String, [Map<String, dynamic>?]) onNavigate;

  const WorkoutFoldersScreen({super.key, required this.onNavigate});

  @override
  State<WorkoutFoldersScreen> createState() => _WorkoutFoldersScreenState();
}

class _WorkoutFoldersScreenState extends State<WorkoutFoldersScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> folders = [];
  Map<String?, List<Map<String, dynamic>>> workoutsByFolder = {};
  List<Map<String, dynamic>> examplePlans = [];
  bool isLoading = true;
  bool isLoadingExamplePlans = false;
  String? selectedFolderId;
  bool examplePlansExpanded = false;
  String? duplicatingTemplateId;
  bool isReordering = false;

  @override
  void initState() {
    super.initState();
    _loadFoldersAndWorkouts();
  }

  Future<void> _loadFoldersAndWorkouts() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        isLoadingExamplePlans = true;
      });
    }

    try {
      // Load plans and example templates in parallel
      final results = await Future.wait([
        _supabaseService.getWorkoutFolders(),
        _supabaseService.getWorkoutTemplates(),
      ]);

      final loadedFolders = results[0] as List<Map<String, dynamic>>;
      final exampleTemplates = results[1] as List<Map<String, dynamic>>;

      // Extract folder IDs for batch loading
      final folderIds = loadedFolders
          .map((f) => f['id'] as String)
          .toList();

      // OPTIMIZED: Batch load all workouts for all folders in parallel
      final workoutResults = await Future.wait([
        // Load all workouts for all folders in one query
        folderIds.isEmpty
            ? Future.value(<String, List<Map<String, dynamic>>>{})
            : _supabaseService.getAllWorkoutsByFolders(folderIds),
        // Load unorganized workouts
        _supabaseService.getWorkoutsByFolder(null),
      ]);

      final Map<String, List<Map<String, dynamic>>> workoutsByFolderId = workoutResults[0] as Map<String, List<Map<String, dynamic>>>;
      final List<Map<String, dynamic>> unorganizedWorkouts = workoutResults[1] as List<Map<String, dynamic>>;

      // Build grouped map
      final Map<String?, List<Map<String, dynamic>>> grouped = {};
      grouped[null] = unorganizedWorkouts;

      // Initialize empty lists for each folder and populate with loaded workouts
      for (var folder in loadedFolders) {
        final folderId = folder['id'] as String;
        grouped[folderId] = workoutsByFolderId[folderId] ?? [];
      }

      if (!mounted) return;
      setState(() {
        folders = loadedFolders;
        workoutsByFolder = grouped;
        examplePlans = exampleTemplates;
        isLoading = false;
        isLoadingExamplePlans = false;
      });
    } catch (e) {
      print('Error loading plans: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isLoadingExamplePlans = false;
      });
    }
  }

  void _showCreatePlanDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedColor = 'default';
    String selectedIcon = 'folder';

    showSafeDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                const SizedBox(height: 12),
                // Color selection
                const Text('Plan Color', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['default', 'blue', 'green', 'orange', 'purple', 'red']
                      .map((color) => ChoiceChip(
                            label: Text(
                              color == 'default' ? 'Default' : color,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: selectedColor == color,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            visualDensity: VisualDensity.compact,
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
              onPressed: () => Navigator.pop(context),
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
                    icon: selectedIcon,
                  );

                  Navigator.pop(context);
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

  void _showEditPlanDialog(Map<String, dynamic> folder) {
    final nameController = TextEditingController(text: folder['name'] as String?);
    final descriptionController = TextEditingController(text: folder['description'] as String?);
    String selectedColor = folder['color'] as String? ?? 'default';

    showSafeDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Workout Plan'),
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
                const SizedBox(height: 12),
                const Text('Plan Color', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['default', 'blue', 'green', 'orange', 'purple', 'red']
                      .map((color) => ChoiceChip(
                            label: Text(
                              color == 'default' ? 'Default' : color,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: selectedColor == color,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            visualDensity: VisualDensity.compact,
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
              onPressed: () => Navigator.pop(context),
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
                  await _supabaseService.updateFolder(
                    folder['id'] as String,
                    {
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      'color': selectedColor,
                    },
                  );

                  Navigator.pop(context);
                  _loadFoldersAndWorkouts();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout plan updated successfully!'),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeWorkoutFromPlan(Map<String, dynamic> workout, String planId, String planName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Plan'),
        content: Text(
          'Remove "${workout['name']}" from $planName?\n\nThe workout will still be available in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.removeWorkoutFromPlan(
          workout['id'] as String,
          planId,
        );
        _loadFoldersAndWorkouts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${workout['name']}" from $planName'),
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
    }
  }

  void _showMoveWorkoutDialog(Map<String, dynamic> workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Unorganized'),
              onTap: () async {
                await _supabaseService.moveWorkoutToFolder(
                  workout['id'] as String,
                  null,
                );
                Navigator.pop(context);
                _loadFoldersAndWorkouts();
              },
            ),
            ...folders.map((folder) => ListTile(
                  leading: Icon(
                    Icons.folder,
                    color: _getColorFromString(folder['color'] as String?),
                  ),
                  title: Text(folder['name'] as String),
                  onTap: () async {
                    await _supabaseService.moveWorkoutToFolder(
                      workout['id'] as String,
                      folder['id'] as String,
                    );
                    Navigator.pop(context);
                    _loadFoldersAndWorkouts();
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAddWorkoutDialog(String planId, String planName) async {
    // Get all workouts
    final allWorkouts = await _supabaseService.getWorkouts();
    
    // Get workouts already in this plan
    final workoutsInPlan = await _supabaseService.getWorkoutsByFolder(planId);
    final workoutIdsInPlan = workoutsInPlan.map((w) => w['id'] as String).toSet();

    if (!mounted) return;

    if (allWorkouts.isEmpty) {
      showSafeDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Workouts Available'),
          content: const Text(
            'You don\'t have any workouts yet. Would you like to create one now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onNavigate('workout-builder');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Workout'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddWorkoutDialog(
        planId: planId,
        planName: planName,
        allWorkouts: allWorkouts,
        initialAddedWorkoutIds: workoutIdsInPlan,
        onWorkoutsAdded: () {
          _loadFoldersAndWorkouts();
        },
        onNavigate: widget.onNavigate,
      ),
    );
  }

  Future<void> _duplicateTemplate(Map<String, dynamic> template) async {
    final templateId = template['id']?.toString();
    if (templateId == null || templateId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template is missing required information.')),
      );
      return;
    }

    setState(() {
      duplicatingTemplateId = templateId;
    });

    try {
      final newWorkout = await _supabaseService.duplicateTemplateToWorkout(templateId);
      await _loadFoldersAndWorkouts();

      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout "${newWorkout['name'] ?? 'Workout'}" added to My Workouts'),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add template: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          duplicatingTemplateId = null;
        });
      }
    }
  }

  String _templateSummary(Map<String, dynamic> template) {
    final exercises =
        (template['workout_template_exercises'] as List?)?.length ?? 0;
    final dynamic durationValue = template['estimated_duration_minutes'];
    int? durationMinutes;
    if (durationValue is int) {
      durationMinutes = durationValue;
    } else if (durationValue is double) {
      durationMinutes = durationValue.round();
    } else if (durationValue != null) {
      durationMinutes = int.tryParse(durationValue.toString());
    }
    final difficulty = (template['difficulty'] as String?)?.trim();
    final category = (template['category'] as String?)?.trim();

    final parts = <String>[];
    if (exercises > 0) {
      parts.add('$exercises exercise${exercises == 1 ? '' : 's'}');
    }
    if (durationMinutes != null && durationMinutes > 0) {
      parts.add('$durationMinutes min');
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      parts.add(difficulty);
    }
    if (category != null && category.isNotEmpty) {
      parts.add(category);
    }

    return parts.isEmpty ? 'Template workout' : parts.join(' • ');
  }

  Widget _buildExamplePlansCard(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (isLoadingExamplePlans) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading example plans...',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final hasTemplates = examplePlans.isNotEmpty;
    final templatesToShow = examplePlans.take(5).toList();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.folder_special,
              color: colorScheme.primary,
              size: 32,
            ),
            title: Text(
              'Example Plans',
              style: textTheme.titleMedium,
            ),
            subtitle: Text(
              hasTemplates
                  ? '${examplePlans.length} template${examplePlans.length == 1 ? '' : 's'} to explore'
                  : 'No example plans available yet',
            ),
            trailing: hasTemplates
                ? Icon(
                    examplePlansExpanded ? Icons.expand_less : Icons.expand_more,
                  )
                : null,
            onTap: hasTemplates
                ? () {
                    setState(() {
                      examplePlansExpanded = !examplePlansExpanded;
                    });
                  }
                : null,
          ),
          if (hasTemplates && examplePlansExpanded) ...[
            const Divider(height: 1),
            ...templatesToShow.map((template) {
              final templateId = template['id']?.toString() ?? '';
              return ListTile(
                contentPadding:
                    const EdgeInsets.only(left: 72, right: 16, top: 8, bottom: 8),
                title: Text(template['name'] as String? ?? 'Template'),
                subtitle: Text(
                  _templateSummary(template),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: templateId.isEmpty
                    ? null
                    : duplicatingTemplateId == templateId
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.file_copy_outlined),
                            tooltip: 'Add to My Workouts',
                            onPressed: () => _duplicateTemplate(template),
                          ),
                onTap: () => widget.onNavigate(
                  'workout-detail',
                  {
                    'workout': template,
                  },
                ),
              );
            }),
            if (examplePlans.length > templatesToShow.length)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: Text(
                  'See all example plans',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onNavigate(
                  'workout-library',
                  {
                    'initialTab': 'Templates',
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _reorderPlans(int oldIndex, int newIndex) async {
    setState(() {
      // Adjust newIndex for list reordering
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      // Reorder the list
      final plan = folders.removeAt(oldIndex);
      folders.insert(newIndex, plan);
    });

    try {
      // Save the new order to the database
      await _supabaseService.reorderPlans(folders);
    } catch (e) {
      print('Error saving plan order: $e');
      // Reload on error to get correct order
      _loadFoldersAndWorkouts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      case 'default':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Plans')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate('dashboard'),
        ),
        title: const Text('Manage Workout Plans'),
        actions: [
          if (folders.isNotEmpty)
            IconButton(
              icon: Icon(isReordering ? Icons.check : Icons.drag_handle),
              onPressed: () {
                setState(() {
                  isReordering = !isReordering;
                  if (!isReordering) {
                    // Collapse all when exiting reorder mode
                    selectedFolderId = null;
                  }
                });
              },
              tooltip: isReordering ? 'Done Reordering' : 'Reorder Plans',
            ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _showCreatePlanDialog,
            tooltip: 'Create Plan',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unorganized workouts section
          if (workoutsByFolder[null]?.isNotEmpty ?? false) ...[
            _PlanSection(
              title: 'Unorganized',
              icon: Icons.folder_open,
              color: Colors.grey,
              workoutCount: workoutsByFolder[null]!.length,
              onTap: () {
                setState(() => selectedFolderId = null);
              },
              isExpanded: selectedFolderId == null,
              workouts: workoutsByFolder[null]!,
              onWorkoutTap: (workout) {
                widget.onNavigate('workout-detail', {'workout': workout});
              },
              planId: null,
              onRemoveWorkout: null, // Can't remove from unorganized
              colorScheme: colorScheme,
              textTheme: textTheme,
              lastWorkoutTime: null,
            ),
            const SizedBox(height: 16),
          ],

          // Workout Plans
          if (isReordering) ...[
            // Reordering hint
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Long press and drag plans to reorder them',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Reorderable list
            ...[
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: _reorderPlans,
                children: folders.map((folder) {
                  final folderId = folder['id'] as String;
                  final workouts = workoutsByFolder[folderId] ?? [];
                  return Card(
                    key: ValueKey(folderId),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.drag_handle,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.folder,
                            color: _getColorFromString(folder['color'] as String?),
                            size: 32,
                          ),
                        ],
                      ),
                      title: Text(folder['name'] as String, style: textTheme.titleMedium),
                      subtitle: Text('${ workouts.length} workout${workouts.length != 1 ? 's' : ''}'),
                    ),
                  );
                }).toList(),
              ),
            ],
          ] else ...[
            ...folders.map((folder) {
            final folderId = folder['id'] as String;
            final workouts = workoutsByFolder[folderId] ?? [];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PlanSection(
                title: folder['name'] as String,
                description: folder['description'] as String?,
                icon: Icons.folder,
                color: _getColorFromString(folder['color'] as String?),
                workoutCount: workouts.length,
                onTap: () {
                  setState(() {
                    selectedFolderId = selectedFolderId == folderId ? null : folderId;
                  });
                },
                isExpanded: selectedFolderId == folderId,
                workouts: workouts,
                onWorkoutTap: (workout) {
                  widget.onNavigate('workout-detail', {'workout': workout});
                },
                planId: folderId,
                onRemoveWorkout: (workout) => _removeWorkoutFromPlan(
                  workout,
                  folderId,
                  folder['name'] as String,
                ),
                isFavorite: folder['is_favorite'] == true,
                onToggleFavorite: () async {
                  final currentFavorite = folder['is_favorite'] == true;
                  await _supabaseService.togglePlanFavorite(
                    folderId,
                    !currentFavorite,
                  );
                  _loadFoldersAndWorkouts();
                },
                onEditPlan: () {
                  _showEditPlanDialog(folder);
                },
                onAddWorkout: () {
                  _showAddWorkoutDialog(folderId, folder['name'] as String);
                },
                onDeletePlan: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Plan'),
                      content: Text(
                        'Are you sure you want to delete "${folder['name']}"?\n\nWorkouts in this plan will be moved to Unorganized.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await _supabaseService.deleteFolder(folderId);
                    _loadFoldersAndWorkouts();
                  }
                },
                colorScheme: colorScheme,
                textTheme: textTheme,
                lastWorkoutTime: folder['last_workout_time'] as String?, // Add this field from folder data
              ),
            );
          }),
          ],

          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildExamplePlansCard(colorScheme, textTheme),
          ),

          // Empty state
          if (folders.isEmpty && (workoutsByFolder[null]?.isEmpty ?? true))
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 80,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Workout Plans Yet',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create workout plans to organize your routines',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _showCreatePlanDialog,
                      icon: const Icon(Icons.create_new_folder),
                      label: const Text('Create Plan'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddWorkoutDialog extends StatefulWidget {
  final String planId;
  final String planName;
  final List<Map<String, dynamic>> allWorkouts;
  final Set<String> initialAddedWorkoutIds;
  final VoidCallback onWorkoutsAdded;
  final Function(String, [Map<String, dynamic>?]) onNavigate;

  const _AddWorkoutDialog({
    required this.planId,
    required this.planName,
    required this.allWorkouts,
    required this.initialAddedWorkoutIds,
    required this.onWorkoutsAdded,
    required this.onNavigate,
  });

  @override
  State<_AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<_AddWorkoutDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _addedWorkoutIds = {};
  Set<String> _addingWorkoutIds = {};

  @override
  void initState() {
    super.initState();
    _addedWorkoutIds = Set.from(widget.initialAddedWorkoutIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredWorkouts {
    if (_searchQuery.isEmpty) {
      return widget.allWorkouts;
    }
    return widget.allWorkouts.where((workout) {
      final name = (workout['name'] as String? ?? '').toLowerCase();
      final description = (workout['description'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  Future<void> _addWorkout(Map<String, dynamic> workout) async {
    final workoutId = workout['id'] as String;
    
    setState(() {
      _addingWorkoutIds.add(workoutId);
    });

    try {
      await SupabaseService.instance.addWorkoutToPlan(
        workoutId,
        widget.planId,
      );
      
      setState(() {
        _addedWorkoutIds.add(workoutId);
        _addingWorkoutIds.remove(workoutId);
      });
      
      widget.onWorkoutsAdded();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${workout['name']}" to ${widget.planName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _addingWorkoutIds.remove(workoutId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredWorkouts = _filteredWorkouts;

    return AlertDialog(
      title: Text('Add Workout to ${widget.planName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search workouts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            // Summary info
            if (filteredWorkouts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${filteredWorkouts.length} workout${filteredWorkouts.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (_addedWorkoutIds.isNotEmpty) ...[
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_addedWorkoutIds.length} added to plan',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 4),
            
            // Workout list
            Expanded(
              child: filteredWorkouts.isEmpty
                  ? Center(
                      child: _searchQuery.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center_outlined,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No workouts available',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Would you like to create a workout to add to this plan?',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onNavigate('workout-builder');
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Workout'),
                                ),
                              ],
                            )
                          : Text(
                              'No workouts found',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredWorkouts.length,
                      itemBuilder: (context, index) {
                        final workout = filteredWorkouts[index];
                        final workoutId = workout['id'] as String;
                        final exercises = workout['workout_exercises'] as List? ?? [];
                        final isAdded = _addedWorkoutIds.contains(workoutId);
                        final isAdding = _addingWorkoutIds.contains(workoutId);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: isAdded ? 0 : 1,
                          color: isAdded 
                              ? colorScheme.surfaceVariant.withOpacity(0.5)
                              : null,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAdded
                                    ? colorScheme.primaryContainer.withOpacity(0.5)
                                    : colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                size: 20,
                                color: isAdded 
                                    ? colorScheme.primary.withOpacity(0.7)
                                    : colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              workout['name'] as String,
                              style: TextStyle(
                                color: isAdded 
                                    ? colorScheme.onSurfaceVariant
                                    : null,
                                fontWeight: isAdded ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${exercises.length} exercise${exercises.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: isAdding
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : isAdded
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: colorScheme.primary.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Added',
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: colorScheme.primary,
                                        ),
                                        tooltip: 'Add to plan',
                                        onPressed: () => _addWorkout(workout),
                                      ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PlanSection extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Color color;
  final int workoutCount;
  final VoidCallback onTap;
  final bool isExpanded;
  final List<Map<String, dynamic>> workouts;
  final Function(Map<String, dynamic>) onWorkoutTap;
  final String? planId;
  final Function(Map<String, dynamic>)? onRemoveWorkout;
  final VoidCallback? onEditPlan;
  final VoidCallback? onDeletePlan;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAddWorkout;
  final bool isFavorite;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String? lastWorkoutTime; // New field for displaying time

  const _PlanSection({
    required this.title,
    this.description,
    required this.icon,
    required this.color,
    required this.workoutCount,
    required this.onTap,
    required this.isExpanded,
    required this.workouts,
    required this.onWorkoutTap,
    this.planId,
    this.onRemoveWorkout,
    this.onEditPlan,
    this.onDeletePlan,
    this.onToggleFavorite,
    this.onAddWorkout,
    this.isFavorite = false,
    required this.colorScheme,
    required this.textTheme,
    this.lastWorkoutTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icon on the left
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and subtitle in the middle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description ?? '$workoutCount exercise${workoutCount != 1 ? 's' : ''} • ${lastWorkoutTime ?? 'Never completed'}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Time/Actions on the right
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Display time if available
                      if (lastWorkoutTime != null)
                        Text(
                          lastWorkoutTime!.split(' ').last, // Show just the time part
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Action buttons row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onToggleFavorite != null)
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.star : Icons.star_border,
                                color: isFavorite ? Colors.amber : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: onToggleFavorite,
                              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (onEditPlan != null)
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: onEditPlan,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          if (onDeletePlan != null)
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 20,
                                color: colorScheme.error,
                              ),
                              onPressed: onDeletePlan,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && workouts.isNotEmpty) ...[
            const Divider(height: 1),
            ...workouts.map((workout) {
              final exercises = (workout['workout_exercises'] as List?)?.length ?? 0;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(workout['name'] as String),
                subtitle: Text(
                  '$exercises exercise${exercises == 1 ? '' : 's'}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: onRemoveWorkout != null
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Remove from plan',
                        color: colorScheme.error,
                        onPressed: () => onRemoveWorkout!(workout),
                      )
                    : null,
                onTap: () => onWorkoutTap(workout),
              );
            }),
            if (onAddWorkout != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: onAddWorkout,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Workout'),
                  ),
                ),
              ),
            ],
          ],
          if (isExpanded && workouts.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No workouts in this plan yet',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Would you like to add an existing workout or create a new one?',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onAddWorkout != null) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onAddWorkout,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Workout'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
