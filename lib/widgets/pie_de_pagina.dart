import 'package:flutter/material.dart';

class PieDePagina extends StatelessWidget {
  const PieDePagina({super.key});

  void _abrirEnlace(BuildContext context, String enlace) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abriendo: $enlace'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'U-NITE',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '© 2024 U-NITE Campus Marketplace. Todos los derechos\nreservados.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 32,
              runSpacing: 16,
              children: [
                _construirEnlace(context, 'Centro de Ayuda'),
                _construirEnlace(context, 'Términos de Servicio'),
                _construirEnlace(context, 'Privacidad'),
                _construirEnlace(context, 'Seguridad Estudiantil'),
                _construirEnlace(context, 'Contacto Institucional'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEnlace(BuildContext context, String texto) {
    return InkWell(
      onTap: () => _abrirEnlace(context, texto),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
