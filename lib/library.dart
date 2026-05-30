import 'package:flutter/material.dart';
import 'navigation_grid.dart';
import 'design_system.dart';
import 'app_card_surface.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
              _LibraryHeader(),
              SizedBox(height: 36),
              _QAItem(
                question: 'What is TheBone.?',
                answer:
                    'TheBone isn’t built to entertain you, overload you with information, or give you a temporary emotional high.\n\nIt is built to help you change your patterns through consistent repetition, persistence, and awareness.\n\nOne intense session of 1,000 repetitions means very little if you spend the rest of the day repeating the same old story, reactions, and mental patterns again.\n\nReal change happens when your repetition, mental diet, and daily behavior start moving in the same direction consistently over time.\n\nThe goal is simple: stop reinforcing the old patterns and thoughts long enough for the new direction to start feeling natural to you.',
              ),
              SizedBox(height: 14),
              _QAItem(
                question: 'How do our thoughts influence our reality?',
                answer:
                    'Your thoughts influence what you repeatedly focus on, emotionally react to, believe, expect, and reinforce every day.\n\nOver time, these repeated internal patterns shape your behavior, decisions, reactions, self-concept, and the way you interpret and respond to your reality.\n\nTheBone is built on the idea that when you consistently change the dominant pattern inside, your external experience gradually starts reflecting that change as well.',
              ),
              SizedBox(height: 14),
              _QAItem(
                question: 'Why repetitions matter',
                answer:
                    'Repetition matters because real change comes from consistency, not one intense session.\n\nThe aim is to keep returning to the new direction until it feels more natural than the old pattern.\n\nThat is why we use moderate but steady repetition across the day.\n\nIt is not about doing more for the sake of more. It is about repeated exposure interrupting old thoughts, reactions, and behaviors, then gradually replacing them with new ones.',
              ),
              SizedBox(height: 14),
              _QAItem(
                question: 'What is the onboarding quiz?',
                answer:
                    'The onboarding quiz is designed to identify your current impact profile and measure how strongly the old story is still influencing your thoughts, reactions, and daily patterns.\n\nBased on your answers, TheBone recommends a repetition level that matches your current conditioning rather than using a one-size-fits-all approach.',
              ),
              SizedBox(height: 14),
              _QAItem(
                question: 'Why is there an audio feature?',
                answer:
                    'The audio feature allows you to create a personalized affirmation file using your own selected affirmations and recordings.\n\nInstead of only repeating the affirmations silently in your mind, you can listen to them and repeat them out loud throughout your day.\n\nWe believe conscious repetition and active engagement create stronger conditioning than passive listening alone.\n\nFor that reason, TheBone does not use subliminals; meaning hidden audio tracks designed to bypass your conscious repetition.\n\nEach recording is temporarily processed into a simple audio file of approximately five minutes, with or without background sound, so you can use it consistently throughout your day.',
              ),
              SizedBox(height: 36),
              NavigationBottomGrid(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Library', style: AppTextStyles.mainTitle),
        const SizedBox(height: 8),
        const Text('Knowledge Base', style: AppTextStyles.body),
        const SizedBox(height: 10),
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

class _QAItem extends StatefulWidget {
  final String question;
  final String answer;

  const _QAItem({required this.question, required this.answer});

  @override
  State<_QAItem> createState() => _QAItemState();
}

class _QAItemState extends State<_QAItem> {
  static const int _collapsedMaxLines = 4;
  bool _expanded = false;

  String _collapsedPreviewText() {
    // Keep expanded view untouched, but normalize collapsed previews so line
    // breaks do not create uneven cut-off and spacing before the action link.
    return widget.answer
        .replaceAll(RegExp(r'\s*\n\s*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isOverflowing(BuildContext context, BoxConstraints constraints) {
    final preview = _collapsedPreviewText();
    final painter = TextPainter(
      text: TextSpan(text: preview, style: AppTextStyles.body),
      textDirection: Directionality.of(context),
      maxLines: _collapsedMaxLines,
    )..layout(maxWidth: constraints.maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.question, style: AppTextStyles.sectionCardTitle),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final canExpand = _isOverflowing(context, constraints);
              final preview = _collapsedPreviewText();
              final lineHeight = TextPainter(
                text: const TextSpan(text: 'A', style: AppTextStyles.body),
                textDirection: Directionality.of(context),
              )..layout(maxWidth: constraints.maxWidth);
              final collapsedHeight =
                  lineHeight.preferredLineHeight * _collapsedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: !_expanded && canExpand
                        ? SizedBox(
                            height: collapsedHeight,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                preview,
                                style: AppTextStyles.body,
                                maxLines: _collapsedMaxLines,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : Text(
                            widget.answer,
                            style: AppTextStyles.body,
                            maxLines: _expanded ? null : _collapsedMaxLines,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                  ),
                  if (canExpand) ...[
                    const SizedBox(height: AppSpacing.sectionTitleToContent),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _expanded = !_expanded;
                          });
                        },
                        child: Text(
                          _expanded ? 'Show less' : 'Read more',
                          style: AppTextStyles.mutedActionLink,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
