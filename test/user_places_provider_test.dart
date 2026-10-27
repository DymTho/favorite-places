import 'package:favorite/models/place.dart';
import 'package:favorite/providers/ui_state.dart';
import 'package:favorite/providers/user_places.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

const _location = PlaceLocation(latitude: 1, longitude: 2, address: 'Somewhere');

void main() {
  final older = makePlace('Old harbour', createdAt: DateTime(2024, 1, 1));
  final newer = makePlace('New park', createdAt: DateTime(2025, 1, 1));

  group('loadPlaces', () {
    test('starts empty and loads the stored places, newest first', () async {
      final env = TestEnv(places: [older, newer]);
      final container = env.container();

      expect(container.read(userPlacesProvider), isEmpty);
      await container.read(userPlacesProvider.notifier).loadPlaces();

      expect(container.read(userPlacesProvider).map((p) => p.title), [
        'New park',
        'Old harbour',
      ]);
    });

    test('throws when the storage cannot be read', () async {
      final env = TestEnv()..repository.failReads = true;
      final container = env.container();
      await expectLater(
        container.read(userPlacesProvider.notifier).loadPlaces(),
        throwsA(anything),
      );
    });
  });

  group('addPlace', () {
    test('copies the photo, stores the place and puts it first', () async {
      final env = TestEnv(places: [older]);
      final container = env.container();
      final notifier = container.read(userPlacesProvider.notifier);
      await notifier.loadPlaces();

      await notifier.addPlace('  Fjord view  ', testImage, _location);

      final places = container.read(userPlacesProvider);
      expect(places.first.title, 'Fjord view'); // trimmed
      expect(places.first.isFavorite, isFalse);
      expect(places, hasLength(2));
      expect(env.imageStore.saved, [testImage]);
      expect(env.repository.places, hasLength(2));
    });

    test('removes the copied photo again when the database write fails', () async {
      final env = TestEnv()..repository.failWrites = true;
      final container = env.container();
      final notifier = container.read(userPlacesProvider.notifier);

      await expectLater(
        notifier.addPlace('Fjord view', testImage, _location),
        throwsA(anything),
      );

      expect(container.read(userPlacesProvider), isEmpty);
      expect(env.imageStore.deleted, hasLength(1));
    });
  });

  group('toggleFavorite', () {
    test('flips the heart and saves it', () async {
      final env = TestEnv(places: [newer]);
      final container = env.container();
      final notifier = container.read(userPlacesProvider.notifier);
      await notifier.loadPlaces();

      await notifier.toggleFavorite(newer.id);
      expect(container.read(userPlacesProvider).single.isFavorite, isTrue);
      expect(env.repository.places.single.isFavorite, isTrue);

      await notifier.toggleFavorite(newer.id);
      expect(container.read(userPlacesProvider).single.isFavorite, isFalse);
    });

    test('goes back to the old value when saving fails', () async {
      final env = TestEnv(places: [newer]);
      final container = env.container();
      final notifier = container.read(userPlacesProvider.notifier);
      await notifier.loadPlaces();
      env.repository.failWrites = true;

      await expectLater(notifier.toggleFavorite(newer.id), throwsA(anything));

      expect(container.read(userPlacesProvider).single.isFavorite, isFalse);
    });
  });

  group('remove and restore', () {
    test('removePlace keeps the photo so it can be undone', () async {
      final env = TestEnv(places: [older, newer]);
      final container = env.container();
      final notifier = container.read(userPlacesProvider.notifier);
      await notifier.loadPlaces();

      await notifier.removePlace(newer);
      expect(container.read(userPlacesProvider).map((p) => p.title), [
        'Old harbour',
      ]);
      expect(env.repository.places, hasLength(1));
      expect(env.imageStore.deleted, isEmpty);

      await notifier.restorePlace(newer);
      expect(container.read(userPlacesProvider).map((p) => p.title), [
        'New park',
        'Old harbour',
      ]);
      expect(env.repository.places, hasLength(2));
    });

    test('discardImage deletes the photo file', () async {
      final env = TestEnv(places: [newer]);
      final container = env.container();
      await container.read(userPlacesProvider.notifier).discardImage(newer);
      expect(env.imageStore.deleted, [newer.image]);
    });
  });

  group('derived providers', () {
    test('search matches the title or the address, ignoring case', () async {
      final env = TestEnv(places: [
        makePlace('Harbour', address: 'Quay 5'),
        makePlace('Park', address: 'Harbour Road'),
        makePlace('Museum', address: 'Main Street'),
      ]);
      final container = env.container();
      await container.read(userPlacesProvider.notifier).loadPlaces();

      expect(container.read(visiblePlacesProvider), hasLength(3));

      container.read(searchQueryProvider.notifier).set('  harbour ');
      expect(
        container.read(visiblePlacesProvider).map((p) => p.title).toSet(),
        {'Harbour', 'Park'},
      );

      container.read(searchQueryProvider.notifier).set('zzz');
      expect(container.read(visiblePlacesProvider), isEmpty);
    });

    test('favorites are the visible places with a heart', () async {
      final env = TestEnv(places: [
        makePlace('A', isFavorite: true),
        makePlace('B'),
        makePlace('C', isFavorite: true),
      ]);
      final container = env.container();
      await container.read(userPlacesProvider.notifier).loadPlaces();

      expect(
        container.read(favoritePlacesProvider).map((p) => p.title).toSet(),
        {'A', 'C'},
      );

      container.read(searchQueryProvider.notifier).set('c');
      expect(container.read(favoritePlacesProvider).map((p) => p.title), ['C']);
    });
  });
}
