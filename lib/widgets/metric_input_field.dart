import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// Remplace la virgule par un point pour que double.tryParse fonctionne
class _CommaToPointFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    // Remplacer toutes les virgules par des points
    final newText = value.text.replaceAll(',', '.');

    // S'assurer qu'il n'y a qu'un seul point décimal
    final parts = newText.split('.');
    final cleaned = parts.length > 2
        ? '${parts[0]}.${parts.sublist(1).join('')}'
        : newText;

    // Rejeter les caractères non numériques
    final filtered = cleaned.replaceAll(RegExp(r'[^\d.]'), '');

    return value.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class MetricInputField extends StatefulWidget {
  final String label;
  final String unit;
  final double? value;
  final ValueChanged<double?> onChanged;
  final IconData icon;
  final Color accentColor;
  final String hint;

  const MetricInputField({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.accentColor = AppTheme.primary,
    this.hint = '0',
  });

  @override
  State<MetricInputField> createState() => _MetricInputFieldState();
}

class _MetricInputFieldState extends State<MetricInputField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value != null ? _fmt(widget.value!) : '');
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Normaliser la virgule avant de parser
        final normalized = _ctrl.text.replaceAll(',', '.');
        widget.onChanged(double.tryParse(normalized));
      }
    });
  }

  @override
  void didUpdateWidget(MetricInputField old) {
    super.didUpdateWidget(old);
    if (!_focusNode.hasFocus) {
      final newText = widget.value != null ? _fmt(widget.value!) : '';
      if (_ctrl.text != newText) {
        _ctrl.text = newText;
        _ctrl.selection = TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(widget.icon, size: 13, color: widget.accentColor),
        const SizedBox(width: 5),
        Text(widget.label,
            style: AppFonts.label(color: Colors.grey.shade600, size: 11)),
      ]),
      const SizedBox(height: 6),
      TextField(
        controller:  _ctrl,
        focusNode:   _focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          // Accepte chiffres + point + virgule
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          // Convertit virgule → point et garde un seul séparateur
          _CommaToPointFormatter(),
        ],
        style: AppFonts.bold(color: Colors.grey.shade800, size: 15),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppFonts.body(color: Colors.grey.shade400, size: 14),
          suffixText: widget.unit,
          suffixStyle: AppFonts.unit(color: widget.accentColor),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.accentColor, width: 2),
          ),
        ),
        onEditingComplete: () {
          final normalized = _ctrl.text.replaceAll(',', '.');
          widget.onChanged(double.tryParse(normalized));
          _focusNode.unfocus();
        },
      ),
    ]);
  }
}