import 'package:flutter/material.dart';
import 'design_system.dart';

const Color _card = Color(0xFF1A1A1A);
const Color _border = Color(0x1FFFFFFF);
const Color _textPrimary = Colors.white;
const Color _textSecondary = Color(0xB3FFFFFF);
const Color _bodyText = Color(0xFFB5B5B5);

/* ================= PRIMARY ================= */

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E4E4),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.buttonLabel13Medium.copyWith(
            color: AppColors.taskActiveText,
          ),
        ),
      ),
    );
  }
}

/* ================= SECONDARY ================= */

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool compact;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 40.0 : 52.0;
    final horizontalPadding = compact ? 18.0 : 24.0;
    final radius = compact ? 20.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.buttonLabel13Medium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/* ================= CARD BUTTON ================= */

class AppCardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AppCardButton({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

/* ================= SELECTION ================= */

class AppSelectionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppSelectionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: selected ? _textPrimary : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _textPrimary : _border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.buttonLabel13Medium.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : _textPrimary,
          ),
        ),
      ),
    );
  }
}

class AppSelectionPillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  const AppSelectionPillButton({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = compact ? 34.0 : 40.0;
    final horizontalPadding = compact ? 14.0 : 18.0;
    final radius = compact ? 17.0 : 20.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: buttonHeight,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDEDED) : const Color(0xFF2A2A2E),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? const Color(0xFF0B0B0D) : const Color(0x26FFFFFF),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.buttonLabel13Medium.copyWith(
            color: selected ? const Color(0xFF0B0B0D) : Colors.white,
          ),
        ),
      ),
    );
  }
}

/* ================= YES/NO BUTTONS ================= */

class AppYesNoButton extends StatelessWidget {
  final VoidCallback? onYes;
  final VoidCallback? onNo;
  final bool? yesSelected;
  final bool? noSelected;

  const AppYesNoButton({
    super.key,
    this.onYes,
    this.onNo,
    this.yesSelected,
    this.noSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: AppPrimaryYesButton(
            selected: yesSelected ?? false,
            onTap: onYes,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppSecondaryNoButton(
            selected: noSelected ?? false,
            onTap: onNo,
          ),
        ),
      ],
    );
  }
}

class AppPrimaryYesButton extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const AppPrimaryYesButton({
    super.key,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDEDED) : const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF0B0B0D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 12,
                color: Color(0xFFEDEDED),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Yes',
              style: AppTextStyles.buttonLabel13Medium.copyWith(
                color: const Color(0xFF0B0B0D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSecondaryNoButton extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const AppSecondaryNoButton({
    super.key,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A2A2E) : const Color(0xFF2A2A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x26FFFFFF), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF3A3A3C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'No',
              style: AppTextStyles.buttonLabel13Medium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= RESET BUTTON ================= */

class AppResetButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppResetButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: 'Reset',
      onTap: onTap,
      compact: true,
    );
  }
}

/* ================= COUNTER ================= */

class AppCounterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppCounterButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: _textPrimary,
              ),
        ),
      ),
    );
  }
}

/* ================= TOGGLE ================= */

class AppToggleRow extends StatelessWidget {
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  const AppToggleRow({
    super.key,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: enabled ? _textPrimary : _bodyText,
                ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: enabled ? _textPrimary : const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Align(
              alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ================= NAV CARD ================= */

class AppNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const AppNavCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0x22FFFFFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: _textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _bodyText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= ICON BUTTON ================= */

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: _textPrimary),
    );
  }
}

/* ================= HAMBURGER ================= */

class AppHamburgerButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppHamburgerButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Scaffold.of(context).openDrawer(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0x99141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: const Icon(
          Icons.menu_rounded,
          size: 22,
          color: _textSecondary,
        ),
      ),
    );
  }
}

/* ================= RECORD/PLAY BUTTONS (YES/NO STYLE) ================= */

class AppRecordPlayButton extends StatelessWidget {
  final VoidCallback? onRecord;
  final VoidCallback? onPlay;
  final bool? recordSelected;
  final bool? playSelected;

  const AppRecordPlayButton({
    super.key,
    this.onRecord,
    this.onPlay,
    this.recordSelected,
    this.playSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: AppSecondaryPlayButton(
            selected: recordSelected ?? false,
            onTap: onRecord,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppSecondaryPlayButton(
            selected: playSelected ?? false,
            onTap: onPlay,
          ),
        ),
      ],
    );
  }
}

class AppPrimaryRecordButton extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const AppPrimaryRecordButton({
    super.key,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDEDED) : const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF0B0B0D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                size: 12,
                color: Color(0xFFEDEDED),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Record',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B0B0D),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSecondaryPlayButton extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const AppSecondaryPlayButton({
    super.key,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A2A2E) : const Color(0xFF2A2A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x26FFFFFF), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF3A3A3C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Play',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSecondaryPauseButton extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const AppSecondaryPauseButton({
    super.key,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A2A2E) : const Color(0xFF2A2A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x26FFFFFF), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF3A3A3C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pause_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Pause',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
