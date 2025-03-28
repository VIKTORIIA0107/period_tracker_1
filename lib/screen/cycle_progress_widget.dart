import 'package:flutter/material.dart';
import 'dart:math' as math;

// CycleProgressWidget creates a circular visualization of the menstrual cycle
// Shows the current cycle day, period days, fertile window, and ovulation day
// Uses CustomPaint to draw the circular progress indicator
class CycleProgressWidget extends StatelessWidget {
  final int cycleLength;
  final int periodLength;
  final int currentCycleDay;
  final double animation;

  const CycleProgressWidget({
    required this.cycleLength,
    required this.periodLength,
    required this.currentCycleDay,
    required this.animation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 160),
        painter: CycleProgressPainter(
          cycleLength: cycleLength,
          periodLength: periodLength,
          currentCycleDay: currentCycleDay,
          animation: animation,
        ),
      ),
    );
  }
}

class CycleProgressPainter extends CustomPainter {
  final int cycleLength;
  final int periodLength;
  final int currentCycleDay;
  final double animation;

  CycleProgressPainter({
    required this.cycleLength,
    required this.periodLength,
    required this.currentCycleDay,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;
    const strokeWidth = 25.0;

    // Calculate angles
    final periodAngle = 2 * math.pi * periodLength / cycleLength;
    final ovulationDayAngle = 2 * math.pi * (cycleLength - 14) / cycleLength;
    final fertileWindowStartAngle =
        2 * math.pi * (cycleLength - 19) / cycleLength;
    final fertileWindowEndAngle =
        2 * math.pi * (cycleLength - 14) / cycleLength;
    final currentDayAngle = 2 * math.pi * currentCycleDay / cycleLength;

    // Draw background cycle
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.shade200
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * animation,
      false,
      backgroundPaint,
    );

    // Draw period segment
    final periodPaint =
        Paint()
          ..color = Colors.pink
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      periodAngle * animation,
      false,
      periodPaint,
    );

    // Draw fertile window segment
    final fertilePaint =
        Paint()
          ..color = Colors.green.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + fertileWindowStartAngle * animation,
      (fertileWindowEndAngle - fertileWindowStartAngle) * animation,
      false,
      fertilePaint,
    );

    // Draw ovulation day marker
    final ovulationPaint =
        Paint()
          ..color = Colors.green.shade700
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + ovulationDayAngle * animation - 0.02,
      0.04,
      false,
      ovulationPaint,
    );

    // Draw current day marker
    if (currentCycleDay > 0 && currentCycleDay <= cycleLength) {
      final markerPaint =
          Paint()
            ..color = Colors.blue.shade600
            ..style = PaintingStyle.fill;

      final markerPosition = Offset(
        center.dx +
            radius * math.cos(-math.pi / 2 + currentDayAngle * animation),
        center.dy +
            radius * math.sin(-math.pi / 2 + currentDayAngle * animation),
      );

      canvas.drawCircle(markerPosition, 8, markerPaint);
    }

    // Draw labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw current day in center
    textPainter
      ..text = TextSpan(
        text: 'Day $currentCycleDay',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      )
      ..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Draw cycle length text
    textPainter
      ..text = TextSpan(
        text: '$cycleLength day cycle',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      )
      ..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 15),
    );
  }

  @override
  bool shouldRepaint(covariant CycleProgressPainter oldDelegate) {
    return oldDelegate.currentCycleDay != currentCycleDay ||
        oldDelegate.animation != animation;
  }
}
