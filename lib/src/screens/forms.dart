import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/models.dart';
import '../state/art_library.dart';
import '../theme.dart';

const grades = [
  'Pre-K',
  'Kindergarten',
  '1st grade',
  '2nd grade',
  '3rd grade',
  '4th grade',
  '5th grade',
  '6th grade',
  '7th grade',
  '8th grade',
  '9th grade',
  '10th grade',
  '11th grade',
  '12th grade',
  'Other',
];

Future<void> showChildForm(
  BuildContext context, {
  ChildProfile? existing,
}) async {
  final library = LibraryScope.of(context);
  final name = TextEditingController(text: existing?.name);
  final birthYear = TextEditingController(
    text: existing?.birthYear?.toString(),
  );
  var grade = existing?.currentGrade ?? 'Kindergarten';
  var colorValue = existing?.colorValue ?? profileColors.first.toARGB32();
  final key = GlobalKey<FormState>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          existing == null ? 'Add a child' : 'Edit child',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.face_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: birthYear,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Birth year (optional)',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final year = int.tryParse(value);
                      return year == null ||
                              year < 1990 ||
                              year > DateTime.now().year
                          ? 'Enter a valid year'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: grade,
                    decoration: const InputDecoration(
                      labelText: 'Current grade',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: grades
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => grade = value!,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Profile color',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    children: profileColors.map((color) {
                      final selected = colorValue == color.toARGB32();
                      return InkWell(
                        onTap: () =>
                            setState(() => colorValue = color.toARGB32()),
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          backgroundColor: color,
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: () async {
                      if (!key.currentState!.validate()) return;
                      await library.saveChild(
                        ChildProfile(
                          id: existing?.id ?? library.newId(),
                          name: name.text.trim(),
                          birthYear: birthYear.text.isEmpty
                              ? null
                              : int.parse(birthYear.text),
                          currentGrade: grade,
                          colorValue: colorValue,
                          createdAt: existing?.createdAt ?? DateTime.now(),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(
                      existing == null ? 'Add child' : 'Save changes',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> showAlbumForm(BuildContext context, {ArtAlbum? existing}) async {
  final library = LibraryScope.of(context);
  final name = TextEditingController(text: existing?.name);
  final description = TextEditingController(text: existing?.description);
  final key = GlobalKey<FormState>();
  var colorValue = existing?.colorValue ?? sky.toARGB32();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      existing == null ? 'New album' : 'Edit album',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Album name',
                  prefixIcon: Icon(Icons.collections_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [coral, mint, sunflower, sky, lavender]
                    .map(
                      (color) => InkWell(
                        onTap: () =>
                            setState(() => colorValue = color.toARGB32()),
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          backgroundColor: color,
                          child: colorValue == color.toARGB32()
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  if (!key.currentState!.validate()) return;
                  await library.saveAlbum(
                    ArtAlbum(
                      id: existing?.id ?? library.newId(),
                      name: name.text.trim(),
                      description: description.text.trim(),
                      colorValue: colorValue,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(existing == null ? 'Create album' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showTagForm(BuildContext context) async {
  final library = LibraryScope.of(context);
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('New tag'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Painting, animals, holiday…',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final value = controller.text.trim();
            if (value.isEmpty) return;
            await library.saveTag(ArtTag(id: library.newId(), name: value));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

class ArtworkEditor extends StatefulWidget {
  const ArtworkEditor({super.key, required this.imagePath, this.existing});
  final String imagePath;
  final Artwork? existing;
  @override
  State<ArtworkEditor> createState() => _ArtworkEditorState();
}

class _ArtworkEditorState extends State<ArtworkEditor> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late String _childId;
  late int _year;
  late String _grade;
  late Set<String> _albumIds;
  late Set<String> _tagIds;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final library = LibraryScope.of(context);
    _title = TextEditingController(
      text: widget.existing?.title ?? 'Untitled masterpiece',
    );
    _notes = TextEditingController(text: widget.existing?.notes);
    _childId = widget.existing?.childId ?? library.children.first.id;
    final child = library.child(_childId)!;
    _year = widget.existing?.year ?? DateTime.now().year;
    _grade = widget.existing?.grade ?? child.currentGrade;
    _albumIds = {...?widget.existing?.albumIds};
    _tagIds = {...?widget.existing?.tagIds};
    _initialized = true;
  }

  bool _initialized = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Save artwork' : 'Edit artwork'),
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Give this artwork a title'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _childId,
              decoration: const InputDecoration(labelText: 'Artist'),
              items: library.children
                  .map(
                    (child) => DropdownMenuItem(
                      value: child.id,
                      child: Text(child.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _childId = value!;
                _grade = library.child(value)!.currentGrade;
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items:
                        List.generate(
                              21,
                              (index) => DateTime.now().year + 1 - index,
                            )
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => _year = value!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_grade),
                    initialValue: _grade,
                    decoration: const InputDecoration(labelText: 'Grade'),
                    items: grades
                        .map(
                          (grade) => DropdownMenuItem(
                            value: grade,
                            child: Text(grade),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => _grade = value!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Story or notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            if (library.albums.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text(
                'Albums',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: library.albums
                    .map(
                      (album) => FilterChip(
                        label: Text(album.name),
                        selected: _albumIds.contains(album.id),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _albumIds.add(album.id)
                              : _albumIds.remove(album.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (library.tags.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text(
                'Tags',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: library.tags
                    .map(
                      (tag) => FilterChip(
                        label: Text('#${tag.name}'),
                        selected: _tagIds.contains(tag.id),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _tagIds.add(tag.id)
                              : _tagIds.remove(tag.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: FilledButton.icon(
          onPressed: _saving ? null : () => _save(library),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'Saving…' : 'Save artwork'),
        ),
      ),
    );
  }

  Future<void> _save(ArtLibrary library) async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final existing = widget.existing;
    await library.saveArtwork(
      Artwork(
        id: existing?.id ?? library.newId(),
        childId: _childId,
        title: _title.text.trim(),
        notes: _notes.text.trim(),
        imagePath: widget.imagePath,
        year: _year,
        grade: _grade,
        isFavorite: existing?.isFavorite ?? false,
        createdAt: existing?.createdAt ?? DateTime.now(),
        scannedAt: existing?.scannedAt ?? DateTime.now(),
        albumIds: _albumIds,
        tagIds: _tagIds,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }
}
