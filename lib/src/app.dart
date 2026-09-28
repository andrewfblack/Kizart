import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'state/art_library.dart';
import 'theme.dart';

class LibraryScope extends InheritedNotifier<ArtLibrary> {
  const LibraryScope({
    super.key,
    required ArtLibrary library,
    required super.child,
  }) : super(notifier: library);

  static ArtLibrary of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LibraryScope>();
    assert(scope != null, 'LibraryScope not found');
    return scope!.notifier!;
  }
}

class KizartApp extends StatelessWidget {
  const KizartApp({super.key, required this.library});
  final ArtLibrary library;

  @override
  Widget build(BuildContext context) => LibraryScope(
    library: library,
    child: MaterialApp(
      title: 'Kizart',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeShell(),
    ),
  );
}
