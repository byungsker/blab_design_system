import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

import 'stories_home.dart';

void main() => runApp(const BLabStorybookApp());

class BLabStorybookApp extends StatefulWidget {
  const BLabStorybookApp({super.key});

  @override
  State<BLabStorybookApp> createState() => _BLabStorybookAppState();
}

class _BLabStorybookAppState extends State<BLabStorybookApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLab Storybook',
      debugShowCheckedModeBanner: false,
      theme: BLabTheme.light,
      darkTheme: BLabTheme.dark,
      themeMode: _themeMode,
      home: StoriesHome(themeMode: _themeMode, onThemeToggle: _toggleTheme),
    );
  }
}
