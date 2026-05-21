import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_item.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'screens/chat/chat_list_screen.dart';
import 'widgets/unite_header.dart';

// ==========================================
// PANTALLA PRINCIPAL DEL MARKETPLACE REDISEÑADA
// ==========================================
class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  String _categoriaSeleccionada = 'Todos';

  void _onCategoriaChanged(String categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC), // Fondo claro y limpio como la foto
      body: CustomScrollView(
        slivers: [
          // Mantenemos tu Header intacto
          const SliverToBoxAdapter(child: UniteHeader(currentIndex: 1)),
          
          // SECCIÓN HERO: Título llamativo y Buscador Centralizado
          const SliverToBoxAdapter(child: _SeccionHero()),

          // SECCIÓN DE CONTENIDO: Layout dividido (Categorías + Productos)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 40.0,
                vertical: 32.0,
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BotonVenderElegante(isMobile: true),
                        const SizedBox(height: 16),
                        _CategoriasLaterales(
                          categoriaActual: _categoriaSeleccionada,
                          onChanged: _onCategoriaChanged,
                          isMobile: true,
                        ),
                        const SizedBox(height: 24),
                        _EncabezadoResultados(),
                        const SizedBox(height: 16),
                        _CuadriculaProductosContenedor(categoria: _categoriaSeleccionada),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barra Lateral Izquierda
                        SizedBox(
                          width: 240,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BotonVenderElegante(isMobile: false),
                              const SizedBox(height: 24),
                              Text(
                                'Categorías',
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _CategoriasLaterales(
                                categoriaActual: _categoriaSeleccionada,
                                onChanged: _onCategoriaChanged,
                                isMobile: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Panel de Productos a la Derecha
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _EncabezadoResultados(),
                              const SizedBox(height: 20),
                              _CuadriculaProductosContenedor(categoria: _categoriaSeleccionada),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          const SliverToBoxAdapter(child: _PieDePagina()),
        ],
      ),
    );
  }
}

// ==========================================
// SECCIÓN HERO (Buscador Gigante + Títulos)
// ==========================================
class _SeccionHero extends StatelessWidget {
  const _SeccionHero();

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 600;

    return Container(
      width: double.infinity,
      //color: Colors.white,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center, // El degradado empieza exactamente en el medio
          radius: 1,             // Define qué tan expandido estará el efecto
          colors: [
            UColors.orange.withOpacity(0.3), // Naranja muy sutil y elegante en el centro
            Colors.white,                    // Se desvanece por completo a blanco puro
          ],
          stops: const [0.0, 0.70], // El naranja se mantiene suave y a partir del 85% se vuelve blanco
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 20.0 : 40.0,
        vertical: isSmall ? 40.0 : 60.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.lexend(
                fontSize: isSmall ? 32 : 48,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
                height: 1.2,
              ),
              children: [
                const TextSpan(text: '¿Qué buscas para tu\n'),
                TextSpan(
                  text: 'carrera',
                  style: TextStyle(color: UColors.orange),
                ),
                const TextSpan(text: ' hoy?'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Explora libros, tecnología y servicios compartidos por tu comunidad universitaria.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: isSmall ? 14 : 16,
              color: const Color(0xFF666666),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),
          // Buscador estilo de la foto
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: const Color(0xFFEBEAEA)),
              ),
              padding: const EdgeInsets.only(left: 20, right: 6),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF999999), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: GoogleFonts.lexend(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Buscar artículo...',
                        hintStyle: GoogleFonts.lexend(
                          color: const Color(0xFF999999),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UColors.orange,
                      foregroundColor: Colors.white,
                      //height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'BUSCAR',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENTE: BOTÓN VENDER REDISEÑADO
// ==========================================
class _BotonVenderElegante extends StatelessWidget {
  final bool isMobile;
  const _BotonVenderElegante({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isMobile ? double.infinity : 240,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          if (_verificarAutenticacion(context)) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublicarArticuloPage()),
            );
          }
        },
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'Vender Artículo',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: UColors.greenDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ==========================================
// FILTROS LATERALES EN ESPAÑOL
// ==========================================
class _CategoriasLaterales extends StatelessWidget {
  final String categoriaActual;
  final Function(String) onChanged;
  final bool isMobile;

  const _CategoriasLaterales({
    required this.categoriaActual,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final categorias = [
      {'nombre': 'Todos', 'icono': Icons.grid_view},
      {'nombre': 'Libros', 'icono': Icons.menu_book},
      {'nombre': 'Electrónica', 'icono': Icons.computer},
      {'nombre': 'Herramientas', 'icono': Icons.architecture},
      {'nombre': 'Accesorios', 'icono': Icons.checkroom},
    ];

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categorias.map((cat) {
            final String nombre = cat['nombre'] as String;
            final bool esSeleccionado = categoriaActual == nombre;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(nombre, style: GoogleFonts.lexend(fontSize: 13)),
                selected: esSeleccionado,
                selectedColor: const Color(0xFFFBF1EE),
                checkmarkColor: UColors.orange,
                labelStyle: TextStyle(
                  color: esSeleccionado ? UColors.orange : const Color(0xFF555555),
                  fontWeight: esSeleccionado ? FontWeight.w600 : FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: esSeleccionado ? UColors.orange : const Color(0xFFEBEAEA),
                  ),
                ),
                onSelected: (_) => onChanged(nombre),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      children: categorias.map((cat) {
        final String nombre = cat['nombre'] as String;
        final IconData icono = cat['icono'] as IconData;
        final bool esSeleccionado = categoriaActual == nombre;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: InkWell(
            onTap: () => onChanged(nombre),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: esSeleccionado ? const Color(0xFFFBF1EE) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    icono,
                    size: 18,
                    color: esSeleccionado ? UColors.orange : const Color(0xFF666666),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    nombre,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: esSeleccionado ? FontWeight.w600 : FontWeight.w500,
                      color: esSeleccionado ? UColors.orange : const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ==========================================
// ENCABEZADO DE RESULTADOS (Explore Marketplace)
// ==========================================
class _EncabezadoResultados extends StatelessWidget {
  const _EncabezadoResultados();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore el Marketplace',
              style: GoogleFonts.lexend(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Descubre artículos de tu comunidad universitaria',
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: const Color(0xFF777777),
              ),
            ),
          ],
        ),
        // Dropdown estético imitando el 'Sort by'
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEBEAEA)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Text(
                'Sort by: Recientes',
                style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// MANEJADOR Y CONTENEDOR DE LA GRID (SUPABASE)
// ==========================================
class _CuadriculaProductosContenedor extends StatefulWidget {
  final String categoria;
  const _CuadriculaProductosContenedor({required this.categoria});

  @override
  State<_CuadriculaProductosContenedor> createState() => _CuadriculaProductosContenedorState();
}

class _CuadriculaProductosContenedorState extends State<_CuadriculaProductosContenedor> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _anuncios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAnuncios();
  }

  @override
  void didUpdateWidget(_CuadriculaProductosContenedor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoria != widget.categoria) {
      _cargarAnuncios();
    }
  }

  Future<void> _cargarAnuncios() async {
    setState(() => _cargando = true);
    try {
      final data = await _supabase
          .from('anuncios_marketplace')
          .select()
          .eq('disponible', true)
          .order('fecha_publicacion', ascending: false);

      List<Map<String, dynamic>> resultado = List<Map<String, dynamic>>.from(data);

      if (widget.categoria != 'Todos') {
        resultado = resultado.where((a) => a['categoria'] == widget.categoria).toList();
      }

      setState(() {
        _anuncios = resultado;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: UColors.orange)),
      );
    }

    if (_anuncios.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Color(0xFF999999)),
            const SizedBox(height: 12),
            Text(
              'No hay productos en esta categoría',
              style: GoogleFonts.lexend(color: const Color(0xFF777777), fontSize: 15),
            ),
          ],
        ),
      );
    }

    double width = MediaQuery.of(context).size.width;
    int columnas = 3; // Estabilizado en 3 columnas para layouts de escritorio medianos/grandes a la derecha
    if (width < 600) columnas = 1;
    else if (width < 1100) columnas = 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Deja que el CustomScrollView maneje el scroll
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnas,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.82, // Proporción perfecta para el diseño de la tarjeta
      ),
      itemCount: _anuncios.length,
      itemBuilder: (context, index) => _TarjetaAnuncioRedisenada(anuncio: _anuncios[index]),
    );
  }
}

// ==========================================
// TARJETA DE PRODUCTO FIEL AL NUEVO DISEÑO
// ==========================================
class _TarjetaAnuncioRedisenada extends StatelessWidget {
  final Map<String, dynamic> anuncio;
  const _TarjetaAnuncioRedisenada({required this.anuncio});

  String _getPrecio() {
    final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    if (modalidades.containsKey('venta')) {
      final precio = modalidades['venta']['precio'];
      return '\$${precio?.toStringAsFixed(2) ?? '0.00'}';
    }
    if (modalidades.containsKey('alquiler')) {
      final alquiler = modalidades['alquiler'];
      if (alquiler is List && alquiler.isNotEmpty) {
        final costo = alquiler[0]['costo'];
        final unidad = alquiler[0]['unidad_tiempo'] ?? '';
        return '\$${costo?.toStringAsFixed(2) ?? '0.00'}/$unidad';
      }
    }
    return 'Consultar';
  }

  String _getImagenUrl() {
    final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    final imagenes = modalidades['imagenes'] as List<dynamic>? ?? [];
    return imagenes.isNotEmpty ? imagenes[0].toString() : '';
  }

  String _getCategoriaTag() {
    return (anuncio['categoria'] ?? 'General').toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final imagenUrl = _getImagenUrl();

    return InkWell(
      onTap: () => _mostrarDetalleAnuncio(context, anuncio),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEBEAEA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenedor de Imagen + Tag de Categoría flotante
            Expanded(
              flex: 11,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      child: imagenUrl.isNotEmpty
                          ? Image.network(imagenUrl, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Icon(Icons.image_not_supported, color: Color(0xFFBBBBBB)),
                            ),
                    ),
                  ),
                  // Tag superior derecho (Ej: TECH, BOOKS, HOUSING)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getCategoriaTag(),
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenedor de Detalles del Producto
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      anuncio['titulo'] ?? '',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getPrecio(),
                      style: GoogleFonts.lexend(
                        color: UColors.orange, // El precio destaca en naranja/marca
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Simulación de estrellas/calificación del diseño
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '4.9',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'por Estudiante',
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// COMPLETAR WIDGETS AUXILIARES E INTACTOS
// ==========================================

bool _verificarAutenticacion(BuildContext context) {
  if (Supabase.instance.client.auth.currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes iniciar sesión para realizar esta acción'),
        backgroundColor: UColors.orange,
      ),
    );
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    return false;
  }
  return true;
}

void _mostrarDetalleAnuncio(
  BuildContext context,
  Map<String, dynamic> anuncio,
) {
  final modalidades =
      anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
  final imagenes = (modalidades['imagenes'] as List<dynamic>? ?? [])
      .cast<String>();
  final titulo = anuncio['titulo'] ?? '';
  final descripcion = anuncio['descripcion'] ?? '';
  final categoria = anuncio['categoria'] ?? '';
  final estado = anuncio['estado_producto'] ?? '';

  String precio = 'Consultar';
  if (modalidades.containsKey('venta')) {
    final p = modalidades['venta']['precio'];
    precio = '\$${(p as num?)?.toStringAsFixed(2) ?? '0.00'}';
  } else if (modalidades.containsKey('alquiler')) {
    final alquiler = modalidades['alquiler'];
    if (alquiler is List && alquiler.isNotEmpty) {
      final costo = alquiler[0]['costo'];
      final unidad = alquiler[0]['unidad_tiempo'] ?? '';
      precio = '\$${(costo as num?)?.toStringAsFixed(2) ?? '0.00'}/$unidad';
    }
  } else if (modalidades.containsKey('trueque')) {
    precio = 'Trueque';
  }

  showDialog(
    context: context,
    builder: (context) {
      int imagenSeleccionada = 0;
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 40,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón cerrar
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F5F5),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 600;

                          final imageSection = Column(
                            children: [
                              // Imagen principal
                              Container(
                                height: 320,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: imagenes.isNotEmpty
                                      ? Image.network(
                                          imagenes[imagenSeleccionada],
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.image_not_supported,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                              // Miniaturas (solo si hay más de 1 imagen)
                              if (imagenes.length > 1) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 80,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imagenes.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (context, i) {
                                      return GestureDetector(
                                        onTap: () => setStateDialog(
                                          () => imagenSeleccionada = i,
                                        ),
                                        child: Container(
                                          width: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: imagenSeleccionada == i
                                                  ? UColors.orange
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              imagenes[i],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          );

                          final infoSection = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badges
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (categoria.isNotEmpty)
                                    _Badge(label: categoria),
                                  if (estado.isNotEmpty)
                                    _Badge(
                                      label:
                                          estado[0].toUpperCase() +
                                          estado.substring(1),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Título
                              Text(
                                titulo,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Precio
                              Text(
                                precio,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: UColors.greenDark,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Descripción
                              if (descripcion.isNotEmpty) ...[
                                const Text(
                                  'Descripción',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  descripcion,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Botón contactar
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (!_verificarAutenticacion(context)) return;

                                      final supabase = Supabase.instance.client;
                                      final compradorId = supabase.auth.currentUser!.id;
                                      final vendedorId = anuncio['vendedor_id']?.toString() ?? '';
                                      final anuncioId = anuncio['id']?.toString();

                                      if (vendedorId.isEmpty || vendedorId == compradorId) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('No puedes contactarte contigo mismo')),
                                        );
                                        return;
                                      }

                                      try {
                                        final existentes = await supabase
                                            .from('conversaciones')
                                            .select('id')
                                            .eq('comprador_id', compradorId)
                                            .eq('vendedor_id', vendedorId);

                                        String conversacionId;
                                        if (existentes.isNotEmpty) {
                                          conversacionId = existentes.first['id'];
                                        } else {
                                          final nueva = await supabase
                                              .from('conversaciones')
                                              .insert({
                                                'comprador_id': compradorId,
                                                'vendedor_id': vendedorId,
                                                'anuncio_id': anuncioId,
                                              })
                                              .select('id')
                                              .single();
                                          conversacionId = nueva['id'];
                                        }

                                        final vendedorData = await supabase
                                            .from('usuarios')
                                            .select('primer_nombre, primer_apellido')
                                            .eq('id', vendedorId)
                                            .maybeSingle();

                                        final nombreVendedor = vendedorData != null
                                            ? '${vendedorData['primer_nombre']} ${vendedorData['primer_apellido']}'
                                            : 'Vendedor';

                                        // Guardar el navigator antes de cerrar el dialog
                                        final nav = Navigator.of(context);
                                        nav.pop(); // cierra el dialog

                                       nav.push(
                                        MaterialPageRoute(
                                          builder: (_) => ChatListScreen(
                                            conversacionInicial: conversacionId,
                                            nombreInicial: nombreVendedor,
                                            otroUserIdInicial: vendedorId,
                                            anuncioIdInicial: anuncioId,
                                          ),
                                        ),
                                      );
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      }
                                    },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Contactar Vendedor'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: UColors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: imageSection),
                                const SizedBox(width: 32),
                                Expanded(flex: 4, child: infoSection),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                imageSection,
                                const SizedBox(height: 24),
                                infoSection,
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ------------------------------------------
// 5. Banners Promocionales
// ------------------------------------------
class _BannersPromocionales extends StatelessWidget {
  const _BannersPromocionales();

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
        color: UColors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¡Libera espacio y gana dinero!',
            style: TextStyle(
              color: UColors.white,
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
              backgroundColor: UColors.white,
              foregroundColor: UColors.orange,
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
        color: UColors.greenIcon.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: UColors.greenDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tratos Seguros',
            style: TextStyle(
              color: UColors.greenDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Encuentros exclusivos en puntos seguros dentro del campus universitario.',
            style: TextStyle(
              color: UColors.greenDark.withValues(alpha: 0.8),
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


// ------------------------------------------
// 8. Pie de Página (Footer)
// ------------------------------------------
class _PieDePagina extends StatelessWidget {
  const _PieDePagina();

  void _abrirEnlace(BuildContext context, String enlace) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo: $enlace'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: UColors.white,
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
                    color: UColors.greenDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '© 2024 U-NITE Campus Marketplace. Todos los derechos\nreservados.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
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
          color: UColors.textDark,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}