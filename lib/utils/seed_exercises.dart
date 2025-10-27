import 'package:weight_tracker/services/supabase_service.dart';

/// Utility to seed default exercises into the database
/// Run this once to populate your Supabase database with common exercises
class ExerciseSeeder {
  static const String kPlaceholderImage =
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400';

  static Future<void> seedDefaultExercises() async {
    final supabase = SupabaseService();

    print('🌱 Starting to seed default exercises...');

    // Define all default exercises
    final exercises = [
      // CHEST EXERCISES
      _exercise('Barbell Bench Press', 'Chest', 'Intermediate', 'Barbell',
          'Classic chest builder. Keep your feet flat on the floor and maintain a slight arch in your lower back.'),
      _exercise('Dumbbell Bench Press', 'Chest', 'Beginner', 'Dumbbells',
          'Allows for greater range of motion than barbell. Keep dumbbells aligned with your chest.'),
      _exercise('Incline Barbell Bench Press', 'Chest', 'Intermediate',
          'Barbell', 'Targets upper chest. Set bench to 30-45 degree angle.'),
      _exercise('Incline Dumbbell Press', 'Chest', 'Intermediate', 'Dumbbells',
          'Great for upper chest development. Use 30-45 degree incline.'),
      _exercise('Decline Bench Press', 'Chest', 'Intermediate', 'Barbell',
          'Emphasizes lower chest. Secure your legs properly.'),
      _exercise('Dumbbell Flyes', 'Chest', 'Beginner', 'Dumbbells',
          'Great for chest stretch and contraction. Keep a slight bend in elbows.'),
      _exercise('Incline Dumbbell Flyes', 'Chest', 'Intermediate', 'Dumbbells',
          'Targets upper chest with stretch. Maintain controlled movement.'),
      _exercise('Cable Crossover', 'Chest', 'Intermediate', 'Cable Machine',
          'Constant tension on chest. Adjust cable height for different angles.'),
      _exercise('Push-ups', 'Chest', 'Beginner', 'Body Weight',
          'Classic bodyweight exercise. Keep core tight and body in straight line.'),
      _exercise('Chest Dips', 'Chest', 'Advanced', 'Dip Bar',
          'Lean forward to target chest. Keep elbows slightly flared.'),
      _exercise('Machine Chest Press', 'Chest', 'Beginner', 'Machine',
          'Beginner-friendly. Adjust seat so handles align with mid-chest.'),
      _exercise('Pec Deck Machine', 'Chest', 'Beginner', 'Machine',
          'Isolation exercise. Focus on squeezing chest at peak contraction.'),

      // BACK EXERCISES
      _exercise('Deadlift', 'Back', 'Advanced', 'Barbell',
          'King of back exercises. Keep back straight and lift with your legs.'),
      _exercise('Barbell Row', 'Back', 'Intermediate', 'Barbell',
          'Great for thickness. Pull to lower chest/upper abs.'),
      _exercise('Dumbbell Row', 'Back', 'Beginner', 'Dumbbells',
          'Unilateral back builder. Support yourself on bench.'),
      _exercise('Pull-ups', 'Back', 'Advanced', 'Pull-up Bar',
          'Excellent for back width. Use various grips for different emphasis.'),
      _exercise('Lat Pulldown', 'Back', 'Beginner', 'Cable Machine',
          'Great alternative to pull-ups. Pull to upper chest.'),
      _exercise('Seated Cable Row', 'Back', 'Beginner', 'Cable Machine',
          'Targets mid-back. Keep torso stable and squeeze shoulder blades.'),
      _exercise('T-Bar Row', 'Back', 'Intermediate', 'T-Bar Machine',
          'Excellent for back thickness. Keep chest up.'),
      _exercise('Face Pulls', 'Back', 'Beginner', 'Cable Machine',
          'Great for rear delts and upper back. Pull to face level.'),
      _exercise('Chin-ups', 'Back', 'Intermediate', 'Pull-up Bar',
          'Underhand grip variation. Excellent for biceps and lats.'),
      _exercise('Single Arm Dumbbell Row', 'Back', 'Beginner', 'Dumbbells',
          'Allows for greater range of motion. Focus on one side at a time.'),
      _exercise('Inverted Row', 'Back', 'Beginner', 'Body Weight',
          'Bodyweight row. Adjust height for difficulty.'),
      _exercise('Hyperextensions', 'Back', 'Beginner', 'Hyperextension Bench',
          'Strengthens lower back. Keep movement controlled.'),

      // LEGS EXERCISES
      _exercise('Barbell Squat', 'Legs', 'Intermediate', 'Barbell',
          'King of leg exercises. Keep chest up and knees tracking over toes.'),
      _exercise('Front Squat', 'Legs', 'Advanced', 'Barbell',
          'Emphasizes quads. Keep elbows high and chest up.'),
      _exercise('Romanian Deadlift', 'Legs', 'Intermediate', 'Barbell',
          'Great for hamstrings and glutes. Keep slight knee bend.'),
      _exercise('Leg Press', 'Legs', 'Beginner', 'Machine',
          'Safe alternative to squats. Don\'t lock out knees at top.'),
      _exercise('Leg Curl', 'Legs', 'Beginner', 'Machine',
          'Isolates hamstrings. Keep hips down on bench.'),
      _exercise('Leg Extension', 'Legs', 'Beginner', 'Machine',
          'Isolates quadriceps. Don\'t hyperextend knees.'),
      _exercise('Walking Lunges', 'Legs', 'Beginner', 'Dumbbells',
          'Great for quads and glutes. Keep torso upright.'),
      _exercise('Bulgarian Split Squat', 'Legs', 'Intermediate', 'Dumbbells',
          'Unilateral leg exercise. Rear foot elevated.'),
      _exercise('Calf Raises', 'Legs', 'Beginner', 'Machine',
          'Targets calves. Full range of motion for best results.'),
      _exercise('Goblet Squat', 'Legs', 'Beginner', 'Dumbbell',
          'Great for learning squat form. Hold dumbbell at chest.'),
      _exercise('Hack Squat', 'Legs', 'Intermediate', 'Machine',
          'Machine squat variation. Targets quads.'),
      _exercise('Step-ups', 'Legs', 'Beginner', 'Dumbbells',
          'Functional leg exercise. Use box or bench.'),

      // SHOULDERS EXERCISES
      _exercise('Overhead Press', 'Shoulders', 'Intermediate', 'Barbell',
          'Main shoulder builder. Press straight up overhead.'),
      _exercise('Dumbbell Shoulder Press', 'Shoulders', 'Beginner', 'Dumbbells',
          'Allows natural movement pattern. Can be done seated or standing.'),
      _exercise('Arnold Press', 'Shoulders', 'Intermediate', 'Dumbbells',
          'Rotation adds extra shoulder activation. Named after Arnold Schwarzenegger.'),
      _exercise('Lateral Raises', 'Shoulders', 'Beginner', 'Dumbbells',
          'Isolates side delts. Keep slight bend in elbows.'),
      _exercise('Front Raises', 'Shoulders', 'Beginner', 'Dumbbells',
          'Targets front delts. Alternate arms or both together.'),
      _exercise('Rear Delt Flyes', 'Shoulders', 'Beginner', 'Dumbbells',
          'Essential for rear deltoids. Bend forward at hips.'),
      _exercise('Cable Lateral Raise', 'Shoulders', 'Beginner', 'Cable Machine',
          'Constant tension on delts. Cross cable behind body.'),
      _exercise('Machine Shoulder Press', 'Shoulders', 'Beginner', 'Machine',
          'Beginner-friendly pressing motion. Good for building strength.'),
      _exercise('Upright Row', 'Shoulders', 'Intermediate', 'Barbell',
          'Works shoulders and traps. Pull elbows high.'),
      _exercise('Shrugs', 'Shoulders', 'Beginner', 'Dumbbells',
          'Builds trap muscles. Just shrug shoulders up.'),
      _exercise('Pike Push-ups', 'Shoulders', 'Intermediate', 'Body Weight',
          'Bodyweight shoulder exercise. Hips up high.'),

      // ARMS EXERCISES
      _exercise('Barbell Curl', 'Arms', 'Beginner', 'Barbell',
          'Classic bicep builder. Keep elbows stable.'),
      _exercise('Dumbbell Curl', 'Arms', 'Beginner', 'Dumbbells',
          'Allows natural wrist rotation. Can be done alternating or together.'),
      _exercise('Hammer Curl', 'Arms', 'Beginner', 'Dumbbells',
          'Targets brachialis. Keep palms facing each other.'),
      _exercise('Concentration Curl', 'Arms', 'Beginner', 'Dumbbell',
          'Isolates biceps. Rest elbow on inner thigh.'),
      _exercise('Preacher Curl', 'Arms', 'Intermediate', 'Barbell',
          'Prevents cheating. Use preacher bench.'),
      _exercise('Cable Curl', 'Arms', 'Beginner', 'Cable Machine',
          'Constant tension on biceps. Various attachments possible.'),
      _exercise('Tricep Dips', 'Arms', 'Intermediate', 'Dip Bar',
          'Excellent tricep builder. Keep torso upright.'),
      _exercise('Close-Grip Bench Press', 'Arms', 'Intermediate', 'Barbell',
          'Mass builder for triceps. Hands shoulder-width apart.'),
      _exercise('Tricep Pushdown', 'Arms', 'Beginner', 'Cable Machine',
          'Isolates triceps. Keep elbows at sides.'),
      _exercise('Overhead Tricep Extension', 'Arms', 'Beginner', 'Dumbbell',
          'Stretches long head of tricep. Keep elbows close to head.'),
      _exercise('Skull Crushers', 'Arms', 'Intermediate', 'Barbell',
          'Lying tricep extension. Lower to forehead or behind head.'),
      _exercise('Diamond Push-ups', 'Arms', 'Intermediate', 'Body Weight',
          'Bodyweight tricep exercise. Hands form diamond shape.'),

      // CORE EXERCISES
      _exercise('Plank', 'Core', 'Beginner', 'Body Weight',
          'Core stability exercise. Keep body straight.'),
      _exercise('Crunches', 'Core', 'Beginner', 'Body Weight',
          'Basic ab exercise. Focus on contracting abs.'),
      _exercise('Bicycle Crunches', 'Core', 'Beginner', 'Body Weight',
          'Works abs and obliques. Bring opposite elbow to knee.'),
      _exercise('Russian Twists', 'Core', 'Intermediate', 'Dumbbell',
          'Targets obliques. Rotate torso side to side.'),
      _exercise('Hanging Leg Raises', 'Core', 'Advanced', 'Pull-up Bar',
          'Advanced ab exercise. Raise legs to horizontal.'),
      _exercise('Ab Wheel Rollout', 'Core', 'Advanced', 'Ab Wheel',
          'Very effective ab exercise. Start from knees if needed.'),
      _exercise('Mountain Climbers', 'Core', 'Beginner', 'Body Weight',
          'Dynamic core exercise. Alternate bringing knees to chest.'),
      _exercise('Side Plank', 'Core', 'Intermediate', 'Body Weight',
          'Targets obliques. Keep body in straight line.'),
      _exercise('Dead Bug', 'Core', 'Beginner', 'Body Weight',
          'Great for core stability. Alternate opposite arm and leg.'),
      _exercise('Cable Woodchoppers', 'Core', 'Intermediate', 'Cable Machine',
          'Rotational core exercise. Move diagonally across body.'),
      _exercise('Leg Raises', 'Core', 'Intermediate', 'Body Weight',
          'Lower ab focus. Raise legs while lying on back.'),
      _exercise('Cable Crunches', 'Core', 'Beginner', 'Cable Machine',
          'Weighted ab exercise. Kneel and crunch down.'),

      // CARDIO EXERCISES
      _exercise('Treadmill Running', 'Cardio', 'Beginner', 'Treadmill',
          'Classic cardio. Adjust speed and incline for intensity.'),
      _exercise('Stationary Bike', 'Cardio', 'Beginner', 'Bike',
          'Low-impact cardio. Great for recovery days.'),
      _exercise('Rowing Machine', 'Cardio', 'Intermediate', 'Rowing Machine',
          'Full-body cardio. Focus on form: legs, core, then arms.'),
      _exercise('Elliptical', 'Cardio', 'Beginner', 'Elliptical',
          'Low-impact cardio machine. Easy on joints.'),
      _exercise('Jump Rope', 'Cardio', 'Intermediate', 'Jump Rope',
          'High-intensity cardio. Great for conditioning.'),
      _exercise('Burpees', 'Cardio', 'Advanced', 'Body Weight',
          'Full-body cardio exercise. High intensity.'),
      _exercise('Box Jumps', 'Cardio', 'Intermediate', 'Plyo Box',
          'Explosive power exercise. Land softly on box.'),
      _exercise('Battle Ropes', 'Cardio', 'Intermediate', 'Battle Ropes',
          'Upper body cardio. Create waves with ropes.'),
      _exercise('Stair Climber', 'Cardio', 'Intermediate', 'Stair Climber',
          'Tough leg cardio. Builds endurance and leg strength.'),
      _exercise('High Knees', 'Cardio', 'Beginner', 'Body Weight',
          'Running in place with high knee drive.'),
      _exercise('Swimming', 'Cardio', 'Intermediate', 'Pool',
          'Full-body low-impact cardio. Various strokes available.'),
      _exercise('Assault Bike', 'Cardio', 'Advanced', 'Assault Bike',
          'Intense full-body cardio. Arms and legs together.'),
    ];

    int successCount = 0;
    int errorCount = 0;

    // Insert each exercise
    for (final exercise in exercises) {
      try {
        await supabase.createExercise(
          name: exercise['name'],
          category: exercise['category'],
          difficulty: exercise['difficulty'],
          equipment: exercise['equipment'],
          notes: exercise['notes'],
          imageUrl: kPlaceholderImage,
          isDefault: true,
        );
        successCount++;
        print('✅ Added: ${exercise['name']} (${exercise['category']})');
      } catch (e) {
        errorCount++;
        print('❌ Failed to add ${exercise['name']}: $e');
      }
    }

    print('\n📊 Seeding Summary:');
    print('   ✅ Successfully added: $successCount exercises');
    print('   ❌ Failed: $errorCount exercises');
    print('   📝 Total attempted: ${exercises.length} exercises');

    if (successCount > 0) {
      print('\n🎉 Default exercises have been seeded! Restart your app to see them.');
    }
  }

  static Map<String, String> _exercise(
    String name,
    String category,
    String difficulty,
    String equipment,
    String notes,
  ) {
    return {
      'name': name,
      'category': category,
      'difficulty': difficulty,
      'equipment': equipment,
      'notes': notes,
    };
  }
}
