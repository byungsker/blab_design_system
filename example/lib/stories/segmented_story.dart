import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

enum _Option { one, two, three }

class SegmentedStory extends StatefulWidget {
  const SegmentedStory({super.key});

  @override
  State<SegmentedStory> createState() => _SegmentedStoryState();
}

class _SegmentedStoryState extends State<SegmentedStory> {
  _Option _two = _Option.one;
  _Option _three = _Option.two;
  _Option _disabled = _Option.two;
  int _overflow = 4;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(BLabSpacing.lg),
      children: [
        _label('Two segments', context),
        BLabSegmentedControl<_Option>(
          items: const [
            BLabSegmentedItem(value: _Option.one, label: 'Light'),
            BLabSegmentedItem(value: _Option.two, label: 'Dark'),
          ],
          selectedValue: _two,
          onChanged: (v) => setState(() => _two = v),
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Three segments', context),
        BLabSegmentedControl<_Option>(
          items: const [
            BLabSegmentedItem(value: _Option.one, label: 'All'),
            BLabSegmentedItem(value: _Option.two, label: 'Active'),
            BLabSegmentedItem(value: _Option.three, label: 'Archived'),
          ],
          selectedValue: _three,
          onChanged: (v) => setState(() => _three = v),
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Narrow horizontal overflow (80px)', context),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 80,
            child: BLabSegmentedControl<_Option>(
              items: const [
                BLabSegmentedItem(value: _Option.one, label: 'One'),
                BLabSegmentedItem(value: _Option.two, label: 'Two'),
              ],
              selectedValue: _two,
              onChanged: (v) => setState(() => _two = v),
            ),
          ),
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Owned overflow reveals selected (80px)', context),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 80,
            child: BLabSegmentedControl<int>(
              items: const [
                BLabSegmentedItem(value: 0, label: 'Zero'),
                BLabSegmentedItem(value: 1, label: 'One'),
                BLabSegmentedItem(value: 2, label: 'Two'),
                BLabSegmentedItem(value: 3, label: 'Three'),
                BLabSegmentedItem(value: 4, label: 'Four'),
              ],
              selectedValue: _overflow,
              onChanged: (value) => setState(() => _overflow = value),
            ),
          ),
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Disabled item and disabled selection', context),
        BLabSegmentedControl<_Option>(
          items: const [
            BLabSegmentedItem(value: _Option.one, label: 'Available'),
            BLabSegmentedItem(
              value: _Option.two,
              label: 'Unavailable',
              enabled: false,
            ),
            BLabSegmentedItem(value: _Option.three, label: 'Later'),
          ],
          selectedValue: _disabled,
          onChanged: (v) => setState(() => _disabled = v),
        ),
      ],
    );
  }

  Widget _label(String text, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BLabSpacing.md),
      child: Text(
        text,
        style: BLabTypography.subtitle.copyWith(
          color: BLabColors.textPrimary(context),
        ),
      ),
    );
  }
}
