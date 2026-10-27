import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/geocoding_service.dart';
import '../data/location_service.dart';
import '../data/photo_service.dart';

// Each Provider below creates one service object and shares it with the whole
// app. Widgets get it with `ref.read(...)`. A test replaces the real service
// with a fake by listing an *override* in the ProviderScope - the widgets do
// not change at all. That is dependency injection with Riverpod.

final photoServiceProvider = Provider<PhotoService>(
  (ref) => ImagePickerPhotoService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => DeviceLocationService(),
);

final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => GeocodingService(),
);

/// The HTTP client that downloads map tiles, shared by every map in the app.
final tileHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Downloads the map tiles (small 256x256 pictures a map is made of) from
/// OpenStreetMap. Tests replace it so that no network request is made.
///
/// The client is handed in on purpose. A `TileLayer` calls `dispose()` on its
/// tile provider when its map leaves the screen, and a provider that created
/// its own client would then close it, so every map shown afterwards would stay
/// empty. A client that is passed in is never closed by the provider.
final tileProviderProvider = Provider<TileProvider>(
  (ref) => NetworkTileProvider(httpClient: ref.watch(tileHttpClientProvider)),
);
