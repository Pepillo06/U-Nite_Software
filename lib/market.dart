import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'post_item.dart';
import 'login_page.dart';
import 'screens/chat/chat_list_screen.dart';
import 'widgets/unite_header.dart';
import 'urgencia_dialog.dart';

// ==========================================
// PANTALLA PRINCIPAL DEL MARKETPLACE
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
    return Scaffold(
      backgroundColor: UColors.footerBg,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: UniteHeader(currentIndex: 1)),
          SliverToBoxAdapter(
            child: _BarraSuperior(
              onVender: () {
                if (_verificarAutenticacion(context)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PublicarArticuloPage(),
                    ),
                  );
                }
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _FiltrosCategorias(
              categoriaActual: _categoriaSeleccionada,
              onChanged: _onCategoriaChanged,
            ),
          ),
          _CuadriculaProductos(categoria: _categoriaSeleccionada),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: const _BannersPromocionales(),
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
// FUNCIÓN AUXILIAR DE AUTENTICACIÓN
// ==========================================
bool _verificarAutenticacion(BuildContext context) {
  if (Supabase.instance.client.auth.currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes iniciar sesión para realizar esta acción'),
        backgroundColor: UColors.orange,
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
    return false;
  }
  return true;
}

// ==========================================
// MODELOS Y DATOS DE PRUEBA
// ==========================================
class _Producto {
  final String titulo;
  final String precio;
  final String ubicacion;
  final bool esNuevo;
  final String imagenUrl;
  final String categoria;
  final String descripcion;
  final List<String> etiquetas;
  final _Vendedor vendedor;
  final List<String> zonasEntrega;
  final List<String> imagenesAdicionales;

  _Producto({
    required this.titulo,
    required this.precio,
    required this.ubicacion,
    required this.esNuevo,
    required this.imagenUrl,
    required this.categoria,
    required this.descripcion,
    required this.etiquetas,
    required this.vendedor,
    required this.zonasEntrega,
    required this.imagenesAdicionales,
  });
}

class _Vendedor {
  final String nombre;
  final String facultad;
  final double estrellas;
  final int ventas;
  final String avatarUrl;
  final bool esVerificado;

  _Vendedor({
    required this.nombre,
    required this.facultad,
    required this.estrellas,
    required this.ventas,
    required this.avatarUrl,
    this.esVerificado = false,
  });
}

final List<_Producto> _productosPrueba = [
  _Producto(
    titulo: 'Cálculo de Stewart - 8va Edición (Como nuevo)',
    precio: '\$45.00',
    ubicacion: 'Biblioteca Pedro Grases',
    esNuevo: true,
    categoria: 'Libros',
    descripcion:
        'Libro esencial para los primeros semestres de ingeniería. Está en excelente estado, sin rayones ni hojas dobladas. Incluye el código de acceso a la plataforma digital (sin usar).',
    etiquetas: ['Ingeniería', 'Libros'],
    vendedor: _Vendedor(
      nombre: 'Carlos Ruiz',
      facultad: 'Facultad de Ingeniería',
      estrellas: 4.8,
      ventas: 48,
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      esVerificado: true,
    ),
    zonasEntrega: ['Entrada de la Biblioteca', 'Bancos del Samán'],
    imagenesAdicionales: [
      'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1589998059171-988d887df646?q=80&w=600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=600&auto=format&fit=crop',
    ],
    imagenUrl:
        'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop',
  ),
  _Producto(
    titulo: 'MacBook Air M1 2020 - 8GB RAM / 256GB SSD',
    precio: '\$750.00',
    ubicacion: 'Módulo de Ingeniería',
    esNuevo: false,
    categoria: 'Electrónica',
    descripcion:
        'Batería al 92% de salud. Estéticamente 10/10. Se entrega con cargador original y caja.',
    etiquetas: ['Apple', 'Computación'],
    vendedor: _Vendedor(
      nombre: 'Ana Martínez',
      facultad: 'Ciencias Económicas',
      estrellas: 5.0,
      ventas: 12,
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
    ),
    zonasEntrega: ['Piso 2, Módulo de Ingeniería', 'Cafetería El Samán'],
    imagenesAdicionales: [],
    imagenUrl:
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=600&auto=format&fit=crop',
  ),
  _Producto(
    titulo: 'Silla Ergonómica Pro para Escritorio',
    precio: '\$120.00',
    ubicacion: 'Residencias (Cerca UNIMET)',
    esNuevo: false,
    categoria: 'Muebles',
    descripcion:
        'Silla con soporte lumbar ajustable. Perfecta para largas jornadas de estudio.',
    etiquetas: ['Hogar', 'Estudio'],
    vendedor: _Vendedor(
      nombre: 'Luis Gómez',
      facultad: 'Arquitectura',
      estrellas: 4.5,
      ventas: 5,
      avatarUrl: 'https://i.pravatar.cc/150?img=8',
    ),
    zonasEntrega: ['Plaza del Rectorado', 'Parada de Autobuses'],
    imagenesAdicionales: [],
    imagenUrl:
        'https://images.unsplash.com/photo-1505843490538-5133c6c7d0e1?q=80&w=600&auto=format&fit=crop',
  ),
  _Producto(
    titulo: 'Habitación Amueblada Cerca del Campus',
    precio: '\$450.00/mes',
    ubicacion: 'Terrazas del Ávila',
    esNuevo: true,
    categoria: 'Alojamientos',
    descripcion:
        'Incluye servicios de agua, luz e internet. Ambiente tranquilo solo para estudiantes.',
    etiquetas: ['Renta', 'Vivienda'],
    vendedor: _Vendedor(
      nombre: 'Sra. Marta',
      facultad: 'Vecina del Sector',
      estrellas: 4.9,
      ventas: 2,
      avatarUrl: 'https://i.pravatar.cc/150?img=22',
    ),
    zonasEntrega: ['Visita previa cita en Vigilancia'],
    imagenesAdicionales: [],
    imagenUrl:
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=600&auto=format&fit=crop',
  ),
  _Producto(
    titulo: 'Audífonos Noise Cancelling Sony WH-1000XM4',
    precio: '\$180.00',
    ubicacion: 'Módulo de Derecho',
    esNuevo: true,
    categoria: 'Electrónica',
    descripcion:
        'Nuevos en caja sellada. La mejor cancelación de ruido del mercado.',
    etiquetas: ['Audio', 'Música'],
    vendedor: _Vendedor(
      nombre: 'Pedro Peña',
      facultad: 'Estudios Jurídicos',
      estrellas: 4.7,
      ventas: 31,
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
    ),
    zonasEntrega: ['Pasillos de Derecho', 'Modulo Central'],
    imagenesAdicionales: [],
    imagenUrl:
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=600&auto=format&fit=crop',
  ),
  _Producto(
    titulo: 'Introducción a la Psicología - Morris & Maisto',
    precio: '\$30.00',
    ubicacion: 'Edificio Eugenio Mendoza',
    esNuevo: false,
    categoria: 'Libros',
    descripcion: 'Poco uso, ideal para psicología general.',
    etiquetas: ['Psicología', 'Texto'],
    vendedor: _Vendedor(
      nombre: 'Elena Ruiz',
      facultad: 'Psicología',
      estrellas: 5.0,
      ventas: 8,
      avatarUrl: 'https://i.pravatar.cc/150?img=26',
    ),
    zonasEntrega: ['Auditorio Eugenio Mendoza', 'Bancos del Samán'],
    imagenesAdicionales: [],
    imagenUrl:
        'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?q=80&w=600&auto=format&fit=crop',
  ),
];

// ==========================================
// WIDGETS
// ==========================================

// ------------------------------------------
// BARRA SUPERIOR (búsqueda + vender)
// ------------------------------------------
class _BarraSuperior extends StatefulWidget {
  final VoidCallback onVender;
  const _BarraSuperior({required this.onVender});

  @override
  State<_BarraSuperior> createState() => _BarraSuperiorState();
}

class _BarraSuperiorState extends State<_BarraSuperior> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Barra de búsqueda
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE3BFB1)),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar libros, muebles, electrónica...',
                  hintStyle: GoogleFonts.lexend(
                    color: const Color(0xFF8F7065),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF8F7065),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Botón Vender Artículo
          ElevatedButton(
            onPressed: widget.onVender,
            style: ElevatedButton.styleFrom(
              backgroundColor: UColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isMobile ? 'Vender' : 'Vender Artículo',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------
// 2. Filtros de Categorías
// ------------------------------------------
class _FiltrosCategorias extends StatelessWidget {
  final String categoriaActual;
  final Function(String) onChanged;

  const _FiltrosCategorias({
    required this.categoriaActual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categorias = [
      {'nombre': 'Todos', 'icono': Icons.grid_view},
      {'nombre': 'Libros', 'icono': Icons.menu_book},
      {'nombre': 'Electrónica', 'icono': Icons.computer},
      {'nombre': 'Muebles', 'icono': Icons.chair_alt},
      {'nombre': 'Alojamientos', 'icono': Icons.home_outlined},
    ];

    return Container(
      color: UColors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(categorias.length, (index) {
            final nombre = categorias[index]['nombre'] as String;
            final esSeleccionado = categoriaActual == nombre;
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: InkWell(
                onTap: () => onChanged(nombre),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: esSeleccionado ? UColors.orange : UColors.footerBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        categorias[index]['icono'] as IconData,
                        size: 20,
                        color: esSeleccionado ? Colors.white : UColors.textGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        nombre,
                        style: TextStyle(
                          color: esSeleccionado
                              ? Colors.white
                              : UColors.textDark,
                          fontWeight: esSeleccionado
                              ? FontWeight.bold
                              : FontWeight.w500,
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

// ------------------------------------------
// 3. Cuadrícula de Productos (desde Supabase)
// ------------------------------------------
class _CuadriculaProductos extends StatefulWidget {
  final String categoria;
  const _CuadriculaProductos({required this.categoria});

  @override
  State<_CuadriculaProductos> createState() => _CuadriculaProductosState();
}

class _CuadriculaProductosState extends State<_CuadriculaProductos> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _anuncios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAnuncios();
  }

  @override
  void didUpdateWidget(_CuadriculaProductos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoria != widget.categoria) {
      _cargarAnuncios();
    }
  }

  Future<void> _cargarAnuncios() async {
    setState(() => _cargando = true);
    try {
      var query = _supabase
          .from('anuncios_marketplace')
          .select()
          .eq('disponible', true)
          .order('fecha_publicacion', ascending: false);

      final data = await query;
      List<Map<String, dynamic>> resultado = List<Map<String, dynamic>>.from(
        data,
      );

      // Filtrar por categoría en cliente (más simple que en query)
      if (widget.categoria != 'Todos') {
        resultado = resultado
            .where((a) => a['categoria'] == widget.categoria)
            .toList();
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
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(color: UColors.orange),
          ),
        ),
      );
    }

    double width = MediaQuery.of(context).size.width;
    int columnas = 4;
    if (width < 600)
      columnas = 1;
    else if (width < 900)
      columnas = 2;
    else if (width < 1200)
      columnas = 3;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      sliver: _anuncios.isEmpty
          ? SliverToBoxAdapter(
              child: Container(
                height: 300,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: UColors.textGray),
                    const SizedBox(height: 16),
                    Text(
                      'No hay productos en esta categoría',
                      style: TextStyle(color: UColors.textGray, fontSize: 18),
                    ),
                  ],
                ),
              ),
            )
          : SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _TarjetaAnuncio(anuncio: _anuncios[index]),
                childCount: _anuncios.length,
              ),
            ),
    );
  }
}

// ------------------------------------------
// 4. Tarjeta Individual de Producto
// ------------------------------------------
class _TarjetaProducto extends StatelessWidget {
  final _Producto producto;
  const _TarjetaProducto({required this.producto});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (_verificarAutenticacion(context)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  _PantallaDetalleProducto(producto: producto),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: UColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        producto.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: UColors.textGray,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: UColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        producto.esNuevo ? 'Nuevo' : 'Usado',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      producto.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      producto.precio,
                      style: const TextStyle(
                        color: UColors.greenDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            producto.ubicacion,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

// ------------------------------------------
// Tarjeta de Anuncio (datos desde Supabase)
// ------------------------------------------
class _TarjetaAnuncio extends StatelessWidget {
  final Map<String, dynamic> anuncio;
  const _TarjetaAnuncio({required this.anuncio});

  String _getPrecio() {
    final modalidades =
        anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
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
    if (modalidades.containsKey('trueque')) return 'Trueque';
    return 'Consultar';
  }

  String _getImagenUrl() {
    final modalidades =
        anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    final imagenes = modalidades['imagenes'] as List<dynamic>? ?? [];
    return imagenes.isNotEmpty ? imagenes[0].toString() : '';
  }

  bool _esNuevo() {
    final estado = (anuncio['estado_producto'] ?? '').toString().toLowerCase();
    return estado == 'nuevo';
  }

  String _getEstadoBadge() {
    final estado = (anuncio['estado_producto'] ?? '').toString();
    if (estado.isEmpty) return 'Usado';
    return estado[0].toUpperCase() + estado.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final imagenUrl = _getImagenUrl();
    final tieneImagen = imagenUrl.isNotEmpty;

    return InkWell(
      onTap: () {
        if (_verificarAutenticacion(context)) {
          _mostrarDetalleAnuncio(context, anuncio);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: UColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: tieneImagen
                          ? Image.network(
                              imagenUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFFF0F0F0),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                            )
                          : Container(
                              color: const Color(0xFFF0F0F0),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Badge de condición
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: UColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getEstadoBadge(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      anuncio['titulo'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getPrecio(),
                      style: const TextStyle(
                        color: UColors.greenDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            anuncio['categoria'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

// ------------------------------------------
// Popup de Detalle de Anuncio
// ------------------------------------------
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
                              // Botón contactar vendedor
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (!_verificarAutenticacion(context)) return;
                                    final urgencia = await mostrarDialogUrgencia(context);
                                    if (urgencia == null || !context.mounted) return;
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
                                      final esNueva = existentes.isEmpty;
                                      if (!esNueva) {
                                        conversacionId = existentes.first['id'];
                                        await supabase
                                            .from('conversaciones')
                                            .update({'anuncio_id': anuncioId})
                                            .eq('id', conversacionId);
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
                                      if (esNueva) {
                                        final compradorData = await supabase
                                            .from('usuarios')
                                            .select('primer_nombre, primer_apellido')
                                            .eq('id', compradorId)
                                            .maybeSingle();
                                        final nombreComprador = compradorData != null
                                            ? '${compradorData['primer_nombre']} ${compradorData['primer_apellido']}'
                                            : 'Un usuario';
                                        try {
                                          await supabase.from('notificaciones').insert({
                                            'usuario_id': vendedorId,
                                            'tipo': 'contacto',
                                            'titulo': 'Nuevo mensaje sobre tu producto',
                                            'mensaje': '$nombreComprador preguntó por "$titulo"',
                                            'leida': false,
                                            'datos': {
                                              'conversacion_id': conversacionId,
                                              'nombre_otro': nombreVendedor,
                                              'otro_user_id': compradorId,
                                              'anuncio_id': anuncioId,
                                            },
                                          });
                                        } catch (_) {}
                                      }
                                      final nav = Navigator.of(context);
                                      nav.pop();
                                      nav.push(MaterialPageRoute(
                                        builder: (_) => ChatListScreen(
                                          conversacionInicial: conversacionId,
                                          nombreInicial: nombreVendedor,
                                          otroUserIdInicial: vendedorId,
                                          anuncioIdInicial: anuncioId,
                                        ),
                                      ));
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
                              // Botón Proponer Trueque (solo si el producto acepta trueque)
                              if (modalidades.containsKey('trueque')) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _mostrarDialogTrueque(context, anuncio),
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                    label: const Text('Proponer Trueque'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF245000),
                                      side: const BorderSide(color: Color(0xFF245000), width: 2),
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

void _mostrarDialogTrueque(BuildContext context, Map<String, dynamic> anuncio) {
  final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
  final descripcionTrueque = modalidades['trueque']?['descripcion']?.toString() ?? '';
  final titulo = anuncio['titulo'] ?? '';
  final ofertaController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: Color(0xFF245000)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Proponer Trueque',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (descripcionTrueque.isNotEmpty) ...[
            Text(
              'El vendedor busca:',
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5B4137),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE3BFB1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: Color(0xFFF36900), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      descripcionTrueque,
                      style: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '¿Qué ofreces a cambio de "$titulo"?',
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ofertaController,
            maxLines: 3,
            style: GoogleFonts.lexend(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ej: Tengo una calculadora científica...',
              hintStyle: GoogleFonts.lexend(color: const Color(0xFF8F7065), fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3BFB1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF245000), width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.lexend(color: const Color(0xFF5B4137))),
        ),
        ElevatedButton(
          onPressed: () async {
            final oferta = ofertaController.text.trim();
            if (oferta.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Describe qué ofreces a cambio', style: GoogleFonts.lexend()),
                  backgroundColor: const Color(0xFFF36900),
                ),
              );
              return;
            }
            Navigator.pop(context);
            await _enviarSolicitudTrueque(context, anuncio, oferta);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF245000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Enviar Propuesta', style: GoogleFonts.lexend(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

Future<void> _enviarSolicitudTrueque(
  BuildContext context,
  Map<String, dynamic> anuncio,
  String objetoOfrecido,
) async {
  final supabase = Supabase.instance.client;
  final compradorId = supabase.auth.currentUser?.id;
  if (compradorId == null) return;

  final vendedorId = anuncio['vendedor_id']?.toString() ?? '';
  final anuncioId = anuncio['id']?.toString();
  final titulo = anuncio['titulo'] ?? '';

  if (vendedorId.isEmpty || vendedorId == compradorId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No puedes proponer trueque contigo mismo')),
    );
    return;
  }

  try {
    final existente = await supabase
        .from('solicitudes_trueque')
        .select('id')
        .eq('anuncio_id', anuncioId!)
        .eq('solicitante_id', compradorId)
        .eq('estado', 'pendiente');

    if (existente.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya tienes una propuesta pendiente para este producto', style: GoogleFonts.lexend()),
            backgroundColor: const Color(0xFFF36900),
          ),
        );
      }
      return;
    }

    await supabase.from('solicitudes_trueque').insert({
      'anuncio_id': anuncioId,
      'solicitante_id': compradorId,
      'receptor_id': vendedorId,
      'objeto_ofrecido': objetoOfrecido,
      'estado': 'pendiente',
    });

    final compradorData = await supabase
        .from('usuarios')
        .select('primer_nombre, primer_apellido')
        .eq('id', compradorId)
        .maybeSingle();
    final nombreComprador = compradorData != null
        ? '${compradorData['primer_nombre']} ${compradorData['primer_apellido']}'
        : 'Un usuario';

    await supabase.from('notificaciones').insert({
      'usuario_id': vendedorId,
      'tipo': 'trueque',
      'titulo': 'Nueva propuesta de trueque',
      'mensaje': '$nombreComprador ofrece "$objetoOfrecido" por "$titulo"',
      'leida': false,
      'datos': {
        'anuncio_id': anuncioId,
        'solicitante_id': compradorId,
        'nombre_otro': nombreComprador,
      },
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Propuesta enviada! El vendedor te responderá pronto.', style: GoogleFonts.lexend()),
          backgroundColor: const Color(0xFF245000),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
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
// 7. Pantalla de Detalle de Producto
// ------------------------------------------
class _PantallaDetalleProducto extends StatelessWidget {
  final _Producto producto;
  const _PantallaDetalleProducto({required this.producto});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: UColors.white,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: UniteHeader(currentIndex: 1)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: 32,
              ),
              child: isMobile
                  ? Column(children: _buildContent(context, true))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildContent(context, false),
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: _PieDePagina()),
        ],
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, bool isMobile) {
    return [
      Expanded(
        flex: isMobile ? 0 : 6,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  producto.imagenUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (producto.imagenesAdicionales.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: producto.imagenesAdicionales.take(3).map((url) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      if (!isMobile) const SizedBox(width: 48),
      if (isMobile) const SizedBox(height: 32),
      Expanded(
        flex: isMobile ? 0 : 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: producto.etiquetas.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: UColors.footerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e,
                    style: TextStyle(
                      color: UColors.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              producto.titulo,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: UColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              producto.precio,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: UColors.greenDark,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UColors.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(producto.vendedor.avatarUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              producto.vendedor.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (producto.vendedor.esVerificado) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: UColors.blueIcon,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          producto.vendedor.facultad,
                          style: TextStyle(
                            color: UColors.textGray,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                Icons.star,
                                size: 14,
                                color: i < producto.vendedor.estrellas.floor()
                                    ? UColors.orange
                                    : UColors.cardBorder,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              '(${producto.vendedor.ventas} ventas)',
                              style: TextStyle(
                                color: UColors.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descripción del Producto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    producto.descripcion,
                    style: TextStyle(
                      color: UColors.textDark,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: UColors.textGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Entrega en: ${producto.ubicacion}',
                        style: TextStyle(color: UColors.textGray, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!_verificarAutenticacion(context)) return;
                  final urgencia = await mostrarDialogUrgencia(context);
                  if (urgencia == null || !context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatListScreen()),
                  );
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border),
                label: const Text('Apartar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: UColors.greenDark,
                  side: const BorderSide(color: UColors.greenDark, width: 2),
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
        ),
      ),
    ];
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