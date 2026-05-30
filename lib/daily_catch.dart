import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_card_surface.dart';
import 'design_system.dart';

class DailyCatchWidget extends StatefulWidget {
  const DailyCatchWidget({super.key});

  @override
  State<DailyCatchWidget> createState() => _DailyCatchWidgetState();
}

class _DailyCatchWidgetState extends State<DailyCatchWidget> {
  late Future<_DailyCatch> dailyCatchFuture;

  @override
  void initState() {
    super.initState();
    dailyCatchFuture = _loadDailyCatch();
  }

  Future<_DailyCatch> _loadDailyCatch() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/daily_home_clean.csv');
      final lines = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (lines.length < 2) {
        return const _DailyCatch(
          title: 'No entry',
          text: 'No daily catch available.',
        );
      }

      final header =
          lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();

      int indexOfAny(List<String> names) {
        for (final name in names) {
          final idx = header.indexOf(name.toLowerCase());
          if (idx >= 0) return idx;
        }
        return -1;
      }

      final titleCol = indexOfAny(const ['title', 'header']);
      final paragraphCol =
          indexOfAny(const ['paragraph', 'pharagraph', 'text', 'body']);
      final dayCol = indexOfAny(const ['dayindex', 'day_index', 'day']);

      final rows = lines
          .skip(1)
          .map((line) {
            final cols = line.split(',');
            String title = '';
            String text = '';
            if (titleCol >= 0 && cols.length > titleCol) {
              title = cols[titleCol].trim();
            }
            if (paragraphCol >= 0 && cols.length > paragraphCol) {
              text = cols[paragraphCol].trim();
            }
            if (title.isEmpty && cols.length > 1) {
              title = cols[1].trim();
            }
            if (text.isEmpty && cols.length > 2) {
              text = cols.sublist(2).join(',').trim();
            }
            if (title.isEmpty && text.isEmpty) return null;

            int? dayNumber;
            if (dayCol >= 0 && cols.length > dayCol) {
              final rawDay = cols[dayCol].trim();
              dayNumber = int.tryParse(rawDay);
              if (dayNumber == null) {
                final match = RegExp(r'\d+').firstMatch(rawDay);
                if (match != null) {
                  dayNumber = int.tryParse(match.group(0)!);
                }
              }
            }

            return {'day': dayNumber, 'title': title, 'text': text};
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      if (rows.isEmpty) {
        return const _DailyCatch(
          title: 'No entry',
          text: 'No daily catch available.',
        );
      }

      final todayDayOfMonth = DateTime.now().day;
      final byDay = rows.where((row) => row['day'] == todayDayOfMonth);
      if (byDay.isNotEmpty) {
        final row = byDay.first;
        return _DailyCatch(
          title: row['title'] ?? '',
          text: row['text'] ?? '',
        );
      }

      final index = (todayDayOfMonth - 1) % rows.length;
      final row = rows[index];
      return _DailyCatch(
        title: row['title'] ?? '',
        text: row['text'] ?? '',
      );
    } catch (_) {
      return const _DailyCatch(
        title: 'No entry',
        text: 'No daily catch available.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DailyCatch>(
      future: dailyCatchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: double.infinity,
            child: AppCardSurface(
              child: const SizedBox(height: 60),
            ),
          );
        }

        final entry = snapshot.data ??
            const _DailyCatch(
              title: 'No entry',
              text: 'No daily catch available.',
            );

        return SizedBox(
          width: double.infinity,
          child: AppCardSurface(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: AppTextStyles.sectionCardTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.text,
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DailyCatchScreen extends StatelessWidget {
  const DailyCatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            children: const [
              DailyCatchWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCatch {
  final String title;
  final String text;

  const _DailyCatch({required this.title, required this.text});
}
