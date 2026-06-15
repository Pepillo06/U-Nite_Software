import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_item.dart';
import 'login_page.dart';
import 'widgets/unite_header.dart';
import 'market_widgets/detalle_anuncio_dialog.dart';

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
  String _busquedaActual = '';
  bool _esVendedor = false;

// ====== NUEVAS VARIABLES PARA LOS FILTROS ======
  bool _mostrarFiltros = false;
  double? _precioMinimo; // <-- Cambiado de double? a dos variables distintas
  double? _precioMaximo; // <-- Nueva variable para el mínimo
  List<String> _estadosSeleccionados = []; 
  List<String> _tiposVentaSeleccionados = []; 

  // NUEVAS VARIABLES ELEVADAS PARA LOS LÍMITES TOTALES
  double _minPrecioGlobal = 0;
  double _maxPrecioGlobal = 1000;

  @override
  void initState() {
    super.initState();
    _verificarRolVendedor(); // Llama a la verificación al iniciar
  }

  void _actualizarLimitesPrecio(double min, double max) {
    setState(() {
      _minPrecioGlobal = min;
      _maxPrecioGlobal = max;
    });
  }
  void _onCategoriaChanged(String categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
    });
  }

  void _onBusquedaChanged(String texto) {
    setState(() {
      _busquedaActual = texto;
    });
  }
  Future<void> _verificarRolVendedor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('usuarios')
          .select('es_vendedor')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _esVendedor = data['es_vendedor'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error verificando rol en MarketPage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UColors.footerBg,
      body: Column(
        children: [
          const UniteHeader(currentIndex: 1),
          _BarraSuperior(
            onBusquedaChanged: _onBusquedaChanged,
            mostrarBotonVender: _esVendedor,
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
          _FiltrosCategorias(
            categoriaActual: _categoriaSeleccionada,
            onChanged: _onCategoriaChanged,
            filtrosVisibles: _mostrarFiltros,
            onToggleFiltros: () {
              setState(() {
                _mostrarFiltros = !_mostrarFiltros;
              });
            },
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel de filtros lateral izquierdo
// Panel de filtros lateral izquierdo
                if (_mostrarFiltros)
                  _PanelFiltrosLateral(
                    precioMinimo: _precioMinimo, // <-- Añadido
                    precioMaximo: _precioMaximo,
                    estadosSeleccionados: _estadosSeleccionados,
                    tiposVentaSeleccionados: _tiposVentaSeleccionados,
                    onPrecioMinimoChanged: (val) => setState(() => _precioMinimo = val), // <-- Añadido
                    onPrecioMaximoChanged: (val) => setState(() => _precioMaximo = val), // <-- Añadido
                    onEstadosChanged: (lista) => setState(() => _estadosSeleccionados = lista),
                    onTiposVentaChanged: (lista) => setState(() => _tiposVentaSeleccionados = lista),
                    onLimpiarFiltros: () => setState(() {
                      _precioMinimo = null; // <-- Limpiar ambos
                      _precioMaximo = null; // <-- Limpiar ambos
                      _estadosSeleccionados = [];
                      _tiposVentaSeleccionados = [];
                    }),
                    minPrecio: _minPrecioGlobal,
                    maxPrecio: _maxPrecioGlobal,
                  ),
                // Contenido principal de productos
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      _CuadriculaProductos(
                        categoria: _categoriaSeleccionada,
                        busqueda: _busquedaActual, 
                        precioMinimo: _precioMinimo, // <-- Añadido
                        precioMaximo: _precioMaximo,
                        estadosSeleccionados: _estadosSeleccionados,
                        tiposVentaSeleccionados: _tiposVentaSeleccionados,
                        onLimpiarCalculados: _actualizarLimitesPrecio,
                      ),
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
                ),
              ],
            ),
          ),
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
// WIDGETS
// ==========================================

// ------------------------------------------
// BARRA SUPERIOR (búsqueda + vender)
// ------------------------------------------
class _BarraSuperior extends StatefulWidget {
  final VoidCallback onVender;
  final ValueChanged<String> onBusquedaChanged; // <-- Nuevo parámetro
  final bool mostrarBotonVender;

  const _BarraSuperior({
    required this.onVender,
    required this.onBusquedaChanged, // <-- Requerido
    required this.mostrarBotonVender,
  });

  @override
  State<_BarraSuperior> createState() => _BarraSuperiorState();
}

class _BarraSuperiorState extends State<_BarraSuperior> {
  final _searchController = TextEditingController();
  Timer? _debounce; // <-- Nuevo: Temporizador para controlar el tiempo de espera

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // <-- Nuevo: Cancelamos el timer si el widget se destruye
    super.dispose();
  }

  // Nuevo método para manejar la escritura con debounce
  void _onTextoCambiado(String texto) {
    // Si el usuario sigue escribiendo, cancelamos el temporizador anterior
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Creamos un nuevo temporizador de 300 milisegundos
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Este bloque se ejecutará SOLO cuando el usuario deje de escribir por 300ms
      widget.onBusquedaChanged(texto);
    });

    // Forzamos un setState local únicamente para mostrar/ocultar el botón 'X' de limpiar
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    const double alturaComponentes = 44.0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 12,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? 240 : 700, 
              ),
              child: Container(
                height: alturaComponentes,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3F3),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE3BFB1)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.lexend(fontSize: 14),
                  // Cambiamos 'onSubmitted' por 'onChanged' asignando nuestra nueva función
                  onChanged: _onTextoCambiado, 
                  decoration: InputDecoration(
                    hintText: 'Buscar libros, muebles...',
                    hintStyle: GoogleFonts.lexend(
                      color: const Color(0xFF8F7065),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF8F7065),
                      size: 20,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Color(0xFF8F7065)),
                            onPressed: () {
                              _searchController.clear();
                              _debounce?.cancel(); // Cancelamos cualquier búsqueda pendiente
                              widget.onBusquedaChanged(''); // Limpia la cuadrícula inmediatamente
                              setState(() {}); 
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: UColors.orange),
                          tooltip: 'Buscar ya',
                          onPressed: () {
                            _debounce?.cancel(); // Cancelamos el timer si decide presionar el botón directamente
                            widget.onBusquedaChanged(_searchController.text);
                          },
                        ),
                        const SizedBox(width: 6), 
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: widget.mostrarBotonVender
              ? SizedBox(
                height: alturaComponentes,
                child: ElevatedButton.icon(
                  onPressed: widget.onVender,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    isMobile ? 'Vender' : 'Vender Artículo',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              )
              : const SizedBox.shrink(),
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
  final bool filtrosVisibles;
  final VoidCallback onToggleFiltros;

  const _FiltrosCategorias({
    required this.categoriaActual,
    required this.onChanged,
    required this.filtrosVisibles,
    required this.onToggleFiltros,
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

    return Container(
      color: UColors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // BOTÓN DE FILTROS CON ANIMACIÓN HOVER
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _BotonFiltroAnimado(
                activo: filtrosVisibles,
                onTap: onToggleFiltros,
                icono: Icons.tune_rounded,
                label: 'Filtros',
                colorActivo: UColors.orange,
                colorInactivo: const Color(0xFFF5F3F3),
                borderColorInactivo: const Color(0xFFE3BFB1),
              ),
            ),
            // CATEGORÍAS ORIGINALES CON ANIMACIÓN HOVER
            ...List.generate(categorias.length, (index) {
              final nombre = categorias[index]['nombre'] as String;
              final esSeleccionado = categoriaActual == nombre;
              final esBotonTodos = index == 0;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _BotonCategoriaAnimado(
                  nombre: nombre,
                  icono: categorias[index]['icono'] as IconData,
                  esSeleccionado: esSeleccionado,
                  esBotonTodos: esBotonTodos,
                  onTap: () => onChanged(nombre),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------
// BOTÓN "FILTROS" CON ANIMACIÓN HOVER
// ------------------------------------------
class _BotonFiltroAnimado extends StatefulWidget {
  final bool activo;
  final VoidCallback onTap;
  final IconData icono;
  final String label;
  final Color colorActivo;
  final Color colorInactivo;
  final Color borderColorInactivo;

  const _BotonFiltroAnimado({
    required this.activo,
    required this.onTap,
    required this.icono,
    required this.label,
    required this.colorActivo,
    required this.colorInactivo,
    required this.borderColorInactivo,
  });

  @override
  State<_BotonFiltroAnimado> createState() => _BotonFiltroAnimadoState();
}

class _BotonFiltroAnimadoState extends State<_BotonFiltroAnimado>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _elevationAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _elevationAnim = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _hovering = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esActivo = widget.activo;
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: esActivo
                      ? UColors.orange
                      : (_hovering
                          ? UColors.orange.withOpacity(0.12)
                          : widget.colorInactivo),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: esActivo
                        ? UColors.orange
                        : (_hovering ? UColors.orange : widget.borderColorInactivo),
                    width: _hovering && !esActivo ? 1.5 : 1,
                  ),
                  boxShadow: _hovering
                      ? [
                          BoxShadow(
                            color: UColors.orange.withOpacity(0.25),
                            blurRadius: _elevationAnim.value * 2,
                            offset: Offset(0, _elevationAnim.value / 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _hovering ? 0.05 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.icono,
                        size: 20,
                        color: esActivo ? Colors.white : UColors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: esActivo ? Colors.white : UColors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------
// BOTÓN DE CATEGORÍA CON ANIMACIÓN HOVER
// ------------------------------------------
class _BotonCategoriaAnimado extends StatefulWidget {
  final String nombre;
  final IconData icono;
  final bool esSeleccionado;
  final bool esBotonTodos;
  final VoidCallback onTap;

  const _BotonCategoriaAnimado({
    required this.nombre,
    required this.icono,
    required this.esSeleccionado,
    required this.esBotonTodos,
    required this.onTap,
  });

  @override
  State<_BotonCategoriaAnimado> createState() => _BotonCategoriaAnimadoState();
}

class _BotonCategoriaAnimadoState extends State<_BotonCategoriaAnimado>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _iconSlideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _iconSlideAnim = Tween<double>(begin: 0.0, end: -2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _hovering = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esSeleccionado = widget.esSeleccionado;
    final esBotonTodos = widget.esBotonTodos;

    Color colorFondo;
    if (esSeleccionado) {
      colorFondo = UColors.orange;
    } else if (_hovering) {
      colorFondo = UColors.orange.withOpacity(0.10);
    } else if (esBotonTodos) {
      colorFondo = const Color.fromARGB(255, 221, 220, 220);
    } else {
      colorFondo = UColors.footerBg;
    }

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: colorFondo,
                  borderRadius: BorderRadius.circular(24),
                  border: _hovering && !esSeleccionado
                      ? Border.all(color: UColors.orange.withOpacity(0.5), width: 1.5)
                      : null,
                  boxShadow: _hovering
                      ? [
                          BoxShadow(
                            color: UColors.orange.withOpacity(esSeleccionado ? 0.35 : 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Transform.translate(
                      offset: Offset(0, _iconSlideAnim.value),
                      child: Icon(
                        widget.icono,
                        size: 20,
                        color: esSeleccionado
                            ? Colors.white
                            : (_hovering ? UColors.orange : UColors.textGray),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.nombre,
                      style: TextStyle(
                        color: esSeleccionado
                            ? Colors.white
                            : (_hovering ? UColors.orange : UColors.textDark),
                        fontWeight: esSeleccionado || esBotonTodos
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
  final String busqueda;
  final double? precioMinimo; // <-- Añadido
  final double? precioMaximo;
  final List<String> estadosSeleccionados;
  final List<String> tiposVentaSeleccionados;
  final Function(double min, double max) onLimpiarCalculados;

  const _CuadriculaProductos({
    super.key,
    required this.categoria,
    required this.busqueda,
    this.precioMinimo, // <-- Añadido
    this.precioMaximo,
    required this.estadosSeleccionados,
    required this.tiposVentaSeleccionados,
    required this.onLimpiarCalculados,
  });

  @override
  State<_CuadriculaProductos> createState() => _CuadriculaProductosState();
}

class _CuadriculaProductosState extends State<_CuadriculaProductos> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _anuncios = [];
  bool _cargando = true;
  bool _esVendedor = false;

  // NUEVAS VARIABLES PARA LOS LÍMITES REALES DE PRECIO
  double _precioMinimoGlobal = 0;
  double _precioMaximoGlobal = 1000;

  @override
  void initState() {
    super.initState();
    _cargarAnuncios();
    _verificarRolVendedor();
  }

  @override
  void didUpdateWidget(_CuadriculaProductos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoria != widget.categoria || 
        oldWidget.busqueda != widget.busqueda ||
        oldWidget.precioMinimo != widget.precioMinimo || //_Añadido
        oldWidget.precioMaximo != widget.precioMaximo ||
        oldWidget.estadosSeleccionados != widget.estadosSeleccionados ||
        oldWidget.tiposVentaSeleccionados != widget.tiposVentaSeleccionados) {
      _cargarAnuncios();
    }
  }

  Future<void> _verificarRolVendedor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Reemplaza 'es_vendedor' por el nombre real de tu columna en Supabase
      final data = await Supabase.instance.client
          .from('usuarios')
          .select('es_vendedor')
          .eq('id', user.id)
          .single();

      setState(() {
        _esVendedor = data['es_vendedor'] ?? false;
      });
    } catch (e) {
      debugPrint('Error verificando rol: $e');
    }
  }

  Future<void> _cargarAnuncios() async {
    setState(() => _cargando = true);
    try {
      // CÓDIGO NUEVO UTILIZANDO RPC (Insensible a acentos y mayúsculas)
      final String queryTexto = widget.busqueda.trim();
      dynamic baseQuery;

      if (queryTexto.isNotEmpty) {
        // Llamamos a la función RPC que creamos en Supabase
        baseQuery = _supabase.rpc(
          'buscar_anuncios_unaccent', 
          params: {'search_term': queryTexto}
        );
      } else {
        // Si no hay texto de búsqueda, usamos la consulta normal que ya tenías
        baseQuery = _supabase
            .from('anuncios_marketplace')
            .select()
            .eq('disponible', true);
      }

      // Nota: Las funciones RPC retornan conjuntos de datos, asegúrate de aplicar el ordenamiento
      final data = await baseQuery.order('fecha_publicacion', ascending: false);
      List<Map<String, dynamic>> resultado = List<Map<String, dynamic>>.from(data);

      // FUNCIÓN INTERNA AUXILIAR PARA EXTRAER EL PRECIO CORRECTO DEL JSON
      double? obtenerPrecioAnuncio(Map<String, dynamic> anuncio) {
        final mod = anuncio['detalles_modalidades'];
        if (mod == null) return null;
        if (mod['venta'] != null && mod['venta']['precio'] != null) {
          return double.tryParse(mod['venta']['precio'].toString());
        }
        if (mod['alquiler'] != null && mod['alquiler'] is List && (mod['alquiler'] as List).isNotEmpty) {
          final primerAlquiler = (mod['alquiler'] as List)[0];
          if (primerAlquiler != null && primerAlquiler['costo'] != null) {
            return double.tryParse(primerAlquiler['costo'].toString());
          }
        }
        return null;
      }

      // === NUEVO: CÁLCULO DINÁMICO DE LÍMITES BASADO EN LOS ANUNCIOS TOTALES ===
      if (resultado.isNotEmpty) {
        List<double> preciosValidos = resultado
            .map((a) => obtenerPrecioAnuncio(a))
            .whereType<double>()
            .toList();

        // Busca esta sección dentro de su método _cargarAnuncios
        if (preciosValidos.isNotEmpty) {
          _precioMinimoGlobal = preciosValidos.reduce((a, b) => a < b ? a : b);
          _precioMaximoGlobal = preciosValidos.reduce((a, b) => a > b ? a : b);
          
          if (_precioMinimoGlobal == _precioMaximoGlobal) {
            _precioMaximoGlobal += 1;
          }

          // NUEVO: Notificar al widget padre inmediatamente
          widget.onLimpiarCalculados(_precioMinimoGlobal, _precioMaximoGlobal);
        }
      }

      // 1. Filtrar por categoría
      if (widget.categoria != 'Todos') {
        resultado = resultado.where((a) => a['categoria'] == widget.categoria).toList();
      }

// 2. Filtrar por rango de precio (Mínimo y Máximo)
      if (widget.precioMinimo != null || widget.precioMaximo != null) {
        resultado = resultado.where((a) {
          final precio = obtenerPrecioAnuncio(a);
          if (precio == null) return false;
          
          bool cumpleMin = widget.precioMinimo == null || precio >= widget.precioMinimo!;
          bool cumpleMax = widget.precioMaximo == null || precio <= widget.precioMaximo!;
          
          return cumpleMin && cumpleMax;
        }).toList();
      }

      // 3. Filtrar por Condición / Uso
      if (widget.estadosSeleccionados.isNotEmpty) {
        resultado = resultado.where((a) {
          final estadoDb = a['estado_producto']?.toString() ?? '';
          return widget.estadosSeleccionados.any((estUi) {
            if (estUi == 'Nuevo' && estadoDb == 'Nuevo') return true;
            if (estUi == 'Como nuevo' && estadoDb == 'Como nuevo') return true;
            if (estUi == 'Bueno' && estadoDb == 'Bueno') return true;
            if (estUi == 'Regular' && estadoDb == 'Regular') return true;
            return false;
          });
        }).toList();
      }

      // 4. Filtrar por Tipo de Venta
      if (widget.tiposVentaSeleccionados.isNotEmpty) {
        resultado = resultado.where((a) {
          final mod = a['detalles_modalidades'];
          if (mod == null) return false;
          return widget.tiposVentaSeleccionados.any((tipo) {
            if (tipo == 'Venta' && mod['venta'] != null) return true;
            if (tipo == 'Alquiler' && mod['alquiler'] != null) return true;
            if (tipo == 'Trueque' && mod['trueque'] != null) return true;
            return false;
          });
        }).toList();
      }

      // 5. ORDENAR: Los anuncios de usuarios PREMIUM aparecen primero
      try {
        final vendedorIds = resultado
            .map((a) => a['vendedor_id']?.toString())
            .whereType<String>()
            .toSet()
            .toList();

        if (vendedorIds.isNotEmpty) {
          final usuariosData = await _supabase
              .from('usuarios')
              .select('id, es_premium')
              .inFilter('id', vendedorIds);

          final Set<String> vendedoresPremium = {};
          for (final u in usuariosData) {
            if (u['es_premium'] == true) {
              vendedoresPremium.add(u['id'].toString());
            }
          }

          if (vendedoresPremium.isNotEmpty) {
            final List<Map<String, dynamic>> anunciosPremium = [];
            final List<Map<String, dynamic>> anunciosNormales = [];

            for (final anuncio in resultado) {
              final vendedorId = anuncio['vendedor_id']?.toString();
              if (vendedorId != null && vendedoresPremium.contains(vendedorId)) {
                anunciosPremium.add(anuncio);
              } else {
                anunciosNormales.add(anuncio);
              }
            }

            // Se mantiene el orden por fecha dentro de cada grupo (premium / no premium)
            resultado = [...anunciosPremium, ...anunciosNormales];
          }
        }
      } catch (e) {
        debugPrint('Error al ordenar anuncios premium: $e');
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
          child: Center(child: CircularProgressIndicator(color: UColors.orange)),
        ),
      );
    }

    double width = MediaQuery.of(context).size.width;
    int columnas = 4;
    if (width < 600) columnas = 1;
    else if (width < 900) columnas = 2;
    else if (width < 1200) columnas = 3;

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
                      'No hay productos que coincidan con los filtros seleccionados',
                      style: TextStyle(color: UColors.textGray, fontSize: 17),
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
// Tarjeta de Anuncio (datos desde Supabase)
// ------------------------------------------
class _TarjetaAnuncio extends StatelessWidget {
  final Map<String, dynamic> anuncio;
  const _TarjetaAnuncio({required this.anuncio});

  // --- 1. FUNCIONES AUXILIARES (Deben estar dentro de la clase) ---
  
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

  // AQUÍ ESTÁ LA FUNCIÓN QUE TE MARCABA ERROR
  String _getEstadoBadge() {
    final estado = (anuncio['estado_producto'] ?? '').toString();
    if (estado.isEmpty) return 'Usado';
    return estado[0].toUpperCase() + estado.substring(1);
  }

  // Abreviaturas para nombres largos de universidades
  String _abreviarUniversidad(String nombre) {
    const abreviaturas = {
      'Universidad Metropolitana': 'UNIMET',
      'Universidad Católica Andrés Bello': 'UCAB',
      'Universidad Santa María': 'USM',
      'Universidad Central de Venezuela': 'UCV',
      'Universidad Monteávila': 'UMA',
      'Universidad Simón Bolívar': 'USB',
    };
    return abreviaturas[nombre] ?? nombre;
  }

  String _getCampus() {
    final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    final campus = modalidades['campus_pickup'];
    if (campus == null || campus is bool || campus is! List) return '';
    final lista = (campus as List).whereType<String>().toList();
    if (lista.isEmpty) return '';
    return lista.map(_abreviarUniversidad).join(' · ');
  }

  // --- 2. MÉTODO BUILD (La interfaz visual) ---

  @override
  Widget build(BuildContext context) {
    final imagenUrl = _getImagenUrl();
    final tieneImagen = imagenUrl.isNotEmpty;

    return InkWell(
      onTap: () {
        if (_verificarAutenticacion(context)) {
          showDialog(
            context: context,
            builder: (context) => DetalleAnuncioDialog(anuncio: anuncio),
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
            // IMAGEN Y BADGE
            Expanded(
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
                  // EL BADGE DE "NUEVO/USADO"
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8622A), Color(0xFFC8440E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFE8622A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getEstadoBadge(), // Se llama a la función aquí
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // TEXTOS CON MAXLINES: 1
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anuncio['titulo'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17, 
                    ),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                  ),
                  const SizedBox(height: 6), 
                  Text(
                    _getPrecio(),
                    style: const TextStyle(
                      color: UColors.greenDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, 
                    ),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: UColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getCampus().isNotEmpty ? _getCampus() : (anuncio['categoria'] ?? ''),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
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

// ==========================================
// WIDGET BARRA LATERAL DE FILTROS DE BÚSQUEDA
// ==========================================
class _PanelFiltrosLateral extends StatefulWidget {
  final double? precioMinimo;
  final double? precioMaximo;
  final List<String> estadosSeleccionados;
  final List<String> tiposVentaSeleccionados;
  final ValueChanged<double?> onPrecioMinimoChanged;
  final ValueChanged<double?> onPrecioMaximoChanged;
  final ValueChanged<List<String>> onEstadosChanged;
  final ValueChanged<List<String>> onTiposVentaChanged;
  final VoidCallback onLimpiarFiltros;
  final double minPrecio;
  final double maxPrecio;

  const _PanelFiltrosLateral({
    required this.precioMinimo,
    required this.precioMaximo,
    required this.estadosSeleccionados,
    required this.tiposVentaSeleccionados,
    required this.onPrecioMinimoChanged,
    required this.onPrecioMaximoChanged,
    required this.onEstadosChanged,
    required this.onTiposVentaChanged,
    required this.onLimpiarFiltros,
    required this.minPrecio,
    required this.maxPrecio,
  });

  @override
  State<_PanelFiltrosLateral> createState() => _PanelFiltrosLateralState();
}

class _PanelFiltrosLateralState extends State<_PanelFiltrosLateral> {
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.precioMinimo?.round().toString() ?? '');
    _maxController = TextEditingController(text: widget.precioMaximo?.round().toString() ?? '');
  }

  @override
  void didUpdateWidget(_PanelFiltrosLateral oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincroniza los campos de texto si los filtros se limpian externamente
    if (widget.precioMinimo == null && _minController.text.isNotEmpty) {
      _minController.clear();
    }
    if (widget.precioMaximo == null && _maxController.text.isNotEmpty) {
      _maxController.clear();
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opcionesEstado = ['Nuevo', 'Como nuevo', 'Bueno', 'Regular'];
    final opcionesTipo = ['Venta', 'Alquiler', 'Trueque'];

    double valorSliderActual = widget.precioMaximo ?? widget.maxPrecio;
    if (valorSliderActual < widget.minPrecio) valorSliderActual = widget.minPrecio;
    if (valorSliderActual > widget.maxPrecio) valorSliderActual = widget.maxPrecio;

    return Container(
      width: 290,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: UColors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE3BFB1), width: 1),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: UColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: widget.onLimpiarFiltros,
                  child: Text(
                    'Limpiar todo',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: UColors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFFE3BFB1)),
            
            // --- FILTRO: PRECIO SLIDER ---
            Text(
              'Rango de Precio',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8F7065),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hasta \$${valorSliderActual.round()} USD',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: UColors.textDark,
              ),
            ),
            Slider(
              value: valorSliderActual,
              min: widget.minPrecio,
              max: widget.maxPrecio,
              divisions: 20,
              activeColor: UColors.orange,
              inactiveColor: const Color(0xFFF5F3F3),
              onChanged: (val) {
                _maxController.text = val.round().toString();
                if (val >= widget.maxPrecio) {
                  widget.onPrecioMaximoChanged(null); 
                } else {
                  widget.onPrecioMaximoChanged(val);
                }
              },
            ),
            const SizedBox(height: 10),

            // --- NUEVOS CAMPOS DE TEXTO MANUALES ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Mínimo',
                      prefixText: '\$ ',
                      labelStyle: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF8F7065)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: UColors.orange),
                      ),
                    ),
                    onChanged: (val) {
                      final precio = double.tryParse(val);
                      widget.onPrecioMinimoChanged(precio);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Máximo',
                      prefixText: '\$ ',
                      labelStyle: GoogleFonts.lexend(fontSize: 12, color: const Color(0xFF8F7065)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: UColors.orange),
                      ),
                    ),
                    onChanged: (val) {
                      final precio = double.tryParse(val);
                      widget.onPrecioMaximoChanged(precio);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- FILTRO: TIPO DE VENTA ---
            Text(
              'Tipo de Venta',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8F7065),
              ),
            ),
            const SizedBox(height: 8),
            ...opcionesTipo.map((tipo) {
              final esSeleccionado = widget.tiposVentaSeleccionados.contains(tipo);
              return CheckboxListTile(
                value: esSeleccionado,
                title: Text(
                  tipo,
                  style: const TextStyle(fontSize: 14, color: UColors.textDark, fontWeight: FontWeight.w500),
                ),
                activeColor: UColors.orange,
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? checked) {
                  final nuevaLista = List<String>.from(widget.tiposVentaSeleccionados);
                  if (checked == true) {
                    nuevaLista.add(tipo);
                  } else {
                    nuevaLista.remove(tipo);
                  }
                  widget.onTiposVentaChanged(nuevaLista);
                },
              );
            }),
            const SizedBox(height: 24),

            // --- FILTRO: USO / CONDICIÓN ---
            Text(
              'Uso / Condición',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8F7065),
              ),
            ),
            const SizedBox(height: 8),
            ...opcionesEstado.map((estado) {
              final esSeleccionado = widget.estadosSeleccionados.contains(estado);
              return CheckboxListTile(
                value: esSeleccionado,
                title: Text(
                  estado,
                  style: const TextStyle(fontSize: 14, color: UColors.textDark, fontWeight: FontWeight.w500),
                ),
                activeColor: UColors.orange,
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? checked) {
                  final nuevaLista = List<String>.from(widget.estadosSeleccionados);
                  if (checked == true) {
                    nuevaLista.add(estado);
                  } else {
                    nuevaLista.remove(estado);
                  }
                  widget.onEstadosChanged(nuevaLista);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}