import 'package:flutter/material.dart';

import '../app/brand.dart';
import '../app/store.dart';
import '../app/theme.dart';

/// Tactics board. The pitch is the whole interface — players are dragged
/// straight onto it, and formations are presets rather than a menu tree.
class ProductApp extends StatefulWidget {
  const ProductApp({super.key});

  @override
  State<ProductApp> createState() => _ProductAppState();
}

class _Formation {
  final String name;
  // Fractional pitch coordinates: 0,0 is the top-left of the playing area.
  final List<Offset> spots;
  const _Formation(this.name, this.spots);
}

const List<_Formation> _formations = [
  _Formation('4-4-2', [
    Offset(0.50, 0.93),
    Offset(0.16, 0.74), Offset(0.38, 0.78), Offset(0.62, 0.78), Offset(0.84, 0.74),
    Offset(0.16, 0.48), Offset(0.38, 0.52), Offset(0.62, 0.52), Offset(0.84, 0.48),
    Offset(0.38, 0.22), Offset(0.62, 0.22),
  ]),
  _Formation('4-3-3', [
    Offset(0.50, 0.93),
    Offset(0.16, 0.74), Offset(0.38, 0.78), Offset(0.62, 0.78), Offset(0.84, 0.74),
    Offset(0.30, 0.52), Offset(0.50, 0.56), Offset(0.70, 0.52),
    Offset(0.18, 0.24), Offset(0.50, 0.18), Offset(0.82, 0.24),
  ]),
  _Formation('3-5-2', [
    Offset(0.50, 0.93),
    Offset(0.28, 0.78), Offset(0.50, 0.80), Offset(0.72, 0.78),
    Offset(0.12, 0.54), Offset(0.34, 0.56), Offset(0.50, 0.50), Offset(0.66, 0.56), Offset(0.88, 0.54),
    Offset(0.38, 0.22), Offset(0.62, 0.22),
  ]),
  _Formation('4-2-3-1', [
    Offset(0.50, 0.93),
    Offset(0.16, 0.74), Offset(0.38, 0.78), Offset(0.62, 0.78), Offset(0.84, 0.74),
    Offset(0.38, 0.58), Offset(0.62, 0.58),
    Offset(0.20, 0.36), Offset(0.50, 0.34), Offset(0.80, 0.36),
    Offset(0.50, 0.14),
  ]),
  _Formation('5-3-2', [
    Offset(0.50, 0.93),
    Offset(0.10, 0.72), Offset(0.30, 0.80), Offset(0.50, 0.82), Offset(0.70, 0.80), Offset(0.90, 0.72),
    Offset(0.30, 0.52), Offset(0.50, 0.56), Offset(0.70, 0.52),
    Offset(0.38, 0.22), Offset(0.62, 0.22),
  ]),
];

class _ProductAppState extends State<ProductApp> {
  static const _kSpots = 'fm_spots';
  static const _kFormation = 'fm_index';

  int _formationIndex = 0;
  List<Offset> _spots = List<Offset>.of(_formations.first.spots);
  int? _dragging;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final index = await Store.getInt(_kFormation);
    final saved = await Store.getRecords(_kSpots);

    var spots = List<Offset>.of(
      _formations[index.clamp(0, _formations.length - 1)].spots,
    );
    if (saved.isNotEmpty) {
      final restored = <Offset>[];
      for (final row in saved) {
        final dx = row['x'];
        final dy = row['y'];
        if (dx is num && dy is num) {
          restored.add(Offset(dx.toDouble(), dy.toDouble()));
        }
      }
      if (restored.length == spots.length) spots = restored;
    }

    if (!mounted) return;
    setState(() {
      _formationIndex = index.clamp(0, _formations.length - 1);
      _spots = spots;
      _ready = true;
    });
  }

  void _persist() {
    Store.setInt(_kFormation, _formationIndex);
    Store.setRecords(_kSpots, [
      for (final s in _spots) {'x': s.dx, 'y': s.dy},
    ]);
  }

  void _applyFormation(int index) {
    setState(() {
      _formationIndex = index;
      _spots = List<Offset>.of(_formations[index].spots);
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: cBg,
        body: Center(child: CircularProgressIndicator(color: cAccent)),
      );
    }

    return Scaffold(
      backgroundColor: cBgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _formationStrip(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _pitch(
                      Size(constraints.maxWidth, constraints.maxHeight),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formationStrip() {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: _formations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = i == _formationIndex;
          return InkWell(
            onTap: () => _applyFormation(i),
            borderRadius: AppTheme.radiusOf(1),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: AppTheme.radius,
                color: active ? cAccent : Colors.transparent,
                border: Border.all(color: active ? cAccent : AppTheme.border),
              ),
              child: Text(
                _formations[i].name,
                style: AppTheme.text(
                  15,
                  weight: FontWeight.w700,
                  spacing: 1.2,
                  color: active ? AppTheme.onAccent : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pitch(Size size) {
    const tokenSize = 34.0;

    return ClipRRect(
      borderRadius: AppTheme.radius,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _PitchPainter(line: cAlt, turf: cBg)),
          ),
          for (var i = 0; i < _spots.length; i++)
            Positioned(
              left: _spots[i].dx * size.width - tokenSize / 2,
              top: _spots[i].dy * size.height - tokenSize / 2,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _dragging = i),
                onPanUpdate: (details) {
                  setState(() {
                    // Clamped so a token can never be dragged off the pitch.
                    final next = Offset(
                      (_spots[i].dx + details.delta.dx / size.width)
                          .clamp(0.04, 0.96),
                      (_spots[i].dy + details.delta.dy / size.height)
                          .clamp(0.04, 0.96),
                    );
                    _spots[i] = next;
                  });
                },
                onPanEnd: (_) {
                  setState(() => _dragging = null);
                  _persist();
                },
                child: _token(i, tokenSize, dragging: _dragging == i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _token(int index, double size, {required bool dragging}) {
    final isKeeper = index == 0;
    return AnimatedScale(
      scale: dragging ? 1.22 : 1.0,
      duration: const Duration(milliseconds: 140),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isKeeper ? cAlt : cAccent,
          border: Border.all(color: cBgDeep, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: dragging ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          isKeeper ? 'GK' : '$index',
          style: TextStyle(
            fontFamily: kDisplayFont,
            fontSize: isKeeper ? 12 : 14,
            fontWeight: FontWeight.w700,
            color: isKeeper ? cBgDeep : AppTheme.onAccent,
          ),
        ),
      ),
    );
  }
}

/// Chalk lines. Drawn rather than shipped as an image so it scales to any
/// screen without a second asset.
class _PitchPainter extends CustomPainter {
  final Color line;
  final Color turf;

  const _PitchPainter({required this.line, required this.turf});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = turf);

    // Mown stripes give the pitch depth without another asset.
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.03);
    const bands = 7;
    for (var i = 0; i < bands; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height / bands * i, size.width, size.height / bands),
        stripe,
      );
    }

    final chalk = Paint()
      ..color = line.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final inset = rect.deflate(10);
    canvas.drawRect(inset, chalk);
    canvas.drawLine(
      Offset(inset.left, inset.center.dy),
      Offset(inset.right, inset.center.dy),
      chalk,
    );
    canvas.drawCircle(inset.center, size.shortestSide * 0.14, chalk);

    final boxWidth = inset.width * 0.62;
    final boxHeight = inset.height * 0.16;
    for (final top in [inset.top, inset.bottom - boxHeight]) {
      canvas.drawRect(
        Rect.fromLTWH(inset.center.dx - boxWidth / 2, top, boxWidth, boxHeight),
        chalk,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.turf != turf;
}
