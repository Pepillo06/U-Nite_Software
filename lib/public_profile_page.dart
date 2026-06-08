import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'market_widgets/detalle_anuncio_dialog.dart';

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
  List<String> _fortalezas = [];
  
  // Estado para el toggle de perfiles dobles
  bool _isVendedorMode = false;

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
      final userData = await _supabase
          .from('usuarios')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

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
          _fortalezas = List<String>.from(userData?['fortalezas'] ?? []);
          
          if (userData != null && userData['es_vendedor'] == true && userData['es_estudiante'] == false) {
            _isVendedorMode = true;
          }

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

  String _calcularAntiguedad(String? fechaRegistro) {
    if (fechaRegistro == null || fechaRegistro.isEmpty) return 'Reciente';
    try {
      final registro = DateTime.parse(fechaRegistro);
      final diff = DateTime.now().difference(registro);
      final dias = diff.inDays;
      if (dias < 30) return '$dias Días';
      final meses = dias ~/ 30;
      if (meses < 12) return '$meses Meses';
      final anios = meses ~/ 12;
      return '$anios Años';
    } catch (e) {
      return 'Reciente';
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

    final String nombre    = _perfilData!['primer_nombre'] ?? 'Usuario';
    final String apellido  = _perfilData!['primer_apellido'] ?? '';
    final String universidad = _perfilData!['universidad'] ?? 'Universidad no registrada';
    final String carrera   = _perfilData!['carrera'] ?? '';
    final String semestre  = _perfilData!['semestre']?.toString() ?? '';
    final String fotoUrl   = _perfilData!['foto_perfil_url'] ?? '';
    final String bannerUrl = _perfilData!['foto_banner_url'] ?? '';
    final String bioVendedor  = _perfilData!['biografia_vendedor'] ?? '';
    final String bioAcademica = _perfilData!['biografia_academica'] ?? '';
    final bool esVendedor  = _perfilData!['es_vendedor'] ?? false;
    final bool esEstudiante = _perfilData!['es_estudiante'] ?? false;
    final String fechaRegistro = _perfilData!['fecha_registro'] ?? '';
    //final int totalVentas = (_perfilData!['total_ventas'] as num?)?.toInt() ?? 0;

// Extraer lugares de entrega únicos de los anuncios activos
    Set<String> lugaresEntregaSet = {};
    for (var anuncio in _anuncios) {
      final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
      final campusRaw = modalidades['campus_pickup'];
      
      // Validación segura: solo lo procesa si realmente es una lista
      if (campusRaw is List) {
        lugaresEntregaSet.addAll(campusRaw.map((e) => e.toString()));
      }
    }
    List<String> lugaresEntrega = lugaresEntregaSet.toList();

    String biografiaMostrada = '';
    if (esVendedor && esEstudiante) {
      biografiaMostrada = _isVendedorMode ? bioVendedor : bioAcademica;
    } else {
      biografiaMostrada = bioVendedor.isNotEmpty ? bioVendedor : bioAcademica;
    }

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
                Stack(
                  children: [
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

                    Padding(
                      padding: EdgeInsets.only(top: isMobile ? 160 : 200),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
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
                                            child: _buildProfileTextInfo(nombre, apellido, universidad, biografiaMostrada, carrera, semestre, isMobile, esVendedor, esEstudiante, lugaresEntrega),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 65),
                                      _buildProfileTextInfo(nombre, apellido, universidad, biografiaMostrada, carrera, semestre, isMobile, esVendedor, esEstudiante, lugaresEntrega),
                                    ],

                                    // ── SWITCH DEBAJO DE LA BIOGRAFÍA Y CENTRADO ──
                                    if (esVendedor && esEstudiante) ...[
                                      const SizedBox(height: 24),
                                      Center(child: _buildRoleToggle()),
                                    ],

                                    const SizedBox(height: 32),

                                    // ── ESTADÍSTICAS (CUADROS) ───────────────────
                                    _buildStatsSection(
                                      isMobile,
                                      fechaRegistro: fechaRegistro,
                                      articulosActivos: _anuncios.length,
                                      lugaresEntrega: lugaresEntrega,
                                    ),

                                    const SizedBox(height: 40),

                                    // ── INVENTARIO ACTIVO (solo visible en modo vendedor) ──
                                    if (esVendedor && (!esEstudiante || _isVendedorMode)) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: const [
                                          Text(
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
                                    ] else ...[
                                      const SizedBox(height: 20),
                                    ],
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

  PreferredSizeWidget _buildAppBar(BuildContext context, {required bool isMobile}) {
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
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      width: 260, // Ancho total del switch fijado para el efecto fluido
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DED8)),
      ),
      child: Stack(
        children: [
          // 1. LA "PASTILLA" DE COLOR QUE SE DESLIZA
          AnimatedAlign(
            duration: const Duration(milliseconds: 300), // Qué tan rápido se mueve
            curve: Curves.easeInOutCubic, // Curva suave de animación
            alignment: _isVendedorMode ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), // Qué tan rápido cambia el color
              width: 130, // Exactamente la mitad del ancho total
              decoration: BoxDecoration(
                // Aquí aplicamos el color dinámico fluido
                color: _isVendedorMode ? const Color(0xFFF05600) : const Color(0xFF38761D),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // 2. LAS OPCIONES Y TEXTOS (transparentes, por encima de la pastilla)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isVendedorMode = false),
                  behavior: HitTestBehavior.opaque, // Hace que toda la mitad sea "clickeable"
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isVendedorMode) ...[
                          const Icon(Icons.school, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          'Estudiante',
                          style: TextStyle(
                            color: !_isVendedorMode ? Colors.white : const Color(0xFF5D4A41),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isVendedorMode = true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isVendedorMode) ...[
                          const Icon(Icons.storefront, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          'Vendedor',
                          style: TextStyle(
                            color: _isVendedorMode ? Colors.white : const Color(0xFF5D4A41),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
  }

  Widget _buildProfileTextInfo(String nombre, String apellido, String universidad, String biografia, String carrera, String semestre, bool isMobile, bool esVendedor, bool esEstudiante, List<String> lugaresEntrega) {
    final String infoAcademica = carrera.isNotEmpty ? '$universidad • $carrera' : universidad;

    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              '$nombre $apellido'.trim(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
            ),
            
            // Plaquitas originales intactas al lado del nombre
            if (esEstudiante)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 14, color: Color(0xFF2E7D32)),
                    SizedBox(width: 4),
                    Text('Estudiante', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (esVendedor)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront, size: 14, color: _orangeDark),
                    const SizedBox(width: 4),
                    Text('Vendedor', style: TextStyle(color: _orangeDark, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          infoAcademica,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: UColors.greenDark),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 12),
        Text(
          biografia.isNotEmpty
              ? biografia
              : (carrera.isNotEmpty ? 'Estudiante de $carrera${semestre.isNotEmpty ? ', semestre $semestre' : ''}.' : 'Sin biografía disponible.'),
          style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        // if (esVendedor && lugaresEntrega.isNotEmpty) ...[
        //   const SizedBox(height: 16),
        //   const Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(Icons.location_on, size: 16, color: Color(0xFFF05600)), // Tu naranja
        //       SizedBox(width: 4),
        //       Text(
        //         'Entregas en:',
        //         style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        //       ),
        //     ],
        //   ),
        //   const SizedBox(height: 8),
        //   Wrap(
        //     alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
        //     spacing: 8,
        //     runSpacing: 8,
        //     children: lugaresEntrega.map((lugar) {
        //       return Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        //         decoration: BoxDecoration(
        //           color: const Color(0xFFF2EFED),
        //           borderRadius: BorderRadius.circular(12),
        //           border: Border.all(color: const Color(0xFFE8DED8)),
        //         ),
        //         child: Text(
        //           lugar,
        //           style: const TextStyle(fontSize: 12, color: Color(0xFF5D4A41), fontWeight: FontWeight.w600),
        //         ),
        //       );
        //     }).toList(),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildStatsSection(
    bool isMobile, {
    required String fechaRegistro,
    required int articulosActivos,
    required List<String> lugaresEntrega,
  }) {
    final antiguedadVal = _calcularAntiguedad(fechaRegistro).split(' ')[0];
    final antiguedadTexto = _calcularAntiguedad(fechaRegistro).split(' ').skip(1).join(' ');

    final List<Widget> cards = [
      _buildStatCard(
        title: 'Artículos Activos',
        icon: Icons.local_offer_outlined, // ICONO AQUÍ
        value: '$articulosActivos',
        subtitle: 'DISPONIBLES',
        backgroundColor: const Color(0xFFE8F5E9),
        borderColor: const Color(0xFFC8E6C9),
        titleColor: const Color(0xFF2E7D32),
        valueColor: const Color(0xFF1B5E20),
        subtitleColor: const Color(0xFF2E7D32),
      ),
      // Mostrar "Habilidades y Perfil" si es solo estudiante, o si el switch está en modo estudiante
      if (!_isVendedorMode)
        _buildStatCard(
          title: 'Habilidades y Perfil',
          icon: Icons.trending_up_outlined,
          customContent: _buildHabilidadesBubbles(),
        )
      else
        _buildStatCard(
          title: 'Zonas de Entrega',
          icon: Icons.location_on_outlined,
          customContent: lugaresEntrega.isEmpty
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text('--', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.black87)),
                    SizedBox(width: 6),
                    Text('UNIVERSIDADES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lugaresEntrega.map((lugar) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD5B8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Tooltip(
                        message: lugar,
                        preferBelow: false,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Color(0xFFBF360C)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                lugar,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      _buildStatCard(
        title: 'Antigüedad',
        icon: Icons.calendar_today_outlined, // ICONO AQUÍ
        value: antiguedadVal,
        subtitle: antiguedadTexto.toUpperCase(),
      ),
    ];

    if (!isMobile) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        ),
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

  Widget _buildHabilidadesBubbles() {
    if (_fortalezas.isEmpty) {
      return const Text(
        'Sin habilidades registradas.',
        style: TextStyle(fontSize: 13, color: Colors.black45, fontStyle: FontStyle.italic),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fortalezas.map((fortaleza) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFB7F0B1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.trending_up, size: 14, color: Color(0xFF1B5E20)),
              const SizedBox(width: 5),
              Text(
                fortaleza,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    String value = '', 
    String subtitle = '',
    Color backgroundColor = Colors.white,
    Color titleColor = Colors.black54,
    Color valueColor = Colors.black87,
    Color subtitleColor = Colors.black45,
    Color borderColor = const Color(0xFFEEEEEE),
    Widget? customContent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. EL TÍTULO (Se queda fijo arriba)
          Row(
            children: [
              Icon(icon, size: 16, color: titleColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Separación fija debajo del título
          
          // 2. EL CONTENIDO (Ocupa el resto del espacio y se centra verticalmente)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft, // Centrado vertical, alineado a la izquierda
              child: customContent ??
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value, 
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: valueColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subtitle, 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtitleColor),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid(BuildContext context) {
    if (_anuncios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text('Este usuario no tiene artículos disponibles.', style: TextStyle(color: Colors.grey, fontSize: 15)),
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
        final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
        final imagenesRaw = modalidades['imagenes'];
        final List<String> imagenes = (imagenesRaw is List) ? imagenesRaw.whereType<String>().toList() : [];
        final tieneImagen = imagenes.isNotEmpty;

        return GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => DetalleAnuncioDialog(anuncio: anuncio)),
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: tieneImagen
                          ? Image.network(
                              imagenes[0], height: 160, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 160, color: const Color(0xFFF0F0F0),
                                child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 35),
                              ),
                            )
                          : Container(height: 160, width: double.infinity, color: const Color(0xFFF0F0F0), child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 35)),
                    ),
                    if (anuncio['categoria'] != null)
                      Positioned(
                        top: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Text(anuncio['categoria'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                            Text(anuncio['titulo'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(anuncio['descripcion'] ?? 'Sin descripción', style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => showDialog(context: context, builder: (_) => DetalleAnuncioDialog(anuncio: anuncio)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5), foregroundColor: Colors.black87, elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Ver Artículo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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