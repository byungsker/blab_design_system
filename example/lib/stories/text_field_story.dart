import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

class TextFieldStory extends StatefulWidget {
  const TextFieldStory({super.key});

  @override
  State<TextFieldStory> createState() => _TextFieldStoryState();
}

class _TextFieldStoryState extends State<TextFieldStory> {
  final _plain = TextEditingController();
  final _withLabel = TextEditingController(text: 'Sample input');
  final _helper = TextEditingController();
  final _error = TextEditingController(text: 'invalid-value');
  final _required = TextEditingController();
  final _disabled = TextEditingController(text: 'Unavailable');
  final _obscured = TextEditingController(text: 'secret');
  final _multiline = TextEditingController();
  final _readOnly = TextEditingController(text: 'Cannot edit this');

  @override
  void dispose() {
    _plain.dispose();
    _withLabel.dispose();
    _helper.dispose();
    _error.dispose();
    _required.dispose();
    _disabled.dispose();
    _obscured.dispose();
    _multiline.dispose();
    _readOnly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(BLabSpacing.lg),
      children: [
        _label('Default', context),
        BLabTextField(controller: _plain, hintText: 'Type here...'),
        SizedBox(height: BLabSpacing.xl),

        _label('With label & value', context),
        BLabTextField(
          controller: _withLabel,
          label: 'Full name',
          hintText: 'Your name',
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Helper relationship', context),
        BLabTextField(
          controller: _helper,
          label: 'Username',
          hintText: 'Enter a username',
          helperText: 'Use 3 or more characters',
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Invalid with error', context),
        BLabTextField(
          controller: _error,
          label: 'Email',
          hintText: 'name@example.com',
          helperText: 'Use an account address',
          errorText: 'Enter a valid email address',
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Required semantics', context),
        BLabTextField(
          controller: _required,
          label: 'Required field',
          isRequired: true,
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Disabled', context),
        BLabTextField(
          controller: _disabled,
          label: 'Disabled field',
          enabled: false,
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Obscured', context),
        BLabTextField(
          controller: _obscured,
          label: 'Password',
          hintText: 'Enter password',
          obscureText: true,
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Multi-line', context),
        BLabTextField(
          controller: _multiline,
          label: 'Notes',
          hintText: 'Write anything',
          maxLines: 4,
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Read-only', context),
        BLabTextField(
          controller: _readOnly,
          label: 'Read only',
          readOnly: true,
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
