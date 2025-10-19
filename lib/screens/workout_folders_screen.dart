import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

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
  bool isLoading = true;
  String? selectedFolderId;

  @override
  void initState() {
    super.initState();
    _loadFoldersAndWorkouts();
  }

  Future<void> _loadFoldersAndWorkouts() async {
    setState(() => isLoading = true);

    try {
      // Load plans
      final loadedFolders = await _supabaseService.getWorkoutFolders();
      
      // Load all workouts
      final allWorkouts = await _supabaseService.getWorkouts();
      
      // Group workouts by plan
      final Map<String?, List<Map<String, dynamic>>> grouped = {};
      grouped[null] = []; // Default "Unorganized" bucket for workouts without a plan
      
      for (var folder in loadedFolders) {
        grouped[folder['id'] as String] = [];
      }
      
      for (var workout in allWorkouts) {
        final folderId = workout['plan_id'] as String?;
        if (grouped.containsKey(folderId)) {
          grouped[folderId]!.add(workout);
        } else {
          grouped[null]!.add(workout);
        }
      }

      setState(() {
        folders = loadedFolders;
        workoutsByFolder = grouped;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading plans: $e');
      setState(() => isLoading = false);
    }
  }

  void _showCreatePlanDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedColor = 'blue';
    String selectedIcon = 'folder';

    showDialog(
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
                  decoration: const InputDecoration(
                    labelText: 'Plan Name',
                    hintText: 'e.g., Strength Training, Cardio Mix',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of this plan',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Color selection
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
              onMoveWorkout: _showMoveWorkoutDialog,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
          ],

          // Workout Plans
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
                onMoveWorkout: _showMoveWorkoutDialog,
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
                  // TODO: Implement edit plan
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
              ),
            );
          }),

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
  final Function(Map<String, dynamic>) onMoveWorkout;
  final VoidCallback? onEditPlan;
  final VoidCallback? onDeletePlan;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

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
    required this.onMoveWorkout,
    this.onEditPlan,
    this.onDeletePlan,
    this.onToggleFavorite,
    this.isFavorite = false,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: color, size: 32),
            title: Text(title, style: textTheme.titleMedium),
            subtitle: description != null
                ? Text(description!)
                : Text('$workoutCount workout${workoutCount != 1 ? 's' : ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onToggleFavorite != null)
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : null,
                      size: 20,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  ),
                if (onEditPlan != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEditPlan,
                  ),
                if (onDeletePlan != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDeletePlan,
                  ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
            onTap: onTap,
          ),
          if (isExpanded && workouts.isNotEmpty) ...[
            const Divider(height: 1),
            ...workouts.map((workout) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  title: Text(workout['name'] as String),
                  subtitle: Text(
                    '${(workout['workout_exercises'] as List?)?.length ?? 0} exercises',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.drive_file_move),
                    onPressed: () => onMoveWorkout(workout),
                  ),
                  onTap: () => onWorkoutTap(workout),
                )),
          ],
          if (isExpanded && workouts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No workouts in this plan yet',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
