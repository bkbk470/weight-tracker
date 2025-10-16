import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final String? returnScreen;

  const ExerciseDetailScreen({
    super.key,
    required this.onNavigate,
    this.returnScreen,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  String selectedPeriod = '3M';
  final periods = ['1M', '3M', '6M', '1Y', 'All'];

  final exerciseName = 'Bench Press';
  final exerciseImageUrl =
      'https://images.unsplash.com/photo-1517964106626-460c5db42163?auto=format&fit=crop&w=1200&q=80';
  final personalRecord = '225 lbs';
  final lastPerformed = '2 days ago';
  final totalVolume = '12,450 lbs';
  final totalSets = 156;

  Widget _buildHeaderBackground(BuildContext context) {
    final gradient = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.surface,
        ],
      ),
    );

    if (exerciseImageUrl.isEmpty) {
      return Container(
        decoration: gradient,
        child: Center(
          child: Icon(
            Icons.fitness_center,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          exerciseImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: gradient,
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
            );
          },
        ),
        Container(
            decoration: gradient.copyWith(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.35),
              Theme.of(context).colorScheme.surface.withOpacity(0.7),
            ],
          ),
        )),
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
                title: Text(exerciseName),
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
