import 'package:flutter/material.dart';
import 'theme.dart';
import 'components/header_unite.dart';
import 'components/hero_section.dart';
import 'components/modules_section.dart';
import 'components/squirrel_section.dart';
import 'components/footer_section.dart'; // Importamos el nuevo footer

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      // Usamos el Header como AppBar
      appBar: HeaderUnite(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(), // Sección de inicio con imagen
            ModulesSection(), // Tarjetas UniExchange y StudyMatch
            SquirrelSection(), // Sección de Uni la Ardilla
            FooterSection(), // Banner naranja y pie de página
          ],
        ),
      ),
    );
  }
}
