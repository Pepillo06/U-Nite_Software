import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class HeaderUnite extends StatelessWidget implements PreferredSizeWidget {
  const HeaderUnite({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Definimos móvil como menos de 850px
    bool isMobile = screenWidth < 850;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 2)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // --- 1. IZQUIERDA: SIEMPRE EL LOGO O MENÚ ---
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMobile)
                      IconButton(
                        icon: const Icon(
                          LucideIcons.menu,
                          color: AppColors.green,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      )
                    else ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
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
                      const SizedBox(width: 8),
                      const Text(
                        'U-NITE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.green,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // --- 2. CENTRO: DINÁMICO ---
            Align(
              alignment: Alignment.center,
              child: isMobile
                  ? _buildAccessRow(isMobile) // EN MÓVIL: ACCESO AL CENTRO
                  : _buildNavRow(), // EN WEB: MÓDULOS AL CENTRO
            ),

            // --- 3. DERECHA: VACÍO EN MÓVIL / ACCESO EN WEB ---
            if (!isMobile)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildAccessRow(isMobile),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Fila de navegación para Web
  Widget _buildNavRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navButton("UniExchange"),
        _navButton("StudyMatch"),
        _navButton("Comunidad"),
      ],
    );
  }

  // Fila de Acceso (Login y Registro)
  Widget _buildAccessRow(bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
          ),
          child: Text(
            isMobile ? "ENTRAR" : "INICIAR SESIÓN",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120, // Ahora podemos usar el ancho completo de 120 sin miedo
          child: DuoButton(
            text: "Registro",
            color: AppColors.green,
            shadowColor: AppColors.greenDark,
            onPressed: () {},
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _navButton(String text) {
    return SizedBox(
      width: 125,
      child: TextButton(
        onPressed: () {},
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
