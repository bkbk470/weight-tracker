/// Model representing a single exercise in a workout
class Exercise {
  final String id;
  final String name;
  final List<ExerciseSet> sets;
  int restTime;
  String notes;
  String? workoutExerciseId;
  String? supabaseExerciseId;
  int? orderIndex;
  DateTime? previousDate;

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.restTime,
    this.notes = '',
    this.workoutExerciseId,
    this.supabaseExerciseId,
    this.orderIndex,
    this.previousDate,
  });

  /// Create an Exercise from preloaded data
  factory Exercise.fromPreloadedData(
    Map<String, dynamic> data,
    int index,
  ) {
    final dynamicSetDetails = data['setDetails'];
    List<ExerciseSet> plannedSets;

    if (dynamicSetDetails is List && dynamicSetDetails.isNotEmpty) {
      plannedSets = dynamicSetDetails.map((set) {
        final weightRaw = set is Map ? set['weight'] : null;
        final repsRaw = set is Map ? set['reps'] : null;
        final restRaw = set is Map
            ? (set['rest'] ?? set['restTime'] ?? set['rest_seconds'])
            : null;

        final weight = weightRaw is num
            ? weightRaw.toInt()
            : int.tryParse('$weightRaw') ?? 0;
        final reps = repsRaw is num
            ? repsRaw.toInt()
            : int.tryParse('$repsRaw') ?? (data['reps'] ?? ExerciseDefaults.reps);
        final rest = restRaw is num
            ? restRaw.toInt()
            : int.tryParse('$restRaw') ?? (data['restTime'] ?? ExerciseDefaults.restSeconds);

        final exerciseSet = ExerciseSet(weight: weight, reps: reps);
        exerciseSet.plannedRestSeconds = rest;
        exerciseSet.restStartTime = rest;
        exerciseSet.currentRestTime = rest;
        return exerciseSet;
      }).toList();
    } else {
      final reps = data['reps'] is num
          ? (data['reps'] as num).toInt()
          : int.tryParse('${data['reps']}') ?? ExerciseDefaults.reps;
      final setsCount = data['sets'] is num
          ? (data['sets'] as num).toInt()
          : int.tryParse('${data['sets']}') ?? ExerciseDefaults.sets;
      final defaultRest = data['restTime'] is num
          ? (data['restTime'] as num).toInt()
          : int.tryParse('${data['restTime']}') ?? ExerciseDefaults.restSeconds;

      plannedSets = List.generate(setsCount, (_) {
        final set = ExerciseSet(weight: 0, reps: reps);
        set.plannedRestSeconds = defaultRest;
        set.restStartTime = defaultRest;
        set.currentRestTime = defaultRest;
        return set;
      });
    }

    return Exercise(
      id: '${DateTime.now().millisecondsSinceEpoch}_${data['name']}_$index',
      name: data['name'],
      sets: plannedSets,
      restTime: plannedSets.isNotEmpty
          ? (plannedSets.first.restStartTime > 0
              ? plannedSets.first.restStartTime
              : (data['restTime'] ?? ExerciseDefaults.restSeconds))
          : (data['restTime'] ?? ExerciseDefaults.restSeconds),
      notes: (data['notes'] as String?) ?? '',
      workoutExerciseId: data['workoutExerciseId'] as String?,
      supabaseExerciseId: data['exerciseId'] as String?,
      orderIndex: data['orderIndex'] as int?,
    );
  }

  /// Check if any set has previous data
  bool get hasPreviousData => sets.any(
        (set) => set.previousWeight != null || set.previousReps != null,
      );

  /// Get total completed sets
  int get completedSetsCount => sets.where((set) => set.completed).length;

  /// Check if all sets are completed
  bool get isFullyCompleted => sets.every((set) => set.completed);
}

/// Model representing a single set in an exercise
class ExerciseSet {
  int weight;
  int reps;
  bool completed;
  bool isResting;
  int restStartTime;
  int currentRestTime;
  double? previousWeight;
  int? previousReps;
  int plannedRestSeconds;

  ExerciseSet({
    required this.weight,
    required this.reps,
    this.completed = false,
    this.isResting = false,
    this.restStartTime = 0,
    this.currentRestTime = 0,
    this.previousWeight,
    this.previousReps,
    this.plannedRestSeconds = 0,
  });

  /// Auto-fill weight from previous session if current is zero
  void autoFillFromPrevious() {
    if (weight == 0 && previousWeight != null && previousWeight! > 0) {
      weight = previousWeight!.ceil();
    }
  }

  /// Check if this set has been improved from previous
  bool get isImprovedFromPrevious {
    if (previousWeight == null || previousReps == null) return false;

    final weightImproved = weight > previousWeight!;
    final repsImproved = weight == previousWeight!.round() && reps > previousReps!;

    return weightImproved || repsImproved;
  }
}

/// Default values for exercises
class ExerciseDefaults {
  static const int reps = 10;
  static const int sets = 3;
  static const int restSeconds = 120;
  static const int maxWeight = 9999;
  static const int maxReps = 999;
  static const int minValue = 0;
}
