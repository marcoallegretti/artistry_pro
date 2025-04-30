import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final Color color;

  const LogoWidget({
    super.key,
    this.size = 48.0,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.brush,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
