import 'package:flutter/material.dart';
import 'design_system.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final CrossAxisAlignment crossAxisAlignment;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isCentered = crossAxisAlignment == CrossAxisAlignment.center;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(title, style: AppTextStyles.mainTitle),
        const SizedBox(height: AppSpacing.s8),
        Text(subtitle, style: AppTextStyles.body),
        const SizedBox(height: 10),
        if (isCentered)
          Center(
            child: Container(
              width: 52,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xAAFFFFFF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          )
        else
          Container(
            width: 52,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xAAFFFFFF),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}
