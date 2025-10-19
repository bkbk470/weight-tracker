import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ProgressScreen({super.key, required this.onNavigate});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String selectedPeriod = '3M';
  String selectedMetric = 'volume';

  final periods = ['1M', '3M', '6M', '1Y'];

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
              title: const Text('Progress'),
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

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Period selector
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

                // Stats Overview
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _StatCard(
                      label: 'Total Workouts',
                      value: '127',
                      change: '+12%',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    _StatCard(
                      label: 'Personal Records',
                      value: '23',
                      change: '+5',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    _StatCard(
                      label: 'Current Streak',
                      value: '12 days',
                      change: '+3',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    _StatCard(
                      label: 'Total Volume',
                      value: '89.2k',
                      change: '+18%',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Progress Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress Chart',
                              style: textTheme.titleLarge,
                            ),
                            DropdownButton<String>(
                              value: selectedMetric,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'volume',
                                  child: Text('Training Volume'),
                                ),
                                DropdownMenuItem(
                                  value: 'strength',
                                  child: Text('Strength Score'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedMetric = value);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
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
                                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                      if (value.toInt() >= 0 && value.toInt() < months.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            months[value.toInt()],
                                            style: textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
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
                                  spots: [
                                    const FlSpot(0, 12500),
                                    const FlSpot(1, 13200),
                                    const FlSpot(2, 14100),
                                    const FlSpot(3, 13800),
                                    const FlSpot(4, 15200),
                                    const FlSpot(5, 16100),
                                  ],
                                  isCurved: true,
                                  color: colorScheme.primary,
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: colorScheme.primary,
                                        strokeWidth: 0,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: colorScheme.primary.withOpacity(0.1),
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
                const SizedBox(height: 32),

                // Weekly Activity
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Week',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 120,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
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
                                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            days[value.toInt()],
                                            style: textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
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
                                _createBarGroup(0, 1, colorScheme.secondary),
                                _createBarGroup(1, 0, colorScheme.secondary),
                                _createBarGroup(2, 1, colorScheme.secondary),
                                _createBarGroup(3, 0, colorScheme.secondary),
                                _createBarGroup(4, 1, colorScheme.secondary),
                                _createBarGroup(5, 1, colorScheme.secondary),
                                _createBarGroup(6, 0, colorScheme.secondary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '4 Workouts',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '80% of weekly goal',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '+1 from last week',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Recent Achievements
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Achievements',
                      style: textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AchievementCard(
                  icon: Icons.emoji_events,
                  title: 'Bench Press PR',
                  value: '225 lbs',
                  date: '2 days ago',
                  type: 'pr',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 12),
                _AchievementCard(
                  icon: Icons.local_fire_department,
                  title: '30 Day Streak',
                  value: 'Consistency',
                  date: '1 week ago',
                  type: 'streak',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 12),
                _AchievementCard(
                  icon: Icons.flag,
                  title: 'Volume Goal',
                  value: '15,000 lbs',
                  date: '2 weeks ago',
                  type: 'goal',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 12),
                _AchievementCard(
                  icon: Icons.military_tech,
                  title: 'Squat PR',
                  value: '315 lbs',
                  date: '3 weeks ago',
                  type: 'pr',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 32),

                // View Exercise Details
                OutlinedButton.icon(
                  onPressed: () => widget.onNavigate('exercise-detail'),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View Exercise Details'),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
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
  final String label;
  final String value;
  final String change;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
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
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String date;
  final String type;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.date,
    required this.type,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    Color containerColor;
    Color iconColor;

    switch (type) {
      case 'pr':
        containerColor = colorScheme.primaryContainer;
        iconColor = colorScheme.onPrimaryContainer;
        break;
      case 'streak':
        containerColor = colorScheme.secondaryContainer;
        iconColor = colorScheme.onSecondaryContainer;
        break;
      default:
        containerColor = colorScheme.surfaceVariant;
        iconColor = colorScheme.onSurface;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: containerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
