import '../models/place.dart';

/// Everything the app needs from a place of storage. Screens and providers only
/// know this interface, so the storage (sqflite today, Firebase tomorrow) can
/// be replaced without touching the UI. Tests use an in-memory version.
abstract class PlacesRepository {
  /// All saved places, newest first.
  Future<List<Place>> fetchPlaces();

  Future<void> insertPlace(Place place);

  Future<void> setFavorite(String id, bool isFavorite);

  Future<void> deletePlace(String id);
}

/// One readable error for every storage failure.
class PlacesRepositoryException implements Exception {
  const PlacesRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
