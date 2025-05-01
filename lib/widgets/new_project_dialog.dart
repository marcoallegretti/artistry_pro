import 'package:flutter/material.dart';
import '../models/canvas_settings.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  // Canvas settings
  double _width = 800;
  double _height = 600;
  Color _backgroundColor = Colors.white;
  bool _isTransparent = false;
  
  // Preset sizes
  final List<Map<String, dynamic>> _presetSizes = [
    {'name': 'A4 (Portrait)', 'width': 595, 'height': 842},
    {'name': 'A4 (Landscape)', 'width': 842, 'height': 595},
    {'name': 'Square', 'width': 800, 'height': 800},
    {'name': 'Instagram', 'width': 1080, 'height': 1080},
    {'name': 'HD', 'width': 1280, 'height': 720},
    {'name': 'Full HD', 'width': 1920, 'height': 1080},
  ];
  
  String? _selectedPreset;
  
  @override
  void initState() {
    super.initState();
    _selectedPreset = _presetSizes[0]['name'] as String;
    _width = _presetSizes[0]['width'] as double;
    _height = _presetSizes[0]['height'] as double;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  void _selectPreset(String? presetName) {
    if (presetName == null) return;
    
    final preset = _presetSizes.firstWhere(
      (preset) => preset['name'] == presetName,
      orElse: () => {'name': '', 'width': 800, 'height': 600},
    );
    
    setState(() {
      _selectedPreset = presetName;
      _width = preset['width'] as double;
      _height = preset['height'] as double;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Project Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Canvas Size',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Preset Size',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPreset,
                items: [
                  ..._presetSizes.map((preset) {
                    return DropdownMenuItem<String>(
                      value: preset['name'] as String,
                      child: Text(preset['name'] as String),
                    );
                  }),
                  const DropdownMenuItem<String>(
                    value: 'custom',
                    child: Text('Custom Size'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value == 'custom') {
                    setState(() {
                      _selectedPreset = 'custom';
                    });
                  } else {
                    _selectPreset(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Width (px)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _width.toStringAsFixed(0),
                      enabled: _selectedPreset == 'custom',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final width = double.tryParse(value);
                        if (width == null || width <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final width = double.tryParse(value);
                        if (width != null && width > 0) {
                          setState(() {
                            _width = width;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('×'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Height (px)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _height.toStringAsFixed(0),
                      enabled: _selectedPreset == 'custom',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final height = double.tryParse(value);
                        if (height != null && height > 0) {
                          setState(() {
                            _height = height;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Background',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Transparent Background'),
                contentPadding: EdgeInsets.zero,
                value: _isTransparent,
                onChanged: (value) {
                  setState(() {
                    _isTransparent = value;
                  });
                },
              ),
              if (!_isTransparent) ...[
                const SizedBox(height: 8),
                const Text('Background Color:'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final Color? color = await showDialog<Color>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Select Color'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: _backgroundColor,
                              onColorChanged: (Color color) {
                                setState(() {
                                  _backgroundColor = color;
                                });
                              },
                              pickerAreaHeightPercent: 0.8,
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () {
                                Navigator.of(context).pop(_backgroundColor);
                              },
                            ),
                          ],
                        );
                      },
                    );
                    
                    if (color != null) {
                      setState(() {
                        _backgroundColor = color;
                      });
                    }
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final canvasSettings = CanvasSettings(
                size: Size(_width, _height),
                backgroundColor: _backgroundColor,
                isTransparent: _isTransparent,
                checkerPatternOpacity: 0.2,
                checkerSquareSize: 10,
              );
              
              Navigator.pop(
                context,
                {
                  'title': _titleController.text,
                  'canvasSettings': canvasSettings,
                },
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// Simple color picker widget
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerAreaHeightPercent = 1.0,
  });

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  Color currentColor = Colors.white;
  final List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    currentColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300 * widget.pickerAreaHeightPercent,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              setState(() {
                currentColor = _colors[index];
              });
              widget.onColorChanged(currentColor);
            },
            child: Container(
              decoration: BoxDecoration(
                color: _colors[index],
                border: Border.all(
                  color: currentColor == _colors[index]
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: currentColor == _colors[index] ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }
}
