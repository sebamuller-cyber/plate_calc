import 'package:flutter/material.dart';
import 'plate_colors.dart';

class BarbellView extends StatelessWidget {
  final List<double> perSide; // pesos por lado (ej: [45, 25, 10, 5])
  final String units;
  final double height;

  const BarbellView({
    super.key,
    required this.perSide,
    required this.units,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarbellPainter(perSide: perSide, units: units),
      ),
    );
  }
}

class _BarbellPainter extends CustomPainter {
  final List<double> perSide;
  final String units;

  _BarbellPainter({required this.perSide, required this.units});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // MÁS CENTRADO: mangas largas hacia el centro.
    final sleeveLength = size.width * 0.28;        // ↑ sube si quieres aún más centrado (0.30/0.32)
    final innerBarLen  = size.width - 2 * sleeveLength;
    final barThickness = 10.0;
    final plateHeight  = size.height * 0.45;

    final paintBar    = Paint()..color = const Color(0xFF424242);
    final paintSleeve = Paint()..color = Colors.black87;

    // Barra central
    final barRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: innerBarLen,
      height: barThickness,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
      paintBar,
    );

    // Mangas
    final leftSleeve  = Rect.fromLTWH(0, cy - barThickness / 2, sleeveLength, barThickness);
    final rightSleeve = Rect.fromLTWH(size.width - sleeveLength, cy - barThickness / 2, sleeveLength, barThickness);
    canvas.drawRect(leftSleeve,  paintSleeve);
    canvas.drawRect(rightSleeve, paintSleeve);

    // Orden: grandes → chicos (para que grandes queden pegados al centro)
    final weights = [...perSide]..sort((a, b) => b.compareTo(a));

    // Calculamos anchos base y compactamos si no caben dentro de la manga
    const baseGap = 4.0;                     // gap base entre discos (se escala si es necesario)
    final baseWidths = weights.map((w) => PlateVisual.width(units, w)).toList();

    double available = sleeveLength - 16;    // margen visual dentro de la manga
    double need = 0;
    for (final w in baseWidths) {
      need += w;
    }
    if (weights.isNotEmpty) need += baseGap * (weights.length - 1);

    final scale = need > available ? (available / need) : 1.0;
    final gap   = baseGap * scale;
    final widths = baseWidths.map((w) => w * scale).toList();

    // Partimos pegado al borde interno de cada manga (cerca del centro)
    double leftStart  = sleeveLength;                 // borde interno manga izq
    double rightStart = size.width - sleeveLength;    // borde interno manga der

    for (int i = 0; i < weights.length; i++) {
      final w  = weights[i];
      final pw = widths[i];
      final c  = PlateVisual.color(units, w);

      // DERECHO: desde el centro hacia afuera (→)
      final rRect = Rect.fromLTWH(
        rightStart + (i == 0 ? 0 : gap),
        cy - plateHeight / 2,
        pw,
        plateHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rRect, const Radius.circular(6)),
        Paint()..color = c,
      );
      rightStart += pw + gap;

      // IZQUIERDO: simétrico desde el centro hacia afuera (←)
      final lRect = Rect.fromLTWH(
        leftStart - pw - (i == 0 ? 0 : gap),
        cy - plateHeight / 2,
        pw,
        plateHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(lRect, const Radius.circular(6)),
        Paint()..color = c,
      );
      leftStart -= pw + gap;
    }
// Collar final (más bajo y completamente negro)
final clipW = 6.0; // ancho del collar (más angosto)
final clipH = plateHeight * 0.35; // más bajo respecto al disco
final clipPaint = Paint()..color = Colors.black; // negro sólido

final leftClip = Rect.fromCenter(
  center: Offset(leftStart - clipW / 2, cy),
  width: clipW,
  height: clipH,
);
final rightClip = Rect.fromCenter(
  center: Offset(rightStart + clipW / 2, cy),
  width: clipW,
  height: clipH,
);

// bordes redondeados mínimos
canvas.drawRRect(
  RRect.fromRectAndRadius(leftClip, const Radius.circular(1)),
  clipPaint,
);
canvas.drawRRect(
  RRect.fromRectAndRadius(rightClip, const Radius.circular(1)),
  clipPaint,
);

  
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PlateLegend extends StatelessWidget {
  final Map<double, int> used;
  final String units;
  const PlateLegend({super.key, required this.used, required this.units});

  @override
  Widget build(BuildContext context) {
    final entries = used.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries.map((e) {
        final color = PlateVisual.color(units, e.key); // MISMO color que en la barra
        final label = '${e.key.toString().replaceAll('.0', '')} $units';
        return Chip(
          avatar: CircleAvatar(backgroundColor: color),
          label: Text('$label  x${e.value}'),
        );
      }).toList(),
    );
  }
}
