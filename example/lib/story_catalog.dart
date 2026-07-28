import 'package:flutter/widgets.dart';

import 'stories/bottom_bar_story.dart';
import 'stories/button_story.dart';
import 'stories/card_story.dart';
import 'stories/keyboard_accessory_story.dart';
import 'stories/pressable_story.dart';
import 'stories/segmented_story.dart';
import 'stories/snackbar_story.dart';
import 'stories/tab_bar_story.dart';
import 'stories/text_field_story.dart';
import 'stories/tokens_story.dart';

@immutable
class StoryCatalogEntry {
  const StoryCatalogEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.subtitle,
    required this.builder,
    this.componentId,
  });

  final String id;
  final String? componentId;
  final String name;
  final String category;
  final String subtitle;
  final WidgetBuilder builder;
}

/// Runtime registration source checked against the Phase 4 story manifest.
///
/// A component id is present only when the page directly renders that public
/// component family. Tokens are a foundation story and intentionally have no
/// component id.
final List<StoryCatalogEntry> blabStoryCatalog = <StoryCatalogEntry>[
  StoryCatalogEntry(
    id: 'tokens',
    name: 'Tokens',
    category: 'Foundations',
    subtitle: 'Colors, typography, spacing, radius, shadow',
    builder: (_) => const TokensStory(),
  ),
  StoryCatalogEntry(
    id: 'button',
    componentId: 'button',
    name: 'Button',
    category: 'Inputs',
    subtitle: 'Primary / Secondary / Destructive',
    builder: (_) => const ButtonStory(),
  ),
  StoryCatalogEntry(
    id: 'text-field',
    componentId: 'text-field',
    name: 'TextField',
    category: 'Inputs',
    subtitle: 'Glass-fill input with label and clear',
    builder: (_) => const TextFieldStory(),
  ),
  StoryCatalogEntry(
    id: 'segmented-control',
    componentId: 'segmented-control',
    name: 'SegmentedControl',
    category: 'Inputs',
    subtitle: 'Pill-shaped segmented picker',
    builder: (_) => const SegmentedStory(),
  ),
  StoryCatalogEntry(
    id: 'tab-bar',
    componentId: 'tab-bar',
    name: 'TabBar',
    category: 'Inputs',
    subtitle: 'Controlled equal-width and scrollable navigation',
    builder: (_) => const TabBarStory(),
  ),
  StoryCatalogEntry(
    id: 'bottom-bar',
    componentId: 'bottom-bar',
    name: 'BottomBar',
    category: 'Inputs',
    subtitle: 'Controlled navigation, action, and disclosure',
    builder: (_) => const BottomBarStory(),
  ),
  StoryCatalogEntry(
    id: 'pressable-wrapper',
    componentId: 'pressable-wrapper',
    name: 'PressableWrapper',
    category: 'Inputs',
    subtitle: 'Direct press, focus, hover, and long-press wrapper',
    builder: (_) => const PressableStory(),
  ),
  StoryCatalogEntry(
    id: 'card',
    componentId: 'card',
    name: 'Card',
    category: 'Surfaces',
    subtitle: 'Static and actionable glass-fill container',
    builder: (_) => const CardStory(),
  ),
  StoryCatalogEntry(
    id: 'snackbar',
    componentId: 'snackbar',
    name: 'Snackbar',
    category: 'Feedback',
    subtitle: 'success / error / warning / info',
    builder: (_) => const SnackbarStory(),
  ),
  StoryCatalogEntry(
    id: 'keyboard-accessory-bar',
    componentId: 'keyboard-accessory-bar',
    name: 'KeyboardAccessoryBar',
    category: 'Inputs',
    subtitle: 'Navigation, editing history, and keyboard dismissal',
    builder: (_) => const KeyboardAccessoryStory(),
  ),
];
