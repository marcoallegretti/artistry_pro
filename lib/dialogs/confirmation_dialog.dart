import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onConfirm;
  final Color? confirmButtonColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmButtonText = 'Confirm',
    this.cancelButtonText = 'Cancel',
    required this.onConfirm,
    this.confirmButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor =
        confirmButtonColor ?? Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelButtonText),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(confirmButtonText),
        ),
      ],
    );
  }

  /// Show the confirmation dialog
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmButtonText = 'Confirm',
    String cancelButtonText = 'Cancel',
    required VoidCallback onConfirm,
    Color? confirmButtonColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: title,
            message: message,
            confirmButtonText: confirmButtonText,
            cancelButtonText: cancelButtonText,
            onConfirm: onConfirm,
            confirmButtonColor: confirmButtonColor,
          ),
        ) ??
        false;
  }
}
