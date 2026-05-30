import 'package:flutter/material.dart';
import 'app_card_surface.dart';
import 'design_system.dart';

class AppNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AppNavCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      padding: const EdgeInsets.all(AppSpacing.s8),
      backgroundColor: AppColors.navCard,
      borderColor: AppColors.border,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0x22FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: const Color(0xB3FFFFFF),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
