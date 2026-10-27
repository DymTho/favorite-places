import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/location_service.dart';
import '../models/place.dart';
import '../providers/services.dart';
import '../screens/map.dart';
import '../utils/transitions.dart';
import 'map_preview.dart';

/// The location part of the "Add place" form. Two ways to choose a place:
/// the phone's current position, or a tap on the map. Either way the result is
/// turned into a [PlaceLocation] (coordinates + address) and handed to the form.
class LocationInput extends ConsumerStatefulWidget {
  const LocationInput({
    super.key,
    required this.onSelectLocation,
    this.errorText,
  });

  final void Function(PlaceLocation location) onSelectLocation;
  final String? errorText;

  @override
  ConsumerState<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends ConsumerState<LocationInput> {
  PlaceLocation? _pickedLocation;
  bool _isGettingLocation = false;
  String? _problem;

  /// Step 1 for both buttons: coordinates in, address out.
  Future<void> _useCoordinates(double latitude, double longitude) async {
    setState(() {
      _isGettingLocation = true;
      _problem = null;
    });
    final address = await ref
        .read(geocodingServiceProvider)
        .reverseGeocode(latitude, longitude);
    if (!mounted) return;
    final location = PlaceLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    setState(() {
      _pickedLocation = location;
      _isGettingLocation = false;
    });
    widget.onSelectLocation(location);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _problem = null;
    });
    try {
      final here = await ref.read(locationServiceProvider).getCurrentLocation();
      await _useCoordinates(here.latitude, here.longitude);
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGettingLocation = false;
        _problem = e.message;
      });
    }
  }

  Future<void> _selectOnMap() async {
    // The map screen hands the tapped point back through Navigator.pop.
    final picked = await Navigator.of(context).push<LatLng>(
      fadeSlideRoute(
        MapScreen(
          isSelecting: true,
          initialLocation: _pickedLocation,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _useCoordinates(picked.latitude, picked.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasError = widget.errorText != null;

    final Widget preview;
    if (_isGettingLocation) {
      preview = const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    } else if (_pickedLocation != null) {
      final location = _pickedLocation!;
      preview = Stack(
        key: ValueKey('${location.latitude},${location.longitude}'),
        fit: StackFit.expand,
        children: [
          MapPreview(location: location, showAttribution: true),
          // At the top, so it never hides the map credit in the corner below.
          Positioned(
            left: 10,
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      preview = Column(
        key: const ValueKey('none'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 36,
            color: hasError ? scheme.error : scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No location chosen',
            style: TextStyle(
              color: hasError ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 170,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasError ? scheme.error : scheme.outlineVariant,
              width: hasError ? 2 : 1,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: preview,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: scheme.error, fontSize: 12.5),
            ),
          ),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Text(
              _problem!,
              style: TextStyle(color: scheme.error, fontSize: 12.5),
            ),
          ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _isGettingLocation ? null : _getCurrentLocation,
          icon: const Icon(Icons.my_location_rounded),
          label: const Text('Get Current Location'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isGettingLocation ? null : _selectOnMap,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Select on Map'),
        ),
      ],
    );
  }
}
