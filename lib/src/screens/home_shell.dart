import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'artwork_detail.dart';
import 'forms.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _scanning = false;

  @override
  Widget build(BuildContext context) {
    final titles = ['Kizart', 'Albums', 'Organize'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Add child',
              onPressed: () => showChildForm(context),
              icon: const Icon(Icons.person_add_alt_1_outlined),
            ),
          if (_index == 1)
            IconButton(
              tooltip: 'New album',
              onPressed: () => showAlbumForm(context),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [GalleryPage(), AlbumsPage(), OrganizePage()],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _scanning ? null : _scan,
              backgroundColor: coral,
              foregroundColor: Colors.white,
              icon: _scanning
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(
                _scanning ? 'Opening…' : 'Scan art',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: 'Albums',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Organize',
          ),
        ],
      ),
    );
  }

  Future<void> _scan() async {
    final library = LibraryScope.of(context);
    if (library.children.isEmpty) {
      await showChildForm(context);
      if (library.children.isEmpty) return;
    }
    setState(() => _scanning = true);
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        scannerSource: ScannerSource.cameraAndGallery,
        iosScannerOptions: IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: .9,
        ),
      );
      if (pictures == null || pictures.isEmpty || !mounted) {
        return;
      }
      final id = library.newId();
      final permanentPath = await library.repository.keepScan(
        pictures.first,
        id,
      );
      if (!mounted) {
        return;
      }
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ArtworkEditor(imagePath: permanentPath),
        ),
      );
      if (saved != true) {
        final file = File(permanentPath);
        if (await file.exists()) await file.delete();
      }
      await CunningDocumentScanner.cleanCache();
    } on CunningDocumentScannerException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The scanner could not open. Check camera access and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  String? _childId;
  String _query = '';
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);
    if (library.children.isEmpty) {
      return EmptyState(
        icon: Icons.palette_outlined,
        title: 'Every masterpiece has a story',
        message: 'Add your first child, then scan artwork to keep those colorful memories safe and organized.',
        action: FilledButton.icon(
          onPressed: () => showChildForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Add a child'),
        ),
      );
    }
    var art = library.artworks
        .where((item) => _childId == null || item.childId == _childId)
        .toList();
    if (_query.isNotEmpty) {
      final query = _query.toLowerCase();
      art = art
          .where(
            (item) =>
                item.title.toLowerCase().contains(query) ||
                item.notes.toLowerCase().contains(query) ||
                library.tags.any(
                  (tag) =>
                      item.tagIds.contains(tag.id) &&
                      tag.name.toLowerCase().contains(query),
                ),
          )
          .toList();
    }
    if (_favoritesOnly) art = art.where((item) => item.isFavorite).toList();
    return Column(
      children: [
        SizedBox(
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            children: [
              _ChildFilter(
                name: 'All',
                selected: _childId == null,
                color: ink,
                count: library.artworks.length,
                onTap: () => setState(() => _childId = null),
              ),
              ...library.children.map(
                (child) => _ChildFilter(
                  name: child.name,
                  selected: _childId == child.id,
                  color: Color(child.colorValue),
                  count: library.artworkCountForChild(child.id),
                  onTap: () => setState(() => _childId = child.id),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search art, notes, or tags',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Favorites only',
                onPressed: () =>
                    setState(() => _favoritesOnly = !_favoritesOnly),
                icon: Icon(
                  _favoritesOnly ? Icons.favorite : Icons.favorite_border,
                  color: _favoritesOnly ? coral : null,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: art.isEmpty
              ? EmptyState(
                  icon: _query.isNotEmpty || _favoritesOnly
                      ? Icons.search_off
                      : Icons.photo_camera_back_outlined,
                  title: _query.isNotEmpty || _favoritesOnly
                      ? 'Nothing matches yet'
                      : 'Ready for some art',
                  message: _query.isNotEmpty || _favoritesOnly
                      ? 'Try another search or turn off the favorites filter.'
                      : 'Tap Scan art to capture the first masterpiece.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: art.length,
                  itemBuilder: (_, index) {
                    final item = art[index];
                    return ArtworkTile(
                      artwork: item,
                      child: library.child(item.childId),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ArtworkDetailScreen(artworkId: item.id),
                        ),
                      ),
                      onFavorite: () => library.toggleFavorite(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ChildFilter extends StatelessWidget {
  const _ChildFilter({
    required this.name,
    required this.selected,
    required this.color,
    required this.count,
    required this.onTap,
  });
  final String name;
  final bool selected;
  final Color color;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 84,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .17) : Colors.white,
          border: Border.all(
            color: selected ? color : const Color(0xFFE8E0D5),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '$count art',
              style: TextStyle(fontSize: 11, color: ink.withValues(alpha: .55)),
            ),
          ],
        ),
      ),
    ),
  );
}

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);
    if (library.albums.isEmpty) {
      return EmptyState(
        icon: Icons.collections_outlined,
        title: 'Group favorite moments',
        message: 'Make albums for school years, themes, holidays, or anything your family loves.',
        action: FilledButton.icon(
          onPressed: () => showAlbumForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Create album'),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: .92,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: library.albums.length,
      itemBuilder: (_, index) {
        final album = library.albums[index];
        final albumArt = library.artworks
            .where((art) => art.albumIds.contains(album.id))
            .toList();
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlbumDetailScreen(albumId: album.id),
            ),
          ),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: Color(album.colorValue),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                if (albumArt.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Opacity(
                        opacity: .28,
                        child: Image.file(
                          File(albumArt.first.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.collections_bookmark_outlined,
                          size: 28,
                        ),
                        const Spacer(),
                        Text(
                          album.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${albumArt.length} ${albumArt.length == 1 ? 'piece' : 'pieces'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({super.key, required this.albumId});
  final String albumId;
  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);
    final albumMatches = library.albums.where((item) => item.id == albumId);
    if (albumMatches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Album not found')));
    }
    final album = albumMatches.first;
    final art = library.artworks
        .where((item) => item.albumIds.contains(album.id))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(album.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await showAlbumForm(context, existing: album);
              }
              if (value == 'delete') {
                await library.deleteAlbum(album.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit album')),
              PopupMenuItem(value: 'delete', child: Text('Delete album')),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (album.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                album.description,
                style: TextStyle(color: ink.withValues(alpha: .68)),
              ),
            ),
          Expanded(
            child: art.isEmpty
                ? const EmptyState(
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'This album is empty',
                    message:
                        'Edit an artwork and select this album to add it here.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: .72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: art.length,
                    itemBuilder: (_, index) {
                      final item = art[index];
                      return ArtworkTile(
                        artwork: item,
                        child: library.child(item.childId),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ArtworkDetailScreen(artworkId: item.id),
                          ),
                        ),
                        onFavorite: () => library.toggleFavorite(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class OrganizePage extends StatelessWidget {
  const OrganizePage({super.key});
  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        SectionHeading(
          'Kids',
          action: TextButton.icon(
            onPressed: () => showChildForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        if (library.children.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No child profiles yet.'),
          )
        else
          ...library.children.map(
            (child) => ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 3,
              ),
              leading: CircleAvatar(
                backgroundColor: Color(child.colorValue),
                child: Text(
                  child.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              title: Text(
                child.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${child.currentGrade} · ${library.artworkCountForChild(child.id)} pieces',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showChildForm(context, existing: child),
            ),
          ),
        const SizedBox(height: 16),
        SectionHeading(
          'Tags',
          action: TextButton.icon(
            onPressed: () => showTagForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: library.tags.isEmpty
              ? Text(
                  'Tags make themes easy to find—like #animals or #painting.',
                  style: TextStyle(color: ink.withValues(alpha: .65)),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: library.tags
                      .map(
                        (tag) => InputChip(
                          label: Text('#${tag.name}'),
                          onDeleted: () => library.deleteTag(tag.id),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 26),
        const SectionHeading('Your library'),
        const _InfoTile(
          icon: Icons.lock_outline,
          title: 'Private by design',
          subtitle: 'Your artwork stays on this device.',
        ),
        const _InfoTile(
          icon: Icons.cloud_outlined,
          title: 'Cloud sync',
          subtitle: 'iCloud and Google Drive are planned for a future update.',
          comingSoon: true,
        ),
        const _InfoTile(
          icon: Icons.local_print_shop_outlined,
          title: 'Print your favorites',
          subtitle: 'Books and prints are planned for a future update.',
          comingSoon: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: Text(
            '${library.artworks.length} artworks · ${library.albums.length} albums',
            textAlign: TextAlign.center,
            style: TextStyle(color: ink.withValues(alpha: .5), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.comingSoon = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool comingSoon;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    leading: CircleAvatar(
      backgroundColor: mint.withValues(alpha: .6),
      child: Icon(icon, color: ink),
    ),
    title: Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        if (comingSoon) ...[
          const SizedBox(width: 8),
          const Chip(label: Text('Soon'), visualDensity: VisualDensity.compact),
        ],
      ],
    ),
    subtitle: Text(subtitle),
  );
}
