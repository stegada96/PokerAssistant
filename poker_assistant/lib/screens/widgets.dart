import 'package:flutter/material.dart';

class ChipPicker<T> extends StatelessWidget {
  final List<T> values;
  final String Function(T) label;
  final T? selected;
  final void Function(T) onPick;
  final Color? Function(T)? colorOf;

  const ChipPicker({
    super.key,
    required this.values,
    required this.label,
    required this.selected,
    required this.onPick,
    this.colorOf,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((v) {
        final c = colorOf?.call(v);
        return ChoiceChip(
          label: Text(
            label(v),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
          selected: selected == v,
          onSelected: (_) => onPick(v),
        );
      }).toList(),
    );
  }
}
