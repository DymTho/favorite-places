import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import 'map_layers.dart';

/// A small map that cannot be moved, with a pin on the place. It is a real
/// [FlutterMap] with all gestures switched off. A drawn placeholder lies
/// underneath, so offline (when no tile can be downloaded) the preview still
/// looks like a map instead of an empty box.
class MapPreview extends StatelessWidget {
  const MapPreview({
    super.key,
    required this.location,
    this.zoom = 15,
    this.pinSize = 40,
    this.showAttribution = false,
  });

  final PlaceLocation location;
  final double zoom;
  final double pinSize;

  /// Show "(c) OpenStreetMap contributors" in the corner. Used on the larger
  /// previews; tiny round ones are credited elsewhere on their screen.
  final bool showAttribution;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude, location.longitude);
    return Stack(
      fit: StackFit.expand,
      children: [
        const MapPlaceholder(showPin: false),
        IgnorePointer(
          child: FlutterMap(
            // A new key rebuilds the map when the location changes.
            key: ValueKey('${point.latitude},${point.longitude},$zoom'),
            options: MapOptions(
              initialCenter: point,
              initialZoom: zoom,
              backgroundColor: Colors.transparent,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              const OsmTileLayer(),
              MarkerLayer(
                markers: [placeMarker(context, point, size: pinSize)],
              ),
              if (showAttribution) const MapAttribution(),
            ],
          ),
        ),
      ],
    );
  }
}

/// A drawn "map tile": soft gradient, a few streets and (optionally) a pin.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key, this.showPin = true, this.iconSize = 40});

  final bool showPin;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primaryContainer, scheme.secondaryContainer],
            ),
          ),
        ),
        CustomPaint(painter: _StreetsPainter(scheme.surface)),
        if (showPin)
          Center(
            child: Icon(
              Icons.location_on_rounded,
              size: iconSize,
              color: scheme.primary,
            ),
          ),
      ],
    );
  }
}

class _StreetsPainter extends CustomPainter {
  _StreetsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = size.shortestSide * 0.035
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(0, h * 0.3), Offset(w, h * 0.42), paint);
    canvas.drawLine(Offset(0, h * 0.72), Offset(w, h * 0.62), paint);
    canvas.drawLine(Offset(w * 0.28, 0), Offset(w * 0.4, h), paint);
    canvas.drawLine(Offset(w * 0.72, 0), Offset(w * 0.64, h), paint);
  }

  @override
  bool shouldRepaint(_StreetsPainter oldDelegate) => oldDelegate.color != color;
}
