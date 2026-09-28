import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/art_repository.dart';
import 'src/state/art_library.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final library = ArtLibrary(ArtRepository());
  await library.initialize();
  runApp(KizartApp(library: library));
}
