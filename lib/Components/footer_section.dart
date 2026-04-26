import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- BANNER NARANJA (Newsletter/CTA) ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          decoration: const BoxDecoration(color: AppColors.orange),
          child: Column(
            children: [
              const Text(
                "¿Listo para unirte a la red estudiantil más grande?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Únete a miles de estudiantes que ya están optimizando su vida universitaria.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              DuoButton(
                text: "¡Registrarme ahora!",
                color: Colors.white,
                shadowColor: Colors.black12,
                onPressed: () {},
                // Modificamos el color del texto para este botón específico
              ),
            ],
          ),
        ),

        // --- FOOTER DETALLADO ---
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIcon(LucideIcons.instagram),
                  _socialIcon(LucideIcons.twitter),
                  _socialIcon(LucideIcons.github),
                  _socialIcon(LucideIcons.mail),
                ],
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                "U-NITE PROJECT",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "© 2026 Hecho con ❤️ para estudiantes.",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(icon, color: Colors.grey, size: 24),
    );
  }
}
