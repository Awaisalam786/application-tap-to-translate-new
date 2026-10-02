import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  Color _getBgColor() {
    switch (status.toLowerCase()) {
      case 'verified':
        return const Color(0xFFDCFCE7); // green 100
      case 'review':
        return const Color(0xFFFEF9C3); // yellow 100
      case 'draft':
        return const Color(0xFFF1F5F9); // slate 100
      case 'rejected':
        return const Color(0xFFFEE2E2); // red 100
      case 'archived':
        return const Color(0xFFE2E8F0); // slate 200
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getTextColor() {
    switch (status.toLowerCase()) {
      case 'verified':
        return const Color(0xFF15803D); // green 700
      case 'review':
        return const Color(0xFFA16207); // yellow 700
      case 'draft':
        return const Color(0xFF475569); // slate 600
      case 'rejected':
        return const Color(0xFFB91C1C); // red 700
      case 'archived':
        return const Color(0xFF334155); // slate 700
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getBgColor(),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getTextColor().withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getTextColor(),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
