import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class ModulesSection extends StatelessWidget {
  const ModulesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          const Text(
            "Herramientas para tu éxito",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 25,
            runSpacing: 25,
            alignment: WrapAlignment.center,
            children: [
              _buildCard(
                title: "UniExchange",
                desc:
                    "Compra, vende o alquila materiales universitarios con otros estudiantes de tu campus.",
                icon: LucideIcons.repeat,
                color: AppColors.orange,
                shadow: AppColors.orangeDark,
              ),
              _buildCard(
                title: "StudyMatch",
                desc:
                    "Encuentra el grupo de estudio perfecto según tus horarios, fortalezas y debilidades.",
                icon: LucideIcons.users,
                color: AppColors.green,
                shadow: AppColors.greenDark,
              ),
              _buildCard(
                title: "Comunidad",
                desc:
                    "Conecta con otros estudiantes, resuelve dudas y comparte experiencias de tu carrera.",
                icon: LucideIcons.messageCircle,
                color: Colors.blue,
                shadow: const Color(0xFF0056b3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Color shadow,
  }) {
    return Container(
      width: 340,
      height: 320, // <--- ALTURA FIJA para que los 3 cuadros sean IDENTICOS
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          // Usamos Expanded para que el texto ocupe el espacio y el botón siempre quede abajo alineado
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              text: "Explorar",
              color: color,
              shadowColor: shadow,
              onPressed: () {},
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
