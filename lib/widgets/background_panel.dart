import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Panel for selecting the background color
class BackgroundPanel extends StatelessWidget {
  final Color backgroundColor;
  final ValueChanged<Color> onBackgroundColorChanged;

  const BackgroundPanel({
    super.key,
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.photo, color: Theme.of(context).colorScheme.primary),
      title: Text('Canvas Background',
          style: Theme.of(context).textTheme.titleMedium),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Background Color',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              BlockPicker(
                pickerColor: backgroundColor,
                onColorChanged: onBackgroundColorChanged,
                availableColors: const [
                  Colors.white,
                  Colors.black,
                  Colors.grey,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
