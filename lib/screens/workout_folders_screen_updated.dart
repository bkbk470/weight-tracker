// This file shows the changes needed for workout_folders_screen.dart
// Replace the existing functions and classes with these updated versions

// 1. REPLACE _showMoveWorkoutDialog with _removeWorkoutFromPlan:

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

// 2. UPDATE the _PlanSection calls in build():

// For Unorganized section (around line 718):
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
            ),

// For regular plans (around line 742):
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

// 3. UPDATE _PlanSection class definition (around line 1205):

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
  });

// 4. UPDATE the workout ListTile in _PlanSection's build method (around line 1287):

          if (isExpanded && workouts.isNotEmpty) ...[
            const Divider(height: 1),
            ...workouts.map((workout) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  title: Text(workout['name'] as String),
                  subtitle: Text(
                    '${(workout['workout_exercises'] as List?)?.length ?? 0} exercises',
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
                )),
