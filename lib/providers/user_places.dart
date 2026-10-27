import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/image_store.dart';
import '../data/places_repository.dart';
import '../data/sqlite_places_repository.dart';
import '../models/place.dart';

final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => SqlitePlacesRepository(),
);

final imageStoreProvider = Provider<ImageStore>((ref) => LocalImageStore());

/// The list of saved places and everything that changes it. The state is the
/// list itself: when `state` gets a new list, every widget that watches this
/// provider rebuilds.
class UserPlacesNotifier extends Notifier<List<Place>> {
  /// The state before anything is loaded.
  @override
  List<Place> build() => const [];

  PlacesRepository get _repository => ref.read(placesRepositoryProvider);
  ImageStore get _images => ref.read(imageStoreProvider);

  /// Reads all places from the database. The list screen waits for this with a
  /// FutureBuilder, so a spinner shows while it runs.
  Future<void> loadPlaces() async {
    state = await _repository.fetchPlaces();
  }

  /// Saves a new place: copy the photo, write the row, then update the state.
  /// Throws if the database write fails (the copied photo is cleaned up).
  Future<void> addPlace(
    String title,
    File image,
    PlaceLocation location,
  ) async {
    final storedImage = await _images.save(image);
    final place = Place(
      title: title.trim(),
      image: storedImage,
      location: location,
    );
    try {
      await _repository.insertPlace(place);
    } catch (_) {
      await _images.delete(storedImage);
      rethrow;
    }
    state = [place, ...state];
  }

  /// Flips the heart. *Optimistic*: the screen changes at once, then the
  /// database is updated; if that fails the change is undone and rethrown.
  Future<void> toggleFavorite(String id) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final before = state[index];
    final after = before.copyWith(isFavorite: !before.isFavorite);
    _replace(after);
    try {
      await _repository.setFavorite(id, after.isFavorite);
    } catch (_) {
      _replace(before);
      rethrow;
    }
  }

  /// Removes a place from the list and the database, but keeps its photo file
  /// so the removal can still be undone. Call [discardImage] when it is final.
  Future<void> removePlace(Place place) async {
    state = [for (final p in state) if (p.id != place.id) p];
    try {
      await _repository.deletePlace(place.id);
    } catch (_) {
      // Let the swipe animation finish before the item comes back, otherwise
      // the Dismissible would still be part of the widget tree.
      await SchedulerBinding.instance.endOfFrame;
      state = _sorted([...state, place]);
      rethrow;
    }
  }

  /// "Undo" after a swipe: puts the place back.
  Future<void> restorePlace(Place place) async {
    await _repository.insertPlace(place);
    state = _sorted([...state, place]);
  }

  /// Deletes the photo file of a place that was removed for good.
  Future<void> discardImage(Place place) => _images.delete(place.image);

  void _replace(Place updated) {
    state = [for (final p in state) p.id == updated.id ? updated : p];
  }

  /// Newest first, the same order the database returns.
  List<Place> _sorted(List<Place> places) =>
      places..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

final userPlacesProvider = NotifierProvider<UserPlacesNotifier, List<Place>>(
  UserPlacesNotifier.new,
);
