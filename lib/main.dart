import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pantallas/pantalla_inicio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ozjypoiauxgvofpebbnj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96anlwb2lhdXhndm9mcGViYm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MzE5MzEsImV4cCI6MjA5NDAwNzkzMX0.MkjT9UpYuF1oUNmD6-WJD5w6c0anhv86GxrhCbUtZlE',
  );

  Timer.periodic(const Duration(seconds: 30), (_) {
    _actualizarUltimaConexion();
  });
  // Actualizar ultima_conexion al abrir la app
  _actualizarUltimaConexion();

  // Escuchar cambios de sesión para actualizar cuando el usuario inicia sesión
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn) {
      _actualizarUltimaConexion();
    }
  });

  runApp(const UNITEApp());
}

Future<void> _actualizarUltimaConexion() async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('usuarios')
        .update({'ultima_conexion': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);
  } catch (_) {}
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
      debugShowCheckedModeBanner: false,
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español (configuración general)
      ],
      
      locale: const Locale('es', ''), 

      home: const HomePage(),
    );
  }
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
