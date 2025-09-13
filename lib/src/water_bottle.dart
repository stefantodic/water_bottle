import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'water_container.dart';
import 'wave.dart';
import 'bubble.dart';

class WaterBottle extends StatefulWidget {
  /// Color of the water
  final Color waterColor;

  /// Color of the bottle
  final Color bottleColor;

  /// Color of the bottle cap
  final Color capColor;

  /// Should idle waves/bubbles animate?
  final bool waveAnimation;

  WaterBottle({
    Key? key,
    this.waterColor = Colors.blue,
    this.bottleColor = Colors.blue,
    this.capColor = Colors.blueGrey,
    this.waveAnimation = true,
  }) : super(key: key);

  @override
  WaterBottleState createState() => WaterBottleState();
}

class WaterBottleState extends State<WaterBottle>
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
            painter: WaterBottlePainter(
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

class WaterBottlePainter extends CustomPainter {
  final List<WaveLayer> waves;
  final List<Bubble> bubbles;
  final double waterLevel;
  final Color bottleColor;
  final Color capColor;

  WaterBottlePainter({
    Listenable? repaint,
    required this.waves,
    required this.bubbles,
    required this.waterLevel,
    required this.bottleColor,
    required this.capColor,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    {
      final paint = Paint()
        ..color = bottleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      paintEmptyBottle(canvas, size, paint);
    }
    {
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final rect = Rect.fromLTRB(0, 0, size.width, size.height);
      canvas.saveLayer(rect, paint);
      paintBottleMask(canvas, size, paint);
    }
    {
      final paint = Paint()
        ..blendMode = BlendMode.srcIn
        ..style = PaintingStyle.fill;
      paintWaves(canvas, size, paint);
    }
    {
      final paint = Paint()
        ..blendMode = BlendMode.srcATop
        ..style = PaintingStyle.fill;
      paintBubbles(canvas, size, paint);
    }
    {
      final paint = Paint()
        ..blendMode = BlendMode.srcATop
        ..style = PaintingStyle.fill;
      paintGlossyOverlay(canvas, size, paint);
    }
    canvas.restore();
    {
      final paint = Paint()
        ..blendMode = BlendMode.srcATop
        ..style = PaintingStyle.fill
        ..color = capColor;
      paintCap(canvas, size, paint);
    }
  }

  void paintEmptyBottle(Canvas canvas, Size size, Paint paint) {
    final neckTop = size.width * 0.1;
    final neckBottom = size.height;
    final neckRingOuterR = size.width;
    final neckRingInner = size.width * 0.1;
    final neckRingInnerR = size.width - neckRingInner;

    final path = Path()
      ..moveTo(0, neckTop)
      ..lineTo(neckRingInner, neckTop)
      ..lineTo(neckRingInner, neckBottom)
      ..lineTo(neckRingInnerR, neckBottom)
      ..lineTo(neckRingInnerR, neckTop)
      ..lineTo(neckRingOuterR, neckTop);

    canvas.drawPath(path, paint);
  }

  void paintBottleMask(Canvas canvas, Size size, Paint paint) {
    final neckRingInner = size.width * 0.1;
    final neckRingInnerR = size.width - neckRingInner;
    canvas.drawRect(
      Rect.fromLTRB(neckRingInner + 5, 0, neckRingInnerR - 5, size.height - 5),
      paint,
    );
  }

  void paintWaves(Canvas canvas, Size size, Paint paint) {
    for (var wave in waves) {
      paint.color = wave.color;
      final transform = Matrix4.identity();
      final desiredW = 15 * size.width;
      final desiredH = 0.1 * size.height;
      final translateRange = desiredW - size.width;
      final scaleX = desiredW / wave.svgData.getBounds().width;
      final scaleY = desiredH / wave.svgData.getBounds().height;
      final translateX = -wave.offset * translateRange;
      final waterRange = size.height + desiredH;
      final translateY = (1.0 - waterLevel) * waterRange - desiredH;
      transform.translate(translateX, translateY);
      transform.scale(scaleX, scaleY);
      canvas.drawPath(wave.svgData.transform(transform.storage), paint);
      if (waves.indexOf(wave) != waves.length - 1) continue;
      final gap = size.height - desiredH - translateY;
      if (gap > 0) {
        canvas.drawRect(
          Rect.fromLTRB(0, desiredH + translateY, size.width, size.height),
          paint,
        );
      }
    }
  }

  void paintBubbles(Canvas canvas, Size size, Paint paint) {
    for (var bubble in bubbles) {
      paint.color = bubble.color;
      final offset = Offset(
        bubble.x * size.width,
        (bubble.y + 1.0 - waterLevel) * size.height,
      );
      final radius = bubble.size * math.min(size.width, size.height);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  void paintGlossyOverlay(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withAlpha(20);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width * 0.5, size.height), paint);
    paint.color = Colors.white.withAlpha(80);
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.9, 0, size.width * 0.95, size.height),
      paint,
    );
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
      colors: [
        Colors.white.withAlpha(180),
        Colors.white.withAlpha(0),
      ],
    ).createShader(rect);
    paint.color = Colors.white;
    paint.shader = gradient;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), paint);
  }

  void paintCap(Canvas canvas, Size size, Paint paint) {
    final capTop = 0.0;
    final capBottom = size.width * 0.2;
    final capMid = (capBottom - capTop) / 2;
    final capL = size.width * 0.08 + 5;
    final capR = size.width - capL;
    final neckRingInner = size.width * 0.1 + 5;
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

  @override
  bool shouldRepaint(WaterBottlePainter oldDelegate) => true;
}
