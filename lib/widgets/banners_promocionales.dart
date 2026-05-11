import 'package:flutter/material.dart';

class BannersPromocionales extends StatelessWidget {
  const BannersPromocionales({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width < 800) {
      return Column(
        children: [
          _construirBannerIzquierdo(context),
          const SizedBox(height: 24),
          _construirBannerDerecho(),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _construirBannerIzquierdo(context)),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _construirBannerDerecho()),
        ],
      ),
    );
  }

  Widget _construirBannerIzquierdo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¡Libera espacio y gana dinero!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vende tus libros del semestre pasado o los muebles que\nya no necesitas a otros estudiantes de tu facultad.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Empezando proceso de venta...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF5722),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Empezar a Vender',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBannerDerecho() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFC8E6C9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tratos Seguros',
            style: TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Encuentros exclusivos en puntos seguros dentro del campus universitario.',
            style: TextStyle(
              color: const Color(0xFF1B5E20).withOpacity(0.8),
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
