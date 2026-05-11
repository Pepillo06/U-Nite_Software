import 'package:flutter/material.dart';
import '../widgets/barra_navegacion_superior.dart';
import '../widgets/filtros_categorias.dart';
import '../widgets/cuadricula_productos.dart';
import '../widgets/banners_promocionales.dart';
import '../widgets/pie_de_pagina.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: BarraNavegacionSuperior()),
          const SliverToBoxAdapter(child: FiltrosCategorias()),
          const CuadriculaProductos(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: const BannersPromocionales(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          const SliverToBoxAdapter(child: PieDePagina()),
        ],
      ),
    );
  }
}
