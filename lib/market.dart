import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'post_item.dart';
import 'login_page.dart';


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
          const SliverToBoxAdapter(child: BarraNavegacionSuperior()),
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

// Función auxiliar para verificar si el usuario está logueado
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

// ------------------------------------------
// 1. Barra de Navegación Superior
// ------------------------------------------
// ------------------------------------------
// 1. Barra de Navegación Superior (Integrada con Supabase)
// ------------------------------------------
class BarraNavegacionSuperior extends StatefulWidget {
  const BarraNavegacionSuperior({super.key});

  @override
  State<BarraNavegacionSuperior> createState() => _BarraNavegacionSuperiorState();
}

class _BarraNavegacionSuperiorState extends State<BarraNavegacionSuperior> {
  final supabase = Supabase.instance.client;
  String? nombreCompleto;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      // Hacemos el SELECT pidiendo primer_nombre y apellido
      // (OJO: verifica que tu columna en la BD se llame 'apellido' o 'primer_apellido')
      final response = await supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido')
          .eq('id', user.id)
          .single();

      final nombre = response['primer_nombre'] as String? ?? '';
      final apellido = response['primer_apellido'] as String? ?? '';

      setState(() {
        nombreCompleto = '$nombre $apellido'.trim();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar el nombre: $e');
      setState(() => isLoading = false);
    }
  }

  void _mostrarMensaje(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: UColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
      child: Row(
        children: [
          // Logo
          InkWell(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MarketPage()),
                (route) => false,
              );
            },
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school,
                    size: 40,
                    color: UColors.orange,
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
                color: UColors.footerBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: UColors.cardBorder),
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
          
          // Iconos de acción y Botón Vender
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  if (_verificarAutenticacion(context)) {
                    _mostrarMensaje(context, 'Abriendo Notificaciones');
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined),
                onPressed: () {
                  if (_verificarAutenticacion(context)) {
                    _mostrarMensaje(context, 'Abriendo Mensajes');
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  if (_verificarAutenticacion(context)) {
                    _mostrarMensaje(context, 'Abriendo Carrito');
                  }
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (_verificarAutenticacion(context)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PublicarArticuloPage()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: UColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Vender Artículo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),

              // ---------------------------------------------------
              // NUEVO BOTÓN DE PERFIL (AVATAR + NOMBRE + APELLIDO)
              // ---------------------------------------------------
              InkWell(
                onTap: () async {
                  if (_verificarAutenticacion(context)) {
                    // Navegamos de forma real a la pantalla de Perfil
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                    _cargarDatosUsuario(); // Volvemos a llamar a la función que pide los datos a Supabase
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: const NetworkImage(
                          'https://i.pravatar.cc/150?img=68', // Mantengo el placeholder de tu compañero
                        ),
                        onBackgroundImageError: (exception, stackTrace) {},
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      // Lógica para mostrar estado de carga o el Nombre y Apellido
                      isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: UColors.orange),
                            )
                          : Text(
                              nombreCompleto?.isNotEmpty == true
                                  ? nombreCompleto!
                                  : 'Mi Perfil', // Fallback por si el usuario no tiene nombre registrado
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              // ---------------------------------------------------
            ],
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
                          color: esSeleccionado ? Colors.white : UColors.textDark,
                          fontWeight:
                              esSeleccionado ? FontWeight.bold : FontWeight.w500,
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
// 3. Cuadrícula de Productos
// ------------------------------------------
class _CuadriculaProductos extends StatelessWidget {
  final String categoria;
  const _CuadriculaProductos({required this.categoria});

  @override
  Widget build(BuildContext context) {
    // Filtrado lógico
    final productosFiltrados =
        categoria == 'Todos'
            ? _productosPrueba
            : _productosPrueba.where((p) => p.categoria == categoria).toList();

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
      sliver:
          productosFiltrados.isEmpty
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final producto = productosFiltrados[index];
                  return _TarjetaProducto(producto: producto);
                }, childCount: productosFiltrados.length),
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
              builder: (context) => _PantallaDetalleProducto(producto: producto),
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
                      child: Image.network(
                        producto.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: UColors.textGray,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          );
                        },
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
            // Detalles
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
          const SliverToBoxAdapter(child: BarraNavegacionSuperior()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: 32,
              ),
              child:
                  isMobile
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
      // Lado Izquierdo: Galería de Imágenes
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
                children:
                    producto.imagenesAdicionales.take(3).map((url) {
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

      // Lado Derecho: Información del Producto
      Expanded(
        flex: isMobile ? 0 : 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges Categoría
            Wrap(
              spacing: 8,
              children:
                  producto.etiquetas.map((e) {
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
            // Título
            Text(
              producto.titulo,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: UColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            // Precio y Badge
            Row(
              children: [
                Text(
                  producto.precio,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: UColors.greenDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            // Vendedor Card
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
                          style: TextStyle(color: UColors.textGray, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                Icons.star,
                                size: 14,
                                color:
                                    i < producto.vendedor.estrellas.floor()
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
            // Descripción del Producto (Cajita del Vendedor)
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
                  // Puntos clave (opcional, para que se vea más pro)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: UColors.textGray),
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
            // Botones de Acción
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
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
