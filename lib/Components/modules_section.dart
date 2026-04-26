import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class ModulesSection extends StatelessWidget {
  const ModulesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          const Text(
            "Herramientas para tu éxito",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildCard(
            title: "UniExchange",
            desc:
                "Compra, vende o alquila materiales universitarios con otros estudiantes.",
            icon: LucideIcons.repeat,
            color: AppColors.orange,
            shadow: AppColors.orangeDark,
            tags: ["Libros", "Calculadoras"],
          ),
          const SizedBox(height: 25),
          _buildCard(
            title: "StudyMatch",
            desc:
                "Encuentra el grupo de estudio perfecto según tus horarios y fortalezas.",
            icon: LucideIcons.users,
            color: AppColors.green,
            shadow: AppColors.greenDark,
            tags: ["Horarios", "Tutorías"],
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
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 35, color: color),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              text: "Explorar $title",
              color: color,
              shadowColor: shadow,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
