import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0A0A0A);
  static const card = Color(0xFF1A1A1A);
  static const navCard = Color(0xFF141414);
  static const border = Color(0x1FFFFFFF);

  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white;
  static const body = Colors.white;

  static const activePill = Color(0xFFEDEDED);
  static const activeText = Color(0xFF0B0B0D);

  static const sectionLabel = Color(0xFF9C9C9C);
  static const bodyText = Colors.white;
  static const taskActivePill = Color(0xFFE4E4E4);
  static const taskInactivePill = Color(0xFF1A1A1A);
  static const taskActiveIconCircle = Color(0xFF0A0A0A);
  static const taskInactiveIconCircle = Color(0xFF232323);
  static const taskInactiveBorder = Color(0x1FFFFFFF);
  static const taskActiveText = Color(0xFF0A0A0A);
}

class AppSpacing {
  static const s8 = 8.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s36 = 36.0;

  static const sectionGap = s24;
  static const sectionTitleToContent = s8;
}

class AppSizes {
  static const taskPillHeight = 48.0;
  static const taskPillRadius = 16.0;
  static const taskTextSize = 16.0;
}

class AppTextStyles {
  static const global = TextStyle(height: 1.2, letterSpacing: -0.2);

  static const mainTitle = TextStyle(
    height: 1.2,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    letterSpacing: -0.8,
  );

  static const sectionLabel = TextStyle(
    height: 1.2,
    fontSize: 13,
    color: AppColors.sectionLabel,
    letterSpacing: 0.2,
  );

  static const cardTitle = TextStyle(
    height: 1.2,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  static const sectionCardTitle = TextStyle(
    height: 1.2,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const body = TextStyle(
    height: 1.3,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.bodyText,
    letterSpacing: -0.2,
  );

  static const primaryButton = TextStyle(
    fontSize: AppSizes.taskTextSize,
    fontWeight: FontWeight.w500,
    color: AppColors.taskActiveText,
    letterSpacing: -0.1,
  );

  static const secondaryButton = TextStyle(
    fontSize: AppSizes.taskTextSize,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  static const buttonLabel13 = TextStyle(
    height: 1.2,
    fontSize: 13,
    letterSpacing: -0.1,
  );

  static const body13 = TextStyle(
    height: 1.2,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const buttonLabel13Medium = TextStyle(
    height: 1.2,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );

  static const mutedActionLink = TextStyle(
    height: 1.2,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.sectionLabel,
    letterSpacing: -0.1,
  );

  static const buttonLabel13SemiBold = TextStyle(
    height: 1.2,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: '.SF Pro Text',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}

final ThemeData appTheme = ThemeData(
  fontFamily: '.SF Pro Text',
  dialogTheme: DialogTheme(
    backgroundColor: const Color(0xFF1D1D1F),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0x33FFFFFF)),
    ),
    titleTextStyle: AppTextStyles.sectionCardTitle.copyWith(
      color: AppColors.textPrimary,
    ),
    contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.sectionLabel,
      textStyle: AppTextStyles.mutedActionLink,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.sectionLabel),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0x55FFFFFF)),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xAAFFFFFF)),
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      height: 1.2,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      height: 1.2,
      color: Colors.white,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      height: 1.2,
      color: Colors.white,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      height: 1.2,
      color: Colors.white,
    ),
  ),
);
