import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExportDialog extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onExport;
  final bool isAnimation;

  const ExportDialog({
    Key? key,
    required this.onExport,
    this.isAnimation = false,
  }) : super(key: key);

  @override
  _ExportDialogState createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Untitled');
  String _format = 'png';
  int _jpegQuality = 90;
  int _frameRate = 24;
  bool _includeTransparency = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formats = widget.isAnimation
        ? ['mp4', 'gif', 'webp']
        : ['png', 'jpg', 'webp', 'psd'];

    if (!formats.contains(_format)) {
      _format = formats.first;
    }

    return AlertDialog(
      title: Text('Export ${widget.isAnimation ? 'Animation' : 'Image'}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'File Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a file name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('Format:', style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: 8),
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
              SizedBox(height: 16),
              if (_format == 'jpg')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('JPEG Quality:',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('${_jpegQuality}%'),
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
              if (widget.isAnimation)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text('Frame Rate:',
                        style: Theme.of(context).textTheme.titleSmall),
                    SizedBox(height: 8),
                    TextFormField(
                      initialValue: _frameRate.toString(),
                      decoration: InputDecoration(
                        labelText: 'FPS',
                        suffixText: 'frames per second',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final fps = int.tryParse(value);
                        if (fps == null || fps <= 0 || fps > 120) {
                          return 'Invalid';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _frameRate = int.parse(value);
                          });
                        }
                      },
                    ),
                  ],
                ),
              if (_format == 'png' || _format == 'webp')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _includeTransparency,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _includeTransparency = value;
                              });
                            }
                          },
                        ),
                        Text('Include transparency'),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final name = _nameController.text;

              final params = <String, dynamic>{
                'format': _format,
                'includeTransparency': _includeTransparency,
              };

              if (_format == 'jpg') {
                params['jpegQuality'] = _jpegQuality;
              }

              if (widget.isAnimation) {
                params['frameRate'] = _frameRate;
              }

              widget.onExport(name, params);
              Navigator.of(context).pop();
            }
          },
          child: Text('Export'),
        ),
      ],
    );
  }
}
