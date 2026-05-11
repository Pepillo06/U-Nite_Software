import 'package:flutter/material.dart';

class BarraNavegacionSuperior extends StatelessWidget {
  const BarraNavegacionSuperior({super.key});

  void _mostrarMensaje(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
      child: Row(
        children: [
          // Logo
          InkWell(
            onTap: () => _mostrarMensaje(context, 'Volviendo a Inicio'),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                          color: Color(0xFFFF5722),
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'U-NITE',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Buscador
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar libros, muebles, electrónica...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                onSubmitted: (value) => _mostrarMensaje(context, 'Buscando: $value'),
              ),
            ),
          ),
          const SizedBox(width: 40),
          // Iconos y Botón
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => _mostrarMensaje(context, 'Abriendo Notificaciones'),
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined),
                onPressed: () => _mostrarMensaje(context, 'Abriendo Mensajes'),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _mostrarMensaje(context, 'Abriendo Carrito'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _mostrarMensaje(context, 'Navegando a Publicar Artículo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Vender Artículo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _mostrarMensaje(context, 'Abriendo Perfil de Usuario'),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=68'),
                  onBackgroundImageError: (exception, stackTrace) {}, // Evita error si falla la imagen
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
