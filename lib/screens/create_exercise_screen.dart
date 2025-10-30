import 'package:flutter/material.dart';
import '../constants/exercise_assets.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';
import '../services/exercise_cache_service.dart';

class CreateExerciseScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const CreateExerciseScreen({super.key, this.onNavigate});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gifUrlController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Chest';
  String _selectedDifficulty = 'Beginner';
  String _selectedEquipment = 'Barbell';

  final _categories = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
    'Other'
  ];
  final _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  final _equipment = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Bodyweight',
    'Kettlebell',
    'Resistance Band',
    'Other',
  ];

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _gifUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final gifUrl = _gifUrlController.text.trim();
      final resolvedGifUrl =
          gifUrl.isNotEmpty ? gifUrl : kExercisePlaceholderImage;

      final exercise = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'difficulty': _selectedDifficulty,
        'equipment': _selectedEquipment,
        'notes': _notesController.text.trim(),
        'isCustom': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      exercise['imageUrl'] = resolvedGifUrl;
      exercise['image_url'] = resolvedGifUrl;

      // Save to local storage first (for offline support)
      await LocalStorageService.instance.saveExercise(exercise);

      // Try to save to Supabase (if online)
      try {
        await SupabaseService.instance.createExercise(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
          equipment: _selectedEquipment,
          notes: _notesController.text.trim(),
          imageUrl: resolvedGifUrl,
        );
      } catch (e) {
        // If Supabase fails (offline), it's ok - local storage has it
        print('Supabase save failed (offline?): $e');
      }

      // PERFORMANCE FIX: Clear exercise cache so new exercise appears immediately
      await ExerciseCacheService.instance.clearCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text} created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to exercises
      if (widget.onNavigate != null) {
        widget.onNavigate!('exercises');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create exercise: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!('exercises');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Info Card
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create your own custom exercises to add to workouts',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Exercise Name
            Text(
              'Exercise Name',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Cable Chest Press',
                prefixIcon: const Icon(Icons.fitness_center),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an exercise name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Demo GIF URL
            Text(
              'Demo GIF URL (optional)',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _gifUrlController,
              decoration: InputDecoration(
                hintText: 'https://your-storage.exercises/demo.gif',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }
                final trimmed = value.trim();
                final isHttp = trimmed.startsWith('http');
                final isStoragePath = trimmed.contains('/');
                if (!isHttp && !isStoragePath) {
                  return 'Enter a web URL or storage path (bucket/object.gif)';
                }
                if (!trimmed.toLowerCase().endsWith('.gif')) {
                  return 'URL should point to a .gif file';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Category
            Text(
              'Category',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Equipment
            Text(
              'Equipment',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedEquipment,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.sports_gymnastics),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _equipment.map((equipment) {
                return DropdownMenuItem(
                  value: equipment,
                  child: Text(equipment),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedEquipment = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Difficulty
            Text(
              'Difficulty',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.trending_up),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _difficulties.map((difficulty) {
                return DropdownMenuItem(
                  value: difficulty,
                  child: Text(difficulty),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDifficulty = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Notes (Optional)
            Text(
              'Notes (Optional)',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add instructions, form tips, or notes...',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Preview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        _nameController.text.isEmpty
                            ? 'Exercise Name'
                            : _nameController.text,
                        style: textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _selectedDifficulty,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedCategory,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedEquipment,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveExercise,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Creating...' : 'Create Exercise'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (widget.onNavigate != null) {
                        widget.onNavigate!('exercises');
                      }
                    },
              child: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
