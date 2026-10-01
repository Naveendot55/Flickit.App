import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/toe_tap/presentation/screens/trainer_screen.dart';
import 'theme/app_theme.dart';

/// Root application widget for Flickit.
class FlickitApp extends StatelessWidget {
  const FlickitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flickit - Toe Tap Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const TrainerScreen(),
    );
  }
}
