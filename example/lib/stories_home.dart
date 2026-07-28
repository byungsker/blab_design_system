import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

import 'story_catalog.dart';

class StoriesHome extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;

  const StoriesHome({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<StoryCatalogEntry>> grouped = {};
    for (final story in blabStoryCatalog) {
      grouped
          .putIfAbsent(story.category, () => <StoryCatalogEntry>[])
          .add(story);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLab Storybook'),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
            ),
            tooltip: themeMode == ThemeMode.light ? 'Dark mode' : 'Light mode',
            onPressed: onThemeToggle,
          ),
          SizedBox(width: BLabSpacing.sm),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(BLabSpacing.md),
        children: [
          for (final entry in grouped.entries) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                BLabSpacing.sm,
                BLabSpacing.md,
                BLabSpacing.sm,
                BLabSpacing.sm,
              ),
              child: Text(
                entry.key.toUpperCase(),
                style: BLabTypography.caption.copyWith(
                  color: BLabColors.textTertiary(context),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            BLabCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < entry.value.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: BLabColors.borderSubtle(context),
                      ),
                    _StoryTile(
                      story: entry.value[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) => _StoryPage(story: entry.value[i]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: BLabSpacing.xxl),
        ],
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  final StoryCatalogEntry story;
  final VoidCallback onTap;

  const _StoryTile({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: BLabSpacing.lg,
          vertical: BLabSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.name, style: BLabTypography.body),
                  SizedBox(height: BLabSpacing.xs),
                  Text(
                    story.subtitle,
                    style: BLabTypography.caption.copyWith(
                      color: BLabColors.textTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: BLabColors.textTertiary(context)),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  final StoryCatalogEntry story;

  const _StoryPage({required this.story});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(story.name)),
      body: story.builder(context),
    );
  }
}
