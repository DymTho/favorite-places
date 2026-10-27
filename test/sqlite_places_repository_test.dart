import 'dart:io';

import 'package:favorite/data/sqlite_places_repository.dart';
import 'package:favorite/models/place.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/fakes.dart';

/// Runs the real SQL against a real SQLite file. sqflite itself only works on
/// a phone, so the desktop `ffi` version of the same API is plugged in.
void main() {
  late Directory dir;
  late SqlitePlacesRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('favorite_places_db_');
    repository = SqlitePlacesRepository(databasePath: dir.path);
  });

  tearDown(() async {
    await repository.close();
    dir.deleteSync(recursive: true);
  });

  test('starts empty', () async {
    expect(await repository.fetchPlaces(), isEmpty);
  });

  test('stores every field of a place and reads it back', () async {
    final place = Place(
      title: 'Fjord view',
      image: testImage,
      location: const PlaceLocation(
        latitude: 62.4722,
        longitude: 6.1549,
        address: 'Larsgardsvegen 2, Aalesund',
      ),
      isFavorite: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    await repository.insertPlace(place);
    final loaded = (await repository.fetchPlaces()).single;

    expect(loaded.id, place.id);
    expect(loaded.title, 'Fjord view');
    expect(loaded.image.path, testImage.path);
    expect(loaded.location.latitude, 62.4722);
    expect(loaded.location.longitude, 6.1549);
    expect(loaded.location.address, 'Larsgardsvegen 2, Aalesund');
    expect(loaded.isFavorite, isTrue);
    expect(loaded.createdAt, place.createdAt);
  });

  test('returns the newest place first', () async {
    await repository.insertPlace(makePlace('Old', createdAt: DateTime(2024)));
    await repository.insertPlace(makePlace('New', createdAt: DateTime(2025)));
    await repository.insertPlace(makePlace('Middle', createdAt: DateTime(2024, 6)));

    final titles = (await repository.fetchPlaces()).map((p) => p.title);

    expect(titles, ['New', 'Middle', 'Old']);
  });

  test('setFavorite changes only that place', () async {
    final a = makePlace('A');
    final b = makePlace('B');
    await repository.insertPlace(a);
    await repository.insertPlace(b);

    await repository.setFavorite(a.id, true);

    final places = {for (final p in await repository.fetchPlaces()) p.title: p};
    expect(places['A']!.isFavorite, isTrue);
    expect(places['B']!.isFavorite, isFalse);
  });

  test('deletePlace removes the row', () async {
    final a = makePlace('A');
    await repository.insertPlace(a);
    await repository.insertPlace(makePlace('B'));

    await repository.deletePlace(a.id);

    expect((await repository.fetchPlaces()).map((p) => p.title), ['B']);
  });

  test('inserting the same id again replaces the place (used by Undo)', () async {
    final a = makePlace('A');
    await repository.insertPlace(a);
    await repository.insertPlace(a);

    expect(await repository.fetchPlaces(), hasLength(1));
  });

  test('the data survives closing and reopening the database', () async {
    await repository.insertPlace(makePlace('Kept after restart'));
    await repository.close();

    final reopened = SqlitePlacesRepository(databasePath: dir.path);
    addTearDown(reopened.close);

    expect((await reopened.fetchPlaces()).single.title, 'Kept after restart');
  });
}
