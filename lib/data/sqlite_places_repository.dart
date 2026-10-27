import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

import '../models/place.dart';
import 'places_repository.dart';

/// Stores places in a SQLite database file on the phone (package `sqflite`).
/// SQLite is a tiny SQL database that lives in one file; sqflite runs the
/// queries on a background thread so the UI never freezes.
class SqlitePlacesRepository implements PlacesRepository {
  /// [databasePath] is only given in tests; the app uses the default folder
  /// that Android/iOS reserve for databases.
  SqlitePlacesRepository({this.databasePath});

  final String? databasePath;

  static const _table = 'user_places';

  Future<sql.Database>? _database;

  /// Opens (and the first time creates) the database. The Future is cached, so
  /// the file is opened only once even if several calls arrive together.
  Future<sql.Database> _getDatabase() => _database ??= _open();

  Future<sql.Database> _open() async {
    final dir = databasePath ?? await sql.getDatabasesPath();
    final file = path.join(dir, 'favoriteplaces.db');
    Future<void> onCreate(sql.Database db, int version) {
      return db.execute(
        'CREATE TABLE $_table('
        'id TEXT PRIMARY KEY, '
        'title TEXT NOT NULL, '
        'image TEXT NOT NULL, '
        'lat REAL NOT NULL, '
        'lng REAL NOT NULL, '
        'address TEXT NOT NULL, '
        'is_favorite INTEGER NOT NULL DEFAULT 0, '
        'created_at INTEGER NOT NULL)',
      );
    }

    return sql.openDatabase(file, version: 1, onCreate: onCreate);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      throw const PlacesRepositoryException(
        'Could not access the places stored on this phone.',
      );
    }
  }

  @override
  Future<List<Place>> fetchPlaces() => _guard(() async {
        final db = await _getDatabase();
        final rows = await db.query(_table, orderBy: 'created_at DESC');
        return rows.map(_fromRow).toList();
      });

  @override
  Future<void> insertPlace(Place place) => _guard(() async {
        final db = await _getDatabase();
        await db.insert(_table, {
          'id': place.id,
          'title': place.title,
          'image': place.image.path,
          'lat': place.location.latitude,
          'lng': place.location.longitude,
          'address': place.location.address,
          'is_favorite': place.isFavorite ? 1 : 0,
          'created_at': place.createdAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
      });

  @override
  Future<void> setFavorite(String id, bool isFavorite) => _guard(() async {
        final db = await _getDatabase();
        await db.update(
          _table,
          {'is_favorite': isFavorite ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      });

  @override
  Future<void> deletePlace(String id) => _guard(() async {
        final db = await _getDatabase();
        await db.delete(_table, where: 'id = ?', whereArgs: [id]);
      });

  Place _fromRow(Map<String, Object?> row) {
    return Place(
      id: row['id'] as String,
      title: row['title'] as String,
      image: File(row['image'] as String),
      location: PlaceLocation(
        latitude: (row['lat'] as num).toDouble(),
        longitude: (row['lng'] as num).toDouble(),
        address: row['address'] as String,
      ),
      isFavorite: (row['is_favorite'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  /// Closes the database file. Used by tests.
  Future<void> close() async {
    final db = await _database;
    await db?.close();
    _database = null;
  }
}
