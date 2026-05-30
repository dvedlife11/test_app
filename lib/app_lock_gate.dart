import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'app_repository.dart';

/// Wraps the app and requires biometric/passcode unlock on launch and resume.
class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  final AppRepository _repository = AppRepository();
  static const Duration _relockAfter = Duration(minutes: 2);

  bool _isUnlocked = false;
  bool _isAuthenticating = false;
  bool _enabled = true;
  String? _error;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEnabledAndMaybeAuthenticate();
  }

  Future<void> _loadEnabledAndMaybeAuthenticate(
      {bool forceAuth = false}) async {
    final enabled = await _repository.getAppLockEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
    });

    if (!_enabled) {
      setState(() {
        _isUnlocked = true;
        _error = null;
        _backgroundedAt = null;
      });
      return;
    }

    if (!forceAuth && _isUnlocked) {
      // Already unlocked in current foreground session.
      if (_backgroundedAt == null) return;

      // If the app was backgrounded only briefly, keep it unlocked.
      final now = DateTime.now();
      if (now.difference(_backgroundedAt!) < _relockAfter) {
        _backgroundedAt = null;
        return;
      }
    }

    await _authenticate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadEnabledAndMaybeAuthenticate());
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_enabled && _isUnlocked) {
        _backgroundedAt = DateTime.now();
      }
    }
  }

  Future<void> _authenticate() async {
    if (!_enabled) return;
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isSupported) {
        setState(() {
          _error = 'Device unlock is not available on this device.';
          _isAuthenticating = false;
        });
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: 'Unlock TheBone. private content',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;
      setState(() {
        _isUnlocked = ok;
        _isAuthenticating = false;
        if (ok) {
          _backgroundedAt = null;
        }
        if (!ok) {
          _error = 'Unlock required to continue.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _error = 'Authentication failed. Try again.';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked || !_enabled) return widget.child;

    return Material(
      color: const Color(0xFF090A0D),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Private Area',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unlock with Face ID, Touch ID or device passcode.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    child: Text(_isAuthenticating ? 'Unlocking...' : 'Unlock'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
