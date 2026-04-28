import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class SquirrelSection extends StatefulWidget {
  const SquirrelSection({super.key});

  @override
  State<SquirrelSection> createState() => _SquirrelSectionState();
}

class _SquirrelSectionState extends State<SquirrelSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0,
      end: -20,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 30),
      color: Colors.white,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _animation.value),
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.network(
                "https://api.dicebear.com/7.x/bottts/svg?seed=Uni&backgroundColor=ff6b00&radius=20",
                height: 180,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stack) => const Icon(
                  LucideIcons.bot,
                  size: 100,
                  color: AppColors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Tu carrera, optimizada por Inteligencia Colectiva",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Uni te ayudará a encontrar lo que necesitas, desde el libro de cálculo hasta el equipo de estudio ideal.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
