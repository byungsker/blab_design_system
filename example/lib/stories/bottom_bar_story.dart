import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/cupertino.dart';

class BottomBarStory extends StatefulWidget {
  const BottomBarStory({super.key});

  @override
  State<BottomBarStory> createState() => _BottomBarStoryState();
}

class _BottomBarStoryState extends State<BottomBarStory> {
  int _selectedIndex = 0;
  bool _firstTabExpanded = false;

  static const _items = <BLabBottomBarItem>[
    BLabBottomBarItem(
      icon: CupertinoIcons.cart,
      activeIcon: CupertinoIcons.cart_fill,
      label: 'Carts',
    ),
    BLabBottomBarItem(
      icon: CupertinoIcons.archivebox,
      activeIcon: CupertinoIcons.archivebox_fill,
      label: 'Archive',
    ),
    BLabBottomBarItem(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Controlled selection: ${_items[_selectedIndex].label}',
              style: BLabTypography.body,
            ),
          ),
        ),
        BLabBottomBar(
          tabs: _items,
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => setState(() => _selectedIndex = index),
          onSearchTap: (_, _) =>
              BLabSnackbar.show(context, message: 'Search action'),
          actionSemanticLabel: 'Search carts',
          showFirstTabChevron: true,
          onFirstTabChevronTap: () =>
              setState(() => _firstTabExpanded = !_firstTabExpanded),
          firstTabChevronSemanticLabel: _firstTabExpanded
              ? 'Collapse cart choices'
              : 'Expand cart choices',
          firstTabChevronExpanded: _firstTabExpanded,
        ),
      ],
    );
  }
}
