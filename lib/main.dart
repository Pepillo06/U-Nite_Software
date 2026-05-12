import 'package:flutter/material.dart';
import 'home_page.dart';

import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
  url: 'https://ozjypoiauxgvofpebbnj.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96anlwb2lhdXhndm9mcGViYm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MzE5MzEsImV4cCI6MjA5NDAwNzkzMX0.MkjT9UpYuF1oUNmD6-WJD5w6c0anhv86GxrhCbUtZlE',
  );
 
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
