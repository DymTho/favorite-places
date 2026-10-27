import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../providers/user_places.dart';
import '../screens/place_detail.dart';
import '../utils/transitions.dart';
import 'map_layers.dart';
import 'state_views.dart';

/// One map with a pin for every saved place. Tap a pin to open the place.
class PlacesOverviewMap extends ConsumerWidget {
  const PlacesOverviewMap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(userPlacesProvider);
    if (places.isEmpty) {
      return const EmptyState(
        icon: Icons.map_outlined,
        title: 'Nothing to show yet',
        message: 'Places you add will appear on this map.',
      );
    }

    final points = [
      for (final place in places)
        LatLng(place.location.latitude, place.location.longitude),
    ];

    return Padding(
      // The bottom padding keeps the map above the floating navigation bar.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: points.first,
            initialZoom: 13,
            minZoom: 2,
            maxZoom: 19,
            // Zoom so that all pins are visible (needs at least two different
            // points; with one point the fixed centre and zoom above are used).
            initialCameraFit: _fitFor(points),
          ),
          children: [
            const OsmTileLayer(),
            MarkerLayer(
              markers: [
                for (final place in places) _marker(context, place),
              ],
            ),
            const MapAttribution(),
          ],
        ),
      ),
    );
  }

  Marker _marker(BuildContext context, Place place) {
    return placeMarker(
      context,
      LatLng(place.location.latitude, place.location.longitude),
      size: 48,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          fadeSlideRoute(PlaceDetailScreen(place: place)),
        ),
        child: Tooltip(
          message: place.title,
          child: Icon(
            Icons.location_on_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
          ),
        ),
      ),
    );
  }

  CameraFit? _fitFor(List<LatLng> points) {
    final allSame = points.every(
      (p) => p.latitude == points.first.latitude && p.longitude == points.first.longitude,
    );
    if (points.length < 2 || allSame) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.all(72),
      maxZoom: 15,
    );
  }
}
