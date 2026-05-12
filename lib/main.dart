import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'post_item.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.lexendTextTheme(),
        useMaterial3: true,
      ),
      //home: const HomePage(),
      home: const PublicarArticuloPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MiAnimacion extends StatelessWidget {
  const MiAnimacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animación Rive'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: RiveAnimation.asset(
            'assests.dart/19762-37175-star-rating-animation.riv',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
