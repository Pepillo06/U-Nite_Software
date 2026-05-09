import 'package:flutter/material.dart';
import 'theme.dart';
import 'components/header_unite.dart';
import 'components/hero_section.dart';
import 'components/modules_section.dart';
import 'components/squirrel_section.dart';
import 'components/footer_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const HeaderUnite(),
      // --- ESTO ES LO QUE HACE QUE LAS RAYITAS FUNCIONEN ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.green),
              child: Text(
                'Menú U-NITE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('UniExchange'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('StudyMatch'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.forum),
              title: const Text('Comunidad'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(),
            ModulesSection(),
            SquirrelSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}
