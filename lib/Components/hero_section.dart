import 'package:flutter/material.dart';
import '../theme.dart'; // Importamos el botón y colores

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.network(
          "https://images.unsplash.com/photo-1543269865-cbf427effbad?q=80&w=2070",
          height: 500,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          height: 500,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.6), AppColors.bg],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "OPTIMIZA TU VIDA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  "UNIVERSITARIA",
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 30),
                DuoButton(
                  text: "¡Comenzar!",
                  color: AppColors.orange,
                  shadowColor: AppColors.orangeDark,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
