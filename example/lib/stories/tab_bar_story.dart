import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

class TabBarStory extends StatefulWidget {
  const TabBarStory({super.key});

  @override
  State<TabBarStory> createState() => _TabBarStoryState();
}

class _TabBarStoryState extends State<TabBarStory>
    with TickerProviderStateMixin {
  late final TabController _fixedController;
  late final TabController _scrollableController;

  @override
  void initState() {
    super.initState();
    _fixedController = TabController(length: 3, vsync: this);
    _scrollableController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _fixedController.dispose();
    _scrollableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(BLabSpacing.lg),
      children: [
        Text('Equal-width', style: BLabTypography.subtitle),
        SizedBox(height: BLabSpacing.sm),
        BLabTabBar(
          controller: _fixedController,
          tabs: const ['Overview', 'Activity', 'Settings'],
        ),
        SizedBox(height: BLabSpacing.xl),
        Text('Scrollable localized labels', style: BLabTypography.subtitle),
        SizedBox(height: BLabSpacing.sm),
        BLabTabBar(
          controller: _scrollableController,
          isScrollable: true,
          dividerColor: BLabColors.borderSubtle(context),
          tabs: const ['전체', '진행 중', '완료', '보관됨', '공유됨', '설정'],
        ),
      ],
    );
  }
}
