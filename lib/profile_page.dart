import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_page.dart';
import 'theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  Map<String, dynamic>? _perfilData;
  List<Map<String, dynamic>> _misAnuncios = [];

  // Paleta de colores
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
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No se encontró una sesión activa');

      // 1. Cargar datos del usuario
      final userData = await _supabase
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .single();

      // 2. Cargar inventario (anuncios activos)
      final anunciosData = await _supabase
          .from('anuncios_marketplace')
          .select()
          .eq('vendedor_id', user.id)
          .eq('disponible', true)
          .order('fecha_publicacion', ascending: false);

      if (mounted) {
        setState(() {
          _perfilData = userData;
          _misAnuncios = List<Map<String, dynamic>>.from(anunciosData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgScaffold,
        body: Center(child: CircularProgressIndicator(color: _orangeDark)),
      );
    }

    if (_perfilData == null) {
      return Scaffold(
        backgroundColor: _bgScaffold,
        body: const Center(child: Text('No hay información disponible.')),
      );
    }

    // Extrayendo datos del perfil
    final String nombre = _perfilData!['primer_nombre'] ?? 'Usuario';
    final String apellido = _perfilData!['primer_apellido'] ?? '';
    final String universidad = _perfilData!['universidad'] ?? 'Universidad no registrada';
    final String carrera = _perfilData!['carrera'] ?? '';
    final String semestre = _perfilData!['semestre']?.toString() ?? '';
    final String fotoUrl = _perfilData!['foto_perfil_url'] ?? '';
    final String fotoBannerUrl = _perfilData!['foto_banner_url'] ?? '';
    final String bioVendedor = _perfilData!['biografia_vendedor'] ?? '';
    final String bioAcademica = _perfilData!['biografia_academica'] ?? '';
    final String biografia = bioVendedor.isNotEmpty ? bioVendedor : bioAcademica;

    return Scaffold(
      backgroundColor: _bgScaffold,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        elevation: 0,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
            tooltip: 'Editar Perfil',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
              if (result == true) {
                _loadAllData();
              }
            },
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 750;
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // --- SECCIÓN SUPERIOR EXPANSIBLE (STACK GLOBAL) ---
                Stack(
                  children: [
                    // 1. EL BANNER: Ahora sí se va de largo ocupando el 100% horizontal de la pantalla
                    Container(
                      height: isMobile ? 160 : 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: fotoBannerUrl.isNotEmpty 
                              ? NetworkImage(fotoBannerUrl) 
                              : const NetworkImage("https://images.unsplash.com/photo-1457369804613-52c61a468e7d?q=80&w=1000"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    // 2. EL CONTENIDO COMPRIMIDO Y CENTRADO
                    Padding(
                      // El padding empuja el bloque exactamente donde termina el banner
                      padding: EdgeInsets.only(top: isMobile ? 160 : 200),
                      child: Center(
                        child: ConstrainedBox(
                          // Aquí limitamos el ancho del perfil a 1000px en Web/PC
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Stack(
                            clipBehavior: Clip.none, // Permite que el avatar suba e invada el banner
                            children: [
                              
                              // Tarjeta contenedora de datos del Perfil
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 40, 
                                  vertical: 24
                                ),
                                child: Column(
                                  crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMobile) ...[
                                      // Diseño Desktop (Lado a Lado)
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(width: 230), // Espacio exacto para el avatar flotante (40 padding + 150 ancho avatar)
                                          Expanded(
                                            child: _buildProfileTextInfo(nombre, apellido, universidad, biografia, carrera, semestre, isMobile)
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      // Diseño Móvil (Vertical Centrado)
                                      const SizedBox(height: 65), // Espacio que deja el avatar arriba en celular
                                      _buildProfileTextInfo(nombre, apellido, universidad, biografia, carrera, semestre, isMobile),
                                    ],

                                    const SizedBox(height: 40),

                                    // --- SECCIÓN DE ESTADÍSTICAS ---
                                    _buildStatsSection(isMobile),

                                    const SizedBox(height: 40),

                                    // --- INVENTARIO ACTIVO ---
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Inventario Activo",
                                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        TextButton(
                                          onPressed: () {},
                                          child: const Text("Ver todos →", style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildInventoryGrid(),
                                    const SizedBox(height: 60),
                                  ],
                                ),
                              ),

                              // AVATAR POSICIONADO FLOTANTE: Vinculado al contenedor comprimido de 1000px
                              Positioned(
                                top: isMobile ? -60 : -40, // Sube de forma responsiva invadiendo el banner
                                left: isMobile ? 0 : 40,   // Alineado perfectamente con el padding horizontal del texto
                                right: isMobile ? 0 : null,
                                child: Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      //border: Border.all(color: Colors.white, width: 6),
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
                                      backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                                      child: fotoUrl.isEmpty
                                          ? Icon(Icons.person, size: isMobile ? 60 : 80, color: Colors.grey[400])
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

  // Widget para los textos informativos
  Widget _buildProfileTextInfo(String nombre, String apellido, String universidad, String biografia, String carrera, String semestre, bool isMobile) {
    final String infoAcademica = carrera.isNotEmpty 
    ? '$universidad • $carrera' 
    : universidad;
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
                  Text(
                    "Vendedor",
                    style: TextStyle(color: _orangeDark, fontSize: 12, fontWeight: FontWeight.bold),
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
            color: UColors.greenDark, // El color verde de tu paleta
          ),
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
      ],
    );
  }

  // Sección de Estadísticas Responsivas
  Widget _buildStatsSection(bool isMobile) {
    List<Widget> cards = [
      _buildStatCard(
        title: "Transacciones Totales",
        value: "57",
        subtitle: "intercambios/ventas",
        icon: Icons.check_circle_outline,
        bgColor: const Color(0xFFE8F5E9),
        valueColor: const Color(0xFF2E7D32),
      ),
      _buildStatCard(
        title: "Artículos Activos",
        value: "${_misAnuncios.length}",
        subtitle: "DISPONIBLES",
        bgColor: Colors.white,
      ),
      _buildStatCard(
        title: "Puntuaciones",
        value: "4.8",
        subtitle: "/ 5.0",
        extraSubtitle: "28 reseñas",
        isRating: true,
        bgColor: Colors.white,
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
          cards[0], const SizedBox(height: 12),
          cards[1], const SizedBox(height: 12),
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
    String? extraSubtitle,
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
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: valueColor)),
              const SizedBox(width: 6),
              if (!isRating && icon == null)
                Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
              if (isRating)
                Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          if (icon != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, size: 14, color: valueColor),
                const SizedBox(width: 4),
                Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: valueColor)),
              ],
            ),
          ],
          if (isRating) ...[
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                return Icon(index < 4 ? Icons.star : Icons.star_half, size: 14, color: _orangeDark);
              }),
            ),
            const SizedBox(height: 4),
            Text(extraSubtitle ?? "", style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ]
        ],
      ),
    );
  }

  // Cuadrícula del inventario responsiva
  Widget _buildInventoryGrid() {
    if (_misAnuncios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text("No hay artículos en venta actualmente.", style: TextStyle(color: Colors.grey, fontSize: 15)),
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
      itemCount: _misAnuncios.length,
      itemBuilder: (context, index) {
        final anuncio = _misAnuncios[index];
        final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
        final imagenes = modalidades['imagenes'] as List<dynamic>? ?? [];
        final tieneImagen = imagenes.isNotEmpty;

        return Container(
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
                        ? Image.network(imagenes[0], height: 160, width: double.infinity, fit: BoxFit.cover)
                        : Container(
                            height: 160, 
                            width: double.infinity, 
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 35),
                          ),
                  ),
                  if (anuncio['categoria'] != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          anuncio['categoria'],
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            anuncio['descripcion'] ?? 'Sin descripción',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F5F5),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text("Ver Artículo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}