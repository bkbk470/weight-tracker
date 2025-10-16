import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';

class _ProfileIconDefinition {
  final String key;
  final IconData icon;

  const _ProfileIconDefinition(this.key, this.icon);
}

const List<_ProfileIconDefinition> _profileIconDefinitions = [
  _ProfileIconDefinition('person', Icons.person),
  _ProfileIconDefinition('face', Icons.face),
  _ProfileIconDefinition('smile', Icons.sentiment_satisfied),
  _ProfileIconDefinition('martial', Icons.sports_martial_arts),
  _ProfileIconDefinition('gym', Icons.fitness_center),
  _ProfileIconDefinition('gymnastics', Icons.sports_gymnastics),
  _ProfileIconDefinition('kabaddi', Icons.sports_kabaddi),
  _ProfileIconDefinition('yoga', Icons.self_improvement),
  _ProfileIconDefinition('run', Icons.directions_run),
  _ProfileIconDefinition('bike', Icons.directions_bike),
  _ProfileIconDefinition('swim', Icons.pool),
  _ProfileIconDefinition('hike', Icons.hiking),
  _ProfileIconDefinition('surf', Icons.surfing),
  _ProfileIconDefinition('row', Icons.rowing),
  _ProfileIconDefinition('tennis', Icons.sports_tennis),
  _ProfileIconDefinition('mma', Icons.sports_mma),
  _ProfileIconDefinition('esports', Icons.sports_esports),
  _ProfileIconDefinition('idea', Icons.tips_and_updates),
];

class EditProfileScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const EditProfileScreen({super.key, required this.onNavigate});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightGoalController = TextEditingController();
  
  final SupabaseService _supabase = SupabaseService.instance;
  final LocalStorageService _localStorage = LocalStorageService.instance;
  
  String? _selectedGender;
  String? _selectedExperienceLevel;
  DateTime? _dateOfBirth;
  bool _isLoading = true;
  bool _isSaving = false;
  String _heightUnit = 'cm';
  String _weightUnit = 'lbs';
  String? _profileIconKey;
  String? _avatarUrl;

  IconData get _currentProfileIcon {
    final key = _profileIconKey;
    if (key != null) {
      for (final def in _profileIconDefinitions) {
        if (def.key == key) return def.icon;
      }
    }
    return Icons.person;
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load units first
      await _loadUnits();

      // Get current user
      final user = _supabase.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to edit your profile')),
          );
          widget.onNavigate('login');
        }
        return;
      }

      // Load profile from Supabase
      Map<String, dynamic>? profile;
      try {
        profile = await _supabase.getProfile();
      } catch (e) {
        // Try loading from local storage if Supabase fails
        profile = _localStorage.getUserProfile();
      }

      if (!mounted) return;

      if (profile != null) {
        _nameController.text = profile['full_name'] ?? '';
        
        // Load avatar/icon
        final avatarUrl = profile['avatar_url'] as String?;
        if (avatarUrl != null && avatarUrl.startsWith('icon:')) {
          _profileIconKey = avatarUrl.substring('icon:'.length);
          _avatarUrl = null;
        } else {
          _profileIconKey = null;
          _avatarUrl = avatarUrl;
        }
        
        // Height
        final heightCm = profile['height_cm'];
        if (heightCm != null) {
          final heightValue = heightCm is num ? heightCm.toDouble() : double.tryParse(heightCm.toString());
          if (heightValue != null) {
            if (_heightUnit == 'cm') {
              _heightController.text = heightValue.toStringAsFixed(1);
            } else {
              // Convert cm to inches
              _heightController.text = (heightValue / 2.54).toStringAsFixed(1);
            }
          }
        }
        
        // Weight goal
        final weightGoal = profile['weight_goal_lbs'];
        if (weightGoal != null) {
          final weightValue = weightGoal is num ? weightGoal.toDouble() : double.tryParse(weightGoal.toString());
          if (weightValue != null) {
            if (_weightUnit == 'lbs') {
              _weightGoalController.text = weightValue.toStringAsFixed(1);
            } else {
              // Convert lbs to kg
              _weightGoalController.text = (weightValue * 0.45359237).toStringAsFixed(1);
            }
          }
        }

        _selectedGender = profile['gender'] as String?;
        _selectedExperienceLevel = profile['experience_level'] as String?;
        
        final dobString = profile['date_of_birth'] as String?;
        if (dobString != null) {
          _dateOfBirth = DateTime.tryParse(dobString);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnits() async {
    String? weightFromSupabase;
    String? lengthFromSupabase;

    try {
      if (_supabase.currentUserId != null) {
        final settings = await _supabase.getUserSettings();
        if (settings != null) {
          weightFromSupabase = settings['weight_unit'] as String?;
          lengthFromSupabase = settings['height_unit'] as String?;
        }
      }
    } catch (_) {
      // Ignore network errors; will fallback to local values
    }

    final localWeight = _localStorage.getSetting('weightUnit');
    final localLength = _localStorage.getSetting('lengthUnit');

    final weight = weightFromSupabase != null
        ? _normalizeWeightUnit(weightFromSupabase)
        : (localWeight is String ? _normalizeWeightUnit(localWeight) : _weightUnit);
    final length = lengthFromSupabase != null
        ? _normalizeLengthUnit(lengthFromSupabase)
        : (localLength is String ? _normalizeLengthUnit(localLength) : _heightUnit);

    if (!mounted) return;
    setState(() {
      _weightUnit = weight;
      _heightUnit = length;
    });
  }

  String _normalizeWeightUnit(String? unit) {
    if (unit == null) return 'lbs';
    final normalized = unit.toLowerCase();
    if (normalized.startsWith('kg')) return 'kg';
    if (normalized.startsWith('lb')) return 'lbs';
    return normalized == 'kg' ? 'kg' : 'lbs';
  }

  String _normalizeLengthUnit(String? unit) {
    if (unit == null) return 'cm';
    final normalized = unit.toLowerCase();
    if (normalized.startsWith('cm')) return 'cm';
    if (normalized.contains('inch')) return 'in';
    if (normalized == 'in') return 'in';
    return normalized == 'cm' ? 'cm' : 'in';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare profile data
      final profileData = <String, dynamic>{};

      // Full name
      if (_nameController.text.isNotEmpty) {
        profileData['full_name'] = _nameController.text.trim();
      }

      // Avatar/Icon
      if (_profileIconKey != null) {
        profileData['avatar_url'] = 'icon:$_profileIconKey';
      } else if (_avatarUrl != null) {
        profileData['avatar_url'] = _avatarUrl;
      }

      // Height - always store in cm
      if (_heightController.text.isNotEmpty) {
        final heightValue = double.tryParse(_heightController.text);
        if (heightValue != null) {
          if (_heightUnit == 'in') {
            // Convert inches to cm
            profileData['height_cm'] = heightValue * 2.54;
          } else {
            profileData['height_cm'] = heightValue;
          }
        }
      }

      // Weight goal - always store in lbs
      if (_weightGoalController.text.isNotEmpty) {
        final weightValue = double.tryParse(_weightGoalController.text);
        if (weightValue != null) {
          if (_weightUnit == 'kg') {
            // Convert kg to lbs
            profileData['weight_goal_lbs'] = weightValue / 0.45359237;
          } else {
            profileData['weight_goal_lbs'] = weightValue;
          }
        }
      }

      // Gender
      if (_selectedGender != null) {
        profileData['gender'] = _selectedGender;
      }

      // Experience level
      if (_selectedExperienceLevel != null) {
        profileData['experience_level'] = _selectedExperienceLevel;
      }

      // Date of birth
      if (_dateOfBirth != null) {
        profileData['date_of_birth'] = _dateOfBirth!.toIso8601String().split('T')[0];
      }

      // Save to Supabase
      bool supabaseSuccess = false;
      try {
        await _supabase.updateProfile(profileData);
        supabaseSuccess = true;
      } catch (e) {
        debugPrint('Failed to save to Supabase: $e');
      }

      // Save to local storage
      try {
        await _localStorage.saveUserProfile(profileData);
      } catch (e) {
        debugPrint('Failed to save to local storage: $e');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            supabaseSuccess
                ? 'Profile updated successfully!'
                : 'Profile saved locally. Will sync when online.',
          ),
          backgroundColor: supabaseSuccess
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.error,
        ),
      );

      // Navigate back
      widget.onNavigate('profile');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your date of birth',
    );

    if (picked != null && mounted) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showProfileIconPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Profile Icon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _profileIconDefinitions.map((def) {
                return _IconOption(
                  icon: def.icon,
                  selected: def.key == _profileIconKey,
                  colorScheme: Theme.of(context).colorScheme,
                  onSelected: () {
                    setState(() {
                      _profileIconKey = def.key;
                      _avatarUrl = null;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate('profile'),
        ),
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving || _isLoading ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: colorScheme.primary,
                            backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                                ? Icon(
                                    _currentProfileIcon,
                                    size: 60,
                                    color: colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () => _showProfileIconPicker(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: colorScheme.onSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Personal Information
                    Text(
                      'Personal Information',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date of Birth
                    InkWell(
                      onTap: _selectDateOfBirth,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(_dateOfBirth)),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                        DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Physical Stats
                    Text(
                      'Physical Stats',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Height',
                        suffixText: _heightUnit,
                        prefixIcon: const Icon(Icons.height),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _weightGoalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Weight Goal',
                        suffixText: _weightUnit,
                        prefixIcon: const Icon(Icons.flag_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedExperienceLevel,
                      decoration: const InputDecoration(
                        labelText: 'Experience Level',
                        prefixIcon: Icon(Icons.fitness_center),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                        DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                        DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedExperienceLevel = value);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Account Actions
                    Text(
                      'Account',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: const Text('Change Password'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => widget.onNavigate('change-password'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving || _isLoading ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}

class _IconOption extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;
  final ColorScheme colorScheme;

  const _IconOption({
    required this.icon,
    required this.selected,
    required this.onSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? colorScheme.onPrimary : colorScheme.primary,
            width: selected ? 3 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? colorScheme.onPrimary : colorScheme.onPrimaryContainer,
          size: 30,
        ),
      ),
    );
  }
}
