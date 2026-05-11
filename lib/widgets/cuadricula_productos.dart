import 'package:flutter/material.dart';
import '../datos/datos_prueba.dart';
import 'tarjeta_producto.dart';

class CuadriculaProductos extends StatelessWidget {
  const CuadriculaProductos({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine cross axis count based on screen width
    double width = MediaQuery.of(context).size.width;
    int columnas = 4;
    if (width < 600) {
      columnas = 1;
    } else if (width < 900) {
      columnas = 2;
    } else if (width < 1200) {
      columnas = 3;
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnas,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final producto = productosPrueba[index];
            return TarjetaProducto(producto: producto);
          },
          childCount: productosPrueba.length,
        ),
      ),
    );
  }
}
