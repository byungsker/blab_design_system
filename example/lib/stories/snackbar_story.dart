import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

class SnackbarStory extends StatefulWidget {
  const SnackbarStory({super.key});

  @override
  State<SnackbarStory> createState() => _SnackbarStoryState();
}

class _SnackbarStoryState extends State<SnackbarStory> {
  BLabSnackbarController? _persistentController;
  String _lastAction = 'No managed action yet';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(BLabSpacing.lg),
      children: [
        _label('Types', context),
        BLabButton(
          text: 'Show success',
          onPressed: () => BLabSnackbar.show(
            context,
            message: 'Draft saved',
            type: BLabSnackbarType.success,
          ),
        ),
        SizedBox(height: BLabSpacing.md),
        BLabButton(
          text: 'Show error',
          variant: BLabButtonVariant.destructive,
          onPressed: () => BLabSnackbar.show(
            context,
            message: "Couldn't save. Check your connection.",
            type: BLabSnackbarType.error,
          ),
        ),
        SizedBox(height: BLabSpacing.md),
        BLabButton(
          text: 'Show warning',
          variant: BLabButtonVariant.secondary,
          onPressed: () => BLabSnackbar.show(
            context,
            message: 'Unsaved changes will be lost',
            type: BLabSnackbarType.warning,
          ),
        ),
        SizedBox(height: BLabSpacing.md),
        BLabButton(
          text: 'Show info',
          variant: BLabButtonVariant.secondary,
          onPressed: () => BLabSnackbar.show(
            context,
            message: 'Synced just now',
            type: BLabSnackbarType.info,
          ),
        ),
        SizedBox(height: BLabSpacing.xl),
        _label('Managed modes', context),
        BLabButton(
          text: 'Show action and dismiss',
          onPressed: () => BLabSnackbar.showManaged(
            context,
            message: 'Archived one item',
            type: BLabSnackbarType.info,
            action: BLabSnackbarAction(
              label: 'Undo',
              onPressed: () => setState(() => _lastAction = 'Undo activated'),
            ),
            showDismissAction: true,
            dismissSemanticLabel: 'Dismiss archive notification',
          ),
        ),
        SizedBox(height: BLabSpacing.md),
        BLabButton(
          text: 'Queue three',
          variant: BLabButtonVariant.secondary,
          onPressed: () {
            for (final message in [
              'First queued',
              'Second queued',
              'Third queued',
            ]) {
              BLabSnackbar.showManaged(
                context,
                message: message,
                type: BLabSnackbarType.success,
              );
            }
          },
        ),
        SizedBox(height: BLabSpacing.md),
        BLabButton(
          text: 'Replace current',
          variant: BLabButtonVariant.secondary,
          onPressed: () => BLabSnackbar.showManaged(
            context,
            message: 'Replacement notification',
            type: BLabSnackbarType.warning,
            queuePolicy: BLabSnackbarQueuePolicy.replaceCurrent,
          ),
        ),
        SizedBox(height: BLabSpacing.md),
        BLabButton(
          text: _persistentController == null
              ? 'Show persistent'
              : 'Dismiss persistent',
          variant: BLabButtonVariant.secondary,
          onPressed: () {
            final current = _persistentController;
            if (current != null) {
              current.dismiss();
              setState(() => _persistentController = null);
              return;
            }
            final controller = BLabSnackbar.showManaged(
              context,
              message: 'Persistent until dismissed',
              type: BLabSnackbarType.info,
              persist: true,
              showDismissAction: true,
              dismissSemanticLabel: 'Dismiss persistent notification',
            );
            setState(() => _persistentController = controller);
            controller.closed.then((_) {
              if (mounted && identical(_persistentController, controller)) {
                setState(() => _persistentController = null);
              }
            });
          },
        ),
        SizedBox(height: BLabSpacing.md),
        Text(_lastAction, style: BLabTypography.caption),
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
