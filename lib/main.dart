import 'package:flutter/material.dart';
import 'pantallas/pantalla_inicio.dart';

void main() {
  runApp(const UNiteApp());
}

class UNiteApp extends StatelessWidget {
  const UNiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U-NITE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        fontFamily: 'Roboto',
      ),
      home: const PantallaInicio(),
    );
  }
}
