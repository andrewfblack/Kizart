import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/art_repository.dart';
import '../models/models.dart';

class ArtLibrary extends ChangeNotifier {
  ArtLibrary(this.repository);
  final ArtRepository repository;
  final Uuid _uuid = const Uuid();

  List<ChildProfile> children = [];
  List<ArtAlbum> albums = [];
  List<ArtTag> tags = [];
  List<Artwork> artworks = [];

  Future<void> initialize() async => refresh();

  Future<void> refresh() async {
    final snapshot = await repository.load();
    children = snapshot.children;
    albums = snapshot.albums;
    tags = snapshot.tags;
    artworks = snapshot.artworks;
    notifyListeners();
  }

  String newId() => _uuid.v7();

  ChildProfile? child(String id) {
    for (final value in children) {
      if (value.id == id) return value;
    }
    return null;
  }

  int artworkCountForChild(String id) =>
      artworks.where((art) => art.childId == id).length;
  int artworkCountForAlbum(String id) =>
      artworks.where((art) => art.albumIds.contains(id)).length;

  Future<void> saveChild(ChildProfile child) async {
    await repository.saveChild(child);
    await refresh();
  }

  Future<void> saveAlbum(ArtAlbum album) async {
    await repository.saveAlbum(album);
    await refresh();
  }

  Future<void> saveTag(ArtTag tag) async {
    await repository.saveTag(tag);
    await refresh();
  }

  Future<void> saveArtwork(Artwork artwork) async {
    await repository.saveArtwork(artwork);
    await refresh();
  }

  Future<void> toggleFavorite(Artwork artwork) =>
      saveArtwork(artwork.copyWith(isFavorite: !artwork.isFavorite));

  Future<void> deleteArtwork(Artwork artwork) async {
    await repository.deleteArtwork(artwork);
    await refresh();
  }

  Future<void> deleteAlbum(String id) async {
    await repository.deleteAlbum(id);
    await refresh();
  }

  Future<void> deleteTag(String id) async {
    await repository.deleteTag(id);
    await refresh();
  }
}
