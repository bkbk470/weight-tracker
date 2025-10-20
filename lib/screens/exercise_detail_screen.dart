import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../constants/exercise_assets.dart';
import '../services/supabase_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final String? returnScreen;
  final Map<String, dynamic>? exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.onNavigate,
    this.returnScreen,
    this.exercise,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _showGif = false;
  String selectedPeriod = '3M';
  final periods = ['1M', '3M', '6M', '1Y', 'All'];

  String _exerciseName = 'Bench Press';
  String _exerciseImagePath = kExercisePlaceholderImage;
  String? _exerciseVideoPath;
  final personalRecord = '225 lbs';
  final lastPerformed = '2 days ago';
  final totalVolume = '12,450 lbs';
  final totalSets = 156;

  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;

  bool get _isGif {
    if (_exerciseVideoPath != null && _exerciseVideoPath!.isNotEmpty) {
      return false;
    }
    final lower = _exerciseImagePath.toLowerCase();
    return lower.endsWith('.gif');
  }

  static final Map<String, Future<Uint8List>> _gifBytesCache = {};
  static final Map<String, Future<ui.Image>> _firstFrameCache = {};
  static final Map<String, Future<Duration>> _gifLoopDurationCache = {};
  Timer? _gifTimer;
  Duration? _gifSingleLoopDuration;

  @override
  void initState() {
    super.initState();
    _initializeExerciseData();
  }

  void _initializeExerciseData() {
    _gifTimer?.cancel();
    _showGif = false;
    _videoController?.dispose();
    _videoController = null;
    _isVideoLoading = false;

    final data = widget.exercise != null
        ? Map<String, dynamic>.from(widget.exercise!)
        : <String, dynamic>{};

    _exerciseName = _firstNonEmptyString(data, ['name', 'title']) ?? 'Bench Press';
    _exerciseImagePath = _firstNonEmptyString(
          data,
          ['image_url', 'imageUrl', 'thumbnail_url', 'media_url'],
        ) ??
        kExercisePlaceholderImage;
    _exerciseVideoPath = _firstNonEmptyString(
      data,
      ['video_url', 'videoUrl', 'video', 'demo_video_url', 'tutorial_video', 'video_path', 'media_video'],
    );

    if (_exerciseVideoPath != null && _exerciseVideoPath!.isNotEmpty) {
      Future.microtask(_prepareVideo);
    }
  }

  String? _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return null;
  }


  @override
  void didUpdateWidget(covariant ExerciseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exercise != oldWidget.exercise) {
      setState(() {
        _initializeExerciseData();
      });
    }
  }

  Future<void> _prepareVideo() async {
    final path = _exerciseVideoPath;
    if (path == null || path.isEmpty) return;

    setState(() => _isVideoLoading = true);

    try {
      String resolved = path;
      if (_needsSignedUrl(path)) {
        resolved = await SupabaseService.instance.getSignedUrlForStoragePath(path);
      }

      final controller = VideoPlayerController.networkUrl(Uri.parse(resolved));
      await controller.initialize();
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _isVideoLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing exercise video: $e');
      if (!mounted) return;
      setState(() {
        _isVideoLoading = false;
        _exerciseVideoPath = null;
      });
    }
  }

  bool _needsSignedUrl(String path) {
    return path.isNotEmpty &&
        !path.startsWith('http') &&
        !path.startsWith('assets/');
  }

  Future<Uint8List> _loadGifBytes(String assetPath) {
    return _gifBytesCache.putIfAbsent(assetPath, () async {
      if (assetPath.startsWith('http')) {
        final response = await http.get(Uri.parse(assetPath));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        throw Exception('Failed to download GIF (${response.statusCode})');
      }
      if (_needsSignedUrl(assetPath)) {
        final signedUrl = await SupabaseService.instance
            .getSignedUrlForStoragePath(assetPath);
        final response = await http.get(Uri.parse(signedUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        throw Exception(
            'Failed to download GIF from signed URL (${response.statusCode})');
      }
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    });
  }

  Future<ui.Image> _loadFirstFrame(String assetPath) {
    return _firstFrameCache.putIfAbsent(assetPath, () async {
      final bytes = await _loadGifBytes(assetPath);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    });
  }

  Future<Duration> _getGifLoopDuration(String assetPath) {
    return _gifLoopDurationCache.putIfAbsent(assetPath, () async {
      final bytes = await _loadGifBytes(assetPath);
      final codec = await ui.instantiateImageCodec(bytes);
      Duration total = Duration.zero;
      for (int i = 0; i < codec.frameCount; i++) {
        final frame = await codec.getNextFrame();
        total += frame.duration;
      }
      if (total == Duration.zero) {
        total = const Duration(seconds: 2);
      }
      return total;
    });
  }

  Widget _buildFullHeaderImage(String path, Widget Function() fallbackBuilder) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => fallbackBuilder(),
      );
    }
    if (_needsSignedUrl(path)) {
      return FutureBuilder<String>(
        future: SupabaseService.instance.getSignedUrlForStoragePath(path),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.network(
              snapshot.data!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => fallbackBuilder(),
            );
          }
          if (snapshot.hasError) {
            return fallbackBuilder();
          }
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 1.5));
        },
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => fallbackBuilder(),
    );
  }

  Widget _buildStaticHeaderImage(
      String path, Widget Function() fallbackBuilder) {
    if (!path.toLowerCase().endsWith('.gif')) {
      return _buildFullHeaderImage(path, fallbackBuilder);
    }

    return FutureBuilder<ui.Image>(
      future: _loadFirstFrame(path),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return RawImage(
            image: snapshot.data,
            fit: BoxFit.cover,
          );
        }
        return fallbackBuilder();
      },
    );
  }

  Future<void> _handlePlayPressed() async {
    if (!_isGif) return;

    setState(() => _showGif = true);
    _gifTimer?.cancel();

    try {
      _gifSingleLoopDuration ??= await _getGifLoopDuration(_exerciseImagePath);
      final totalDuration =
          (_gifSingleLoopDuration ?? const Duration(seconds: 2)) * 2;
      _gifTimer = Timer(totalDuration, () {
        if (!mounted) return;
        setState(() => _showGif = false);
      });
    } catch (e) {
      // Fallback to a steady timeout if decoding fails.
      _gifTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        setState(() => _showGif = false);
      });
    }
  }

  @override
  void dispose() {
    _gifTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildHeaderBackground(BuildContext context) {
    Widget gradientOverlay() => IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Theme.of(context).colorScheme.surface.withOpacity(0.7),
                ],
              ),
            ),
          ),
        );

    Widget errorFallback() => Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Icon(
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
        );

    if (_videoController != null && _videoController!.value.isInitialized) {
      final size = _videoController!.value.size;
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
          gradientOverlay(),
        ],
      );
    }

    if (_isVideoLoading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          errorFallback(),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          gradientOverlay(),
        ],
      );
    }

    if (_exerciseImagePath.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          errorFallback(),
          gradientOverlay(),
        ],
      );
    }

    final baseImage = _isGif && !_showGif
        ? _buildStaticHeaderImage(_exerciseImagePath, errorFallback)
        : _buildFullHeaderImage(_exerciseImagePath, errorFallback);

    return Stack(
      fit: StackFit.expand,
      children: [
        baseImage,
        if (_isGif && !_showGif)
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: _handlePlayPressed,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.play_arrow,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        if (_isGif && _showGif)
          _buildFullHeaderImage(_exerciseImagePath, errorFallback),
        gradientOverlay(),
      ],
    );
  }

  String get _backDestination => widget.returnScreen ?? 'exercises';

  Future<bool> _handleWillPop() async {
    widget.onNavigate(_backDestination);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => widget.onNavigate(_backDestination),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(_exerciseName),
                background: _buildHeaderBackground(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard(
                        icon: Icons.emoji_events,
                        label: 'Personal Record',
                        value: personalRecord,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                      _StatCard(
                        icon: Icons.calendar_today,
                        label: 'Last Performed',
                        value: lastPerformed,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                      _StatCard(
                        icon: Icons.bar_chart,
                        label: 'Total Volume',
                        value: totalVolume,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                      _StatCard(
                        icon: Icons.fitness_center,
                        label: 'Total Sets',
                        value: totalSets.toString(),
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Period Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress Over Time',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: periods.map((period) {
                        final isSelected = period == selectedPeriod;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(period),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => selectedPeriod = period);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weight Progression',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(
                                    show: true, drawVerticalLine: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const months = [
                                          'Jan',
                                          'Feb',
                                          'Mar',
                                          'Apr',
                                          'May',
                                          'Jun'
                                        ];
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < months.length) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              months[value.toInt()],
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: const [
                                      FlSpot(0, 185),
                                      FlSpot(1, 195),
                                      FlSpot(2, 205),
                                      FlSpot(3, 205),
                                      FlSpot(4, 215),
                                      FlSpot(5, 225),
                                    ],
                                    isCurved: true,
                                    color: colorScheme.primary,
                                    barWidth: 3,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter:
                                          (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: colorScheme.primary,
                                          strokeWidth: 0,
                                        );
                                      },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color:
                                          colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Volume Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volume Progression',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                gridData: const FlGridData(
                                    show: true, drawVerticalLine: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${(value / 1000).toInt()}k',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const months = [
                                          'Jan',
                                          'Feb',
                                          'Mar',
                                          'Apr',
                                          'May',
                                          'Jun'
                                        ];
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < months.length) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              months[value.toInt()],
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: [
                                  _createBarGroup(
                                      0, 1850, colorScheme.secondary),
                                  _createBarGroup(
                                      1, 2100, colorScheme.secondary),
                                  _createBarGroup(
                                      2, 2250, colorScheme.secondary),
                                  _createBarGroup(
                                      3, 2200, colorScheme.secondary),
                                  _createBarGroup(
                                      4, 2400, colorScheme.secondary),
                                  _createBarGroup(
                                      5, 2600, colorScheme.secondary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recent History
                  Text(
                    'Recent History',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...[
                    {
                      'date': '2 days ago',
                      'weight': '225 lbs',
                      'sets': '3',
                      'reps': '8, 8, 6'
                    },
                    {
                      'date': '5 days ago',
                      'weight': '220 lbs',
                      'sets': '3',
                      'reps': '8, 8, 8'
                    },
                    {
                      'date': '1 week ago',
                      'weight': '215 lbs',
                      'sets': '4',
                      'reps': '8, 8, 8, 7'
                    },
                    {
                      'date': '10 days ago',
                      'weight': '215 lbs',
                      'sets': '3',
                      'reps': '8, 8, 8'
                    },
                  ].map((workout) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            size: 20,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                            '${workout['weight']} × ${workout['sets']} sets'),
                        subtitle: Text(
                            'Reps: ${workout['reps']}\n${workout['date']}'),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _createBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
