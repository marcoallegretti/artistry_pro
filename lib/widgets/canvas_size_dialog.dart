import 'package:flutter/material.dart';

class CanvasSizeDialog extends StatefulWidget {
  final Size? initialSize;

  const CanvasSizeDialog({Key? key, this.initialSize}) : super(key: key);

  @override
  _CanvasSizeDialogState createState() => _CanvasSizeDialogState();
}

class _CanvasSizeDialogState extends State<CanvasSizeDialog> {
  final _formKey = GlobalKey<FormState>();
  late double _width;
  late double _height;
  String _preset = 'custom';
  bool _maintainAspectRatio = false;
  double? _aspectRatio;

  // Common presets used in digital paint apps
  final Map<String, Size> _presets = {
    'custom': const Size(0, 0), // Placeholder for custom size
    'Instagram Post (1080×1080)': const Size(1080, 1080),
    'HD (1920×1080)': const Size(1920, 1080),
    '4K (3840×2160)': const Size(3840, 2160),
    'A4 Print (2480×3508)': const Size(2480, 3508),
    'Twitter Header (1500×500)': const Size(1500, 500),
    'Facebook Cover (851×315)': const Size(851, 315),
  };

  @override
  void initState() {
    super.initState();
    // Default to 1080×1080 canvas if no initial size provided
    _width = widget.initialSize?.width ?? 1080;
    _height = widget.initialSize?.height ?? 1080;
    
    // Check if the initial size matches any preset
    for (var entry in _presets.entries) {
      if (entry.key != 'custom' && 
          entry.value.width == _width && 
          entry.value.height == _height) {
        _preset = entry.key;
        break;
      }
    }
    
    if (widget.initialSize != null) {
      _aspectRatio = widget.initialSize!.width / widget.initialSize!.height;
    }
  }

  void _applyPreset(String presetName) {
    if (presetName == 'custom') return;
    
    final preset = _presets[presetName]!;
    setState(() {
      _width = preset.width;
      _height = preset.height;
      _aspectRatio = _width / _height;
    });
  }

  void _updateWidth(String value) {
    if (value.isEmpty) return;
    final newWidth = double.tryParse(value);
    if (newWidth == null) return;
    
    setState(() {
      _width = newWidth;
      if (_maintainAspectRatio && _aspectRatio != null) {
        _height = _width / _aspectRatio!;
      } else {
        _aspectRatio = _width / _height;
      }
    });
  }

  void _updateHeight(String value) {
    if (value.isEmpty) return;
    final newHeight = double.tryParse(value);
    if (newHeight == null) return;
    
    setState(() {
      _height = newHeight;
      if (_maintainAspectRatio && _aspectRatio != null) {
        _width = _height * _aspectRatio!;
      } else {
        _aspectRatio = _width / _height;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Canvas Size'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Presets dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Preset',
                  border: OutlineInputBorder(),
                ),
                value: _preset,
                items: _presets.keys.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _preset = newValue;
                    if (newValue != 'custom') {
                      _applyPreset(newValue);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Width and height inputs
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Width (px)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _width.round().toString(),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                      onChanged: _updateWidth,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Height (px)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _height.round().toString(),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                      onChanged: _updateHeight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Maintain aspect ratio checkbox
              Row(
                children: [
                  Checkbox(
                    value: _maintainAspectRatio,
                    onChanged: (bool? value) {
                      setState(() {
                        _maintainAspectRatio = value ?? false;
                        if (_maintainAspectRatio) {
                          _aspectRatio = _width / _height;
                        }
                      });
                    },
                  ),
                  const Text('Maintain aspect ratio'),
                ],
              ),
              
              // Canvas preview
              const SizedBox(height: 16),
              const Text('Preview:'),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _width / _height,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${_width.round()} × ${_height.round()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context, 
                Size(_width, _height),
              );
            }
          },
          child: const Text('Create Canvas'),
        ),
      ],
    );
  }
}
