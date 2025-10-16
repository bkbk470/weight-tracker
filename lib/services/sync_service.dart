import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

class SyncService {
  static SyncService? _instance;
  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  SyncService._();

  final LocalStorageService _localStorage = LocalStorageService.instance;
  final SupabaseService _supabase = SupabaseService.instance;
  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Get sync status
  Map<String, dynamic> getSyncStatus() {
    final stats = _localStorage.getStorageStats();
    final lastSync = _localStorage.getLastSyncTime();
    
    return {
      'isSyncing': _isSyncing,
      'lastSync': lastSync,
      'lastSyncAttempt': _lastSyncAttempt,
      'pendingItems': stats['pendingSync'],
      'needsSync': _localStorage.needsSync(),
    };
  }

  // Sync all data with Supabase
  Future<Map<String, dynamic>> syncAll() async {
    if (_isSyncing) {
      return {
        'success': false,
        'message': 'Sync already in progress',
      };
    }

    _isSyncing = true;
    _lastSyncAttempt = DateTime.now();

    try {
      // Check internet connection
      if (!await isOnline()) {
        return {
          'success': false,
          'message': 'No internet connection',
          'offline': true,
        };
      }

      // Get pending workouts
      final pendingWorkouts = _localStorage.getPendingSyncWorkouts();
      
      int syncedCount = 0;
      int failedCount = 0;

      // Sync workouts to Supabase
      for (var workout in pendingWorkouts) {
        try {
          // Sync to Supabase
          await _supabase.createWorkoutLog(
            workoutName: workout['name'] ?? 'Workout',
            startTime: DateTime.parse(workout['startTime'] ?? DateTime.now().toIso8601String()),
            endTime: workout['endTime'] != null ? DateTime.parse(workout['endTime']) : null,
            durationSeconds: workout['duration'],
            notes: workout['notes'],
          );
          
          // Mark as synced locally
          await _localStorage.markWorkoutSynced(workout['id']);
          syncedCount++;
        } catch (e) {
          failedCount++;
          print('Failed to sync workout ${workout['id']}: $e');
        }
      }

      // Update last sync time
      if (syncedCount > 0) {
        await _localStorage.updateLastSyncTime();
      }

      return {
        'success': true,
        'synced': syncedCount,
        'failed': failedCount,
        'message': syncedCount > 0 
            ? 'Successfully synced $syncedCount item(s)'
            : 'Everything up to date',
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Sync failed: $e',
      };
    } finally {
      _isSyncing = false;
    }
  }

  // Download data from Supabase
  Future<Map<String, dynamic>> downloadFromSupabase() async {
    if (!await isOnline()) {
      return {
        'success': false,
        'message': 'No internet connection',
        'offline': true,
      };
    }

    try {
      int downloadedCount = 0;
      
      // Download exercises
      final exercises = await _supabase.getExercises();
      for (var exercise in exercises) {
        if (exercise['is_custom'] == true) {
          await _localStorage.saveExercise(exercise);
          downloadedCount++;
        }
      }
      
      // Download measurements
      final measurements = await _supabase.getAllMeasurements();
      for (var measurement in measurements) {
        await _localStorage.saveMeasurement(measurement);
        downloadedCount++;
      }

      return {
        'success': true,
        'downloaded': downloadedCount,
        'message': 'Downloaded $downloadedCount item(s)',
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Download failed: $e',
      };
    }
  }

  // Auto-sync when online
  Future<void> autoSync() async {
    // Only auto-sync if we have pending data and we're online
    if (_localStorage.needsSync() && await isOnline()) {
      // Don't sync too frequently (wait at least 5 minutes)
      if (_lastSyncAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(_lastSyncAttempt!);
        if (timeSinceLastAttempt.inMinutes < 5) {
          return;
        }
      }

      await syncAll();
    }
  }

  // Force sync (manual trigger)
  Future<Map<String, dynamic>> forceSync() async {
    _lastSyncAttempt = null; // Reset to allow immediate sync
    return await syncAll();
  }
}
