import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/exercise_assets.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseService._();

  final Map<String, _SignedUrlCacheEntry> _signedUrlCache = {};

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Get current user
  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => currentUser?.id;

  // ==================== AUTHENTICATION ====================

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Get auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ==================== PROFILE ====================

  // Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUserId == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', currentUserId!)
        .single();

    return response;
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    await client.from('profiles').update(updates).eq('id', currentUserId!);
  }

  // ==================== EXERCISES ====================

  // Get all exercises (default + custom)
  Future<List<Map<String, dynamic>>> getExercises() async {
    if (currentUserId == null) return [];

    final response = await client
        .from('exercises')
        .select()
        .or('is_default.eq.true,user_id.eq.$currentUserId')
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  // Get exercises by category
  Future<List<Map<String, dynamic>>> getExercisesByCategory(
      String category) async {
    if (currentUserId == null) return [];

    final response = await client
        .from('exercises')
        .select()
        .eq('category', category)
        .or('is_default.eq.true,user_id.eq.$currentUserId')
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  // Create custom exercise
  Future<Map<String, dynamic>> createExercise({
    required String name,
    required String category,
    required String difficulty,
    required String equipment,
    String? notes,
    String? imageUrl,
    bool isDefault = false, // Add this parameter
  }) async {
    if (currentUserId == null && !isDefault) throw Exception('Not authenticated');

    final response = await client
        .from('exercises')
        .insert({
          // Only add user_id if NOT a default exercise
          if (!isDefault) 'user_id': currentUserId,
          'name': name,
          'category': category,
          'difficulty': difficulty,
          'equipment': equipment,
          'notes': notes,
          'is_custom': !isDefault,
          'is_default': isDefault,
          'image_url': (imageUrl != null && imageUrl.isNotEmpty)
              ? imageUrl
              : kExercisePlaceholderImage,
        })
        .select()
        .single();

    return response;
  }

  Future<String> getSignedUrlForStoragePath(
    String storagePath, {
    Duration validFor = const Duration(minutes: 55),
  }) async {
    final now = DateTime.now();
    final cached = _signedUrlCache[storagePath];
    if (cached != null && now.isBefore(cached.expiresAt)) {
      return cached.url;
    }

    final firstSlash = storagePath.indexOf('/');
    if (firstSlash <= 0 || firstSlash >= storagePath.length - 1) {
      throw ArgumentError(
          'Storage path must be in the format "bucket/object". Received: $storagePath');
    }

    final bucket = storagePath.substring(0, firstSlash);
    final objectPath = storagePath.substring(firstSlash + 1);
    final signedUrl = await client.storage
        .from(bucket)
        .createSignedUrl(objectPath, validFor.inSeconds);

    final expiresAt = now.add(validFor);
    _signedUrlCache[storagePath] = _SignedUrlCacheEntry(signedUrl, expiresAt);
    return signedUrl;
  }

  /// Find an exercise ID by name or create one if it does not exist.
  Future<String> getOrCreateExerciseId({
    required String name,
    String category = 'Other',
    String difficulty = 'Intermediate',
    String equipment = 'Bodyweight',
    String? notes,
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    // Attempt to find an existing exercise (default or custom) by name
    final existing = await client
        .from('exercises')
        .select('id')
        .eq('name', name)
        .limit(1)
        .maybeSingle();

    if (existing != null && existing['id'] != null) {
      return existing['id'] as String;
    }

    // Create a new custom exercise if none was found
    final created = await createExercise(
      name: name,
      category: category,
      difficulty: difficulty,
      equipment: equipment,
      notes: notes,
    );

    return created['id'] as String;
  }

  // Update custom exercise
  Future<void> updateExercise(
      String exerciseId, Map<String, dynamic> updates) async {
    await client.from('exercises').update(updates).eq('id', exerciseId);
  }

  // Delete custom exercise
  Future<void> deleteExercise(String exerciseId) async {
    await client.from('exercises').delete().eq('id', exerciseId);
  }

  // ==================== WORKOUT PLANS ====================

  // Get all plans for the current user
  Future<List<Map<String, dynamic>>> getWorkoutFolders() async {
    if (currentUserId == null) return [];

    try {
      final response = await client
          .from('workout_plans')
          .select()
          .eq('user_id', currentUserId!)
          .order('is_favorite', ascending: false) // Favorites first
          .order('order_index', ascending: true); // Then by order
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching plans: $e');
      return [];
    }
  }

  // Update plan order
  Future<void> updatePlanOrder(String planId, int newOrderIndex) async {
    await client
        .from('workout_plans')
        .update({'order_index': newOrderIndex})
        .eq('id', planId);
  }

  // Reorder plans - updates all plans with new order
  Future<void> reorderPlans(List<Map<String, dynamic>> orderedPlans) async {
    // Update each plan with its new order index
    for (int i = 0; i < orderedPlans.length; i++) {
      final plan = orderedPlans[i];
      final dynamic planId = plan['id'];

      if (planId == null) {
        // Skip if the plan does not have an identifier (shouldn't happen, but guards against crashes)
        print('Skipping plan at index $i because its id is null');
        continue;
      }

      await updatePlanOrder(planId.toString(), i);
    }
  }

  // Get only favorite plans
  Future<List<Map<String, dynamic>>> getFavoritePlans() async {
    if (currentUserId == null) return [];

    try {
      final response = await client
          .from('workout_plans')
          .select()
          .eq('user_id', currentUserId!)
          .eq('is_favorite', true)
          .order('order_index', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching favorite plans: $e');
      return [];
    }
  }

  // Create a new plan
  Future<Map<String, dynamic>> createFolder({
    required String name,
    String? description,
    String? color,
    String? icon,
    String? parentFolderId,
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    final data = {
      'user_id': currentUserId,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'parent_plan_id': parentFolderId,
    };

    final response = await client
        .from('workout_plans')
        .insert(data)
        .select()
        .single();

    return response;
  }

  // Update plan
  Future<void> updateFolder(String folderId, Map<String, dynamic> updates) async {
    await client
        .from('workout_plans')
        .update(updates)
        .eq('id', folderId);
  }

  // Toggle plan favorite status
  Future<void> togglePlanFavorite(String planId, bool isFavorite) async {
    await client
        .from('workout_plans')
        .update({'is_favorite': isFavorite})
        .eq('id', planId);
  }

  // Delete plan
  Future<void> deleteFolder(String folderId) async {
    await client
        .from('workout_plans')
        .delete()
        .eq('id', folderId);
  }

  // Move workout to plan (legacy - keeps plan_id for primary plan)
  Future<void> moveWorkoutToFolder(String workoutId, String? folderId) async {
    await client
        .from('workouts')
        .update({'plan_id': folderId})
        .eq('id', workoutId);
  }

  // Add workout to plan (many-to-many)
  Future<void> addWorkoutToPlan(String workoutId, String planId) async {
    await client
        .from('workout_plan_workouts')
        .insert({
          'workout_id': workoutId,
          'workout_plan_id': planId,
        });
  }

  // Remove workout from plan (many-to-many)
  Future<void> removeWorkoutFromPlan(String workoutId, String planId) async {
    await client
        .from('workout_plan_workouts')
        .delete()
        .eq('workout_id', workoutId)
        .eq('workout_plan_id', planId);
  }

  // Get all plans that contain a specific workout
  Future<List<Map<String, dynamic>>> getPlansForWorkout(String workoutId) async {
    try {
      final response = await client
          .from('workout_plan_workouts')
          .select('workout_plan_id, workout_plans(*)')
          .eq('workout_id', workoutId);
      
      return List<Map<String, dynamic>>.from(
        response.map((item) => item['workout_plans'] as Map<String, dynamic>)
      );
    } catch (e) {
      print('Error fetching plans for workout: $e');
      return [];
    }
  }

  // Get workouts by plan (using many-to-many relationship)
  Future<List<Map<String, dynamic>>> getWorkoutsByFolder(String? folderId) async {
    if (currentUserId == null) return [];

    try {
      if (folderId != null) {
        // Get workouts in this plan via junction table
        // OPTIMIZED: Only fetch basic workout info, not full exercise details
        final response = await client
            .from('workout_plan_workouts')
            .select('''
              workout_id,
              workouts (
                id,
                name,
                description,
                difficulty,
                estimated_duration_minutes,
                is_favorite,
                created_at,
                updated_at
              )
            ''')
            .eq('workout_plan_id', folderId)
            .order('order_index', ascending: true);

        return List<Map<String, dynamic>>.from(
          response.map((item) => item['workouts'] as Map<String, dynamic>)
        );
      } else {
        // Get workouts not in any plan (orphaned workouts)
        // First, get all workout IDs that are in plans
        final workoutsInPlans = await client
            .from('workout_plan_workouts')
            .select('workout_id');

        final workoutIdsInPlans = workoutsInPlans
            .map((item) => item['workout_id'] as String)
            .toSet();

        // Then fetch all user's workouts
        final allWorkouts = await client
            .from('workouts')
            .select('''
              id,
              name,
              description,
              difficulty,
              estimated_duration_minutes,
              is_favorite,
              created_at,
              updated_at
            ''')
            .eq('user_id', currentUserId!)
            .order('created_at', ascending: false);

        // Filter out workouts that are in plans
        final unorganizedWorkouts = allWorkouts
            .where((workout) => !workoutIdsInPlans.contains(workout['id']))
            .toList();

        return List<Map<String, dynamic>>.from(unorganizedWorkouts);
      }
    } catch (e) {
      print('Error fetching workouts by plan: $e');
      return [];
    }
  }

  // OPTIMIZED: Batch load all workouts for all folders in one query
  Future<Map<String, List<Map<String, dynamic>>>> getAllWorkoutsByFolders(List<String> folderIds) async {
    if (currentUserId == null || folderIds.isEmpty) return {};

    try {
      // Single query to get all workouts for all folders
      final response = await client
          .from('workout_plan_workouts')
          .select('''
            workout_plan_id,
            order_index,
            workouts (
              id,
              name,
              description,
              difficulty,
              estimated_duration_minutes,
              is_favorite,
              created_at,
              updated_at
            )
          ''')
          .inFilter('workout_plan_id', folderIds)
          .order('order_index', ascending: true);

      // Group workouts by folder
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var folderId in folderIds) {
        grouped[folderId] = [];
      }

      for (var item in response) {
        final folderId = item['workout_plan_id'] as String;
        final workout = item['workouts'] as Map<String, dynamic>;
        if (grouped.containsKey(folderId)) {
          grouped[folderId]!.add(workout);
        }
      }

      return grouped;
    } catch (e) {
      print('Error batch loading workouts: $e');
      return {};
    }
  }

  // OPTIMIZED: Batch load last workout dates for multiple workouts in one query
  Future<Map<String, DateTime?>> getLastWorkoutDates(List<String> workoutIds) async {
    if (currentUserId == null || workoutIds.isEmpty) return {};

    try {
      final response = await client
          .from('workout_logs')
          .select('workout_id, start_time')
          .inFilter('workout_id', workoutIds)
          .eq('user_id', currentUserId!)
          .order('start_time', ascending: false);

      // Get the most recent date for each workout
      final Map<String, DateTime?> lastDates = {};
      for (var log in response) {
        final workoutId = log['workout_id'] as String;
        if (!lastDates.containsKey(workoutId)) {
          final startTime = log['start_time'] as String?;
          lastDates[workoutId] = startTime != null ? DateTime.parse(startTime) : null;
        }
      }

      // Fill in null for workouts with no logs
      for (var workoutId in workoutIds) {
        lastDates.putIfAbsent(workoutId, () => null);
      }

      return lastDates;
    } catch (e) {
      print('Error batch loading last workout dates: $e');
      return {};
    }
  }

  // ==================== WORKOUTS (TEMPLATES) ====================

  // Get all workouts
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    if (currentUserId == null) return [];

    final response = await client
        .from('workouts')
        .select('''
          *,
          workout_exercises (
            *,
            exercise:exercises (*)
          )
        ''')
        .eq('user_id', currentUserId!)
        .order('order_index', ascending: true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update workout order
  Future<void> updateWorkoutOrder(String workoutId, int newOrderIndex) async {
    await client
        .from('workouts')
        .update({'order_index': newOrderIndex})
        .eq('id', workoutId);
  }

  // Reorder workouts - updates all workouts with new order
  Future<void> reorderWorkouts(List<Map<String, dynamic>> orderedWorkouts) async {
    // Update each workout with its new order index
    for (int i = 0; i < orderedWorkouts.length; i++) {
      final workoutId = orderedWorkouts[i]['id'] as String;
      await updateWorkoutOrder(workoutId, i);
    }
  }

  // Get all workout templates (public templates available to all users)
  Future<List<Map<String, dynamic>>> getWorkoutTemplates() async {
    final response = await client
        .from('workout_templates')
        .select('''
          *,
          workout_template_exercises (
            *,
            exercise:exercises (*)
          )
        ''')
        .order('is_featured', ascending: false)
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get featured workout templates
  Future<List<Map<String, dynamic>>> getFeaturedWorkoutTemplates() async {
    final response = await client.from('workout_templates').select('''
          *,
          workout_template_exercises (
            *,
            exercise:exercises (*)
          )
        ''').eq('is_featured', true).order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get workout templates by category
  Future<List<Map<String, dynamic>>> getWorkoutTemplatesByCategory(
      String category) async {
    final response = await client.from('workout_templates').select('''
          *,
          workout_template_exercises (
            *,
            exercise:exercises (*)
          )
        ''').eq('category', category).order('difficulty', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get workout templates by difficulty
  Future<List<Map<String, dynamic>>> getWorkoutTemplatesByDifficulty(
      String difficulty) async {
    final response = await client.from('workout_templates').select('''
          *,
          workout_template_exercises (
            *,
            exercise:exercises (*)
          )
        ''').eq('difficulty', difficulty).order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get single workout template
  Future<Map<String, dynamic>?> getWorkoutTemplate(String templateId) async {
    try {
      final response = await client.from('workout_templates').select('''
            *,
            workout_template_exercises (
              *,
              exercise:exercises (*)
            )
          ''').eq('id', templateId).maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching workout template: $e');
      return null;
    }
  }

  // Duplicate a workout template as a user workout
  Future<Map<String, dynamic>> duplicateTemplateToWorkout(
      String templateId) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    // Fetch the template
    final template = await getWorkoutTemplate(templateId);
    if (template == null) throw Exception('Template not found');

    // Create a new user workout from the template
    final originalName = (template['name'] as String?) ?? 'Workout Template';
    final duplicateName = originalName.startsWith('Copy of ')
        ? originalName
        : 'Copy of $originalName';

    final newWorkout = await createWorkout(
      name: duplicateName,
      description: template['description'] as String?,
      difficulty: template['difficulty'] as String?,
      estimatedDurationMinutes: template['estimated_duration_minutes'] as int?,
    );

    // Copy all exercises from the template
    final templateExercises =
        template['workout_template_exercises'] as List? ?? [];
    for (var i = 0; i < templateExercises.length; i++) {
      final exercise = templateExercises[i] as Map<String, dynamic>;
      final exerciseData = exercise['exercise'] as Map<String, dynamic>?;
      final exerciseId =
          exercise['exercise_id'] as String? ?? exerciseData?['id'] as String?;

      if (exerciseId != null) {
        await addExerciseToWorkout(
          workoutId: newWorkout['id'] as String,
          exerciseId: exerciseId,
          orderIndex: i,
          targetSets: exercise['target_sets'] as int? ?? 3,
          targetReps: exercise['target_reps'] as int? ?? 10,
          restTimeSeconds: exercise['rest_time_seconds'] as int? ?? 90,
          notes: exercise['notes'] as String?,
        );
      }
    }

    // Fetch the complete workout with exercises to return
    final completeWorkout = await getWorkout(newWorkout['id'] as String);
    return completeWorkout ?? newWorkout;
  }

  // Get single workout
  Future<Map<String, dynamic>?> getWorkout(String workoutId) async {
    try {
      final response = await client.from('workouts').select('''
            *,
            workout_exercises (
              *,
              exercise:exercises (*)
            )
          ''').eq('id', workoutId).maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching workout: $e');
      return null;
    }
  }

  // Create workout
  Future<Map<String, dynamic>> createWorkout({
    required String name,
    String? description,
    String? difficulty,
    int? estimatedDurationMinutes,
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    final response = await client
        .from('workouts')
        .insert({
          'user_id': currentUserId,
          'name': name,
          'description': description,
          'difficulty': difficulty,
          'estimated_duration_minutes': estimatedDurationMinutes,
        })
        .select()
        .single();

    return response;
  }

  // Update workout
  Future<void> updateWorkout(
      String workoutId, Map<String, dynamic> updates) async {
    await client.from('workouts').update(updates).eq('id', workoutId);
  }

  // Delete workout
  Future<void> deleteWorkout(String workoutId) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    await client
        .from('workouts')
        .delete()
        .eq('id', workoutId)
        .eq('user_id', currentUserId!);
  }

  // Add exercise to workout
  Future<Map<String, dynamic>> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    required int orderIndex,
    int targetSets = 3,
    int targetReps = 10,
    int restTimeSeconds = 90,
    String? notes,
  }) async {
    final response = await client
        .from('workout_exercises')
        .insert({
          'workout_id': workoutId,
          'exercise_id': exerciseId,
          'order_index': orderIndex,
          'target_sets': targetSets,
          'target_reps': targetReps,
          'rest_time_seconds': restTimeSeconds,
          'notes': notes,
        })
        .select()
        .single();

    return response;
  }

  // Remove exercise from workout
  Future<void> removeExerciseFromWorkout(String workoutExerciseId) async {
    await client.from('workout_exercises').delete().eq('id', workoutExerciseId);
  }

  Future<Map<String, dynamic>?> getWorkoutExerciseRow({
    required String workoutId,
    String? workoutExerciseId,
    String? exerciseId,
    int? orderIndex,
  }) async {
    if (workoutExerciseId != null) {
      return await client
          .from('workout_exercises')
          .select()
          .eq('id', workoutExerciseId)
          .maybeSingle();
    }

    if (exerciseId == null) return null;

    var query = client
        .from('workout_exercises')
        .select()
        .eq('workout_id', workoutId)
        .eq('exercise_id', exerciseId);

    if (orderIndex != null) {
      query = query.eq('order_index', orderIndex);
    }

    return await query.maybeSingle();
  }

  // ==================== WORKOUT LOGS ====================

  // Get workout logs
  Future<List<Map<String, dynamic>>> getWorkoutLogs({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    if (currentUserId == null) return [];

    var query = client.from('workout_logs').select('''
          *,
          exercise_sets (*)
        ''').eq('user_id', currentUserId!);

    if (startDate != null) {
      query = query.gte('start_time', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('start_time', endDate.toIso8601String());
    }

    final response =
        await query.order('start_time', ascending: false).limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  // Create workout log
  Future<Map<String, dynamic>> createWorkoutLog({
    String? workoutId,
    required String workoutName,
    required DateTime startTime,
    DateTime? endTime,
    int? durationSeconds,
    String? notes,
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    final response = await client
        .from('workout_logs')
        .insert({
          'user_id': currentUserId,
          'workout_id': workoutId,
          'workout_name': workoutName,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime?.toIso8601String(),
          'duration_seconds': durationSeconds,
          'notes': notes,
        })
        .select()
        .single();

    return response;
  }

  // Update workout log
  Future<void> updateWorkoutLog(
      String logId, Map<String, dynamic> updates) async {
    await client.from('workout_logs').update(updates).eq('id', logId);
  }

  // Delete workout log
  Future<void> deleteWorkoutLog(String logId) async {
    await client.from('workout_logs').delete().eq('id', logId);
  }

  Future<void> updateWorkoutExercise(
      String workoutExerciseId, Map<String, dynamic> updates) async {
    await client
        .from('workout_exercises')
        .update(updates)
        .eq('id', workoutExerciseId);
  }

  // Add exercise set to workout log
  Future<void> addExerciseSet({
    required String workoutLogId,
    required String exerciseId,
    required String exerciseName,
    required int setNumber,
    double? weightLbs,
    int? reps,
    bool completed = true,
    int? restTimeSeconds,
    String? notes,
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    await client
        .from('exercise_sets')
        .insert({
          'workout_log_id': workoutLogId,
          'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'set_number': setNumber,
          'weight_lbs': weightLbs,
          'reps': reps,
          'completed': completed,
          'rest_time_seconds': restTimeSeconds,
          'notes': notes,
        })
        .select()
        .single(); // ✅ optional, confirm success
  }

  // ==================== MEASUREMENTS ====================

  // Get measurements by type
  Future<List<Map<String, dynamic>>> getMeasurements(String type,
      {String? notes}) async {
    if (currentUserId == null) return [];

    var query = client
        .from('measurements')
        .select()
        .eq('user_id', currentUserId!)
        .eq('measurement_type', type);
    if (notes != null) {
      query = query.eq('notes', notes);
    }
    final response = await query.order('measurement_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get all measurements
  Future<List<Map<String, dynamic>>> getAllMeasurements() async {
    if (currentUserId == null) return [];

    final response = await client
        .from('measurements')
        .select()
        .eq('user_id', currentUserId!)
        .order('measurement_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get latest measurement by type
  Future<Map<String, dynamic>?> getLatestMeasurement(String type,
      {String? notes}) async {
    if (currentUserId == null) return null;

    var query = client
        .from('measurements')
        .select()
        .eq('user_id', currentUserId!)
        .eq('measurement_type', type);
    if (notes != null) {
      query = query.eq('notes', notes);
    }
    final response = await query
        .order('measurement_date', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  // Add measurement
  Future<Map<String, dynamic>> addMeasurement({
    required String measurementType,
    required double value,
    required String unit,
    required DateTime measurementDate,
    String? notes,
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    final response = await client
        .from('measurements')
        .insert({
          'user_id': currentUserId,
          'measurement_type': measurementType,
          'value': value,
          'unit': unit,
          'measurement_date': measurementDate.toIso8601String(),
          'notes': notes,
        })
        .select()
        .single();

    return response;
  }

  Future<List<Map<String, dynamic>>> getLatestExerciseSetsForExercise(
      String exerciseId,
      {int historyLimit = 30}) async {
    if (currentUserId == null) return [];

    final response = await client
        .from('exercise_sets')
        .select(
            'id, workout_log_id, set_number, weight_lbs, reps, rest_time_seconds, created_at, workout_logs!inner(user_id)')
        .eq('exercise_id', exerciseId)
        .eq('workout_logs.user_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(historyLimit);

    final List<Map<String, dynamic>> data =
        List<Map<String, dynamic>>.from(response);
    if (data.isEmpty) return data;

    final latestLogId = data.first['workout_log_id'];
    final filtered = data
        .where((record) => record['workout_log_id'] == latestLogId)
        .toList();
    filtered.sort((a, b) {
      final aSet = a['set_number'];
      final bSet = b['set_number'];
      final aVal =
          aSet is int ? aSet : int.tryParse(aSet?.toString() ?? '') ?? 0;
      final bVal =
          bSet is int ? bSet : int.tryParse(bSet?.toString() ?? '') ?? 0;
      return aVal.compareTo(bVal);
    });

    return filtered.map((record) {
      final map = Map<String, dynamic>.from(record);
      map.remove('workout_logs');
      return map;
    }).toList();
  }

  // Update measurement
  Future<void> updateMeasurement(
      String measurementId, Map<String, dynamic> updates) async {
    await client.from('measurements').update(updates).eq('id', measurementId);
  }

  // Delete measurement
  Future<void> deleteMeasurement(String measurementId) async {
    await client.from('measurements').delete().eq('id', measurementId);
  }

  // ==================== USER SETTINGS ====================

  // Get user settings
  Future<Map<String, dynamic>?> getUserSettings() async {
    if (currentUserId == null) return null;

    final response = await client
        .from('user_settings')
        .select()
        .eq('user_id', currentUserId!)
        .maybeSingle();

    return response;
  }

  // Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    await client
        .from('user_settings')
        .update(updates)
        .eq('user_id', currentUserId!);
  }

  Future<void> upsertUserSettings(Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    final payload = Map<String, dynamic>.from(updates);
    payload['user_id'] = currentUserId!;
    await client.from('user_settings').upsert(payload, onConflict: 'user_id');
  }

  // ==================== STATISTICS ====================

  // Get total workouts count
  Future<int> getTotalWorkoutsCount() async {
    if (currentUserId == null) return 0;

    final response = await client
        .from('workout_logs')
        .select('id')
        .eq('user_id', currentUserId!);

    return (response as List).length;
  }

  // Get workout history for date range
  Future<List<Map<String, dynamic>>> getWorkoutHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (currentUserId == null) return [];

    final response = await client
        .from('workout_logs')
        .select()
        .eq('user_id', currentUserId!)
        .gte('start_time', startDate.toIso8601String())
        .lte('start_time', endDate.toIso8601String())
        .order('start_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}

class _SignedUrlCacheEntry {
  _SignedUrlCacheEntry(this.url, this.expiresAt);

  final String url;
  final DateTime expiresAt;
}
