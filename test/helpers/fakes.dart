import 'dart:convert';
import 'dart:io';

import 'package:favorite/data/image_store.dart';
import 'package:favorite/data/location_service.dart';
import 'package:favorite/data/geocoding_service.dart';
import 'package:favorite/data/photo_service.dart';
import 'package:favorite/data/places_repository.dart';
import 'package:favorite/models/place.dart';
import 'package:favorite/providers/services.dart';
import 'package:favorite/providers/user_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show TileCoordinates, TileLayer, TileProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// A 1x1 transparent PNG: a real picture without needing a camera or the network.
final _pngBytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAALSURBVBhXY2AAAgAABQABqtXIUQAAAABJRU5ErkJggg==');

/// A picture file that tests use as the photo of a place.
final File testImage = _createTestImage();

File _createTestImage() {
  final file = File('${Directory.systemTemp.path}/favorite_places_test.png');
  file.writeAsBytesSync(_pngBytes);
  return file;
}

Place makePlace(
  String title, {
  String address = '1 Test Street',
  bool isFavorite = false,
  DateTime? createdAt,
  String? id,
}) {
  return Place(
    id: id,
    title: title,
    image: testImage,
    location: PlaceLocation(latitude: 62.47, longitude: 6.15, address: address),
    isFavorite: isFavorite,
    createdAt: createdAt,
  );
}

/// Keeps the places in a list instead of a database. Set [failWrites] to make
/// every write fail, to test the error handling.
class InMemoryPlacesRepository implements PlacesRepository {
  InMemoryPlacesRepository([List<Place> initial = const []])
      : places = [...initial];

  final List<Place> places;
  bool failWrites = false;
  bool failReads = false;

  @override
  Future<List<Place>> fetchPlaces() async {
    if (failReads) throw const PlacesRepositoryException('read failed');
    return [...places]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> insertPlace(Place place) async {
    if (failWrites) throw const PlacesRepositoryException('write failed');
    places.removeWhere((p) => p.id == place.id);
    places.add(place);
  }

  @override
  Future<void> setFavorite(String id, bool isFavorite) async {
    if (failWrites) throw const PlacesRepositoryException('write failed');
    final index = places.indexWhere((p) => p.id == id);
    if (index != -1) places[index] = places[index].copyWith(isFavorite: isFavorite);
  }

  @override
  Future<void> deletePlace(String id) async {
    if (failWrites) throw const PlacesRepositoryException('write failed');
    places.removeWhere((p) => p.id == id);
  }
}

/// "Saves" a photo by returning the same file, and remembers what was deleted.
class FakeImageStore implements ImageStore {
  final saved = <File>[];
  final deleted = <File>[];

  @override
  Future<File> save(File image) async {
    saved.add(image);
    return image;
  }

  @override
  Future<void> delete(File image) async => deleted.add(image);
}

class FakePhotoService implements PhotoService {
  /// What the "camera" returns; null means the user cancelled.
  File? result = testImage;
  int cameraCalls = 0;
  int galleryCalls = 0;

  @override
  Future<File?> takePicture() async {
    cameraCalls++;
    return result;
  }

  @override
  Future<File?> pickFromGallery() async {
    galleryCalls++;
    return result;
  }
}

class FakeLocationService implements LocationService {
  /// Set to make [getCurrentLocation] fail with this message.
  String? error;

  @override
  Future<Coordinates> getCurrentLocation() async {
    if (error != null) throw LocationException(error!);
    return (latitude: 62.4722, longitude: 6.1549);
  }
}

/// Map tiles without the network: every tile is a 1x1 transparent picture.
class BlankTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_pngBytes);
}

/// Everything a test needs to control the app from outside.
class TestEnv {
  TestEnv({List<Place> places = const []})
      : repository = InMemoryPlacesRepository(places);

  final InMemoryPlacesRepository repository;
  final imageStore = FakeImageStore();
  final photos = FakePhotoService();
  final location = FakeLocationService();

  /// No API key, so no network call is ever made.
  final maps = GeocodingService(apiKey: '');

  List<Override> get overrides => [
        placesRepositoryProvider.overrideWithValue(repository),
        imageStoreProvider.overrideWithValue(imageStore),
        photoServiceProvider.overrideWithValue(photos),
        locationServiceProvider.overrideWithValue(location),
        geocodingServiceProvider.overrideWithValue(maps),
        tileProviderProvider.overrideWithValue(BlankTileProvider()),
      ];

  ProviderContainer container() {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }
}

/// Shows [home] inside a ProviderScope with the fakes from [env], on a tall
/// screen so nothing has to be scrolled into view.
Future<void> pumpApp(WidgetTester tester, TestEnv env, Widget home) async {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: env.overrides,
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

