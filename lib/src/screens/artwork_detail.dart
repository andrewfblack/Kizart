import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../theme.dart';
import 'forms.dart';

class ArtworkDetailScreen extends StatelessWidget {
  const ArtworkDetailScreen({super.key, required this.artworkId});
  final String artworkId;

  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);
    final matches = library.artworks.where((item) => item.id == artworkId);
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Artwork not found')));
    }
    final artwork = matches.first;
    final child = library.child(artwork.childId);
    final tags = library.tags
        .where((tag) => artwork.tagIds.contains(tag.id))
        .toList();
    final albums = library.albums
        .where((album) => artwork.albumIds.contains(album.id))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artwork'),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                files: [XFile(artwork.imagePath)],
                text: '${artwork.title} by ${child?.name ?? 'my child'}',
              ),
            ),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtworkEditor(
                      imagePath: artwork.imagePath,
                      existing: artwork,
                    ),
                  ),
                );
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete artwork?'),
                    content: const Text(
                      'This removes the photo and its details from this device. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await library.deleteArtwork(artwork);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.file(
              File(artwork.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const AspectRatio(
                aspectRatio: 1,
                child: ColoredBox(
                  color: Color(0xFFF0EAE0),
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${child?.name ?? 'Unknown artist'} · ${artwork.grade} · ${artwork.year}',
                      style: TextStyle(
                        fontSize: 15,
                        color: ink.withValues(alpha: .65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: artwork.isFavorite ? 'Remove favorite' : 'Favorite',
                onPressed: () => library.toggleFavorite(artwork),
                icon: Icon(
                  artwork.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: artwork.isFavorite ? coral : null,
                ),
              ),
            ],
          ),
          if (artwork.notes.isNotEmpty) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                artwork.notes,
                style: const TextStyle(fontSize: 16, height: 1.45),
              ),
            ),
          ],
          if (albums.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Albums',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: albums
                  .map(
                    (album) => Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Color(album.colorValue),
                      ),
                      label: Text(album.name),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: tags
                  .map((tag) => Chip(label: Text('#${tag.name}')))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
