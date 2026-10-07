import 'package:flutter/material.dart';
import '../../../quran/presentation/screens/mushaf_screen.dart';

class MushafPage extends StatelessWidget {
  final int initialPage;
  const MushafPage({super.key, this.initialPage = 1});

  @override
  Widget build(BuildContext context) {
    return MushafScreen(initialPage: initialPage);
  }
}
