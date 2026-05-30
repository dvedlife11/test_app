import 'package:flutter/material.dart';
import 'app_section_label.dart';

class NavigationBottomGrid extends StatelessWidget {
  final Color? backgroundColor;
  final Color? cardColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? bodyColor;

  const NavigationBottomGrid({
    super.key,
    this.backgroundColor,
    this.cardColor,
    this.borderColor,
    this.textColor,
    this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.transparent;
    final card = cardColor ?? Colors.black.withOpacity(0.6);
    final border = borderColor ?? Colors.white24;
    final text = textColor ?? Colors.white;
    final body = bodyColor ?? Colors.white70;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionLabel(title: 'Your World', centered: true),
          const SizedBox(height: 8),
          SizedBox(
            height: 340,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _NavCard(
                        title: 'Home',
                        subtitle: 'Back home',
                        routeName: '/home_final',
                        cardColor: card,
                        borderColor: border,
                        textColor: text,
                        bodyColor: body,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _NavCard(
                        title: 'Dashboard',
                        subtitle: 'See your stats',
                        routeName: '/dashboard',
                        cardColor: card,
                        borderColor: border,
                        textColor: text,
                        bodyColor: body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _NavCard(
                        title: 'Need Help?',
                        subtitle: 'Guidance',
                        routeName: '/library',
                        cardColor: card,
                        borderColor: border,
                        textColor: text,
                        bodyColor: body,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _NavCard(
                        title: 'Setup',
                        subtitle: 'Preferences',
                        routeName: '/setup',
                        cardColor: card,
                        borderColor: border,
                        textColor: text,
                        bodyColor: body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _NavCard(
                        title: 'Chat with BUDDY',
                        subtitle: 'Performance coach',
                        routeName: '/buddy-chat',
                        cardColor: card,
                        borderColor: border,
                        textColor: text,
                        bodyColor: body,
                        icon: Icons.smart_toy_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String routeName;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color bodyColor;
  final IconData? icon;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.routeName,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.bodyColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData = icon ?? _getDefaultIcon();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x66000000),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 14,
                color: textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: bodyColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDefaultIcon() {
    if (title == 'Home') {
      return Icons.home_rounded;
    } else if (title == 'Dashboard') {
      return Icons.insights_rounded;
    } else if (title == 'Need Help?') {
      return Icons.menu_book_rounded;
    } else if (title == 'Setup') {
      return Icons.tune_rounded;
    } else if (title == 'Chat with BUDDY') {
      return Icons.smart_toy_rounded;
    } else {
      return Icons.circle;
    }
  }
}
