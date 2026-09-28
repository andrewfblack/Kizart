class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.currentGrade,
    required this.colorValue,
    required this.createdAt,
    this.birthYear,
  });

  final String id;
  final String name;
  final int? birthYear;
  final String currentGrade;
  final int colorValue;
  final DateTime createdAt;

  factory ChildProfile.fromMap(Map<String, Object?> map) => ChildProfile(
    id: map['id']! as String,
    name: map['name']! as String,
    birthYear: map['birth_year'] as int?,
    currentGrade: map['current_grade']! as String,
    colorValue: map['color_value']! as int,
    createdAt: DateTime.parse(map['created_at']! as String),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'birth_year': birthYear,
    'current_grade': currentGrade,
    'color_value': colorValue,
    'created_at': createdAt.toIso8601String(),
  };
}

class ArtAlbum {
  const ArtAlbum({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final int colorValue;
  final DateTime createdAt;

  factory ArtAlbum.fromMap(Map<String, Object?> map) => ArtAlbum(
    id: map['id']! as String,
    name: map['name']! as String,
    description: map['description']! as String,
    colorValue: map['color_value']! as int,
    createdAt: DateTime.parse(map['created_at']! as String),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'color_value': colorValue,
    'created_at': createdAt.toIso8601String(),
  };
}

class ArtTag {
  const ArtTag({required this.id, required this.name});
  final String id;
  final String name;

  factory ArtTag.fromMap(Map<String, Object?> map) =>
      ArtTag(id: map['id']! as String, name: map['name']! as String);
  Map<String, Object?> toMap() => {'id': id, 'name': name};
}

class Artwork {
  const Artwork({
    required this.id,
    required this.childId,
    required this.title,
    required this.notes,
    required this.imagePath,
    required this.year,
    required this.grade,
    required this.isFavorite,
    required this.createdAt,
    required this.scannedAt,
    this.albumIds = const {},
    this.tagIds = const {},
  });

  final String id;
  final String childId;
  final String title;
  final String notes;
  final String imagePath;
  final int year;
  final String grade;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime scannedAt;
  final Set<String> albumIds;
  final Set<String> tagIds;

  factory Artwork.fromMap(
    Map<String, Object?> map, {
    Set<String> albumIds = const {},
    Set<String> tagIds = const {},
  }) => Artwork(
    id: map['id']! as String,
    childId: map['child_id']! as String,
    title: map['title']! as String,
    notes: map['notes']! as String,
    imagePath: map['image_path']! as String,
    year: map['year']! as int,
    grade: map['grade']! as String,
    isFavorite: (map['is_favorite']! as int) == 1,
    createdAt: DateTime.parse(map['created_at']! as String),
    scannedAt: DateTime.parse(map['scanned_at']! as String),
    albumIds: albumIds,
    tagIds: tagIds,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'child_id': childId,
    'title': title,
    'notes': notes,
    'image_path': imagePath,
    'year': year,
    'grade': grade,
    'is_favorite': isFavorite ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'scanned_at': scannedAt.toIso8601String(),
  };

  Artwork copyWith({bool? isFavorite}) => Artwork(
    id: id,
    childId: childId,
    title: title,
    notes: notes,
    imagePath: imagePath,
    year: year,
    grade: grade,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt,
    scannedAt: scannedAt,
    albumIds: albumIds,
    tagIds: tagIds,
  );
}
