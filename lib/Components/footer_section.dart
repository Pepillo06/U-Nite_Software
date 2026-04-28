import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          color: AppColors.orange,
          child: Column(
            children: [
              const Text(
                "¿Listo para unirte a la red estudiantil más grande?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Únete a miles de estudiantes que ya están optimizando su vida universitaria.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              DuoButton(
                text: "¡Registrarme ahora!",
                color: Colors.white,
                shadowColor: const Color(0xFFE0E0E0),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(LucideIcons.instagram, color: Colors.grey),
                  SizedBox(width: 20),
                  Icon(LucideIcons.twitter, color: Colors.grey),
                  SizedBox(width: 20),
                  Icon(LucideIcons.github, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                "U-NITE PROJECT",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.green,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                "© 2026 Hecho con ❤️ para estudiantes.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
