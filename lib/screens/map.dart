import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../widgets/map_layers.dart';

/// Where the map opens when no place is chosen yet (NTNU in Aalesund).
const _defaultTarget = LatLng(62.4722, 6.1549);

/// A full-screen interactive OpenStreetMap, used in two ways:
///  - **selecting**: tap the map to drop a pin, then confirm. The chosen point
///    is returned with `Navigator.pop`; the caller receives it as the result of
///    `Navigator.push`.
///  - **viewing**: shows a pin at a saved place; taps do nothing.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.initialLocation,
    this.isSelecting = false,
    this.markerTitle,
  });

  final PlaceLocation? initialLocation;
  final bool isSelecting;

  /// Name of the place, shown under the map when viewing a place.
  final String? markerTitle;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // The controller moves the camera from code (the + and - buttons).
  final _controller = MapController();
  LatLng? _picked;

  LatLng get _start {
    final initial = widget.initialLocation;
    return initial == null
        ? _defaultTarget
        : LatLng(initial.latitude, initial.longitude);
  }

  @override
  void initState() {
    super.initState();
    // When choosing again, start with the previously chosen point marked.
    if (widget.isSelecting && widget.initialLocation != null) _picked = _start;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    final camera = _controller.camera;
    _controller.move(camera.center, (camera.zoom + delta).clamp(2, 19));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pinned = widget.isSelecting
        ? _picked
        : (widget.initialLocation == null ? null : _start);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelecting ? 'Pick your Location' : 'Your Location'),
        actions: [
          if (widget.isSelecting)
            IconButton(
              tooltip: 'Use this location',
              icon: const Icon(Icons.check_rounded),
              onPressed: _picked == null
                  ? null
                  : () => Navigator.of(context).pop(_picked),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _start,
              initialZoom: 15,
              minZoom: 2,
              maxZoom: 19,
              // onTap gives the tapped point as latitude/longitude.
              onTap: widget.isSelecting
                  ? (tapPosition, point) => setState(() => _picked = point)
                  : null,
            ),
            children: [
              const OsmTileLayer(),
              MarkerLayer(
                markers: [if (pinned != null) placeMarker(context, pinned)],
              ),
              const MapAttribution(),
            ],
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Zoom in',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                IconButton.filledTonal(
                  tooltip: 'Zoom out',
                  icon: const Icon(Icons.remove_rounded),
                  onPressed: () => _zoomBy(-1),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: widget.isSelecting
                    ? (_picked == null
                        ? _MapNote(
                            key: const ValueKey('hint'),
                            label: 'Tap the map to drop a pin',
                            style: text.labelLarge,
                            color: scheme.surface.withValues(alpha: 0.95),
                          )
                        : FilledButton.icon(
                            key: const ValueKey('confirm'),
                            onPressed: () => Navigator.of(context).pop(_picked),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Use this location'),
                          ))
                    : (widget.markerTitle == null
                        ? const SizedBox.shrink()
                        : _MapNote(
                            key: const ValueKey('title'),
                            label: widget.markerTitle!,
                            style: text.titleMedium,
                            color: scheme.surface.withValues(alpha: 0.95),
                          )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded note floating over the map.
class _MapNote extends StatelessWidget {
  const _MapNote({
    super.key,
    required this.label,
    required this.style,
    required this.color,
  });

  final String label;
  final TextStyle? style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label, textAlign: TextAlign.center, style: style),
    );
  }
}
