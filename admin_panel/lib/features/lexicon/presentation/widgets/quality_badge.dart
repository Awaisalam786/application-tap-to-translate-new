import 'package:flutter/material.dart';
import '../../../quality/domain/models/word_quality.dart';

class QualityBadge extends StatelessWidget {
  final WordQualityReport quality;
  final double fontSize;

  const QualityBadge({
    super.key,
    required this.quality,
    this.fontSize = 11,
  });

  Color _getBgColor() {
    switch (quality.status) {
      case WordQualityStatus.complete:
        return const Color(0xFFDCFCE7); // green 100
      case WordQualityStatus.needsReview:
        return const Color(0xFFFEF9C3); // yellow 100
      case WordQualityStatus.incomplete:
        return const Color(0xFFFFEDD5); // orange 100
      case WordQualityStatus.missingRequired:
        return const Color(0xFFFEE2E2); // red 100
    }
  }

  Color _getTextColor() {
    switch (quality.status) {
      case WordQualityStatus.complete:
        return const Color(0xFF15803D); // green 700
      case WordQualityStatus.needsReview:
        return const Color(0xFFA16207); // yellow 700
      case WordQualityStatus.incomplete:
        return const Color(0xFFC2410C); // orange 700
      case WordQualityStatus.missingRequired:
        return const Color(0xFFB91C1C); // red 700
    }
  }

  IconData _getIcon() {
    switch (quality.status) {
      case WordQualityStatus.complete:
        return Icons.check_circle_outline;
      case WordQualityStatus.needsReview:
        return Icons.rate_review_outlined;
      case WordQualityStatus.incomplete:
        return Icons.pending_outlined;
      case WordQualityStatus.missingRequired:
        return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final issuesText = quality.issues.isEmpty
        ? 'Completeness score: ${quality.score}%'
        : 'Score: ${quality.score}%\nIssues:\n• ${quality.issues.join('\n• ')}';

    return Tooltip(
      message: issuesText,
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _getBgColor(),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _getTextColor().withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(), size: fontSize + 2, color: _getTextColor()),
            const SizedBox(width: 4),
            Text(
              quality.status.label,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
