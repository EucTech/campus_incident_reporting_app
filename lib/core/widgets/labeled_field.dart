import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';

class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.obscure = false,
    this.maxLines = 1,
    this.maxLength,
    this.onSubmitted,
    this.onChanged,
    this.capitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscure;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextCapitalization capitalization;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: context.text.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.capitalization,
          autofillHints: widget.autofillHints,
          obscureText: _hidden,
          maxLines: widget.maxLines,
          inputFormatters: [if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength)],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          style: context.text.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: p.muted,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
