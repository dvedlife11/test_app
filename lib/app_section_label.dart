import 'package:flutter/material.dart';
import 'design_system.dart';

class AppSectionLabel extends StatelessWidget {
  final String title;
  final bool centered;

  const AppSectionLabel({
    super.key,
    required this.title,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: AppTextStyles.sectionLabel,
    );

    if (!centered) return label;
    return SizedBox(width: double.infinity, child: label);
  }
}
