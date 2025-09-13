import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'bubble.dart';
import 'water_bottle.dart';
import 'wave.dart';
import 'water_container.dart';

class TriangularBottle extends StatefulWidget {
  /// Color of the water
  final Color waterColor;

  /// Color of the bottle
  final Color bottleColor;

  /// Color of the bottle cap
  final Color capColor;

  /// Should idle waves/bubbles animate?
  final bool waveAnimation;

  TriangularBottle({
    Key? key,
    this.waterColor = Colors.blue,
    this.bottleColor = Colors.blue,
    this.capColor = Colors.blueGrey,
    this.waveAnimation = true,
  }) : super(key: key);

  @override
  TriangularBottleState createState() => TriangularBottleState();
}

class TriangularBottleState extends State<TriangularBottle>
    with TickerProviderStateMixin, WaterContainer {
  @override
  void initState() {
    super.initState();
    initWater(widget.waterColor, this);

    if (widget.waveAnimation) {
      waves.first.animation.addListener(() {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    disposeWater();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        AspectRatio(
          aspectRatio: 1 / 1,
          child: CustomPaint(
            painter: TriangularBottleStatePainter(
              waves: waves,
              bubbles: widget.waveAnimation ? bubbles : const <Bubble>[],
              waterLevel: waterLevel,
              bottleColor: widget.bottleColor,
              capColor: widget.capColor,
            ),
          ),
        ),
      ],
    );
  }
}

class TriangularBottleStatePainter extends WaterBottlePainter {
  static const BREAK_POINT = 1.2;

  TriangularBottleStatePainter({
    Listenable? repaint,
    required List<WaveLayer> waves,
    required List<Bubble> bubbles,
    required double waterLevel,
    required Color bottleColor,
    required Color capColor,
  }) : super(
          repaint: repaint,
          waves: waves,
          bubbles: bubbles,
          waterLevel: waterLevel,
          bottleColor: bottleColor,
          capColor: capColor,
        );

  @override
  void paintEmptyBottle(Canvas canvas, Size size, Paint paint) {
    const SMOOTH_CORNER = true;
    final r = math.min(size.width, size.height);
    final neckTop = size.width * 0.1;
    final neckBottom = size.height - r + 3;
    final neckRingOuter = size.width * 0.28;
    final neckRingOuterR = size.width - neckRingOuter;
    final neckRingInner = size.width * 0.35;
    final neckRingInnerR = size.width - neckRingInner;
    final bodyBottom = size.height;
    final bodyL = 0.0;
    final bodyR = size.width;

    final path = Path()
      ..moveTo(neckRingOuter, neckTop)
      ..lineTo(neckRingInner, neckTop)
      ..lineTo(neckRingInner, neckBottom);

    if (SMOOTH_CORNER) {
      final bodyLAX = (neckRingInner - bodyL) * 0.1 + bodyL;
      final bodyLAY = (bodyBottom - neckBottom) * 0.9 + neckBottom;
      final bodyLBX = (bodyR - bodyL) * 0.1 + bodyL;
      final bodyLBY = bodyBottom;
      final bodyRAX = size.width - bodyLAX;
      final bodyRAY = bodyLAY;
      final bodyRBX = size.width - bodyLBX;
      final bodyRBY = bodyLBY;

      path
        ..lineTo(bodyLAX, bodyLAY)
        ..conicTo(bodyL, bodyBottom, bodyLBX, bodyLBY, 1)
        ..lineTo(bodyRBX, bodyRBY)
        ..conicTo(bodyR, bodyBottom, bodyRAX, bodyRAY, 1);
    } else {
      path
        ..lineTo(bodyL, bodyBottom)
        ..lineTo(bodyR, bodyBottom);
    }

    path
      ..lineTo(neckRingInnerR, neckBottom)
      ..lineTo(neckRingInnerR, neckTop)
      ..lineTo(neckRingOuterR, neckTop);

    canvas.drawPath(path, paint);
  }

  @override
  void paintBottleMask(Canvas canvas, Size size, Paint paint) {
    const SMOOTH_CORNER = true;
    final r = math.min(size.width, size.height);
    final neckTop = size.width * 0.1;
    final neckBottom = size.height - r + 3;
    final neckRingInner = size.width * 0.35 + 5;
    final neckRingInnerR = size.width - neckRingInner;
    final bodyBottom = size.height - 5;
    final bodyL = 5.0;
    final bodyR = size.width - 5;

    final path = Path()
      ..moveTo(neckRingInner, neckTop)
      ..lineTo(neckRingInner, neckBottom);

    if (SMOOTH_CORNER) {
      final bodyLAX = (neckRingInner - bodyL) * 0.1 + bodyL;
      final bodyLAY = (bodyBottom - neckBottom) * 0.9 + neckBottom;
      final bodyLBX = (bodyR - bodyL) * 0.1 + bodyL;
      final bodyLBY = bodyBottom;
      final bodyRAX = size.width - bodyLAX;
      final bodyRAY = bodyLAY;
      final bodyRBX = size.width - bodyLBX;
      final bodyRBY = bodyLBY;

      path
        ..lineTo(bodyLAX, bodyLAY)
        ..conicTo(bodyL, bodyBottom, bodyLBX, bodyLBY, 1)
        ..lineTo(bodyRBX, bodyRBY)
        ..conicTo(bodyR, bodyBottom, bodyRAX, bodyRAY, 1);
    } else {
      path
        ..lineTo(bodyL, bodyBottom)
        ..lineTo(bodyR, bodyBottom);
    }

    path
      ..lineTo(neckRingInnerR, neckBottom)
      ..lineTo(neckRingInnerR, neckTop)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  void paintGlossyOverlay(Canvas canvas, Size size, Paint paint) {
    final r = math.min(size.width, size.height);
    final rect = Offset(0, size.height - r) & size;
    final gradient = RadialGradient(
      center: Alignment.center,
      colors: [
        Colors.white.withAlpha(120),
        Colors.white.withAlpha(0),
      ],
    ).createShader(rect);

    paint.color = Colors.white;
    paint.shader = gradient;

    canvas.drawRect(
      Rect.fromLTRB(5, size.height - r + 3, size.width - 5, size.height - 5),
      paint,
    );
  }

  @override
  void paintCap(Canvas canvas, Size size, Paint paint) {
    if (size.height / size.width < BREAK_POINT) return;

    final capTop = 0.0;
    final capBottom = size.width * 0.2;
    final capMid = (capBottom - capTop) / 2;
    final capL = size.width * 0.33 + 5;
    final capR = size.width - capL;
    final neckRingInner = size.width * 0.35 + 5;
    final neckRingInnerR = size.width - neckRingInner;

    final path = Path()
      ..moveTo(capL, capTop)
      ..lineTo(neckRingInner, capMid)
      ..lineTo(neckRingInner, capBottom)
      ..lineTo(neckRingInnerR, capBottom)
      ..lineTo(neckRingInnerR, capMid)
      ..lineTo(capR, capTop)
      ..close();

    canvas.drawPath(path, paint);
  }
}
