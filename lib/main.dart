import 'package:flutter/material.dart';
import 'home_page.dart';

import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

void main() {
  runApp(const UNITEApp());
}

class UNITEApp extends StatelessWidget {
  const UNITEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U-Nite Software',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: UColors.orange),
        textTheme: GoogleFonts.lexendTextTheme(),
        useMaterial3: true,
      ),

      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
