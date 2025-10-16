import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class _MeasurementDefinition {
  final String typeKey;
  final String supabaseType;
  final String label;
  final String section;
  final String unit;
  final IconData icon;
  final int decimals;
  final String? notesTag;

  const _MeasurementDefinition({
    required this.typeKey,
    required this.supabaseType,
    required this.label,
    required this.section,
    required this.unit,
    required this.icon,
    this.decimals = 1,
    this.notesTag,
  });
}

class _MeasurementRecord {
  final String id;
  final double value;
  final DateTime date;
  final String unit;
  final String? notes;
  final bool synced;

  const _MeasurementRecord({
    required this.id,
    required this.value,
    required this.date,
    required this.unit,
    this.notes,
    this.synced = true,
  });
}

class _MeasurementInfo {
  _MeasurementRecord? latest;
  List<_MeasurementRecord> history;

  _MeasurementInfo({this.latest, List<_MeasurementRecord>? history})
      : history = history ?? <_MeasurementRecord>[];
}

class MeasurementsScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const MeasurementsScreen({super.key, this.onNavigate});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  static const List<_MeasurementDefinition> _definitions = [
    // General Metrics
    _MeasurementDefinition(
      typeKey: 'weight',
      supabaseType: 'weight',
      label: 'Weight',
      section: 'General Metrics',
      unit: 'lbs',
      icon: Icons.monitor_weight,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'body_fat',
      supabaseType: 'body_fat',
      label: 'Body Fat',
      section: 'General Metrics',
      unit: '%',
      icon: Icons.percent,
      decimals: 1,
    ),
    // Upper Body
    _MeasurementDefinition(
      typeKey: 'neck',
      supabaseType: 'neck',
      label: 'Neck',
      section: 'Upper Body',
      unit: 'in',
      icon: Icons.accessibility_new,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'shoulders',
      supabaseType: 'shoulders',
      label: 'Shoulders',
      section: 'Upper Body',
      unit: 'in',
      icon: Icons.airport_shuttle,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'chest',
      supabaseType: 'chest',
      label: 'Chest',
      section: 'Upper Body',
      unit: 'in',
      icon: Icons.favorite,
      decimals: 1,
    ),
    // Arms
    _MeasurementDefinition(
      typeKey: 'left_bicep',
      supabaseType: 'left_bicep',
      label: 'Left Bicep',
      section: 'Arms',
      unit: 'in',
      icon: Icons.fitness_center,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'right_bicep',
      supabaseType: 'right_bicep',
      label: 'Right Bicep',
      section: 'Arms',
      unit: 'in',
      icon: Icons.fitness_center,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'left_forearm',
      supabaseType: 'left_forearm',
      label: 'Left Forearm',
      section: 'Arms',
      unit: 'in',
      icon: Icons.back_hand,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'right_forearm',
      supabaseType: 'right_forearm',
      label: 'Right Forearm',
      section: 'Arms',
      unit: 'in',
      icon: Icons.back_hand,
      decimals: 1,
    ),
    // Core
    _MeasurementDefinition(
      typeKey: 'upper_abs',
      supabaseType: 'upper_abs',
      label: 'Upper Abs',
      section: 'Core',
      unit: 'in',
      icon: Icons.rectangle,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'waist',
      supabaseType: 'waist',
      label: 'Waist',
      section: 'Core',
      unit: 'in',
      icon: Icons.circle_outlined,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'lower_abs',
      supabaseType: 'lower_abs',
      label: 'Lower Abs',
      section: 'Core',
      unit: 'in',
      icon: Icons.crop_square,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'hips',
      supabaseType: 'hips',
      label: 'Hips',
      section: 'Core',
      unit: 'in',
      icon: Icons.circle,
      decimals: 1,
    ),
    // Lower Body
    _MeasurementDefinition(
      typeKey: 'left_thigh',
      supabaseType: 'left_thigh',
      label: 'Left Thigh',
      section: 'Lower Body',
      unit: 'in',
      icon: Icons.directions_walk,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'right_thigh',
      supabaseType: 'right_thigh',
      label: 'Right Thigh',
      section: 'Lower Body',
      unit: 'in',
      icon: Icons.directions_walk,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'left_calf',
      supabaseType: 'left_calf',
      label: 'Left Calf',
      section: 'Lower Body',
      unit: 'in',
      icon: Icons.directions_run,
      decimals: 1,
    ),
    _MeasurementDefinition(
      typeKey: 'right_calf',
      supabaseType: 'right_calf',
      label: 'Right Calf',
      section: 'Lower Body',
      unit: 'in',
      icon: Icons.directions_run,
      decimals: 1,
    ),
  ];

  final LocalStorageService _localStorage = LocalStorageService.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  late final Map<String, List<_MeasurementDefinition>> _sections;
  final Map<String, _MeasurementInfo> _measurementData = {};
  final Set<String> _savingTypes = {};

  bool _isLoading = true;
  String? _loadError;
  DateTime? _lastUpdated;
  String _weightUnit = 'lbs';
  String _lengthUnit = 'in';

  @override
  void initState() {
    super.initState();
    _sections = _groupDefinitionsBySection();
    _loadUnitsAndMeasurements();
  }

  Future<void> _loadUnitsAndMeasurements() async {
    await _loadUnits();
    if (!mounted) return;
    await _loadMeasurements();
  }

  Map<String, List<_MeasurementDefinition>> _groupDefinitionsBySection() {
    final map = <String, List<_MeasurementDefinition>>{};
    for (final def in _definitions) {
      map.putIfAbsent(def.section, () => <_MeasurementDefinition>[]).add(def);
    }
    return map;
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
        : (localLength is String ? _normalizeLengthUnit(localLength) : _lengthUnit);

    if (!mounted) return;
    setState(() {
      _weightUnit = weight;
      _lengthUnit = length;
      // No direct loading state here
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
    if (unit == null) return 'in';
    final normalized = unit.toLowerCase();
    if (normalized.startsWith('cm')) return 'cm';
    if (normalized.contains('inch')) return 'in';
    if (normalized == 'in') return 'in';
    return normalized == 'cm' ? 'cm' : 'in';
  }

  bool _isWeightDefinition(_MeasurementDefinition def) => def.typeKey == 'weight';

  bool _isLengthDefinition(_MeasurementDefinition def) =>
      def.unit == 'in' && def.typeKey != 'weight';

  String _unitForDefinition(_MeasurementDefinition def) {
    if (_isWeightDefinition(def)) return _weightUnit;
    if (_isLengthDefinition(def)) return _lengthUnit;
    return def.unit;
  }

  double _convertWeight(double value, String from, String to) {
    final fromUnit = _normalizeWeightUnit(from);
    final toUnit = _normalizeWeightUnit(to);
    if (fromUnit == toUnit) return value;
    if (fromUnit == 'lbs' && toUnit == 'kg') return value * 0.45359237;
    if (fromUnit == 'kg' && toUnit == 'lbs') return value / 0.45359237;
    return value;
  }

  double _convertLength(double value, String from, String to) {
    final fromUnit = _normalizeLengthUnit(from);
    final toUnit = _normalizeLengthUnit(to);
    if (fromUnit == toUnit) return value;
    if (fromUnit == 'in' && toUnit == 'cm') return value * 2.54;
    if (fromUnit == 'cm' && toUnit == 'in') return value / 2.54;
    return value;
  }

  double _convertValueForDisplay(_MeasurementDefinition def, double value, String fromUnit) {
    if (_isWeightDefinition(def)) {
      return _convertWeight(value, fromUnit, _weightUnit);
    }
    if (_isLengthDefinition(def)) {
      return _convertLength(value, fromUnit, _lengthUnit);
    }
    return value;
  }

  Future<void> _loadMeasurements() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final tempData = <String, _MeasurementInfo>{};

      for (final def in _definitions) {
        final records = await _fetchRecordsForDefinition(def);
        tempData[def.typeKey] = _MeasurementInfo(
          latest: records.isNotEmpty ? records.first : null,
          history: records,
        );
      }

      if (!mounted) return;

      setState(() {
        _measurementData
          ..clear()
          ..addAll(tempData);
        _lastUpdated = _computeLastUpdated(_measurementData);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<_MeasurementRecord>> _fetchRecordsForDefinition(_MeasurementDefinition def) async {
    final records = <_MeasurementRecord>[];
    final seen = <String>{};

    if (_supabase.currentUserId != null) {
      try {
        final supaRecords = await _supabase.getMeasurements(def.supabaseType, notes: def.notesTag);
        for (final item in supaRecords) {
          final record = _recordFromSupabase(item, def);
          if (record != null && seen.add(record.id)) {
            records.add(record);
          }
        }
      } catch (e) {
        debugPrint('Failed to load Supabase measurements for ${def.typeKey}: $e');
      }
    }

    try {
      final localRecords = _localStorage.getMeasurementsByType(def.typeKey);
      for (final item in localRecords) {
        final record = _recordFromLocal(item, def);
        if (record != null && seen.add(record.id)) {
          records.add(record);
        }
      }
    } catch (e) {
      debugPrint('Failed to load local measurements for ${def.typeKey}: $e');
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return _limitHistory(records);
  }

  List<_MeasurementRecord> _limitHistory(List<_MeasurementRecord> records, [int max = 20]) {
    if (records.length <= max) return records;
    return records.sublist(0, max);
  }

  DateTime? _computeLastUpdated(Map<String, _MeasurementInfo> data) {
    DateTime? latest;
    for (final info in data.values) {
      final record = info.latest;
      if (record == null) continue;
      if (latest == null || record.date.isAfter(latest)) {
        latest = record.date;
      }
    }
    return latest;
  }

  String _formatValue(double value, int decimals) => value.toStringAsFixed(decimals);

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final local = date.toLocal();
    final month = months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month ${local.day}, ${local.year} • $hour:$minute';
  }

  Future<bool> _handleSaveMeasurement(
    _MeasurementDefinition def,
    double value,
    BuildContext context,
  ) async {
    if (!mounted) return false;

    setState(() {
      _savingTypes.add(def.typeKey);
    });

    final now = DateTime.now();
    final unit = _unitForDefinition(def);
    Map<String, dynamic>? supaRecord;
    var supabaseSuccess = false;

    if (_supabase.currentUserId != null) {
      try {
        supaRecord = await _supabase.addMeasurement(
          measurementType: def.supabaseType,
          value: value,
          unit: unit,
          measurementDate: now,
          notes: def.notesTag,
        );
        supabaseSuccess = true;
      } catch (e) {
        supabaseSuccess = false;
        supaRecord = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally. Will sync when online. ($e)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    try {
      final localMap = <String, dynamic>{
        'id': supaRecord?['id'],
        'type': def.typeKey,
        'measurement_type': def.supabaseType,
        'value': value,
        'unit': unit,
        'measurement_date': now.toIso8601String(),
        'date': now.toIso8601String(),
        'notes': def.notesTag,
        'syncStatus': supabaseSuccess ? 'synced' : 'pending',
      };

      await _localStorage.saveMeasurement(localMap);

      _MeasurementRecord? record;
      if (supaRecord != null) {
        record = _recordFromSupabase(supaRecord!, def);
      }
      record ??= _recordFromLocal(localMap, def);

      if (record == null) {
        throw Exception('Unable to process measurement value');
      }

      if (!mounted) return true;

      setState(() {
        final info = _measurementData[def.typeKey] ?? _MeasurementInfo();
        info.history.insert(0, record!);
        info.history = _limitHistory(info.history);
        info.latest = record;
        _measurementData[def.typeKey] = info;
        _lastUpdated = _computeLastUpdated(_measurementData);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${def.label} updated to ${_formatValue(value, def.decimals)} $unit'),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save measurement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _savingTypes.remove(def.typeKey);
        });
      }
    }
  }

  _MeasurementRecord? _recordFromSupabase(Map<String, dynamic> data, _MeasurementDefinition def) {
    final valueRaw = data['value'];
    final dateRaw = data['measurement_date'] ?? data['date'];
    if (valueRaw == null || dateRaw == null) return null;

    // Debug: Print the raw date from Supabase
    debugPrint('DEBUG: Raw date from Supabase for ${def.typeKey}: $dateRaw');

    final double? value =
        valueRaw is num ? valueRaw.toDouble() : double.tryParse(valueRaw.toString());
    final DateTime? date = DateTime.tryParse(dateRaw.toString());
    
    // Debug: Print the parsed DateTime
    debugPrint('DEBUG: Parsed DateTime: $date');
    
    if (value == null || date == null) return null;

    return _MeasurementRecord(
      id: data['id']?.toString() ?? '${def.typeKey}-${date.millisecondsSinceEpoch}',
      value: value,
      date: date,
      unit: (data['unit'] ?? def.unit).toString(),
      notes: data['notes']?.toString(),
      synced: true,
    );
  }

  _MeasurementRecord? _recordFromLocal(Map<String, dynamic> data, _MeasurementDefinition def) {
    final valueRaw = data['value'];
    final dateRaw = data['measurement_date'] ?? data['date'];
    if (valueRaw == null || dateRaw == null) return null;

    final double? value =
        valueRaw is num ? valueRaw.toDouble() : double.tryParse(valueRaw.toString());
    final DateTime? date =
        dateRaw is DateTime ? dateRaw : DateTime.tryParse(dateRaw.toString());
    if (value == null || date == null) return null;

    final syncStatus = data['syncStatus']?.toString();

    return _MeasurementRecord(
      id: data['id']?.toString() ?? '${def.typeKey}-${date.millisecondsSinceEpoch}',
      value: value,
      date: date,
      unit: (data['unit'] ?? def.unit).toString(),
      notes: data['notes']?.toString(),
      synced: syncStatus == 'synced',
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
          onPressed: () {
            widget.onNavigate?.call('profile');
          },
        ),
        title: const Text('Body Measurements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUnitsAndMeasurements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(colorScheme, textTheme),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    final children = <Widget>[
      Card(
        color: colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Track your progress by updating measurements regularly.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    if (_loadError != null) {
      children.add(const SizedBox(height: 16));
      children.add(
        Card(
          color: colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load measurements',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loadUnitsAndMeasurements,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (final entry in _sections.entries) {
      children.add(const SizedBox(height: 24));
      children.add(
        Text(
          entry.key,
          style: textTheme.titleLarge,
        ),
      );
      children.add(const SizedBox(height: 16));

      for (final def in entry.value) {
        final info = _measurementData[def.typeKey];
        children.add(
          _EditableMeasurementCard(
            definition: def,
            latest: info?.latest,
            history: info?.history ?? const [],
            colorScheme: colorScheme,
            textTheme: textTheme,
            isSaving: _savingTypes.contains(def.typeKey),
            onSave: (value) => _handleSaveMeasurement(def, value, context),
            formatDate: _formatDate,
            formatValue: (value) => _formatValue(value, def.decimals),
            unitLabel: _unitForDefinition(def),
            convertToDisplay: (value, unit) => _convertValueForDisplay(def, value, unit),
          ),
        );
        children.add(const SizedBox(height: 12));
      }
    }

    children.add(const SizedBox(height: 24));
    children.add(
      Center(
        child: Text(
          _lastUpdated == null
              ? 'No measurements recorded yet.'
              : 'Last updated: ${_formatDate(_lastUpdated!)}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    children.add(const SizedBox(height: 48));

    return RefreshIndicator(
      onRefresh: _loadUnitsAndMeasurements,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: children,
      ),
    );
  }
}

class _EditableMeasurementCard extends StatelessWidget {
  final _MeasurementDefinition definition;
  final _MeasurementRecord? latest;
  final List<_MeasurementRecord> history;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isSaving;
  final Future<bool> Function(double value) onSave;
  final String Function(DateTime date) formatDate;
  final String Function(double value) formatValue;
  final String unitLabel;
  final double Function(double value, String fromUnit) convertToDisplay;

  const _EditableMeasurementCard({
    required this.definition,
    required this.latest,
    required this.history,
    required this.colorScheme,
    required this.textTheme,
    required this.isSaving,
    required this.onSave,
    required this.formatDate,
    required this.formatValue,
    required this.unitLabel,
    required this.convertToDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final latestDisplay = latest != null
        ? convertToDisplay(latest!.value, latest!.unit)
        : null;
    final displayValue = latestDisplay != null
        ? '${formatValue(latestDisplay)} $unitLabel'
        : '-- $unitLabel';
    final subtitle = latest != null
        ? 'Last updated ${formatDate(latest!.date)}'
        : 'Tap to add your first measurement';

    return Card(
      child: InkWell(
        onTap: isSaving ? null : () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  definition.icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.label,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Flexible(
                      child: Text(
                        displayValue,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(
      text: latest != null
          ? formatValue(convertToDisplay(latest!.value, latest!.unit))
          : '',
    );
    String? errorText;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          definition.icon,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          definition.label,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: definition.label,
                  suffixText: unitLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(definition.icon),
                  errorText: errorText,
                ),
                enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent History',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _MeasurementHistory(
                    history: history,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    formatDate: formatDate,
                    formatValue: formatValue,
                    unitLabel: unitLabel,
                    toDisplayValue: (record) => convertToDisplay(record.value, record.unit),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final parsed = double.tryParse(controller.text.trim());
                              if (parsed == null) {
                                setModalState(() {
                                  errorText = 'Enter a valid number';
                                });
                                return;
                              }
                              setModalState(() {
                                isSubmitting = true;
                                errorText = null;
                              });
                              final success = await onSave(parsed);
                              if (!context.mounted) return;
                              if (success) {
                                Navigator.pop(context);
                              } else {
                                setModalState(() {
                                  isSubmitting = false;
                                });
                              }
                            },
                      icon: isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(isSubmitting ? 'Saving...' : 'Save Measurement'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


class _MeasurementHistory extends StatelessWidget {
  final List<_MeasurementRecord> history;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String Function(DateTime date) formatDate;
  final String Function(double value) formatValue;
  final String unitLabel;
  final double Function(_MeasurementRecord record) toDisplayValue;

  const _MeasurementHistory({
    required this.history,
    required this.colorScheme,
    required this.textTheme,
    required this.formatDate,
    required this.formatValue,
    required this.unitLabel,
    required this.toDisplayValue,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No measurements recorded yet.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: history.take(10).map((record) {
        final displayValue = toDisplayValue(record);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatValue(displayValue)} $unitLabel',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDate(record.date),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  record.synced ? Icons.cloud_done : Icons.cloud_upload,
                  color: record.synced ? colorScheme.secondary : colorScheme.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
