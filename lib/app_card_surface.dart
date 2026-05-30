import 'package:flutter/material.dart';
import 'design_system.dart';
import 'dart:ui';

class AppCardSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppCardSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              // Gradient glassmorphism background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF232526),
                      Color(0xFF414345),
                      Color(0xFF6A82FB),
                      Color(0xFFFC5C7D),
                    ],
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        (backgroundColor ?? AppColors.card).withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: borderColor ?? Colors.white.withOpacity(0.55),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
