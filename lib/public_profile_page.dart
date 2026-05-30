import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'market_widgets/detalle_anuncio_dialog.dart'; // Ajusta la ruta si es necesario

// ============================================================
// PÁGINA DE PERFIL PÚBLICO (ver perfil de otro usuario)
// ============================================================
class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  Map<String, dynamic>? _perfilData;
  List<Map<String, dynamic>> _anuncios = [];

  final Color _orangeDark = const Color(0xFFF05600);
  final Color _bgScaffold = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Datos del usuario público
      final userData = await _supabase
          .from('usuarios')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      // 2. Anuncios activos de ese usuario
      final anunciosData = await _supabase
          .from('anuncios_marketplace')
          .select()
          .eq('vendedor_id', widget.userId)
          .eq('disponible', true)
          .order('fecha_publicacion', ascending: false);

      if (mounted) {
        setState(() {
          _perfilData = userData;
          _anuncios = List<Map<String, dynamic>>.from(anunciosData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgScaffold,
        body: Center(child: CircularProgressIndicator(color: _orangeDark)),
      );
    }

    if (_perfilData == null) {
      return Scaffold(
        backgroundColor: _bgScaffold,
        appBar: _buildAppBar(context, isMobile: false),
        body: const Center(
          child: Text('No se encontró información de este usuario.'),
        ),
      );
    }

    // ── Extraer datos ──────────────────────────────────────────────────────
    final String nombre    = _perfilData!['primer_nombre'] ?? 'Usuario';
    final String apellido  = _perfilData!['primer_apellido'] ?? '';
    final String universidad = _perfilData!['universidad'] ?? 'Universidad no registrada';
    final String carrera   = _perfilData!['carrera'] ?? '';
    final String semestre  = _perfilData!['semestre']?.toString() ?? '';
    final String fotoUrl   = _perfilData!['foto_perfil_url'] ?? '';
    final String bannerUrl = _perfilData!['foto_banner_url'] ?? '';
    final String bioVendedor  = _perfilData!['biografia_vendedor'] ?? '';
    final String bioAcademica = _perfilData!['biografia_academica'] ?? '';
    final String biografia = bioVendedor.isNotEmpty ? bioVendedor : bioAcademica;
    final bool esVendedor  = _perfilData!['es_vendedor'] ?? false;
    final bool esEstudiante = _perfilData!['es_estudiante'] ?? false;
    final double calificacion = (_perfilData!['calificacion_promedio'] as num?)?.toDouble() ?? 0.0;
    final int totalVentas  = (_perfilData!['total_ventas'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: _bgScaffold,
      appBar: _buildAppBar(context, isMobile: MediaQuery.of(context).size.width < 750),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 750;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── BANNER + AVATAR ──────────────────────────────────────
                Stack(
                  children: [
                    // Banner
                    Container(
                      height: isMobile ? 160 : 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: bannerUrl.isNotEmpty
                              ? NetworkImage(bannerUrl)
                              : const NetworkImage(
                                  'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?q=80&w=1000'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Contenido debajo del banner
                    Padding(
                      padding: EdgeInsets.only(top: isMobile ? 160 : 200),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // ── INFO + STATS + INVENTARIO ──────────────
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 40,
                                  vertical: 24,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMobile
                                      ? CrossAxisAlignment.center
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMobile) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(width: 230),
                                          Expanded(
                                            child: _buildProfileTextInfo(
                                              nombre, apellido, universidad,
                                              biografia, carrera, semestre,
                                              isMobile, esVendedor, esEstudiante,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 65),
                                      _buildProfileTextInfo(
                                        nombre, apellido, universidad,
                                        biografia, carrera, semestre,
                                        isMobile, esVendedor, esEstudiante,
                                      ),
                                    ],

                                    const SizedBox(height: 40),

                                    // ── ESTADÍSTICAS ───────────────────────
                                    _buildStatsSection(
                                      isMobile,
                                      totalVentas: totalVentas,
                                      calificacion: calificacion,
                                      articulosActivos: _anuncios.length,
                                    ),

                                    const SizedBox(height: 40),

                                    // ── INVENTARIO ACTIVO ──────────────────
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Artículos disponibles',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildInventoryGrid(context),
                                    const SizedBox(height: 60),
                                  ],
                                ),
                              ),

                              // ── AVATAR FLOTANTE ────────────────────────
                              Positioned(
                                top: isMobile ? -60 : -40,
                                left: isMobile ? 0 : 40,
                                right: isMobile ? 0 : null,
                                child: Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: isMobile ? 60 : 90,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: fotoUrl.isNotEmpty
                                          ? NetworkImage(fotoUrl)
                                          : null,
                                      child: fotoUrl.isEmpty
                                          ? Icon(Icons.person,
                                              size: isMobile ? 60 : 80,
                                              color: Colors.grey[400])
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── AppBar sin botón de editar ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context,
      {required bool isMobile}) {
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: false,
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'images/Logo_U-NITE_SoloU.png',
            height: 36,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.school_rounded,
              color: Color(0xFFF36900),
              size: 36,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text(
              'U-NITE',
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF245000),
              ),
            ),
          ],
        ],
      ),
      // Sin actions → sin botón de editar
    );
  }

  // ── Texto informativo del perfil ───────────────────────────────────────────
  Widget _buildProfileTextInfo(
    String nombre,
    String apellido,
    String universidad,
    String biografia,
    String carrera,
    String semestre,
    bool isMobile,
    bool esVendedor,
    bool esEstudiante,
  ) {
    final String infoAcademica =
        carrera.isNotEmpty ? '$universidad • $carrera' : universidad;

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment:
              isMobile ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              '$nombre $apellido'.trim(),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              textAlign:
                  isMobile ? TextAlign.center : TextAlign.start,
            ),
            if (esVendedor)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront, size: 14, color: _orangeDark),
                    const SizedBox(width: 4),
                    Text(
                      'Vendedor',
                      style: TextStyle(
                          color: _orangeDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (esEstudiante)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school,
                        size: 14, color: Color(0xFF2E7D32)),
                    SizedBox(width: 4),
                    Text(
                      'Estudiante',
                      style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          infoAcademica,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: UColors.greenDark,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 12),
        Text(
          biografia.isNotEmpty
              ? biografia
              : (carrera.isNotEmpty
                  ? 'Estudiante de $carrera${semestre.isNotEmpty ? ', semestre $semestre' : ''}.'
                  : 'Sin biografía disponible.'),
          style: const TextStyle(
              fontSize: 14, color: Colors.black54, height: 1.5),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }

  // ── Sección de estadísticas ────────────────────────────────────────────────
  Widget _buildStatsSection(
    bool isMobile, {
    required int totalVentas,
    required double calificacion,
    required int articulosActivos,
  }) {
    // Estrellas según calificación
    final int estrellaLlenas = calificacion.floor().clamp(0, 5);
    final bool mediaEstrella =
        (calificacion - estrellaLlenas) >= 0.5 && estrellaLlenas < 5;

    final List<Widget> cards = [
      _buildStatCard(
        title: 'Transacciones Totales',
        value: totalVentas > 0 ? '$totalVentas' : '—',
        subtitle: 'intercambios/ventas',
        icon: Icons.check_circle_outline,
        bgColor: const Color(0xFFE8F5E9),
        valueColor: const Color(0xFF2E7D32),
      ),
      _buildStatCard(
        title: 'Artículos Activos',
        value: '$articulosActivos',
        subtitle: 'DISPONIBLES',
        bgColor: Colors.white,
      ),
      _buildStatCard(
        title: 'Puntuaciones',
        value: calificacion > 0 ? calificacion.toStringAsFixed(1) : '—',
        subtitle: '/ 5.0',
        isRating: true,
        bgColor: Colors.white,
        estrellaLlenas: estrellaLlenas,
        mediaEstrella: mediaEstrella,
        sinCalificacion: calificacion == 0,
      ),
    ];

    if (!isMobile) {
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 16),
          Expanded(child: cards[1]),
          const SizedBox(width: 16),
          Expanded(child: cards[2]),
        ],
      );
    } else {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
        ],
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    Color bgColor = Colors.white,
    Color valueColor = Colors.black87,
    IconData? icon,
    bool isRating = false,
    int estrellaLlenas = 0,
    bool mediaEstrella = false,
    bool sinCalificacion = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: valueColor)),
              const SizedBox(width: 6),
              if (!isRating && icon == null)
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45)),
              if (isRating && !sinCalificacion)
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
            ],
          ),
          if (icon != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, size: 14, color: valueColor),
                const SizedBox(width: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: valueColor)),
              ],
            ),
          ],
          if (isRating) ...[
            const SizedBox(height: 4),
            if (!sinCalificacion)
              Row(
                children: List.generate(5, (i) {
                  if (i < estrellaLlenas) {
                    return Icon(Icons.star_rounded,
                        size: 14, color: _orangeDark);
                  } else if (i == estrellaLlenas && mediaEstrella) {
                    return Icon(Icons.star_half_rounded,
                        size: 14, color: _orangeDark);
                  } else {
                    return Icon(Icons.star_outline_rounded,
                        size: 14, color: Colors.grey[300]);
                  }
                }),
              )
            else
              Text('Sin calificaciones aún',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ],
        ],
      ),
    );
  }

  // ── Cuadrícula de inventario (con popup al hacer clic) ────────────────────
  Widget _buildInventoryGrid(BuildContext context) {
    if (_anuncios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text(
            'Este usuario no tiene artículos disponibles.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: _anuncios.length,
      itemBuilder: (context, index) {
        final anuncio = _anuncios[index];
        final modalidades =
            anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
        final imagenesRaw = modalidades['imagenes'];
        final List<String> imagenes = (imagenesRaw is List)
            ? imagenesRaw.whereType<String>().toList()
            : [];
        final tieneImagen = imagenes.isNotEmpty;

        return GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => DetalleAnuncioDialog(anuncio: anuncio),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: tieneImagen
                          ? Image.network(
                              imagenes[0],
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                color: const Color(0xFFF0F0F0),
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey, size: 35),
                              ),
                            )
                          : Container(
                              height: 160,
                              width: double.infinity,
                              color: const Color(0xFFF0F0F0),
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 35),
                            ),
                    ),
                    if (anuncio['categoria'] != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            anuncio['categoria'],
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anuncio['titulo'] ?? 'Sin título',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              anuncio['descripcion'] ?? 'Sin descripción',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) =>
                                  DetalleAnuncioDialog(anuncio: anuncio),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Ver Artículo',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}