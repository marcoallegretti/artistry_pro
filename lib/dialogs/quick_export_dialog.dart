import 'package:flutter/material.dart';

/// A simplified export dialog for quick exports from the top bar
class QuickExportDialog extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onExport;
  final bool isAnimation;

  const QuickExportDialog({
    super.key,
    required this.onExport,
    this.isAnimation = false,
  });

  @override
  _QuickExportDialogState createState() => _QuickExportDialogState();
}

class _QuickExportDialogState extends State<QuickExportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Untitled');
  String _format = 'png';
  int _jpegQuality = 90;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formats = widget.isAnimation ? ['gif'] : ['png', 'jpg'];

    return AlertDialog(
      title: const Text('Quick Export'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a file name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Format:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: formats.map((format) {
                return ButtonSegment<String>(
                  value: format,
                  label: Text(format.toUpperCase()),
                );
              }).toList(),
              selected: {_format},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _format = newSelection.first;
                });
              },
            ),
            if (_format == 'jpg')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('JPEG Quality:',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text('$_jpegQuality%'),
                    ],
                  ),
                  Slider(
                    min: 10,
                    max: 100,
                    divisions: 9,
                    value: _jpegQuality.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _jpegQuality = value.toInt();
                      });
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final name = _nameController.text;
              final params = <String, dynamic>{
                'format': _format,
                'includeTransparency': true,
              };

              if (_format == 'jpg') {
                params['jpegQuality'] = _jpegQuality;
              }

              widget.onExport(name, params);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}
