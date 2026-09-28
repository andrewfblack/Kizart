import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class LibrarySnapshot {
  const LibrarySnapshot({
    required this.children,
    required this.albums,
    required this.tags,
    required this.artworks,
  });
  final List<ChildProfile> children;
  final List<ArtAlbum> albums;
  final List<ArtTag> tags;
  final List<Artwork> artworks;
}

class ArtRepository {
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    return openDatabase(
      p.join(directory.path, 'kizart.sqlite'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE children(
          id TEXT PRIMARY KEY, name TEXT NOT NULL, birth_year INTEGER,
          current_grade TEXT NOT NULL, color_value INTEGER NOT NULL,
          created_at TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE albums(
          id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL,
          color_value INTEGER NOT NULL, created_at TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE tags(
          id TEXT PRIMARY KEY, name TEXT NOT NULL COLLATE NOCASE UNIQUE)''');
        await db.execute('''CREATE TABLE artworks(
          id TEXT PRIMARY KEY, child_id TEXT NOT NULL, title TEXT NOT NULL,
          notes TEXT NOT NULL, image_path TEXT NOT NULL, year INTEGER NOT NULL,
          grade TEXT NOT NULL, is_favorite INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, scanned_at TEXT NOT NULL,
          FOREIGN KEY(child_id) REFERENCES children(id) ON DELETE CASCADE)''');
        await db.execute('''CREATE TABLE artwork_albums(
          artwork_id TEXT NOT NULL, album_id TEXT NOT NULL,
          PRIMARY KEY(artwork_id, album_id),
          FOREIGN KEY(artwork_id) REFERENCES artworks(id) ON DELETE CASCADE,
          FOREIGN KEY(album_id) REFERENCES albums(id) ON DELETE CASCADE)''');
        await db.execute('''CREATE TABLE artwork_tags(
          artwork_id TEXT NOT NULL, tag_id TEXT NOT NULL,
          PRIMARY KEY(artwork_id, tag_id),
          FOREIGN KEY(artwork_id) REFERENCES artworks(id) ON DELETE CASCADE,
          FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE)''');
      },
    );
  }

  Future<LibrarySnapshot> load() async {
    final db = await database;
    final childRows = await db.query('children', orderBy: 'created_at');
    final albumRows = await db.query('albums', orderBy: 'created_at DESC');
    final tagRows = await db.query('tags', orderBy: 'name COLLATE NOCASE');
    final artRows = await db.query('artworks', orderBy: 'created_at DESC');
    final albumLinks = await db.query('artwork_albums');
    final tagLinks = await db.query('artwork_tags');
    final albumsByArt = <String, Set<String>>{};
    final tagsByArt = <String, Set<String>>{};
    for (final row in albumLinks) {
      albumsByArt
          .putIfAbsent(row['artwork_id']! as String, () => {})
          .add(row['album_id']! as String);
    }
    for (final row in tagLinks) {
      tagsByArt
          .putIfAbsent(row['artwork_id']! as String, () => {})
          .add(row['tag_id']! as String);
    }
    return LibrarySnapshot(
      children: childRows.map(ChildProfile.fromMap).toList(),
      albums: albumRows.map(ArtAlbum.fromMap).toList(),
      tags: tagRows.map(ArtTag.fromMap).toList(),
      artworks: artRows
          .map(
            (row) => Artwork.fromMap(
              row,
              albumIds: albumsByArt[row['id']] ?? {},
              tagIds: tagsByArt[row['id']] ?? {},
            ),
          )
          .toList(),
    );
  }

  Future<void> saveChild(ChildProfile child) async => (await database).insert(
    'children',
    child.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  Future<void> saveAlbum(ArtAlbum album) async => (await database).insert(
    'albums',
    album.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  Future<void> saveTag(ArtTag tag) async => (await database).insert(
    'tags',
    tag.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> saveArtwork(Artwork artwork) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'artworks',
        artwork.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'artwork_albums',
        where: 'artwork_id = ?',
        whereArgs: [artwork.id],
      );
      await txn.delete(
        'artwork_tags',
        where: 'artwork_id = ?',
        whereArgs: [artwork.id],
      );
      for (final albumId in artwork.albumIds) {
        await txn.insert('artwork_albums', {
          'artwork_id': artwork.id,
          'album_id': albumId,
        });
      }
      for (final tagId in artwork.tagIds) {
        await txn.insert('artwork_tags', {
          'artwork_id': artwork.id,
          'tag_id': tagId,
        });
      }
    });
  }

  Future<void> deleteArtwork(Artwork artwork) async {
    await (await database).delete(
      'artworks',
      where: 'id = ?',
      whereArgs: [artwork.id],
    );
    final file = File(artwork.imagePath);
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteChild(String id) async =>
      (await database).delete('children', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteAlbum(String id) async =>
      (await database).delete('albums', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteTag(String id) async =>
      (await database).delete('tags', where: 'id = ?', whereArgs: [id]);

  Future<String> keepScan(String temporaryPath, String id) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'artwork'));
    await directory.create(recursive: true);
    final extension = p.extension(temporaryPath).isEmpty
        ? '.jpg'
        : p.extension(temporaryPath);
    final destination = p.join(directory.path, '$id$extension');
    await File(temporaryPath).copy(destination);
    return destination;
  }
}
