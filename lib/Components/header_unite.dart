import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class HeaderUnite extends StatelessWidget implements PreferredSizeWidget {
  const HeaderUnite({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: Row(
          children: [
            // Logo Icono
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.graduationCap,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            // Texto U-NITE
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
                children: [
                  TextSpan(
                    text: 'U',
                    style: TextStyle(color: AppColors.green),
                  ),
                  TextSpan(
                    text: '-',
                    style: TextStyle(color: AppColors.orange),
                  ),
                  TextSpan(
                    text: 'NITE',
                    style: TextStyle(color: AppColors.green),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Botón Login (Texto)
            TextButton(
              onPressed: () {},
              child: const Text(
                "LOG IN",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Botón Registro (DuoButton)
            DuoButton(
              text: "Registro",
              color: AppColors.green,
              shadowColor: AppColors.greenDark,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
