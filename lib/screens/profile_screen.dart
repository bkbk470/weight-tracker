import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
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

class ProfileScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const ProfileScreen({
    super.key,
    required this.onNavigate,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  int totalWorkouts = 0;
  bool isLoading = true;
  String? _profileIconKey;
  String? _avatarUrl;
  final LocalStorageService _localStorage = LocalStorageService.instance;
  String _measurementSystem = 'imperial';
  String _weightUnit = 'lbs';
  String _lengthUnit = 'in';
  bool _unitsLoading = true;
  bool _updatingUnits = false;
  String _currentAppIcon = 'default';

  IconData get _currentProfileIcon {
    final key = _profileIconKey;
    if (key != null) {
      for (final def in _profileIconDefinitions) {
        if (def.key == key) return def.icon;
      }
    }
    return Icons.person;
  }

  Future<void> _loadMeasurementUnits() async {
    String? weightSetting;
    String? lengthSetting;

    try {
      final settings = await SupabaseService.instance.getUserSettings();
      if (settings != null) {
        weightSetting = settings['weight_unit'] as String?;
        lengthSetting = settings['height_unit'] as String?;
      }
    } catch (_) {
      // Ignore errors and rely on local storage fallback
    }

    final localWeight = _localStorage.getSetting('weightUnit');
    final localLength = _localStorage.getSetting('lengthUnit');

    final resolvedWeight = _normalizeWeightUnit(
      weightSetting ?? (localWeight is String ? localWeight : _weightUnit),
    );
    final resolvedLength = _normalizeLengthUnit(
      lengthSetting ?? (localLength is String ? localLength : _lengthUnit),
    );
    final system = (resolvedWeight == 'kg' || resolvedLength == 'cm') ? 'metric' : 'imperial';

    if (!mounted) return;
    setState(() {
      _weightUnit = resolvedWeight;
      _lengthUnit = resolvedLength;
      _measurementSystem = system;
      _unitsLoading = false;
    });
  }

  String _normalizeWeightUnit(String unit) {
    final normalized = unit.toLowerCase();
    if (normalized.startsWith('kg')) return 'kg';
    return 'lbs';
  }

  String _normalizeLengthUnit(String unit) {
    final normalized = unit.toLowerCase();
    if (normalized.startsWith('cm')) return 'cm';
    if (normalized.contains('inch')) return 'in';
    return normalized == 'in' ? 'in' : 'cm';
  }

  String _measurementUnitsSubtitle() {
    if (_unitsLoading) return 'Loading units...';
    final base = _measurementSystem == 'metric' ? 'Metric (kg, cm)' : 'Imperial (lbs, in)';
    return _updatingUnits ? '$base • Updating…' : base;
  }

  Future<void> _updateMeasurementUnits(String system) async {
    if (!_unitsLoading && _measurementSystem == system) return;

    final newWeight = system == 'metric' ? 'kg' : 'lbs';
    final newLength = system == 'metric' ? 'cm' : 'in';

    if (mounted) {
      setState(() {
        _measurementSystem = system;
        _weightUnit = newWeight;
        _lengthUnit = newLength;
        _updatingUnits = true;
      });
    }

    try {
      if (SupabaseService.instance.currentUserId != null) {
        await SupabaseService.instance.upsertUserSettings({
          'weight_unit': newWeight,
          'height_unit': system == 'metric' ? 'cm' : 'inches',
        });
      }
      await _localStorage.saveSetting('weightUnit', newWeight);
      await _localStorage.saveSetting('lengthUnit', newLength);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              system == 'metric'
                  ? 'Switched to Metric (kg, cm)'
                  : 'Switched to Imperial (lbs, in)',
            ),
          ),
        );
      }
    } catch (e) {
      await _localStorage.saveSetting('weightUnit', newWeight);
      await _localStorage.saveSetting('lengthUnit', newLength);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally. Sync when online. ($e)'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingUnits = false;
        });
      }
    }
  }

  void _showMeasurementUnitsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Measurement Units'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Imperial (lbs, in)'),
                value: 'imperial',
                groupValue: _measurementSystem,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    _updateMeasurementUnits(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Metric (kg, cm)'),
                value: 'metric',
                groupValue: _measurementSystem,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    _updateMeasurementUnits(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadCurrentAppIcon() async {
    if (kIsWeb) return; // App icon changing not supported on web

    try {
      final currentIcon = await FlutterDynamicIcon.getAlternateIconName();
      if (mounted) {
        setState(() {
          _currentAppIcon = currentIcon ?? 'default';
        });
      }
    } catch (e) {
      debugPrint('Error loading current app icon: $e');
    }
  }

  Future<void> _changeAppIcon(String iconName) async {
    if (kIsWeb) return; // App icon changing not supported on web

    try {
      if (iconName == 'default') {
        await FlutterDynamicIcon.setAlternateIconName(null);
      } else {
        await FlutterDynamicIcon.setAlternateIconName(iconName);
      }

      if (mounted) {
        setState(() {
          _currentAppIcon = iconName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App icon changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change app icon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppIconDialog(BuildContext context) {
    final icons = [
      {'name': 'default', 'label': 'Blue (Default)', 'color': const Color(0xFF1976D2)},
      {'name': 'AppIcon-red', 'label': 'Red', 'color': const Color(0xFFD32F2F)},
      {'name': 'AppIcon-green', 'label': 'Green', 'color': const Color(0xFF388E3C)},
      {'name': 'AppIcon-orange', 'label': 'Orange', 'color': const Color(0xFFF57C00)},
      {'name': 'AppIcon-purple', 'label': 'Purple', 'color': const Color(0xFF7B1FA2)},
      {'name': 'AppIcon-dark', 'label': 'Dark', 'color': const Color(0xFF212121)},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose App Icon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: icons.map((icon) {
              final iconName = icon['name'] as String;
              final label = icon['label'] as String;
              final color = icon['color'] as Color;
              final isSelected = _currentAppIcon == iconName;

              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                        : null,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(label),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  Navigator.pop(context);
                  _changeAppIcon(iconName);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrentAppIcon();
  }

  Future<void> _loadUserData() async {
    try {
      // Get current user
      final user = SupabaseService.instance.currentUser;
      
      if (user != null) {
        setState(() {
          userEmail = user.email ?? 'No email';
        });

        // Try to get profile data
        try {
          final profile = await SupabaseService.instance.getProfile();
          if (profile != null && mounted) {
            setState(() {
              userName = profile['full_name'] ?? user.email?.split('@')[0] ?? 'User';
              final avatarUrl = profile['avatar_url'] as String?;
              if (avatarUrl != null && avatarUrl.startsWith('icon:')) {
                _profileIconKey = avatarUrl.substring('icon:'.length);
                _avatarUrl = null;
              } else {
                _profileIconKey = null;
                _avatarUrl = avatarUrl;
              }
            });
          } else {
            setState(() {
              userName = user.email?.split('@')[0] ?? 'User';
              _profileIconKey = null;
              _avatarUrl = null;
            });
          }
        } catch (e) {
          // If profile fetch fails, use email
          setState(() {
            userName = user.email?.split('@')[0] ?? 'User';
            _profileIconKey = null;
            _avatarUrl = null;
          });
        }

        // Get total workouts count
        try {
          final count = await SupabaseService.instance.getTotalWorkoutsCount();
          if (mounted) {
            setState(() {
              totalWorkouts = count;
            });
          }
        } catch (e) {
          print('Error loading workouts count: $e');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = 'Error loading';
        userEmail = 'Error loading';
      });
    } finally {
      await _loadMeasurementUnits();
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfileIcon(String iconKey) async {
    final previous = _profileIconKey;
    final previousAvatar = _avatarUrl;
    setState(() {
      _profileIconKey = iconKey;
      _avatarUrl = null;
    });

    try {
      await SupabaseService.instance.updateProfile({'avatar_url': 'icon:$iconKey'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile icon updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileIconKey = previous;
        _avatarUrl = previousAvatar;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile icon: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your account and preferences.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primary,
                      backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                          ? Icon(
                              _currentProfileIcon,
                              size: 40,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Sign Out Button
                const SizedBox(height: 16),

                // Stats Summary
                Text(
                  'Your Stats',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '$totalWorkouts',
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Workouts',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '23',
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PRs',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Settings
                Text(
                  'Settings',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme'),
                    subtitle: Text(
                      widget.currentThemeMode == ThemeMode.system
                      ? 'System default'
                      : widget.currentThemeMode == ThemeMode.light
                      ? 'Light mode'
                      : 'Dark mode',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                      showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                      title: const Text('Choose Theme'),
                      content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: widget.currentThemeMode,
                      onChanged: (value) {
                      if (value != null) {
                      widget.onThemeChanged(value);
                      Navigator.pop(context);
                      }
                      },
                      ),
                      RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: widget.currentThemeMode,
                      onChanged: (value) {
                      if (value != null) {
                      widget.onThemeChanged(value);
                      Navigator.pop(context);
                      }
                      },
                      ),
                      RadioListTile<ThemeMode>(
                      title: const Text('System default'),
                      value: ThemeMode.system,
                      groupValue: widget.currentThemeMode,
                      onChanged: (value) {
                      if (value != null) {
                      widget.onThemeChanged(value);
                      Navigator.pop(context);
                      }
                      },
                      ),
                      ],
                      ),
                      ),
                      );
                      },
                  ),
                ),
                if (!kIsWeb)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.apps_outlined),
                      title: const Text('App Icon'),
                      subtitle: Text(_currentAppIcon == 'default'
                          ? 'Blue (Default)'
                          : _currentAppIcon.replaceAll('AppIcon-', '').replaceFirst(
                                _currentAppIcon.replaceAll('AppIcon-', '')[0],
                                _currentAppIcon.replaceAll('AppIcon-', '')[0].toUpperCase(),
                              )),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAppIconDialog(context),
                    ),
                  ),
                _SettingsTile(
                  icon: Icons.straighten,
                  title: 'Body Measurements',
                  subtitle: 'Track all body part measurements',
                  onTap: () => widget.onNavigate('measurements'),
                ),
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () => widget.onNavigate('edit-profile'),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text('Measurement Units'),
                    subtitle: Text(_measurementUnitsSubtitle()),
                    trailing: _updatingUnits
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: (_unitsLoading || _updatingUnits)
                        ? null
                        : () => _showMeasurementUnitsDialog(context),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () => widget.onNavigate('notifications'),
                ),
                _SettingsTile(
                  icon: Icons.history,
                  title: 'Workout History',
                  subtitle: 'View all completed workouts',
                  onTap: () => widget.onNavigate('workout-history'),
                ),
                const SizedBox(height: 32),

                // Support
                Text(
                  'Support',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  onTap: () => widget.onNavigate('help-support'),
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Learn more about FitTrack',
                  onTap: () => widget.onNavigate('about'),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () => widget.onNavigate('privacy-policy'),
                ),
                const SizedBox(height: 32),

                // Logout
                OutlinedButton.icon(
                  onPressed: () => widget.onNavigate('login'),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'FitTrack v1.0.0',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showProfileImagePicker(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Picture',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Icon options
            Text(
              'Choose an icon',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
            children: _profileIconDefinitions.map((def) {
              return _IconOption(
                icon: def.icon,
                selected: def.key == _profileIconKey,
                colorScheme: colorScheme,
                onSelected: () {
                  Navigator.pop(context);
                  _updateProfileIcon(def.key);
                },
              );
            }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Upload option
            ListTile(
              leading: Icon(Icons.photo_library, color: colorScheme.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement image picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gallery picker will be implemented'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colorScheme.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera will be implemented'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMeasurementsDialog(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Measurements'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update your body measurements to track progress',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coming soon: Full measurement editor with history tracking',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _MeasurementRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
