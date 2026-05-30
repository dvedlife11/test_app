import 'package:flutter/material.dart';

import 'design_system.dart';

class AppBottomPopupAction<T> {
  final String label;
  final T? value;
  final T? Function()? resolveValue;
  final Color? color;

  const AppBottomPopupAction({
    required this.label,
    this.value,
    this.resolveValue,
    this.color,
  });
}

Future<T?> showAppBottomPopupDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<AppBottomPopupAction<T>> actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final insetBottom = MediaQuery.of(sheetContext).viewInsets.bottom;
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + insetBottom),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1D1D1F),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.sectionCardTitle),
                const SizedBox(height: 12),
                content,
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map(
                        (action) => TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                action.color ?? AppColors.sectionLabel,
                            textStyle: AppTextStyles.mutedActionLink,
                          ),
                          onPressed: () => Navigator.pop(
                            sheetContext,
                            action.resolveValue?.call() ?? action.value,
                          ),
                          child: Text(
                            action.label,
                            style: AppTextStyles.mutedActionLink,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
