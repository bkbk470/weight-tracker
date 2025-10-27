import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

/// Centralized service for managing exercise data with caching and background sync
class ExerciseCacheService {
  static const String _lastSyncKey = 'exercises_last_sync';
  static const Duration _syncInterval = Duration(hours: 24); // Sync once per day

  static ExerciseCacheService? _instance;
  static ExerciseCacheService get instance {
    _instance ??= ExerciseCacheService._();
    return _instance!;
  }

  ExerciseCacheService._();

  // In-memory cache for the current session (fastest access)
  List<Map<String, dynamic>>? _memoryCache;
  bool _isSyncing = false;

  /// Get exercises - uses memory cache > local storage > remote fetch
  Future<List<Map<String, dynamic>>> getExercises({bool forceRefresh = false}) async {
    // 1. Check memory cache first (instant)
    if (_memoryCache != null && !forceRefresh) {
      return _memoryCache!;
    }

    // 2. Load from local storage (fast - Hive)
    final localStorage = LocalStorageService.instance;
    final localExercises = localStorage.getAllExercises();

    if (localExercises.isNotEmpty && !forceRefresh) {
      _memoryCache = localExercises;

      // Trigger background sync if needed (non-blocking)
      _syncInBackgroundIfNeeded();

      return localExercises;
    }

    // 3. Fetch from remote if no local data
    return await _fetchAndCacheFromRemote();
  }

  /// Fetch from remote and update all caches
  Future<List<Map<String, dynamic>>> _fetchAndCacheFromRemote() async {
    try {
      final supabaseExercises = await SupabaseService.instance.getExercises();

      // Save to local storage
      final localStorage = LocalStorageService.instance;
      for (final exercise in supabaseExercises) {
        await localStorage.saveExercise(exercise);
      }

      // Update memory cache
      _memoryCache = supabaseExercises;

      // Update last sync timestamp
      await _updateLastSyncTime();

      return supabaseExercises;
    } catch (e) {
      print('Error fetching exercises from remote: $e');

      // Fallback to local storage
      final localStorage = LocalStorageService.instance;
      final localExercises = localStorage.getAllExercises();
      _memoryCache = localExercises;
      return localExercises;
    }
  }

  /// Sync in background if sync interval has passed
  Future<void> _syncInBackgroundIfNeeded() async {
    if (_isSyncing) return;

    final shouldSync = await _shouldSync();
    if (shouldSync) {
      _isSyncing = true;

      // Run sync in background (fire and forget)
      _fetchAndCacheFromRemote().then((_) {
        _isSyncing = false;
      }).catchError((error) {
        print('Background sync failed: $error');
        _isSyncing = false;
      });
    }
  }

  /// Check if we should sync based on last sync time
  Future<bool> _shouldSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);

      if (lastSyncStr == null) return true;

      final lastSync = DateTime.parse(lastSyncStr);
      final now = DateTime.now();

      return now.difference(lastSync) > _syncInterval;
    } catch (e) {
      print('Error checking sync time: $e');
      return true; // Sync on error
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error updating sync time: $e');
    }
  }

  /// Pre-load exercises at app startup (non-blocking)
  Future<void> preloadExercises() async {
    // Don't await - run in background
    getExercises().catchError((error) {
      print('Preload exercises failed: $error');
      return <Map<String, dynamic>>[];
    });
  }

  /// Force refresh exercises from remote
  Future<List<Map<String, dynamic>>> refreshExercises() async {
    _memoryCache = null; // Clear memory cache
    return await _fetchAndCacheFromRemote();
  }

  /// Get exercises by category (uses cached data)
  Future<List<Map<String, dynamic>>> getExercisesByCategory(String category) async {
    final allExercises = await getExercises();

    if (category == 'All') {
      return allExercises;
    }

    return allExercises
        .where((e) => e['category'] == category)
        .toList();
  }

  /// Search exercises (uses cached data)
  Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    if (query.isEmpty) {
      return await getExercises();
    }

    final allExercises = await getExercises();
    final lowerQuery = query.toLowerCase();

    return allExercises.where((exercise) {
      final name = (exercise['name'] as String? ?? '').toLowerCase();
      final category = (exercise['category'] as String? ?? '').toLowerCase();
      final equipment = (exercise['equipment'] as String? ?? '').toLowerCase();

      return name.contains(lowerQuery) ||
             category.contains(lowerQuery) ||
             equipment.contains(lowerQuery);
    }).toList();
  }

  /// Clear all caches
  void clearCache() {
    _memoryCache = null;
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCache': _memoryCache != null ? '${_memoryCache!.length} exercises' : 'empty',
      'isSyncing': _isSyncing,
    };
  }
}
