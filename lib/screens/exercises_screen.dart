import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../constants/exercise_assets.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';
import '../utils/safe_dialog_helpers.dart';

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

  void _showExerciseBottomSheet(BuildContext context, Exercise exercise) {
    FocusManager.instance.primaryFocus?.unfocus();
    showSafeModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseInfoSheet(
        exercise: exercise,
      ),
    );
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
        top: true,
        bottom: false,
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
                            onTap: () => _showExerciseBottomSheet(context, exercise),
                          );
                        },
                        childCount: filteredExercises.length,
                      ),
                    ),
                  ),
          ],
        ),
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

// Bottom sheet for exercise details
class _ExerciseInfoSheet extends StatefulWidget {
  final Exercise exercise;

  const _ExerciseInfoSheet({
    required this.exercise,
  });

  @override
  State<_ExerciseInfoSheet> createState() => _ExerciseInfoSheetState();
}

class _ExerciseInfoSheetState extends State<_ExerciseInfoSheet> {
  String selectedPeriod = '3M';
  final periods = ['1M', '3M', '6M', '1Y', 'All'];
  List<Map<String, dynamic>> exerciseHistory = [];
  bool isLoadingHistory = true;

  // Stats
  String? personalRecord;
  String? lastPerformed;
  String? totalVolume;
  int? totalSets;

  @override
  void initState() {
    super.initState();
    _loadExerciseHistory();
  }

  Future<void> _loadExerciseHistory() async {
    try {
      // Get exercise ID from database
      final exercises = await SupabaseService.instance.getExercises();
      final exerciseData = exercises.firstWhere(
        (e) => (e['name'] as String).toLowerCase() == widget.exercise.name.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (exerciseData['id'] != null) {
        final history = await SupabaseService.instance.getLatestExerciseSetsForExercise(
          exerciseData['id'] as String,
          historyLimit: 50,
        );

        if (mounted) {
          setState(() {
            exerciseHistory = history;
            _calculateStats();
            isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      print('Error loading exercise history: $e');
      if (mounted) {
        setState(() {
          isLoadingHistory = false;
        });
      }
    }
  }

  void _calculateStats() {
    if (exerciseHistory.isEmpty) return;

    // Personal Record (highest weight)
    double maxWeight = 0;
    int totalVolumeLbs = 0;
    int setCount = 0;
    DateTime? lastDate;

    for (final set in exerciseHistory) {
      final weight = (set['weight_lbs'] as num?)?.toDouble() ?? 0;
      final reps = (set['reps'] as num?)?.toInt() ?? 0;
      final createdAt = set['created_at'] as String?;

      if (weight > maxWeight) {
        maxWeight = weight;
      }

      totalVolumeLbs += (weight * reps).toInt();
      setCount++;

      if (createdAt != null) {
        final date = DateTime.parse(createdAt);
        if (lastDate == null || date.isAfter(lastDate)) {
          lastDate = date;
        }
      }
    }

    personalRecord = maxWeight > 0 ? '${maxWeight.toInt()} lbs' : 'No data';
    totalVolume = totalVolumeLbs > 0 ? '${totalVolumeLbs.toString()} lbs' : 'No data';
    totalSets = setCount;

    if (lastDate != null) {
      final now = DateTime.now();
      final difference = now.difference(lastDate);
      if (difference.inDays == 0) {
        lastPerformed = 'Today';
      } else if (difference.inDays == 1) {
        lastPerformed = 'Yesterday';
      } else if (difference.inDays < 7) {
        lastPerformed = '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        lastPerformed = '${(difference.inDays / 7).floor()} weeks ago';
      } else {
        lastPerformed = '${(difference.inDays / 30).floor()} months ago';
      }
    } else {
      lastPerformed = 'Never';
    }
  }

  bool _needsSignedUrl(String path) {
    return path.isNotEmpty &&
        !path.startsWith('http') &&
        !path.startsWith('assets/');
  }

  Widget _buildExerciseImage(String imageUrl, ColorScheme colorScheme) {
    // If it's a Supabase storage path, get signed URL
    if (_needsSignedUrl(imageUrl)) {
      return FutureBuilder<String>(
        future: SupabaseService.instance.getSignedUrlForStoragePath(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.network(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            );
          }
          if (snapshot.hasError) {
            return Container(
              color: colorScheme.surfaceVariant,
              child: Icon(
                Icons.fitness_center,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            );
          }
          return Container(
            color: colorScheme.surfaceVariant,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }

    // Otherwise use the URL directly
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorScheme.surfaceVariant,
          child: Icon(
            Icons.fitness_center,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: colorScheme.surfaceVariant,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(String difficulty, ColorScheme colorScheme) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Exercise name
                    Text(
                      widget.exercise.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category and difficulty badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(widget.exercise.category),
                          backgroundColor: colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.exercise.difficulty.isNotEmpty)
                          Chip(
                            label: Text(widget.exercise.difficulty),
                            backgroundColor: _getDifficultyColor(widget.exercise.difficulty, colorScheme).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _getDifficultyColor(widget.exercise.difficulty, colorScheme),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Exercise image
                    if (widget.exercise.imageUrl.isNotEmpty && widget.exercise.imageUrl != kExercisePlaceholderImage) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildExerciseImage(widget.exercise.imageUrl, colorScheme),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Stats Cards
                    if (!isLoadingHistory) ...[
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _StatCard(
                            icon: Icons.emoji_events,
                            label: 'Personal Record',
                            value: personalRecord ?? 'No data',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          _StatCard(
                            icon: Icons.calendar_today,
                            label: 'Last Performed',
                            value: lastPerformed ?? 'Never',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          _StatCard(
                            icon: Icons.bar_chart,
                            label: 'Total Volume',
                            value: totalVolume ?? 'No data',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          _StatCard(
                            icon: Icons.fitness_center,
                            label: 'Total Sets',
                            value: totalSets?.toString() ?? '0',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Equipment
                    _InfoSection(
                      icon: Icons.sports_gymnastics,
                      title: 'Equipment',
                      content: widget.exercise.equipment.isEmpty ? 'Bodyweight' : widget.exercise.equipment,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 16),
                    // Muscle Group
                    if (widget.exercise.rawData['muscle_group'] != null &&
                        (widget.exercise.rawData['muscle_group'] as String).isNotEmpty)
                      _InfoSection(
                        icon: Icons.accessibility_new,
                        title: 'Muscle Group',
                        content: widget.exercise.rawData['muscle_group'] as String,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    if (widget.exercise.rawData['muscle_group'] != null &&
                        (widget.exercise.rawData['muscle_group'] as String).isNotEmpty)
                      const SizedBox(height: 16),
                    // Instructions
                    _InfoSection(
                      icon: (widget.exercise.rawData['instructions'] as String?)?.isNotEmpty ?? false
                          ? Icons.article
                          : Icons.info_outline,
                      title: (widget.exercise.rawData['instructions'] as String?)?.isNotEmpty ?? false
                          ? 'Instructions'
                          : 'About',
                      content: (widget.exercise.rawData['instructions'] as String?)?.isNotEmpty ?? false
                          ? widget.exercise.rawData['instructions'] as String
                          : 'This is a ${widget.exercise.category} exercise. Focus on proper form and controlled movements.',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    if (widget.exercise.rawData['description'] != null &&
                        (widget.exercise.rawData['description'] as String).isNotEmpty)
                      _InfoSection(
                        icon: Icons.description,
                        title: 'Description',
                        content: widget.exercise.rawData['description'] as String,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    if (widget.exercise.rawData['description'] != null &&
                        (widget.exercise.rawData['description'] as String).isNotEmpty)
                      const SizedBox(height: 16),
                    // Video URL indicator
                    if (widget.exercise.videoUrl != null && widget.exercise.videoUrl!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_outline, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Video demonstration available',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Info section widget for exercise details
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// Stat card widget for displaying exercise statistics
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
