import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class ExercisesScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ExercisesScreen({super.key, required this.onNavigate});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

const Map<String, String> kDefaultExerciseImages = {
  // Chest
  'Bench Press': 'https://images.unsplash.com/photo-1517964106626-460c5db42163?auto=format&fit=crop&w=1200&q=80',
  'Incline Bench Press': 'https://images.unsplash.com/photo-1541532713592-79a0317b6b77?auto=format&fit=crop&w=1200&q=80',
  'Decline Bench Press': 'https://images.unsplash.com/photo-1598971639058-114c5db42163?auto=format&fit=crop&w=1200&q=80',
  'Dumbbell Flyes': 'https://images.unsplash.com/photo-1561212044-bac5ef688a07?auto=format&fit=crop&w=1200&q=80',
  'Cable Crossover': 'https://images.unsplash.com/photo-1571732083810-7da1afcfdee0?auto=format&fit=crop&w=1200&q=80',
  'Push-ups': 'https://images.unsplash.com/photo-1579758629413-2f66c04778d4?auto=format&fit=crop&w=1200&q=80',
  'Dips': 'https://images.unsplash.com/photo-1613769044938-45cebbd0f4af?auto=format&fit=crop&w=1200&q=80',

  // Back
  'Deadlifts': 'https://images.unsplash.com/photo-1508672019048-805c876b67e2?auto=format&fit=crop&w=1200&q=80',
  'Pull-ups': 'https://images.unsplash.com/photo-1583454110551-21f2fa2a6e1d?auto=format&fit=crop&w=1200&q=80',
  'Barbell Rows': 'https://images.unsplash.com/photo-1615810615820-0dda8d733925?auto=format&fit=crop&w=1200&q=80',
  'Lat Pulldown': 'https://images.unsplash.com/photo-1556817411-31ae72fa3ea0?auto=format&fit=crop&w=1200&q=80',
  'Seated Cable Rows': 'https://images.unsplash.com/photo-1579758629938-03607ccdbaba?auto=format&fit=crop&w=1200&q=80',
  'T-Bar Rows': 'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?auto=format&fit=crop&w=1200&q=80',
  'Face Pulls': 'https://images.unsplash.com/photo-1597176098514-1f70c9f3d3ef?auto=format&fit=crop&w=1200&q=80',

  // Legs
  'Squats': 'https://images.unsplash.com/photo-1483721310020-03333e577078?auto=format&fit=crop&w=1200&q=80',
  'Front Squats': 'https://images.unsplash.com/photo-1614090972494-3431bb0e0dfe?auto=format&fit=crop&w=1200&q=80',
  'Leg Press': 'https://images.unsplash.com/photo-1583454110551-21f2fa2a6e1d?auto=format&fit=crop&w=1200&q=80',
  'Lunges': 'https://images.unsplash.com/photo-1530210124550-912dc1381cb8?auto=format&fit=crop&w=1200&q=80',
  'Romanian Deadlifts': 'https://images.unsplash.com/photo-1594737626072-90dc20311f10?auto=format&fit=crop&w=1200&q=80',
  'Leg Curls': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?auto=format&fit=crop&w=1200&q=80',
  'Leg Extensions': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1200&q=80',
  'Calf Raises': 'https://images.unsplash.com/photo-1526403225721-94bcd2fbfd06?auto=format&fit=crop&w=1200&q=80',

  // Shoulders
  'Overhead Press': 'https://images.unsplash.com/photo-1527356926124-9c7593dba9a1?auto=format&fit=crop&w=1200&q=80',
  'Dumbbell Shoulder Press': 'https://images.unsplash.com/photo-1571019610964-3bd01d038e72?auto=format&fit=crop&w=1200&q=80',
  'Lateral Raises': 'https://images.unsplash.com/photo-1615810615820-0dda8d733925?auto=format&fit=crop&w=1200&q=80',
  'Front Raises': 'https://images.unsplash.com/photo-1613769044938-45cebbd0f4af?auto=format&fit=crop&w=1200&q=80',
  'Rear Delt Flyes': 'https://images.unsplash.com/photo-1571731956672-b2f6a0dd9c15?auto=format&fit=crop&w=1200&q=80',
  'Arnold Press': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80',
  'Upright Rows': 'https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?auto=format&fit=crop&w=1200&q=80',

  // Arms
  'Bicep Curls': 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
  'Hammer Curls': 'https://images.unsplash.com/photo-1526401485004-46910ecc8e51?auto=format&fit=crop&w=1200&q=80',
  'Preacher Curls': 'https://images.unsplash.com/photo-1526401281623-37939bbacd81?auto=format&fit=crop&w=1200&q=80',
  'Tricep Dips': 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?auto=format&fit=crop&w=1200&q=80',
  'Tricep Pushdowns': 'https://images.unsplash.com/photo-1518611012118-f07fcbfc03e2?auto=format&fit=crop&w=1200&q=80',
  'Skull Crushers': 'https://images.unsplash.com/photo-1594737626072-90dc20311f10?auto=format&fit=crop&w=1200&q=80',
  'Cable Curls': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80',
  'Close-Grip Bench Press': 'https://images.unsplash.com/photo-1517964106626-460c5db42163?auto=format&fit=crop&w=1200&q=80',

  // Core
  'Planks': 'https://images.unsplash.com/photo-1579758629413-2f66c04778d4?auto=format&fit=crop&w=1200&q=80',
  'Crunches': 'https://images.unsplash.com/photo-1541534401786-2077eed87a74?auto=format&fit=crop&w=1200&q=80',
  'Russian Twists': 'https://images.unsplash.com/photo-1540202404-8ab83db238b8?auto=format&fit=crop&w=1200&q=80',
  'Leg Raises': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?auto=format&fit=crop&w=1200&q=80',
  'Cable Crunches': 'https://images.unsplash.com/photo-1620403724051-ce7c43f1f9cb?auto=format&fit=crop&w=1200&q=80',
  'Ab Wheel Rollouts': 'https://images.unsplash.com/photo-1556817411-31ae72fa3ea0?auto=format&fit=crop&w=1200&q=80',
  'Hanging Leg Raises': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1200&q=80',
  'Mountain Climbers': 'https://images.unsplash.com/photo-1597176098514-1f70c9f3d3ef?auto=format&fit=crop&w=1200&q=80',

  // Cardio
  'Running': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=1200&q=80',
  'Cycling': 'https://images.unsplash.com/photo-1471295253337-3ceaaedca402?auto=format&fit=crop&w=1200&q=80',
  'Jump Rope': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=1200&q=80',
  'Burpees': 'https://images.unsplash.com/photo-1546484959-f0d9f3c7adb7?auto=format&fit=crop&w=1200&q=80',
  'Rowing': 'https://images.unsplash.com/photo-1526401281623-37939bbacd81?auto=format&fit=crop&w=1200&q=80',
  'Stair Climbing': 'https://images.unsplash.com/photo-1562777717-dc6984f65d3f?auto=format&fit=crop&w=1200&q=80',
};
class _ExercisesScreenState extends State<ExercisesScreen> {
  final TextEditingController searchController = TextEditingController();
  String selectedCategory = 'All';
  String searchQuery = '';
  List<Exercise> customExercises = [];
  static const List<String> categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
    'Other',
  ];

  final List<Exercise> allExercises = [
    // Chest
    Exercise(name: 'Bench Press', category: 'Chest', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Bench Press']),
    Exercise(name: 'Incline Bench Press', category: 'Chest', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Incline Bench Press']),
    Exercise(name: 'Decline Bench Press', category: 'Chest', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Decline Bench Press']),
    Exercise(name: 'Dumbbell Flyes', category: 'Chest', difficulty: 'Beginner', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Dumbbell Flyes']),
    Exercise(name: 'Cable Crossover', category: 'Chest', difficulty: 'Intermediate', equipment: 'Cable', imageUrl: kDefaultExerciseImages['Cable Crossover']),
    Exercise(name: 'Push-ups', category: 'Chest', difficulty: 'Beginner', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Push-ups']),
    Exercise(name: 'Dips', category: 'Chest', difficulty: 'Intermediate', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Dips']),
    
    // Back
    Exercise(name: 'Deadlifts', category: 'Back', difficulty: 'Advanced', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Deadlifts']),
    Exercise(name: 'Pull-ups', category: 'Back', difficulty: 'Intermediate', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Pull-ups']),
    Exercise(name: 'Barbell Rows', category: 'Back', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Barbell Rows']),
    Exercise(name: 'Lat Pulldown', category: 'Back', difficulty: 'Beginner', equipment: 'Cable', imageUrl: kDefaultExerciseImages['Lat Pulldown']),
    Exercise(name: 'Seated Cable Rows', category: 'Back', difficulty: 'Beginner', equipment: 'Cable', imageUrl: kDefaultExerciseImages['Seated Cable Rows']),
    Exercise(name: 'T-Bar Rows', category: 'Back', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['T-Bar Rows']),
    Exercise(name: 'Face Pulls', category: 'Back', difficulty: 'Beginner', equipment: 'Cable', imageUrl: kDefaultExerciseImages['Face Pulls']),
    
    // Legs
    Exercise(name: 'Squats', category: 'Legs', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Squats']),
    Exercise(name: 'Front Squats', category: 'Legs', difficulty: 'Advanced', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Front Squats']),
    Exercise(name: 'Leg Press', category: 'Legs', difficulty: 'Beginner', equipment: 'Machine', imageUrl: kDefaultExerciseImages['Leg Press']),
    Exercise(name: 'Lunges', category: 'Legs', difficulty: 'Beginner', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Lunges']),
    Exercise(name: 'Romanian Deadlifts', category: 'Legs', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Romanian Deadlifts']),
    Exercise(name: 'Leg Curls', category: 'Legs', difficulty: 'Beginner', equipment: 'Machine', imageUrl: kDefaultExerciseImages['Leg Curls']),
    Exercise(name: 'Leg Extensions', category: 'Legs', difficulty: 'Beginner', equipment: 'Machine', imageUrl: kDefaultExerciseImages['Leg Extensions']),
    Exercise(name: 'Calf Raises', category: 'Legs', difficulty: 'Beginner', equipment: 'Machine', imageUrl: kDefaultExerciseImages['Calf Raises']),
    
    // Shoulders
    Exercise(name: 'Overhead Press', category: 'Shoulders', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Overhead Press']),
    Exercise(name: 'Dumbbell Shoulder Press', category: 'Shoulders', difficulty: 'Beginner', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Dumbbell Shoulder Press']),
    Exercise(name: 'Lateral Raises', category: 'Shoulders', difficulty: 'Beginner', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Lateral Raises']),
    Exercise(name: 'Front Raises', category: 'Shoulders', difficulty: 'Beginner', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Front Raises']),
    Exercise(name: 'Rear Delt Flyes', category: 'Shoulders', difficulty: 'Beginner', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Rear Delt Flyes']),
    Exercise(name: 'Arnold Press', category: 'Shoulders', difficulty: 'Intermediate', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Arnold Press']),
    Exercise(name: 'Upright Rows', category: 'Shoulders', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Upright Rows']),
    
    // Arms
    Exercise(name: 'Bicep Curls', category: 'Arms', difficulty: 'Beginner', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Bicep Curls']),
    Exercise(name: 'Hammer Curls', category: 'Arms', difficulty: 'Beginner', equipment: 'Dumbbell', imageUrl: kDefaultExerciseImages['Hammer Curls']),
    Exercise(name: 'Preacher Curls', category: 'Arms', difficulty: 'Beginner', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Preacher Curls']),
    Exercise(name: 'Tricep Dips', category: 'Arms', difficulty: 'Intermediate', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Tricep Dips']),
    Exercise(name: 'Tricep Pushdowns', category: 'Arms', difficulty: 'Beginner', equipment: 'Cable', imageUrl: kDefaultExerciseImages['Tricep Pushdowns']),
    Exercise(name: 'Skull Crushers', category: 'Arms', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Skull Crushers']),
    Exercise(name: 'Cable Curls', category: 'Arms', difficulty: 'Beginner', equipment: 'Cable', imageUrl: kDefaultExerciseImages['Cable Curls']),
    Exercise(name: 'Close-Grip Bench Press', category: 'Arms', difficulty: 'Intermediate', equipment: 'Barbell', imageUrl: kDefaultExerciseImages['Close-Grip Bench Press']),
    
    // Core
    Exercise(name: 'Planks', category: 'Core', difficulty: 'Beginner', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Planks']),
    Exercise(name: 'Crunches', category: 'Core', difficulty: 'Beginner', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Crunches']),
    Exercise(name: 'Russian Twists', category: 'Core', difficulty: 'Beginner', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Russian Twists']),
    Exercise(name: 'Leg Raises', category: 'Core', difficulty: 'Intermediate', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Leg Raises']),
    Exercise(name: 'Cable Crunches', category: 'Core', difficulty: 'Beginner', equipment: 'Cable', imageUrl: kDefaultExerciseImages['Cable Crunches']),
    Exercise(name: 'Ab Wheel Rollouts', category: 'Core', difficulty: 'Advanced', equipment: 'Ab Wheel', imageUrl: kDefaultExerciseImages['Ab Wheel Rollouts']),
    Exercise(name: 'Hanging Leg Raises', category: 'Core', difficulty: 'Advanced', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Hanging Leg Raises']),
    Exercise(name: 'Mountain Climbers', category: 'Core', difficulty: 'Intermediate', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Mountain Climbers']),
    
    // Cardio
    Exercise(name: 'Running', category: 'Cardio', difficulty: 'Beginner', equipment: 'None', imageUrl: kDefaultExerciseImages['Running']),
    Exercise(name: 'Cycling', category: 'Cardio', difficulty: 'Beginner', equipment: 'Bike', imageUrl: kDefaultExerciseImages['Cycling']),
    Exercise(name: 'Jump Rope', category: 'Cardio', difficulty: 'Intermediate', equipment: 'Jump Rope', imageUrl: kDefaultExerciseImages['Jump Rope']),
    Exercise(name: 'Burpees', category: 'Cardio', difficulty: 'Intermediate', equipment: 'Bodyweight', imageUrl: kDefaultExerciseImages['Burpees']),
    Exercise(name: 'Rowing', category: 'Cardio', difficulty: 'Beginner', equipment: 'Machine', imageUrl: kDefaultExerciseImages['Rowing']),
    Exercise(name: 'Stair Climbing', category: 'Cardio', difficulty: 'Beginner', equipment: 'Machine', imageUrl: kDefaultExerciseImages['Stair Climbing']),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Exercise> get filteredExercises {
    // Combine default exercises with custom exercises
    final allExercisesList = [...allExercises, ...customExercises];
    
    return allExercisesList.where((exercise) {
      final matchesCategory = selectedCategory == 'All' || exercise.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty || 
          exercise.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          exercise.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
          exercise.equipment.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Exercises'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() => searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

          // Category Filter
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => selectedCategory = category);
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Results Count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${filteredExercises.length} exercises',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Exercise List
          filteredExercises.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises found',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final exercise = filteredExercises[index];
                        return _ExerciseCard(
                          exercise: exercise,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          onTap: () => widget.onNavigate('exercise-detail'),
                        );
                      },
                      childCount: filteredExercises.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onNavigate('create-exercise'),
        icon: const Icon(Icons.add),
        label: const Text('Create Exercise'),
      ),
    );
  }
}

class Exercise {
  final String name;
  final String category;
  final String difficulty;
  final String equipment;
  final String imageUrl;
  final bool isCustom;

  Exercise({
    required this.name,
    required this.category,
    required this.difficulty,
    required this.equipment,
    String? imageUrl,
    this.isCustom = false,
  }) : imageUrl = imageUrl ?? kDefaultExerciseImages[name] ?? '';
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  Color _getDifficultyColor() {
    switch (exercise.difficulty) {
      case 'Beginner':
        return colorScheme.secondary;
      case 'Intermediate':
        return colorScheme.primary;
      case 'Advanced':
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }

  IconData _getCategoryIcon() {
    switch (exercise.category) {
      case 'Chest':
        return Icons.favorite;
      case 'Back':
        return Icons.accessibility_new;
      case 'Legs':
        return Icons.directions_run;
      case 'Shoulders':
        return Icons.fitness_center;
      case 'Arms':
        return Icons.sports_martial_arts;
      case 'Core':
        return Icons.center_focus_strong;
      case 'Cardio':
        return Icons.monitor_heart;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: exercise.imageUrl.isNotEmpty
                ? Image.network(
                    exercise.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _fallbackIcon(colorScheme, _getCategoryIcon()),
                  )
                : _fallbackIcon(colorScheme, _getCategoryIcon()),
          ),
        ),
        title: Text(
          exercise.name,
          style: textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (exercise.isCustom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CUSTOM',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercise.difficulty,
                    style: textTheme.labelSmall?.copyWith(
                      color: _getDifficultyColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.label_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  exercise.category,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.sports_gymnastics,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  exercise.equipment,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _fallbackIcon(ColorScheme scheme, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
