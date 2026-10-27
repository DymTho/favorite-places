import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/services.dart';

/// The OpenStreetMap tiles. A map is a grid of small pictures ("tiles") that
/// are downloaded for the visible area and zoom level; `{z}/{x}/{y}` in the URL
/// is replaced with the zoom and the tile's column and row.
class OsmTileLayer extends ConsumerWidget {
  const OsmTileLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      // OpenStreetMap asks every app to identify itself in the User-Agent.
      userAgentPackageName: 'com.example.favorite',
      tileProvider: ref.watch(tileProviderProvider),
    );
  }
}

/// The credit OpenStreetMap's licence requires next to its map. The widget
/// itself prints "flutter_map | (c) " in front of the text.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleAttributionWidget(
      source: Text('OpenStreetMap contributors'),
    );
  }
}

/// A map pin whose tip is exactly on [point].
Marker placeMarker(
  BuildContext context,
  LatLng point, {
  double size = 44,
  Widget? child,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Marker(
    point: point,
    width: size,
    height: size,
    // The pin is drawn above the point, so its tip touches the point.
    alignment: Alignment.topCenter,
    child: child ??
        Icon(
          Icons.location_on_rounded,
          size: size,
          color: scheme.primary,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
        ),
  );
}
