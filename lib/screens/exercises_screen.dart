import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../constants/exercise_assets.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class ExercisesScreen extends StatefulWidget {
  final void Function(String, [Map<String, dynamic>?]) onNavigate;

  const ExercisesScreen({super.key, required this.onNavigate});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

const Map<String, String> kDefaultExerciseImages = {};

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

  List<Exercise> allExercises = [];

  @override
  void initState() {
    super.initState();
    _loadCustomExercises();
  }

  Future<void> _loadCustomExercises() async {
    try {
      final supabaseExercises = await SupabaseService.instance.getExercises();
      final defaultOnly = supabaseExercises
          .where((e) => (e['is_default'] ?? false) == true)
          .toList();
      final customOnly = supabaseExercises
          .where((e) => (e['is_custom'] ?? false) == true)
          .toList();

      for (final exercise in supabaseExercises) {
        await LocalStorageService.instance.saveExercise(exercise);
      }

      setState(() {
        allExercises = defaultOnly
            .map((e) => _createExerciseFromMap(e, isCustomOverride: false))
            .toList();

        customExercises = customOnly
            .map((e) => _createExerciseFromMap(e, isCustomOverride: true))
            .toList();
      });
    } catch (e) {
      print('Failed to load from Supabase (offline?): $e');

      final localStorage = LocalStorageService.instance;
      final saved = localStorage.getAllExercises();

      setState(() {
        final defaultSaved = saved.where((e) {
          final isCustom = e['isCustom'] ?? e['is_custom'] ?? false;
          return !isCustom;
        }).toList();
        final customSaved = saved.where((e) {
          final isCustom = e['isCustom'] ?? e['is_custom'] ?? false;
          return isCustom;
        }).toList();

        allExercises = defaultSaved
            .map((e) => _createExerciseFromMap(Map<String, dynamic>.from(e), isCustomOverride: false))
            .toList();

        customExercises = customSaved
            .map((e) => _createExerciseFromMap(Map<String, dynamic>.from(e), isCustomOverride: true))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String? _firstNonEmptyString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }
    return null;
  }

  Exercise _createExerciseFromMap(Map<String, dynamic> source,
      {bool? isCustomOverride}) {
    final data = Map<String, dynamic>.from(source);
    final imageUrl = _firstNonEmptyString(
          data,
          ['image_url', 'imageUrl', 'thumbnail_url', 'media_url'],
        ) ??
        kDefaultExerciseImages[data['name']] ??
        kExercisePlaceholderImage;
    final videoUrl = _firstNonEmptyString(
      data,
      ['video_url', 'videoUrl', 'video', 'demo_video_url', 'tutorial_video', 'video_path', 'media_video'],
    );
    final isCustom = isCustomOverride ??
        (data['is_custom'] == true || data['isCustom'] == true);

    return Exercise(
      name: (data['name'] as String?) ?? 'Exercise',
      category: (data['category'] as String?) ?? 'Other',
      difficulty: (data['difficulty'] as String?) ?? 'Intermediate',
      equipment: (data['equipment'] as String?) ?? 'Bodyweight',
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      isCustom: isCustom,
      rawData: data,
    );
  }

  List<Exercise> get filteredExercises {
    // Combine default exercises with custom exercises
    final allExercisesList = [...allExercises, ...customExercises];

    return allExercisesList.where((exercise) {
      final matchesCategory =
          selectedCategory == 'All' || exercise.category == selectedCategory;
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
      body: SafeArea(
        child: CustomScrollView(
            slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercises',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse and manage your exercise library.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          onTap: () => widget.onNavigate(
                            'exercise-detail',
                            {'exercise': exercise.toDetailPayload()},
                          ),
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
  final String? videoUrl;
  final Map<String, dynamic> rawData;

  Exercise({
    required this.name,
    required this.category,
    required this.difficulty,
    required this.equipment,
    String? imageUrl,
    this.videoUrl,
    this.isCustom = false,
    Map<String, dynamic>? rawData,
  })  : imageUrl = imageUrl ??
            kDefaultExerciseImages[name] ??
            kExercisePlaceholderImage,
        rawData = rawData != null
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};

  Map<String, dynamic> toDetailPayload() {
    final payload = Map<String, dynamic>.from(rawData);
    payload['name'] ??= name;
    payload['category'] ??= category;
    payload['difficulty'] ??= difficulty;
    payload['equipment'] ??= equipment;
    payload['image_url'] ??= imageUrl;
    payload['imageUrl'] ??= imageUrl;
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      payload.putIfAbsent('video_url', () => videoUrl);
      payload['videoUrl'] ??= videoUrl;
    }
    payload['is_custom'] ??= isCustom;
    payload['isCustom'] ??= isCustom;
    return payload;
  }
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

  static final Map<String, Future<ui.Image>> _firstFrameCache = {};
  static final Map<String, Future<Uint8List>> _gifBytesCache = {};

  bool get _isGif => exercise.imageUrl.toLowerCase().endsWith('.gif');

  bool _needsSignedUrl(String path) {
    return path.isNotEmpty &&
        !path.startsWith('http') &&
        !path.startsWith('assets/');
  }

  Future<Uint8List> _loadGifBytes(String path) {
    return _gifBytesCache.putIfAbsent(path, () async {
      try {
        if (path.startsWith('http')) {
          final response = await http.get(Uri.parse(path));
          if (response.statusCode == 200) {
            return response.bodyBytes;
          }
          throw Exception('Failed to download GIF: ${response.statusCode}');
        } else if (_needsSignedUrl(path)) {
          final signedUrl =
              await SupabaseService.instance.getSignedUrlForStoragePath(path);
          final response = await http.get(Uri.parse(signedUrl));
          if (response.statusCode == 200) {
            return response.bodyBytes;
          }
          throw Exception(
              'Failed to download GIF from signed URL: ${response.statusCode}');
        } else {
          final data = await rootBundle.load(path);
          return data.buffer.asUint8List();
        }
      } catch (e) {
        throw Exception('Failed to load GIF bytes: $e');
      }
    });
  }

  Future<ui.Image> _loadFirstFrame(String path) {
    return _firstFrameCache.putIfAbsent(path, () async {
      final bytes = await _loadGifBytes(path);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    });
  }

  Widget _buildImage(BuildContext context) {
    if (exercise.imageUrl.isEmpty) {
      return _fallbackIcon(colorScheme, _getCategoryIcon());
    }

    if (_isGif) {
      return FutureBuilder<ui.Image>(
        future: _loadFirstFrame(exercise.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RawImage(
              image: snapshot.data,
              fit: BoxFit.cover,
            );
          }
          return _fallbackIcon(colorScheme, _getCategoryIcon());
        },
      );
    }

    if (exercise.imageUrl.startsWith('assets/')) {
      return Image.asset(
        exercise.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackIcon(colorScheme, _getCategoryIcon()),
      );
    }

    if (_needsSignedUrl(exercise.imageUrl)) {
      return FutureBuilder<String>(
        future: SupabaseService.instance
            .getSignedUrlForStoragePath(exercise.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.network(
              snapshot.data!,
              gaplessPlayback: true,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _fallbackIcon(colorScheme, _getCategoryIcon()),
            );
          }
          if (snapshot.hasError) {
            return _fallbackIcon(colorScheme, _getCategoryIcon());
          }
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 1.5));
        },
      );
    }

    return Image.network(
      exercise.imageUrl,
      gaplessPlayback: true,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _fallbackIcon(colorScheme, _getCategoryIcon()),
    );
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (exercise.imageUrl.isNotEmpty)
                  _buildImage(context)
                else
                  _fallbackIcon(colorScheme, _getCategoryIcon()),
              ],
            ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
