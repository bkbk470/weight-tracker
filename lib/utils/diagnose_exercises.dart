import 'package:weight_tracker/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diagnostic utility to check why exercises aren't showing up
class ExerciseDiagnostic {
  static Future<void> diagnoseExerciseIssue() async {
    print('🔍 Starting Exercise Diagnostic...\n');

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    print('📋 Step 1: Check Authentication');
    print('   Current User ID: ${currentUserId ?? "❌ NOT LOGGED IN"}');
    print('   User Email: ${supabase.auth.currentUser?.email ?? "N/A"}');

    if (currentUserId == null) {
      print('   ⚠️  WARNING: Not authenticated! Exercises require login.\n');
      return;
    }
    print('   ✅ Authenticated\n');

    try {
      // Check 1: Total exercises in database
      print('📋 Step 2: Check Total Exercises in Database');
      final totalCount = await supabase
          .from('exercises')
          .select('id', const FetchOptions(count: CountOption.exact))
          .count();
      print('   Total exercises in table: $totalCount\n');

      if (totalCount == 0) {
        print('   ❌ Table is empty!\n');
        return;
      }

      // Check 2: Sample of first few exercises
      print('📋 Step 3: Sample First 5 Exercises');
      final sampleExercises = await supabase
          .from('exercises')
          .select('id, name, is_default, is_custom, user_id, category')
          .limit(5);

      for (var ex in sampleExercises) {
        print('   - ${ex['name']}');
        print('     is_default: ${ex['is_default']}');
        print('     is_custom: ${ex['is_custom']}');
        print('     user_id: ${ex['user_id']}');
        print('     category: ${ex['category']}');
      }
      print('');

      // Check 3: Count by is_default status
      print('📋 Step 4: Check is_default Field');
      final defaultTrue = await supabase
          .from('exercises')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('is_default', true)
          .count();
      final defaultFalse = await supabase
          .from('exercises')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('is_default', false)
          .count();
      final defaultNull = await supabase
          .from('exercises')
          .select('id', const FetchOptions(count: CountOption.exact))
          .isFilter('is_default', null)
          .count();

      print('   Exercises with is_default = true: $defaultTrue');
      print('   Exercises with is_default = false: $defaultFalse');
      print('   Exercises with is_default = null: $defaultNull\n');

      if (defaultTrue == 0) {
        print('   ⚠️  PROBLEM FOUND: No exercises have is_default = true!');
        print('   💡 Solution: Update exercises to set is_default = true\n');
      }

      // Check 4: Count by user_id
      print('📋 Step 5: Check user_id Field');
      final userExercises = await supabase
          .from('exercises')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', currentUserId)
          .count();
      final nullUserId = await supabase
          .from('exercises')
          .select('id', const FetchOptions(count: CountOption.exact))
          .isFilter('user_id', null)
          .count();

      print('   Exercises with your user_id: $userExercises');
      print('   Exercises with user_id = null: $nullUserId\n');

      // Check 5: Test the actual app query
      print('📋 Step 6: Test App Query (is_default=true OR user_id=current)');
      final appQueryResults = await supabase
          .from('exercises')
          .select('id, name, category', const FetchOptions(count: CountOption.exact))
          .or('is_default.eq.true,user_id.eq.$currentUserId')
          .count();

      print('   Results from app query: $appQueryResults exercises\n');

      if (appQueryResults == 0) {
        print('   ❌ PROBLEM: App query returns 0 exercises!');
        print('   This means exercises need EITHER:');
        print('   - is_default = true, OR');
        print('   - user_id = $currentUserId\n');
      } else {
        print('   ✅ App query returns exercises!\n');
      }

      // Check 6: Category breakdown
      print('📋 Step 7: Category Breakdown');
      final categories = await supabase
          .from('exercises')
          .select('category')
          .or('is_default.eq.true,user_id.eq.$currentUserId');

      final categoryMap = <String, int>{};
      for (var ex in categories) {
        final cat = ex['category'] as String? ?? 'Unknown';
        categoryMap[cat] = (categoryMap[cat] ?? 0) + 1;
      }

      categoryMap.forEach((category, count) {
        print('   $category: $count exercises');
      });
      print('');

      // Check 7: RLS Policies
      print('📋 Step 8: Check Row Level Security');
      print('   ℹ️  If RLS is enabled but no policies match, exercises won\'t show.');
      print('   Check your Supabase dashboard → Authentication → Policies\n');

      // Summary
      print('📊 DIAGNOSTIC SUMMARY:');
      print('═══════════════════════════════════════════════════════');
      if (appQueryResults == 0) {
        print('❌ ISSUE FOUND: Exercises exist but don\'t match app query\n');

        if (defaultTrue == 0 && userExercises == 0) {
          print('🔧 SOLUTION: Update exercises to set is_default = true');
          print('   Run this SQL in Supabase:\n');
          print('   UPDATE exercises SET is_default = true WHERE is_default IS NULL OR is_default = false;');
        } else if (defaultTrue > 0) {
          print('🔧 Possible RLS Policy Issue');
          print('   Check Supabase → Authentication → Policies');
          print('   Ensure "Users can view default exercises" policy exists');
        }
      } else {
        print('✅ Exercises are accessible! ($appQueryResults found)');
        print('   If they still don\'t show in app, check:');
        print('   1. ExerciseCacheService - might need to refresh');
        print('   2. App UI filters - might be filtering by category');
        print('   3. Search text - might be filtering results');
      }
      print('═══════════════════════════════════════════════════════\n');

    } catch (e, stackTrace) {
      print('❌ Error during diagnostic: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Quick fix: Update all exercises to be default exercises
  static Future<void> fixMakeAllExercisesDefault() async {
    print('🔧 Attempting to make all exercises default...\n');

    final supabase = Supabase.instance.client;

    try {
      final result = await supabase.rpc('update_all_exercises_to_default');
      print('✅ Successfully updated exercises!');
      print('   Result: $result\n');
      print('   Please restart your app to see the exercises.\n');
    } catch (e) {
      print('❌ RPC function not available. Use SQL instead:');
      print('   Run this in Supabase SQL Editor:\n');
      print('   UPDATE exercises');
      print('   SET is_default = true, user_id = null');
      print('   WHERE is_default IS NULL OR is_default = false;\n');
    }
  }
}
