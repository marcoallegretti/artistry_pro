import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/painting_models.dart';

class NewDocumentDialog extends StatefulWidget {
  final Function(String, Size, double, ColorMode) onCreateDocument;

  const NewDocumentDialog({
    Key? key,
    required this.onCreateDocument,
  }) : super(key: key);

  @override
  _NewDocumentDialogState createState() => _NewDocumentDialogState();
}

class _NewDocumentDialogState extends State<NewDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Untitled');
  final _widthController = TextEditingController(text: '1920');
  final _heightController = TextEditingController(text: '1080');
  final _resolutionController = TextEditingController(text: '300');
  ColorMode _colorMode = ColorMode.RGB;

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Document'),
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
                  labelText: 'Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      decoration: InputDecoration(
                        labelText: 'Width',
                        suffixText: 'px',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final width = int.tryParse(value);
                        if (width == null || width <= 0 || width > 8000) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: 'Height',
                        suffixText: 'px',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final height = int.tryParse(value);
                        if (height == null || height <= 0 || height > 8000) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _resolutionController,
                decoration: InputDecoration(
                  labelText: 'Resolution',
                  suffixText: 'ppi',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final resolution = int.tryParse(value);
                  if (resolution == null ||
                      resolution <= 0 ||
                      resolution > 1200) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<ColorMode>(
                value: _colorMode,
                decoration: InputDecoration(
                  labelText: 'Color Mode',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  DropdownMenuItem(value: ColorMode.RGB, child: Text('RGB')),
                  DropdownMenuItem(value: ColorMode.CMYK, child: Text('CMYK')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _colorMode = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              _buildPresetButtons(),
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
              final width = double.parse(_widthController.text);
              final height = double.parse(_heightController.text);
              final resolution = double.parse(_resolutionController.text);

              widget.onCreateDocument(
                  name, Size(width, height), resolution, _colorMode);
              Navigator.of(context).pop();
            }
          },
          child: Text('Create'),
        ),
      ],
    );
  }

  Widget _buildPresetButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Presets:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetButton('HD', 1280, 720),
            _buildPresetButton('Full HD', 1920, 1080),
            _buildPresetButton('4K', 3840, 2160),
            _buildPresetButton('Square', 1080, 1080),
            _buildPresetButton('Instagram', 1080, 1350),
            _buildPresetButton('A4', 2480, 3508),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, int width, int height) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _widthController.text = width.toString();
          _heightController.text = height.toString();
        });
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }
}
