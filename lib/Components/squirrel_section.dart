import 'package:flutter/material.dart';
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
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0,
      end: -15,
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
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      color: Colors.white,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animation.value),
                child: child,
              );
            },
            child: Image.network(
              "https://api.dicebear.com/7.x/bottts/svg?seed=squirrel&backgroundColor=ff6b00",
              height: 180,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Tu carrera, optimizada por Inteligencia Colectiva",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Uni te ayudará a encontrar lo que necesitas, desde el libro de cálculo hasta el equipo de estudio ideal.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
