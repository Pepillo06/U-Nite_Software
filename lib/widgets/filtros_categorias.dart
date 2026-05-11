import 'package:flutter/material.dart';

class FiltrosCategorias extends StatefulWidget {
  const FiltrosCategorias({super.key});

  @override
  State<FiltrosCategorias> createState() => _FiltrosCategoriasState();
}

class _FiltrosCategoriasState extends State<FiltrosCategorias> {
  int indiceSeleccionado = 0;
  final categorias = [
    {'nombre': 'Todos', 'icono': Icons.grid_view},
    {'nombre': 'Libros', 'icono': Icons.menu_book},
    {'nombre': 'Electrónica', 'icono': Icons.computer},
    {'nombre': 'Muebles', 'icono': Icons.chair_alt},
    {'nombre': 'Alojamientos', 'icono': Icons.home_outlined},
  ];

  void _seleccionarCategoria(int index) {
    setState(() {
      indiceSeleccionado = index;
    });
    
    final nombre = categorias[index]['nombre'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtrando por: $nombre'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(categorias.length, (index) {
            final esSeleccionado = indiceSeleccionado == index;
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: InkWell(
                onTap: () => _seleccionarCategoria(index),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: esSeleccionado ? const Color(0xFFFF5722) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        categorias[index]['icono'] as IconData,
                        size: 20,
                        color: esSeleccionado ? Colors.white : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categorias[index]['nombre'] as String,
                        style: TextStyle(
                          color: esSeleccionado ? Colors.white : Colors.grey.shade800,
                          fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
