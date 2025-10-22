import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  final void Function(String, [Map<String, dynamic>?])? onNavigate;

  const WorkoutHistoryScreen({super.key, this.onNavigate});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<Map<String, dynamic>> workouts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreWorkouts = true;
  String? error;
  
  static const int _pageSize = 20;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        workouts.clear();
        hasMoreWorkouts = true;
        isLoading = true;
        error = null;
      });
    } else {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    try {
      final data = await SupabaseService.instance.getWorkoutLogs(limit: _pageSize);
      
      if (!mounted) return;
      
      setState(() {
        workouts = data;
        isLoading = false;
        hasMoreWorkouts = data.length >= _pageSize;
        _currentPage = 0;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreWorkouts() async {
    if (isLoadingMore || !hasMoreWorkouts) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      // Get the oldest workout's timestamp to use as cursor
      DateTime? oldestDate;
      if (workouts.isNotEmpty) {
        final oldestWorkout = workouts.last;
        final dateStr = oldestWorkout['start_time'] as String?;
        if (dateStr != null) {
          oldestDate = DateTime.tryParse(dateStr);
        }
      }

      // Fetch next page
      final data = await SupabaseService.instance.getWorkoutLogs(
        limit: _pageSize,
        endDate: oldestDate,
      );

      if (!mounted) return;

      setState(() {
        // Filter out any duplicates (workout with same start_time as cursor)
        final newWorkouts = data.where((newWorkout) {
          final newDate = newWorkout['start_time'] as String?;
          return !workouts.any((existing) => existing['start_time'] == newDate);
        }).toList();

        workouts.addAll(newWorkouts);
        hasMoreWorkouts = data.length >= _pageSize;
        _currentPage++;
        isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isLoadingMore = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading more workouts: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '0:00';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$month/$day/${date.year} $hour:$minute';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!('profile');
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text('Workout History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadWorkouts(refresh: true),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Workouts',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _loadWorkouts(refresh: true),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : workouts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              size: 80,
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Workouts Yet',
                              style: textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete your first workout to see it here!',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadWorkouts(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: workouts.length + (hasMoreWorkouts ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Load More button at the end
                          if (index == workouts.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton.icon(
                                        onPressed: _loadMoreWorkouts,
                                        icon: const Icon(Icons.expand_more),
                                        label: Text('Load More (${workouts.length} loaded)'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          }

                          final workout = workouts[index];
                          final rawSets = (workout['exercise_sets'] as List?)
                                  ?.whereType<Map<String, dynamic>>()
                                  .toList() ??
                              <Map<String, dynamic>>[];

                          final Map<String, List<Map<String, dynamic>>> setsByExercise =
                              {};
                          final Map<String, String> exerciseNames = {};
                          final List<String> exerciseOrder = [];

                          for (final set in rawSets) {
                            final key =
                                (set['exercise_id'] ?? set['exercise_name'] ?? 'exercise_${exerciseOrder.length}')
                                    .toString();
                            if (!setsByExercise.containsKey(key)) {
                              setsByExercise[key] = [];
                              exerciseOrder.add(key);
                            }
                            setsByExercise[key]!.add(set);
                            exerciseNames[key] =
                                (set['exercise_name'] as String?) ?? exerciseNames[key] ?? 'Exercise';
                          }

                          for (final key in exerciseOrder) {
                            setsByExercise[key]!.sort((a, b) {
                              final aNumber = (a['set_number'] is num)
                                  ? (a['set_number'] as num).toInt()
                                  : int.tryParse('${a['set_number'] ?? ''}') ?? 0;
                              final bNumber = (b['set_number'] is num)
                                  ? (b['set_number'] as num).toInt()
                                  : int.tryParse('${b['set_number'] ?? ''}') ?? 0;
                              return aNumber.compareTo(bNumber);
                            });
                          }
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                workout['workout_name'] ?? 'Workout',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                        _formatDate(workout['start_time']),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Duration: ${_formatDuration(workout['duration_seconds'])}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.numbers,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${rawSets.length} sets',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                if (rawSets.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No sets recorded',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Exercise Sets',
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ...exerciseOrder.map((groupKey) {
                                          final exerciseName =
                                              exerciseNames[groupKey] ?? 'Exercise';
                                          final exerciseSets = setsByExercise[groupKey] ?? [];

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceVariant.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      exerciseName,
                                                      style: textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      '${exerciseSets.length} set${exerciseSets.length == 1 ? '' : 's'}',
                                                      style: textTheme.bodySmall?.copyWith(
                                                        color: colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Column(
                                                  children: [
                                                    for (var i = 0;
                                                        i < exerciseSets.length;
                                                        i++)
                                                      Padding(
                                                        padding: EdgeInsets.only(
                                                          bottom: i == exerciseSets.length - 1
                                                              ? 0
                                                              : 10,
                                                        ),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.surfaceVariant
                                                                .withOpacity(0.35),
                                                            borderRadius:
                                                                BorderRadius.circular(12),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              final set = exerciseSets[i];
                                                              final setNumber =
                                                                  (set['set_number'] is num)
                                                                      ? (set['set_number'] as num)
                                                                          .toInt()
                                                                      : int.tryParse(
                                                                              '${set['set_number'] ?? ''}') ??
                                                                          i + 1;
                                                              final weight = set['weight_lbs'];
                                                              final reps = set['reps'];
                                                              final weightDisplay = weight is num
                                                                  ? (weight % 1 == 0
                                                                      ? weight
                                                                          .toStringAsFixed(0)
                                                                      : weight
                                                                          .toStringAsFixed(1))
                                                                  : (weight?.toString() ?? '0');
                                                              final repsDisplay = reps is num
                                                                  ? reps.toInt().toString()
                                                                  : (reps?.toString() ?? '0');
                                                              final notes =
                                                                  (set['notes'] as String?)
                                                                      ?.trim();
                                                              Container(
                                                                width: 40,
                                                                height: 40,
                                                                decoration: BoxDecoration(
                                                                  color: colorScheme
                                                                      .secondaryContainer,
                                                                  borderRadius:
                                                                      BorderRadius.circular(8),
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    '$setNumber',
                                                                    style: textTheme.labelLarge
                                                                        ?.copyWith(
                                                                      color: colorScheme
                                                                          .onSecondaryContainer,
                                                                      fontWeight:
                                                                          FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      '$weightDisplay lbs × $repsDisplay reps',
                                                                      style: textTheme.bodyMedium
                                                                          ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                    if (notes != null &&
                                                                        notes.isNotEmpty)
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(
                                                                          top: 4,
                                                                        ),
                                                                        child: Text(
                                                                          notes,
                                                                          style: textTheme.bodySmall
                                                                              ?.copyWith(
                                                                            color: colorScheme
                                                                                .onSurfaceVariant,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                              if (set['completed'] == true)
                                                                Icon(
                                                                  Icons.check_circle,
                                                                  color:
                                                                      colorScheme.secondary,
                                                                  size: 20,
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
