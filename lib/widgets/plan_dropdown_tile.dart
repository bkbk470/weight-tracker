import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A reusable widget for displaying workout plans in a dropdown or list format
/// matching the alignment style shown in the screenshot
class PlanDropdownTile extends StatelessWidget {
  final String title;
  final int exerciseCount;
  final DateTime? scheduledTime;
  final bool isCompleted;
  final VoidCallback? onTap;
  final Color? accentColor;

  const PlanDropdownTile({
    super.key,
    required this.title,
    required this.exerciseCount,
    this.scheduledTime,
    this.isCompleted = false,
    this.onTap,
    this.accentColor,
  });

  String _formatScheduleInfo() {
    if (scheduledTime == null) {
      return 'Never completed';
    }

    final now = DateTime.now();
    final difference = now.difference(scheduledTime!);

    String timeAgo;
    if (difference.inDays == 0 && difference.inHours >= 0) {
      timeAgo = 'Today';
    } else if (difference.inDays == 1) {
      timeAgo = 'Yesterday';
    } else if (difference.inDays == -1) {
      timeAgo = 'Tomorrow';
    } else if (difference.inDays < 0 && difference.inDays > -7) {
      timeAgo = 'In ${-difference.inDays} days';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      timeAgo = weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      timeAgo = months == 1 ? '1 month ago' : '$months months ago';
    }

    final timeFormat = DateFormat('h:mm a');
    final timeStr = timeFormat.format(scheduledTime!);

    return '$timeAgo at $timeStr';
  }

  String _formatTimeOnly() {
    if (scheduledTime == null) return '';
    final timeFormat = DateFormat('h:mm a');
    return timeFormat.format(scheduledTime!);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveAccentColor = accentColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Icon on the left
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: effectiveAccentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                color: effectiveAccentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content in the middle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time on the right (only time, not full description)
                      if (scheduledTime != null)
                        Text(
                          _formatTimeOnly(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''} • ${_formatScheduleInfo()}',
                    style: textTheme.bodySmall?.copyWith(
                      color: isCompleted 
                          ? effectiveAccentColor.withOpacity(0.8)
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dropdown/popup menu that displays a list of workout plans
class PlanDropdownMenu extends StatelessWidget {
  final List<PlanDropdownItem> plans;
  final Function(PlanDropdownItem)? onPlanSelected;
  final String title;

  const PlanDropdownMenu({
    super.key,
    required this.plans,
    this.onPlanSelected,
    this.title = 'Select Plan',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Plans list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 32, top: 8),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return PlanDropdownTile(
                  title: plan.title,
                  exerciseCount: plan.exerciseCount,
                  scheduledTime: plan.scheduledTime,
                  isCompleted: plan.isCompleted,
                  accentColor: plan.accentColor,
                  onTap: () {
                    Navigator.of(context).pop();
                    onPlanSelected?.call(plan);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show the dropdown menu as a bottom sheet
  static Future<PlanDropdownItem?> show({
    required BuildContext context,
    required List<PlanDropdownItem> plans,
    String title = 'Select Plan',
  }) {
    return showModalBottomSheet<PlanDropdownItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => PlanDropdownMenu(
          plans: plans,
          title: title,
          onPlanSelected: (plan) {},
        ),
      ),
    );
  }
}

/// Data model for a plan dropdown item
class PlanDropdownItem {
  final String id;
  final String title;
  final int exerciseCount;
  final DateTime? scheduledTime;
  final bool isCompleted;
  final Color? accentColor;
  final Map<String, dynamic>? metadata;

  const PlanDropdownItem({
    required this.id,
    required this.title,
    required this.exerciseCount,
    this.scheduledTime,
    this.isCompleted = false,
    this.accentColor,
    this.metadata,
  });
}
