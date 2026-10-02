import 'package:flutter/material.dart';

class CefrBadge extends StatelessWidget {
  final String cefr;
  final double fontSize;

  const CefrBadge({
    super.key,
    required this.cefr,
    this.fontSize = 11,
  });

  Color _getColor() {
    switch (cefr.toUpperCase()) {
      case 'A1':
        return const Color(0xFF0284C7); // sky 600
      case 'A2':
        return const Color(0xFF2563EB); // blue 600
      case 'B1':
        return const Color(0xFF7C3AED); // violet 600
      case 'B2':
        return const Color(0xFF9333EA); // purple 600
      case 'C1':
        return const Color(0xFFC026D3); // fuchsia 600
      case 'C2':
        return const Color(0xFFDB2777); // pink 600
      default:
        return const Color(0xFF64748B); // slate 500
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        cefr.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
