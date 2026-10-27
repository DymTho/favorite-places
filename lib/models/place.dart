import 'dart:io';

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Where a place is: coordinates plus a human readable address.
class PlaceLocation {
  const PlaceLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;

  /// "62.4722° N, 6.1549° E" - used as the address when the real one is not
  /// available (no API key, no internet).
  String get coordinatesText => formatCoordinates(latitude, longitude);

  PlaceLocation copyWith({String? address}) => PlaceLocation(
        latitude: latitude,
        longitude: longitude,
        address: address ?? this.address,
      );
}

/// A saved favorite place. Immutable: changes (like toggling the heart) create
/// a new object with [copyWith], so Riverpod can see that the state changed.
class Place {
  Place({
    String? id,
    required this.title,
    required this.image,
    required this.location,
    this.isFavorite = false,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;

  /// The photo is a file inside the app's own documents folder. Only its path
  /// is stored in the database, never the picture itself.
  final File image;
  final PlaceLocation location;
  final bool isFavorite;
  final DateTime createdAt;

  Place copyWith({bool? isFavorite}) => Place(
        id: id,
        title: title,
        image: image,
        location: location,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
      );
}

/// Formats coordinates for people: "62.4722° N, 6.1549° E".
String formatCoordinates(double latitude, double longitude) {
  final ns = latitude >= 0 ? 'N' : 'S';
  final ew = longitude >= 0 ? 'E' : 'W';
  return '${latitude.abs().toStringAsFixed(4)}° $ns, '
      '${longitude.abs().toStringAsFixed(4)}° $ew';
}
