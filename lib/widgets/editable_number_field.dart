import 'package:flutter/material.dart';

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
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
    
    // Select all text when focus is gained
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void didUpdateWidget(EditableNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isHighlighted
              ? colorScheme.secondary.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.3),
          width: widget.isHighlighted ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: widget.textStyle,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          isDense: true,
        ),
        onChanged: (value) {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            widget.onChanged(intValue);
          }
        },
      ),
    );
  }
}
