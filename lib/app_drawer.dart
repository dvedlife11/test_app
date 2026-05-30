import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: const Text('Main', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/home_final');
                });
              },
            ),
            ListTile(
              title: const Text('Dashboard',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/dashboard');
                });
              },
            ),
            ListTile(
              title: const Text('Catch The Bone',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/catch');
                });
              },
            ),
            ListTile(
              title:
                  const Text('Library', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/library');
                });
              },
            ),
            ListTile(
              title: const Text('Setup', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/setup');
                });
              },
            ),
            ListTile(
              title:
                  const Text('Design', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/blueprint');
                });
              },
            ),
            ListTile(
              title: const Text('Audio', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/audio');
                });
              },
            ),
            ListTile(
              title: const Text('Daily Quiz',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/daily_quiz');
                });
              },
            ),
            ListTile(
              title:
                  const Text('Counter?', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/counter');
                });
              },
            ),
            ListTile(
              title: const Text('Onboarding',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/onboarding_quiz');
                });
              },
            ),
            ListTile(
              title: const Text('Affirmation',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/card_affirmation');
                });
              },
            ),
            ListTile(
              title:
                  const Text('Umbrella', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/card_umbrella');
                });
              },
            ),
            ListTile(
              title:
                  const Text('Daily', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/daily_catch');
                });
              },
            ),
            ListTile(
              title:
                  const Text('Test Daily Catch', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.pushNamed(context, '/audio_copy');
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
