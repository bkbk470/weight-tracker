import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global manager to ensure only one field is editing at a time
class _EditableFieldManager {
  static final _EditableFieldManager _instance = _EditableFieldManager._internal();
  factory _EditableFieldManager() => _instance;
  _EditableFieldManager._internal();

  VoidCallback? _currentEditingField;

  void registerEditingField(VoidCallback stopEditing) {
    // Stop any currently editing field
    _currentEditingField?.call();
    _currentEditingField = stopEditing;
  }

  void unregisterEditingField() {
    _currentEditingField = null;
  }

  void stopCurrentEditing() {
    _currentEditingField?.call();
  }
}

/// A click-to-edit number field that completely avoids the Flutter Web focus bug
/// by only showing the TextField when explicitly tapped and ensuring only one field
/// is editing at a time
class EditableNumberField extends StatefulWidget {
  final int value;
  final Function(int) onChanged;
  final bool isHighlighted;
  final TextStyle? textStyle;
  final double height;

  const EditableNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.isHighlighted = false,
    this.textStyle,
    this.height = 40,
  });

  @override
  State<EditableNumberField> createState() => _EditableNumberFieldState();
}

class _EditableNumberFieldState extends State<EditableNumberField> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final _manager = _EditableFieldManager();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(EditableNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_isEditing) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    if (_isEditing) {
      _manager.unregisterEditingField();
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (_isEditing) return;
    
    // Stop any other field that's currently editing
    _manager.registerEditingField(_stopEditing);
    
    setState(() {
      _isEditing = true;
      _controller.text = '${widget.value}';
    });
    
    // Focus and select all text after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isEditing) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  void _stopEditing() {
    if (!mounted || !_isEditing) return;
    
    _manager.unregisterEditingField();
    
    // Unfocus immediately to prevent Flutter Web bug
    _focusNode.unfocus();
    
    // Small delay before parsing and updating
    Future.microtask(() {
      if (!mounted) return;
      
      final text = _controller.text.trim();
      if (text.isNotEmpty) {
        final intValue = int.tryParse(text);
        if (intValue != null && intValue >= 0 && intValue != widget.value) {
          widget.onChanged(intValue);
        }
      }
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _controller.text = '${widget.value}'; // Reset to current value
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: _isEditing ? null : _startEditing,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: _isEditing 
              ? colorScheme.surface
              : colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: widget.isHighlighted
                ? colorScheme.secondary.withOpacity(0.5)
                : (_isEditing 
                    ? colorScheme.primary.withOpacity(0.5)
                    : colorScheme.outline.withOpacity(0.3)),
            width: (_isEditing || widget.isHighlighted) ? 2 : 1,
          ),
        ),
        child: _isEditing
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: widget.textStyle,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _stopEditing(),
                onTapOutside: (_) => _stopEditing(),
              )
            : Center(
                child: Text(
                  '${widget.value}',
                  style: widget.textStyle,
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}
