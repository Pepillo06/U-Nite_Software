import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

import '../widgets/unite_header.dart';
import 'crear_grupos.dart';
import 'public_profile_page.dart';


class StudymatchPage extends StatefulWidget {
  const StudymatchPage({super.key});

  @override
  State<StudymatchPage> createState() => _StudymatchPageState();
}

class _StudymatchPageState extends State<StudymatchPage> {
  int _selectedTab = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filtroMateria;
  String? _filtroSeccion;

  String? _filtroPrivacidad; // null = todos, 'publico' = públicos, 'privado' = privados

  List<_GrupoData> _grupos = [];
  bool _isLoading = true;

  // ─── PERSONAS ────────────────────────────────────────────────────────────
  List<_PersonaData> _estudiantes = [];
  List<_PersonaData> _amigos = [];
  List<_SolicitudData> _solicitudesPendientes = [];
  Set<String> _misAmigosIds = {};
  bool _isLoadingPersonas = false;
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('grupos_estudio')
          .select('id, nombre, descripcion, materia, seccion, max_miembros, es_privado, foto_url, creado_por');

      final grupos = (response as List).map((row) {
        return _GrupoData.fromMap(row);
      }).toList();

      if (mounted) {
        setState(() {
          _grupos = grupos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error al cargar grupos: $e'),
          ),
        );
      }
    }
  }

  // ─── CARGA DE PERSONAS ───────────────────────────────────────────────────
  Future<void> _cargarEstudiantes() async {
    if (_isLoadingPersonas) return;
    setState(() => _isLoadingPersonas = true);
    try {
      final supabase = Supabase.instance.client;
      final miId = supabase.auth.currentUser?.id;

      // Si _misAmigosIds aún está vacío (no se cargaron amigos antes), los obtenemos primero
      Set<String> idsAmigos = _misAmigosIds;
      if (idsAmigos.isEmpty && miId != null) {
        final r1 = await supabase
            .from('amigos')
            .select('amigo_id')
            .eq('usuario_id', miId)
            .eq('estado', 'aceptados');
        final r2 = await supabase
            .from('amigos')
            .select('usuario_id')
            .eq('amigo_id', miId)
            .eq('estado', 'aceptados');
        for (final r in (r1 as List)) {
          final id = r['amigo_id']?.toString();
          if (id != null) idsAmigos = {...idsAmigos, id};
        }
        for (final r in (r2 as List)) {
          final id = r['usuario_id']?.toString();
          if (id != null) idsAmigos = {...idsAmigos, id};
        }
      }

      final response = await supabase
          .from('usuarios')
          .select('id, primer_nombre, primer_apellido, foto_perfil_url, carrera, universidad')
          .neq('id', miId ?? '')
          .eq('es_estudiante', true);

      // Filtrar amigos y calcular amigos en común
      final List<_PersonaData> lista = [];
      for (final row in (response as List)) {
        final id = row['id']?.toString() ?? '';
        if (idsAmigos.contains(id)) continue; // excluir amigos ya aceptados

        // Amigos en común: amigos del otro que también están en mis amigos
        final otroResp1 = await supabase
            .from('amigos')
            .select('amigo_id')
            .eq('usuario_id', id)
            .eq('estado', 'aceptados');
        final otroResp2 = await supabase
            .from('amigos')
            .select('usuario_id')
            .eq('amigo_id', id)
            .eq('estado', 'aceptados');

        final Set<String> idsDelOtro = {};
        for (final r in (otroResp1 as List)) {
          final aid = r['amigo_id']?.toString();
          if (aid != null) idsDelOtro.add(aid);
        }
        for (final r in (otroResp2 as List)) {
          final aid = r['usuario_id']?.toString();
          if (aid != null) idsDelOtro.add(aid);
        }

        final enComun = idsAmigos.intersection(idsDelOtro).length;
        lista.add(_PersonaData.fromMap(row, amigosEnComun: enComun));
      }

      if (mounted) {
        setState(() {
          _estudiantes = lista;
          _misAmigosIds = idsAmigos;
          _isLoadingPersonas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPersonas = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error al cargar estudiantes: $e'),
          ),
        );
      }
    }
  }

  Future<void> _cargarAmigos() async {
    if (_isLoadingPersonas) return;
    setState(() => _isLoadingPersonas = true);
    try {
      final supabase = Supabase.instance.client;
      final miId = supabase.auth.currentUser?.id;
      if (miId == null) {
        setState(() => _isLoadingPersonas = false);
        return;
      }

      // Solicitudes recibidas pendientes
      final solicitudesResp = await supabase
          .from('amigos')
          .select('id, usuario_id ( id, primer_nombre, primer_apellido, foto_perfil_url, carrera )')
          .eq('amigo_id', miId)
          .eq('estado', 'pendiente');

      // Amigos aceptados (ambos lados)
      final amigosResp = await supabase
          .from('amigos')
          .select('estado, amigo_id ( id, primer_nombre, primer_apellido, foto_perfil_url, carrera )')
          .eq('usuario_id', miId)
          .eq('estado', 'aceptados');

      final amigosResp2 = await supabase
          .from('amigos')
          .select('estado, usuario_id ( id, primer_nombre, primer_apellido, foto_perfil_url, carrera )')
          .eq('amigo_id', miId)
          .eq('estado', 'aceptados');

      // Construir set de IDs de mis amigos
      final Set<String> idsAmigos = {};
      final List<_PersonaData> listaAmigos = [];

      for (final row in (amigosResp as List)) {
        final data = row['amigo_id'];
        if (data != null) {
          final id = data['id']?.toString() ?? '';
          if (id.isNotEmpty) idsAmigos.add(id);
          listaAmigos.add(_PersonaData.fromMap(data));
        }
      }
      for (final row in (amigosResp2 as List)) {
        final data = row['usuario_id'];
        if (data != null) {
          final id = data['id']?.toString() ?? '';
          if (id.isNotEmpty) idsAmigos.add(id);
          listaAmigos.add(_PersonaData.fromMap(data));
        }
      }

      // Calcular amigos en común para cada amigo.
      // Traemos TODOS los vínculos de amistad aceptados de una vez para evitar N queries
      // y hacemos la intersección en memoria.
      //
      // Estrategia: para cada amigo, sus amigos son quienes aparecen en la tabla
      // con ese ID en cualquiera de los dos lados. La intersección con idsAmigos
      // (mis amigos) da los amigos en común, excluyendo miId y el propio amigo.
      final List<_PersonaData> listaAmigosConComun = [];
      for (final amigo in listaAmigos) {
        final r1 = await supabase
            .from('amigos')
            .select('amigo_id')
            .eq('usuario_id', amigo.id)
            .eq('estado', 'aceptados');
        final r2 = await supabase
            .from('amigos')
            .select('usuario_id')
            .eq('amigo_id', amigo.id)
            .eq('estado', 'aceptados');

        final Set<String> idsDelOtro = {};
        for (final r in (r1 as List)) {
          // amigo_id puede venir como String UUID directamente
          final raw = r['amigo_id'];
          final id = (raw is Map) ? raw['id']?.toString() : raw?.toString();
          if (id != null && id != miId && id != amigo.id) idsDelOtro.add(id);
        }
        for (final r in (r2 as List)) {
          final raw = r['usuario_id'];
          final id = (raw is Map) ? raw['id']?.toString() : raw?.toString();
          if (id != null && id != miId && id != amigo.id) idsDelOtro.add(id);
        }

        final enComun = idsAmigos.intersection(idsDelOtro).length;
        listaAmigosConComun.add(_PersonaData(
          id: amigo.id,
          nombre: amigo.nombre,
          apellido: amigo.apellido,
          fotoPerfil: amigo.fotoPerfil,
          carrera: amigo.carrera,
          universidad: amigo.universidad,
          amigosEnComun: enComun,
        ));
      }

      final List<_SolicitudData> solicitudes = [];
      for (final row in (solicitudesResp as List)) {
        final data = row['usuario_id'];
        if (data != null) {
          solicitudes.add(_SolicitudData(
            solicitudId: row['id'].toString(),
            persona: _PersonaData.fromMap(data),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _amigos = listaAmigosConComun;
          _misAmigosIds = idsAmigos;
          _solicitudesPendientes = solicitudes;
          _isLoadingPersonas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPersonas = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error al cargar amigos: $e'),
          ),
        );
      }
    }
  }

  Future<void> _enviarSolicitud(String amigoId) async {
    try {
      final supabase = Supabase.instance.client;
      final miId = supabase.auth.currentUser?.id;
      if (miId == null) return;

      await supabase.from('amigos').insert({
        'usuario_id': miId,
        'amigo_id': amigoId,
        'estado': 'pendiente',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2E5900),
            content: Text('Solicitud de amistad enviada'),
          ),
        );
        // Refrescar lista para reflejar estado
        _cargarEstudiantes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _aceptarSolicitud(String solicitudId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('amigos')
          .update({'estado': 'aceptados'})
          .eq('id', solicitudId);

      if (mounted) _cargarAmigos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFD32F2F), content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rechazarSolicitud(String solicitudId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('amigos').delete().eq('id', solicitudId);
      if (mounted) _cargarAmigos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFD32F2F), content: Text('Error: $e')),
        );
      }
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_GrupoData> get _gruposFiltrados {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return _grupos.where((g) {
      // Tab 1 = Mis Grupos: solo los creados por el usuario logueado
      // Tab 2 = Grupos Publicos: los que NO creo el usuario logueado
      if (_selectedTab == 1 && g.creadoPor != userId) return false;
      if (_selectedTab == 2 && g.creadoPor == userId) return false;

      final matchSearch = _searchQuery.isEmpty ||
          g.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchMateria = _filtroMateria == null ||
          g.materia.toLowerCase().contains(_filtroMateria!.toLowerCase());
      final matchSeccion = _filtroSeccion == null ||
          'Sec \${g.seccion}'.toLowerCase().contains(_filtroSeccion!.toLowerCase()) ||
          g.seccion.toString() == _filtroSeccion;
      final matchPrivacidad = _filtroPrivacidad == null ||
          (_filtroPrivacidad == 'privado' ? g.esPrivado : !g.esPrivado);

      return matchSearch && matchMateria && matchSeccion && matchPrivacidad;
    }).toList();
  }

  bool get _isPersonasTab => _selectedTab >= 3 && _selectedTab <= 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      appBar: const UniteHeader(currentIndex: 4),
      body: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isMobile = w < 600;
        final isTablet = w >= 600 && w < 1024;
        final isDesktop = w >= 1024;

        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 32,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 32,
                  0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: _isPersonasTab
                      ? _HeroBannerPersonas(isMobile: isMobile)
                      : _HeroBanner(isMobile: isMobile),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : isTablet ? 24 : 48,
                  vertical: 24,
                ),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 200,
                            child: _Sidebar(
                              selected: _selectedTab,
                              onSelect: _onTabSelect,
                              horizontal: false,
                            ),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: _buildContent(
                                  isMobile: false, isTablet: false),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Sidebar(
                            selected: _selectedTab,
                            onSelect: _onTabSelect,
                            horizontal: true,
                            compact: isMobile,
                          ),
                          const SizedBox(height: 20),
                          _buildContent(
                              isMobile: isMobile, isTablet: isTablet),
                        ],
                      ),
              ),
              const _Footer(),
            ],
          ),
        );
      }),
    );
  }

  void _onTabSelect(int i) {
    // Al tocar el header "Personas", ir directo a "Amigos"
    final tab = (i == 3) ? 4 : i;
    setState(() => _selectedTab = tab);
    if (tab == 4) _cargarAmigos();
    if (tab == 5) _cargarEstudiantes();
  }

  Widget _buildContent({required bool isMobile, required bool isTablet}) {
    // ─── TABS DE PERSONAS ────────────────────────────────────────────────
    if (_selectedTab == 4) {
      return _PersonasContent(
        isMobile: isMobile,
        isTablet: isTablet,
        searchCtrl: _searchCtrl,
        searchQuery: _searchQuery,
        onSearchChanged: (v) => setState(() => _searchQuery = v),
        isLoading: _isLoadingPersonas,
        amigos: _amigos,
        solicitudesPendientes: _solicitudesPendientes,
        onAceptar: _aceptarSolicitud,
        onRechazar: _rechazarSolicitud,
        subTab: 'amigos',
      );
    }
    if (_selectedTab == 5) {
      return _PersonasContent(
        isMobile: isMobile,
        isTablet: isTablet,
        searchCtrl: _searchCtrl,
        searchQuery: _searchQuery,
        onSearchChanged: (v) => setState(() => _searchQuery = v),
        isLoading: _isLoadingPersonas,
        estudiantes: _estudiantes,
        onAgregar: _enviarSolicitud,
        subTab: 'estudiantes',
      );
    }
    // ────────────────────────────────────────────────────────────────────

    final gridCols = isMobile ? 1 : isTablet ? 2 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile
            ? Column(
                children: [
                  _SearchBar(
                      hintText: 'Buscar grupos',
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v)),
                  const SizedBox(height: 10),
                  SizedBox(
                      width: double.infinity,
                      child: _CreateButton(onTap: _showCreateDialog)),
                ],
              )
            : Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: 600,
                    child: _SearchBar(
                        hintText: 'Buscar grupos',
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v)),
                  ),
                  const Spacer(),
                  _CreateButton(onTap: _showCreateDialog),
                ],
              ),
        const SizedBox(height: 24),
        _FiltersRow(
          filtroMateria: _filtroMateria,
          filtroSeccion: _filtroSeccion,
          filtroPrivacidad: _filtroPrivacidad,
          onClearMateria: () => setState(() => _filtroMateria = null),
          onClearSeccion: () => setState(() => _filtroSeccion = null),
          onPrivacidadChanged: (v) => setState(() => _filtroPrivacidad = v),
          wrap: isMobile,
        ),
        const SizedBox(height: 20),
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: Color(0xFFE65100)),
                ),
              )
            : _GruposGrid(
                grupos: _gruposFiltrados,
                columns: gridCols,
                onCrear: _showCreateDialog),
      ],
    );
  }

  void _showCreateDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearGrupoPage()),
    );
    _cargarGrupos();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELOS DE PERSONAS
// ═══════════════════════════════════════════════════════════════════════════

class _PersonaData {
  final String id;
  final String nombre;
  final String apellido;
  final String? fotoPerfil;
  final String? carrera;
  final String? universidad;
  final int amigosEnComun;

  _PersonaData({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.fotoPerfil,
    this.carrera,
    this.universidad,
    this.amigosEnComun = 0,
  });

  factory _PersonaData.fromMap(Map<String, dynamic> map, {int amigosEnComun = 0}) {
    return _PersonaData(
      id: map['id']?.toString() ?? '',
      nombre: map['primer_nombre'] ?? '',
      apellido: map['primer_apellido'] ?? '',
      fotoPerfil: map['foto_perfil_url'],
      carrera: map['carrera'],
      universidad: map['universidad'],
      amigosEnComun: amigosEnComun,
    );
  }

  String get nombreCompleto => '$nombre $apellido'.trim();
}

class _SolicitudData {
  final String solicitudId;
  final _PersonaData persona;
  _SolicitudData({required this.solicitudId, required this.persona});
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTENIDO PERSONAS
// ═══════════════════════════════════════════════════════════════════════════

class _PersonasContent extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool isLoading;
  final String subTab; // 'amigos' | 'estudiantes'

  // amigos
  final List<_PersonaData>? amigos;
  final List<_SolicitudData>? solicitudesPendientes;
  final Future<void> Function(String)? onAceptar;
  final Future<void> Function(String)? onRechazar;

  // estudiantes
  final List<_PersonaData>? estudiantes;
  final Future<void> Function(String)? onAgregar;

  const _PersonasContent({
    required this.isMobile,
    required this.isTablet,
    required this.searchCtrl,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isLoading,
    required this.subTab,
    this.amigos,
    this.solicitudesPendientes,
    this.onAceptar,
    this.onRechazar,
    this.estudiantes,
    this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final gridCols = isMobile ? 1 : isTablet ? 2 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de búsqueda + botón Agregar
        isMobile
            ? Column(
                children: [
                  _SearchBar(
                    hintText: 'Buscar amigos',
                    controller: searchCtrl,
                    onChanged: onSearchChanged,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: _AgregarButton(),
                  ),
                ],
              )
            : Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: 600,
                    child: _SearchBar(
                      hintText: 'Buscar amigos',
                      controller: searchCtrl,
                      onChanged: onSearchChanged,
                    ),
                  ),
                  const Spacer(),
                  _AgregarButton(),
                ],
              ),
        const SizedBox(height: 24),

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: Color(0xFFE65100)),
            ),
          )
        else if (subTab == 'amigos')
          _AmigosView(
            amigos: amigos ?? [],
            solicitudes: solicitudesPendientes ?? [],
            searchQuery: searchQuery,
            gridCols: gridCols,
            isMobile: isMobile,
            onAceptar: onAceptar!,
            onRechazar: onRechazar!,
          )
        else
          _EstudiantesView(
            estudiantes: estudiantes ?? [],
            searchQuery: searchQuery,
            gridCols: gridCols,
            onAgregar: onAgregar!,
          ),
      ],
    );
  }
}

// ─── VISTA: AMIGOS ────────────────────────────────────────────────────────

class _AmigosView extends StatelessWidget {
  final List<_PersonaData> amigos;
  final List<_SolicitudData> solicitudes;
  final String searchQuery;
  final int gridCols;
  final bool isMobile;
  final Future<void> Function(String) onAceptar;
  final Future<void> Function(String) onRechazar;

  const _AmigosView({
    required this.amigos,
    required this.solicitudes,
    required this.searchQuery,
    required this.gridCols,
    required this.isMobile,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final amigosFiltrados = amigos.where((p) =>
        searchQuery.isEmpty ||
        p.nombreCompleto.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (p.carrera ?? '').toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Solicitudes pendientes
        if (solicitudes.isNotEmpty) ...[
          Row(children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Solicitudes de Amistad',
              style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${solicitudes.length} NUEVAS',
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          isMobile
              ? Column(
                  children: solicitudes
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SolicitudCard(
                              solicitud: s,
                              onAceptar: onAceptar,
                              onRechazar: onRechazar,
                            ),
                          ))
                      .toList(),
                )
              : Row(
                  children: solicitudes
                      .take(3)
                      .map((s) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _SolicitudCard(
                                solicitud: s,
                                onAceptar: onAceptar,
                                onRechazar: onRechazar,
                              ),
                            ),
                          ))
                      .toList(),
                ),
          const SizedBox(height: 28),
        ],

        // Mis amigos
        Row(children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFE65100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Mis Amigos',
            style: GoogleFonts.lexend(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        if (amigosFiltrados.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Aún no tienes amigos agregados.',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),
          )
        else if (gridCols == 1)
          Column(
            children: [
              ...amigosFiltrados.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PersonaCard(persona: p, esAmigo: true),
                  )),
              _InvitarAmigosCard(),
            ],
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: amigosFiltrados.length + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCols,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 240,
            ),
            itemBuilder: (_, i) {
              if (i == amigosFiltrados.length) return _InvitarAmigosCard();
              return _PersonaCard(
                persona: amigosFiltrados[i],
                esAmigo: true,
              );
            },
          ),
      ],
    );
  }
}

// ─── VISTA: ESTUDIANTES ───────────────────────────────────────────────────

class _EstudiantesView extends StatelessWidget {
  final List<_PersonaData> estudiantes;
  final String searchQuery;
  final int gridCols;
  final Future<void> Function(String) onAgregar;

  const _EstudiantesView({
    required this.estudiantes,
    required this.searchQuery,
    required this.gridCols,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final filtrados = estudiantes.where((p) =>
        searchQuery.isEmpty ||
        p.nombreCompleto.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (p.carrera ?? '').toLowerCase().contains(searchQuery.toLowerCase())).toList();

    if (filtrados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No se encontraron estudiantes.',
            style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF9E9E9E)),
          ),
        ),
      );
    }

    if (gridCols == 1) {
      return Column(
        children: filtrados
            .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PersonaCard(
                    persona: p,
                    esAmigo: false,
                    onAgregar: onAgregar,
                  ),
                ))
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtrados.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 240,
      ),
      itemBuilder: (_, i) => _PersonaCard(
        persona: filtrados[i],
        esAmigo: false,
        onAgregar: onAgregar,
      ),
    );
  }
}

// ─── TARJETA SOLICITUD ────────────────────────────────────────────────────

class _SolicitudCard extends StatefulWidget {
  final _SolicitudData solicitud;
  final Future<void> Function(String) onAceptar;
  final Future<void> Function(String) onRechazar;

  const _SolicitudCard({
    required this.solicitud,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  State<_SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends State<_SolicitudCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.solicitud.persona;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFF0EAE6)),
      ),
      child: Row(
        children: [
          _Avatar(url: p.fotoPerfil, nombre: p.nombreCompleto, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombreCompleto,
                    style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A))),
                if ((p.carrera ?? '').isNotEmpty)
                  Text(p.carrera!,
                      style: GoogleFonts.lexend(
                          fontSize: 12, color: const Color(0xFF9E9E9E))),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFE65100)),
            )
          else ...[
            GestureDetector(
              onTap: () async {
                setState(() => _loading = true);
                await widget.onAceptar(widget.solicitud.solicitudId);
                if (mounted) setState(() => _loading = false);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF2E7D32), size: 18),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                setState(() => _loading = true);
                await widget.onRechazar(widget.solicitud.solicitudId);
                if (mounted) setState(() => _loading = false);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF9E9E9E).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFF757575), size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── TARJETA PERSONA ──────────────────────────────────────────────────────

class _PersonaCard extends StatefulWidget {
  final _PersonaData persona;
  final bool esAmigo;
  final Future<void> Function(String)? onAgregar;

  const _PersonaCard({
    required this.persona,
    required this.esAmigo,
    this.onAgregar,
  });

  @override
  State<_PersonaCard> createState() => _PersonaCardState();
}

class _PersonaCardState extends State<_PersonaCard> {
  bool _enviado = false;
  bool _loading = false;

  Widget _buildButton() {
    final p = widget.persona;
    if (widget.esAmigo) {
      return TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
        label: Text('Enviar Mensaje',
            style: GoogleFonts.lexend(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13)),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF2E5900),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        ),
      );
    }
    if (_enviado) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text('Solicitud enviada',
            style: GoogleFonts.lexend(
                fontSize: 13, color: const Color(0xFF9E9E9E))),
      );
    }
    return TextButton.icon(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              await widget.onAgregar!(p.id);
              if (mounted) {
                setState(() {
                  _loading = false;
                  _enviado = true;
                });
              }
            },
      icon: _loading
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.person_add_rounded,
              size: 15, color: Colors.white),
      label: Text('Agregar',
          style: GoogleFonts.lexend(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13)),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFE65100),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.persona;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProfilePage(userId: p.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EAE6)),
        ),
        child: isMobile
            // ── MÓVIL: layout horizontal ──────────────────────────────────
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    _Avatar(
                        url: p.fotoPerfil,
                        nombre: p.nombreCompleto,
                        radius: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.nombreCompleto,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((p.carrera ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              p.carrera!,
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: const Color(0xFFE65100),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (p.amigosEnComun > 0) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outlined,
                                    size: 12, color: Color(0xFF9E9E9E)),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '${p.amigosEnComun} en común',
                                    style: GoogleFonts.lexend(
                                      fontSize: 10,
                                      color: const Color(0xFF9E9E9E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Botón pegado a la derecha
                    _buildButton(),
                  ],
                ),
              )
            // ── GRID (tablet/desktop): layout vertical ────────────────────
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Avatar
                    _Avatar(
                        url: p.fotoPerfil,
                        nombre: p.nombreCompleto,
                        radius: 24),
                    const SizedBox(height: 8),
                    // Nombre
                    Text(
                      p.nombreCompleto,
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((p.carrera ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        p.carrera!,
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: const Color(0xFFA53C00),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (p.amigosEnComun > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outlined,
                              size: 13, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${p.amigosEnComun} AMIGOS EN COMÚN',
                              style: GoogleFonts.lexend(
                                fontSize: 10,
                                color: const Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Empuja el botón hacia abajo
                    const Spacer(),
                    // Botón pegado al fondo
                    SizedBox(
                      width: double.infinity,
                      child: _buildButton(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── TARJETA INVITAR AMIGOS ───────────────────────────────────────────────

class _InvitarAmigosCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return CustomPaint(
      painter: _DashedRectPainter(color: const Color(0xFFD7CCC8)),
      child: Container(
        height: isMobile ? 72 : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: isMobile
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: Color(0xFF9E9E9E), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Invitar amigos',
                              style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF212121))),
                          Text(
                            'Comparte U-NITE con tus compañeros.',
                            style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: const Color(0xFFAFA49C)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: Color(0xFF9E9E9E), size: 22),
                ),
                const SizedBox(height: 12),
                Text('Invitar amigos',
                    style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121))),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Comparte U-NITE con tus compañeros de curso.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: const Color(0xFFAFA49C),
                        height: 1.45),
                  ),
                ),
              ]),
      ),
    );
  }
}

// ─── AVATAR ───────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final String nombre;
  final double radius;

  const _Avatar({required this.nombre, this.url, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final initials = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEFE0D0),
      backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      child: (url == null || url!.isEmpty)
          ? Text(initials,
              style: GoogleFonts.lexend(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE65100)))
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO BANNER (GRUPOS - original)
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final bool isMobile;
  const _HeroBanner({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isMobile ? 200 : 260,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(
          'assets/estudiantess.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 255, 102, 0), Color.fromARGB(255, 255, 125, 82)]),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                const Color.fromARGB(172, 205, 97, 39).withOpacity(0.92),
                const Color(0xFF3E2723).withOpacity(0.65),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 48, vertical: 28),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isMobile
                      ? 'Encuentra tu perfecto\ngrupo de estudio'
                      : 'Encuentra tu perfecto grupo\nde estudio',
                  style: GoogleFonts.lexend(
                    fontSize: isMobile ? 22 : 35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: isMobile ? double.infinity : 340,
                  child: Text(
                    'Conéctate con compañeros de tu misma sección y materia y aprueben juntos.',
                    style: GoogleFonts.lexend(
                      fontSize: isMobile ? 13 : 17,
                      color: Colors.white.withOpacity(0.88),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO BANNER PERSONAS
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBannerPersonas extends StatelessWidget {
  final bool isMobile;
  const _HeroBannerPersonas({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isMobile ? 200 : 260,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(
          'assets/amigos.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF33691E)],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                const Color.fromARGB(255, 91, 52, 11).withOpacity(0.88),
                const Color(0xFF3E2723).withOpacity(0.60),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 48, vertical: 28),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isMobile
                      ? 'Encuentra a tus amigos'
                      : 'Encuentra a tus amigos',
                  style: GoogleFonts.lexend(
                    fontSize: isMobile ? 22 : 35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: isMobile ? double.infinity : 360,
                  child: Text(
                    'Conecta con compañeros de tu misma facultad, intercambia conocimientos y crea una red académica sólida.',
                    style: GoogleFonts.lexend(
                      fontSize: isMobile ? 13 : 17,
                      color: Colors.white.withOpacity(0.88),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════════════════

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final bool horizontal;
  final bool compact;

  const _Sidebar({
    required this.selected,
    required this.onSelect,
    this.horizontal = false,
    this.compact = false,
  });

  static const _items = [
    _SI(icon: Icons.grid_view_rounded, label: 'Grupos', isHeader: true),
    _SI(icon: null, label: 'Mis Grupos', isHeader: false),
    _SI(icon: null, label: 'Grupos Públicos', isHeader: false),
    _SI(icon: Icons.people_alt_outlined, label: 'Personas', isHeader: true),
    _SI(icon: null, label: 'Amigos', isHeader: false),
    _SI(icon: null, label: 'Estudiantes', isHeader: false),
  ];

  @override
  Widget build(BuildContext context) {
    final bool showGruposSubItems = (selected >= 0 && selected <= 2);
    final bool showPersonasSubItems = (selected >= 3 && selected <= 5);

    Widget? gruposTile;
    final List<Widget> gruposSubTiles = [];
    Widget? personasTile;
    final List<Widget> personasSubTiles = [];

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final isSubItem = !item.isHeader;

      final bool isActive = (i == 0)
          ? showGruposSubItems
          : (i == 3)
              ? showPersonasSubItems
              : (selected == i);

      final tile = GestureDetector(
        onTap: () {
          if (i == 0 && showGruposSubItems) {
            onSelect(-1);
          } else if (i == 3 && showPersonasSubItems) {
            onSelect(-1);
          } else {
            onSelect(i);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: horizontal ? null : 160,
          padding: horizontal
              ? EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14, vertical: compact ? 7 : 9)
              : EdgeInsets.symmetric(
                  horizontal: isSubItem ? 12 : 10, vertical: 9),
          decoration: BoxDecoration(
            color: (isActive && !item.isHeader) ? const Color(0xFFEFE0D0) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: (isActive && item.isHeader)
                ? Border.all(color: const Color(0xFFE65100), width: 1.0)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSubItem && !horizontal) ...[
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE65100)
                        : const Color(0xFFD0C4BB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (item.icon != null) ...[
                Icon(item.icon,
                    size: compact ? 15 : 17,
                    color: isActive
                        ? const Color(0xFFE65100)
                        : const Color(0xFF757575)),
                const SizedBox(width: 6),
              ],
              Text(
                item.label,
                style: GoogleFonts.lexend(
                  fontSize: compact ? 12 : 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFFE65100)
                      : const Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      );

      final tileWithPadding = Padding(
        padding: horizontal
            ? const EdgeInsets.only(right: 8)
            : const EdgeInsets.only(bottom: 2),
        child: tile,
      );

      if (i == 0) gruposTile = tileWithPadding;
      if (i == 1 || i == 2) gruposSubTiles.add(tileWithPadding);
      if (i == 3) personasTile = tileWithPadding;
      if (i == 4 || i == 5) personasSubTiles.add(tileWithPadding);
    }

    final List<Widget> tiles = [];

    if (gruposTile != null) tiles.add(gruposTile);
    tiles.add(
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        child: ClipRect(
          child: showGruposSubItems
              ? (horizontal
                  ? Row(mainAxisSize: MainAxisSize.min, children: gruposSubTiles)
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: gruposSubTiles))
              : (horizontal ? const SizedBox(width: 0) : const SizedBox(height: 0)),
        ),
      ),
    );

    if (!horizontal) tiles.add(const SizedBox(height: 6));

    if (personasTile != null) tiles.add(personasTile);
    tiles.add(
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        child: ClipRect(
          child: showPersonasSubItems
              ? (horizontal
                  ? Row(mainAxisSize: MainAxisSize.min, children: personasSubTiles)
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: personasSubTiles))
              : (horizontal ? const SizedBox(width: 0) : const SizedBox(height: 0)),
        ),
      ),
    );

    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: tiles),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFE3BFB1), thickness: 1.2, height: 24),
        ...tiles,
        const Divider(color: Color(0xFFE3BFB1), thickness: 1.2, height: 24),
      ],
    );
  }
}

class _SI {
  final IconData? icon;
  final String label;
  final bool isHeader;
  const _SI({required this.icon, required this.label, required this.isHeader});
}

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═══════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3BFB1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 1))
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF212121)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle:
              GoogleFonts.lexend(color: const Color(0xFFAFA49C), fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFFAFA49C), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE BUTTON (grupos)
// ═══════════════════════════════════════════════════════════════════════════

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: Text('Crear Grupo',
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── BOTÓN AGREGAR (personas) ─────────────────────────────────────────────

class _AgregarButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: Text('Agregar',
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════

class _FiltersRow extends StatelessWidget {
  final String? filtroMateria;
  final String? filtroSeccion;
  final String? filtroPrivacidad;
  final VoidCallback onClearMateria;
  final VoidCallback onClearSeccion;
  final ValueChanged<String?> onPrivacidadChanged;
  final bool wrap;

  const _FiltersRow({
    required this.filtroMateria,
    required this.filtroSeccion,
    required this.filtroPrivacidad,
    required this.onClearMateria,
    required this.onClearSeccion,
    required this.onPrivacidadChanged,
    required this.wrap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _FilterBtn(label: 'Filtrar materias', icon: Icons.tune_rounded),
      _FilterBtn(label: 'Sección', icon: Icons.school_outlined),
      // Filtro de privacidad
      _PrivacidadFilterBtn(
        valor: filtroPrivacidad,
        onChanged: onPrivacidadChanged,
      ),
      if (filtroMateria != null)
        _ActiveChip(label: filtroMateria!, onRemove: onClearMateria),
      if (filtroSeccion != null)
        _ActiveChip(label: filtroSeccion!, onRemove: onClearSeccion),
      if (filtroPrivacidad != null)
        _ActiveChip(
          label: filtroPrivacidad == 'privado' ? 'Privados' : 'Públicos',
          onRemove: () => onPrivacidadChanged(null),
          color: filtroPrivacidad == 'privado'
              ? const Color(0xFFFFF3E0)
              : const Color(0xFFE8F5E9),
          borderColor: filtroPrivacidad == 'privado'
              ? const Color(0xFFFFCC80)
              : const Color(0xFFA5D6A7),
          textColor: filtroPrivacidad == 'privado'
              ? const Color(0xFFE65100)
              : const Color(0xFF2E7D32),
        ),
    ];

    if (wrap) {
      return Wrap(spacing: 8, runSpacing: 8, children: children);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children
            .map((c) =>
                Padding(padding: const EdgeInsets.only(right: 8), child: c))
            .toList(),
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FilterBtn({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3BFB1)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: const Color(0xFF757575)),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.lexend(
                fontSize: 13, color: const Color(0xFF424242))),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down_rounded,
            size: 15, color: Color(0xFF757575)),
      ]),
    );
  }
}

class _PrivacidadFilterBtn extends StatelessWidget {
  final String? valor;
  final ValueChanged<String?> onChanged;
  const _PrivacidadFilterBtn({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isActive = valor != null;
    return PopupMenuButton<String>(
      onSelected: (v) => onChanged(v == 'todos' ? null : v),
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'todos',
          child: Row(children: [
            Icon(Icons.apps_rounded, size: 16, color: const Color(0xFF757575)),
            const SizedBox(width: 8),
            Text('Todos', style: GoogleFonts.lexend(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'publico',
          child: Row(children: [
            Icon(Icons.lock_open_outlined, size: 16, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text('Públicos', style: GoogleFonts.lexend(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'privado',
          child: Row(children: [
            Icon(Icons.lock_rounded, size: 16, color: const Color(0xFFE65100)),
            const SizedBox(width: 8),
            Text('Privados', style: GoogleFonts.lexend(fontSize: 13)),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: valor == 'publico'
              ? const Color(0xFFE8F5E9)
              : valor == 'privado'
                  ? const Color(0xFFFFF3E0)
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: valor == 'publico'
                ? const Color(0xFFA5D6A7)
                : valor == 'privado'
                    ? const Color(0xFFE65100)
                    : const Color(0xFFE3BFB1),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            valor == 'privado' ? Icons.lock_rounded : Icons.lock_open_outlined,
            size: 15,
            color: valor == 'publico'
                ? const Color(0xFF2E7D32)
                : valor == 'privado'
                    ? const Color(0xFFE65100)
                    : const Color(0xFF757575),
          ),
          const SizedBox(width: 6),
          Text(
            valor == null
                ? 'Privacidad'
                : valor == 'privado'
                    ? 'Privados'
                    : 'Públicos',
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: valor == 'publico'
                  ? const Color(0xFF2E7D32)
                  : valor == 'privado'
                      ? const Color(0xFFE65100)
                      : const Color(0xFF424242),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 15,
            color: valor == 'publico'
                ? const Color(0xFF2E7D32)
                : valor == 'privado'
                    ? const Color(0xFFE65100)
                    : const Color(0xFF757575),
          ),
        ]),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Color color;
  final Color borderColor;
  final Color textColor;
  const _ActiveChip({
    required this.label,
    required this.onRemove,
    this.color = const Color(0xFFE8F5E9),
    this.borderColor = const Color(0xFFA5D6A7),
    this.textColor = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: GoogleFonts.lexend(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close_rounded, size: 13, color: textColor),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID DE GRUPOS
// ═══════════════════════════════════════════════════════════════════════════

class _GruposGrid extends StatelessWidget {
  final List<_GrupoData> grupos;
  final int columns;
  final VoidCallback onCrear;

  const _GruposGrid(
      {required this.grupos, required this.columns, required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final total = grupos.length + 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: total,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: columns == 1 ? double.infinity : 290,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: columns == 1 ? 1.7 : 0.85,
      ),
      itemBuilder: (_, i) {
        if (i == grupos.length) return _CrearCard(onTap: onCrear);
        return _GrupoCard(grupo: grupos[i]);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO GRUPO
// ═══════════════════════════════════════════════════════════════════════════

class _GrupoData {
  final String id;
  final String nombre;
  final String descripcion;
  final int miembros;
  final int max;
  final String materia;
  final int seccion;
  final String? fotoUrl;
  final bool esPrivado;
  final String? creadoPor;

  _GrupoData({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.miembros,
    required this.max,
    required this.materia,
    required this.seccion,
    this.fotoUrl,
    this.esPrivado = false,
    this.creadoPor,
  });

  factory _GrupoData.fromMap(Map<String, dynamic> map) {
    return _GrupoData(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre'] ?? 'Sin nombre',
      descripcion: map['descripcion'] ?? '',
      miembros: 0,
      max: map['max_miembros'] ?? 20,
      materia: map['materia'] ?? '',
      seccion: map['seccion'] is int
          ? map['seccion']
          : int.tryParse(map['seccion']?.toString() ?? '1') ?? 1,
      fotoUrl: map['foto_url'],
      esPrivado: map['es_privado'] == true,
      creadoPor: map['creado_por']?.toString(),
    );
  }

  IconData get icono {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc')) return Icons.calculate_outlined;
    if (m.contains('físic') || m.contains('fisic')) return Icons.bolt_outlined;
    if (m.contains('quím') || m.contains('quim')) return Icons.science_outlined;
    if (m.contains('dato') || m.contains('progr') || m.contains('comp') || m.contains('sistem')) return Icons.computer_outlined;
    if (m.contains('bio')) return Icons.biotech_outlined;
    if (m.contains('hist')) return Icons.history_edu_outlined;
    if (m.contains('econ') || m.contains('admin')) return Icons.bar_chart_outlined;
    return Icons.menu_book_outlined;
  }

  Color get iconBg {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc')) return const Color(0xFFFFF3E0);
    if (m.contains('físic') || m.contains('fisic')) return const Color(0xFFF3E5F5);
    if (m.contains('quím') || m.contains('quim')) return const Color(0xFFE8F5E9);
    if (m.contains('dato') || m.contains('progr') || m.contains('comp') || m.contains('sistem')) return const Color(0xFFE3F2FD);
    if (m.contains('bio')) return const Color(0xFFE0F7FA);
    if (m.contains('hist')) return const Color(0xFFFBE9E7);
    if (m.contains('econ') || m.contains('admin')) return const Color(0xFFF9FBE7);
    return const Color(0xFFF5F5F5);
  }

  Color get iconColor {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc')) return const Color(0xFFE65100);
    if (m.contains('físic') || m.contains('fisic')) return const Color(0xFF6A1B9A);
    if (m.contains('quím') || m.contains('quim')) return const Color(0xFF2E7D32);
    if (m.contains('dato') || m.contains('progr') || m.contains('comp') || m.contains('sistem')) return const Color(0xFF1565C0);
    if (m.contains('bio')) return const Color(0xFF00695C);
    if (m.contains('hist')) return const Color(0xFFBF360C);
    if (m.contains('econ') || m.contains('admin')) return const Color(0xFF558B2F);
    return const Color(0xFF616161);
  }

  String get seccionLabel => 'Sec $seccion';
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA GRUPO
// ═══════════════════════════════════════════════════════════════════════════

class _GrupoCard extends StatelessWidget {
  final _GrupoData grupo;
  const _GrupoCard({required this.grupo});

  Future<void> _manejarUnirse(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (grupo.esPrivado) {
      // Mostrar diálogo de solicitud
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFE65100), size: 20),
            const SizedBox(width: 8),
            Text('Grupo privado',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          content: Text(
            'Este grupo requiere aprobación del administrador. ¿Deseas enviar una solicitud para unirte a "${grupo.nombre}"?',
            style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF424242)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.lexend(color: const Color(0xFF757575))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 15),
              label: Text('Solicitar', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      try {
        await supabase.from('solicitudes_grupo').insert({
          'grupo_id': grupo.id,
          'usuario_id': userId,
          'estado': 'pendiente',
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Solicitud enviada. El administrador la revisará pronto.',
              style: GoogleFonts.lexend(color: Colors.white),
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        // Si el error es por duplicado (unique constraint), avisar al usuario
        final msg = e.toString().contains('duplicate') || e.toString().contains('unique')
            ? 'Ya tienes una solicitud pendiente para este grupo.'
            : 'Error al enviar la solicitud: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(msg, style: GoogleFonts.lexend(color: Colors.white)),
          ),
        );
      }
    } else {
      // Lógica de unirse a grupo público (tu implementación existente)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: grupo.esPrivado
              ? const Color(0xFFFFCC80)
              : const Color(0xFFF0EAE6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                    color: grupo.iconBg,
                    borderRadius: BorderRadius.circular(16)),
                child: grupo.fotoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          grupo.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(grupo.icono, color: grupo.iconColor, size: 30),
                        ),
                      )
                    : Icon(grupo.icono, color: grupo.iconColor, size: 30),
              ),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                // Badge de privacidad
                if (grupo.esPrivado)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_rounded,
                          size: 11, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text('Privado',
                          style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: const Color(0xFFE65100),
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                _MiniTag(
                    label: grupo.materia,
                    bg: const Color(0xFFE8F5E9),
                    fg: const Color(0xFF2E7D32)),
                const SizedBox(height: 4),
                _MiniTag(
                    label: grupo.seccionLabel,
                    bg: const Color(0xFFF5F5F5),
                    fg: const Color(0xFF757575)),
              ]),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Text(grupo.nombre,
                    style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              if (grupo.esPrivado) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Requiere aprobación del administrador',
                  child: const Icon(Icons.lock_rounded,
                      size: 16, color: Color(0xFFE65100)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Expanded(
              child: Text(grupo.descripcion,
                  style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: const Color(0xFF8A8A8A),
                      height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
            Row(children: [
              _AvatarStack(count: grupo.miembros.clamp(1, 4)),
              const SizedBox(width: 8),
              Flexible(
                child: Text('${grupo.miembros} / ${grupo.max} miembros',
                    style: GoogleFonts.lexend(
                        fontSize: 11, color: const Color(0xFF9E9E9E)),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 5, runSpacing: 5, children: [
              _MiniTag(
                  label: grupo.seccionLabel,
                  bg: const Color(0xFFF5F5F5),
                  fg: const Color(0xFF757575)),
              _MiniTag(
                  label: grupo.materia,
                  bg: const Color(0xFFF5F5F5),
                  fg: const Color(0xFF757575)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _manejarUnirse(context),
                icon: Icon(
                  grupo.esPrivado ? Icons.send_rounded : Icons.login_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                label: Text(
                  grupo.esPrivado ? 'Solicitar unirse' : 'Unirse',
                  style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: grupo.esPrivado
                      ? const Color(0xFFE65100)
                      : const Color(0xFF2E5900),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA CREAR
// ═══════════════════════════════════════════════════════════════════════════

class _CrearCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CrearCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRectPainter(color: const Color(0xFFD7CCC8)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5), shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF9E9E9E), size: 24),
            ),
            const SizedBox(height: 12),
            Text('Crear un grupo',
                style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121))),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '¿No puedes encontrar un grupo de tu clase? Crea uno e invita a tus amigos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: const Color(0xFFAFA49C),
                    height: 1.45),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  static const _colors = [
    Color(0xFFB0BEC5),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFCC80),
  ];

  @override
  Widget build(BuildContext context) {
    final n = count.clamp(1, 4);
    return SizedBox(
      width: n * 17.0 + 8,
      height: 26,
      child: Stack(
        children: List.generate(
            n,
            (i) => Positioned(
                  left: i * 16.0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                )),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _MiniTag({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: GoogleFonts.lexend(
              fontSize: 11, color: fg, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIÁLOGO CREAR GRUPO
// ═══════════════════════════════════════════════════════════════════════════

class _CrearGrupoDialog extends StatefulWidget {
  const _CrearGrupoDialog();

  @override
  State<_CrearGrupoDialog> createState() => _CrearGrupoDialogState();
}

class _CrearGrupoDialogState extends State<_CrearGrupoDialog> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lexend(fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0D8D2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0D8D2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text('Crear nuevo grupo',
                          style: GoogleFonts.lexend(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A)))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints()),
                ]),
                const SizedBox(height: 20),
                TextField(
                    controller: _nombreCtrl,
                    style: GoogleFonts.lexend(fontSize: 14),
                    decoration:
                        _dec('Nombre del grupo', icon: Icons.group_outlined)),
                const SizedBox(height: 14),
                TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.lexend(fontSize: 14),
                    decoration: _dec('Descripción')),
                const SizedBox(height: 14),
                TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.lexend(fontSize: 14),
                    decoration: _dec('Máximo de miembros',
                        icon: Icons.people_outline)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0D8D2)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: Text('Cancelar',
                          style: GoogleFonts.lexend(
                              color: const Color(0xFF616161))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: Text('Crear grupo',
                          style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEDE8E3)))),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 48, vertical: 28),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _brand(),
              const SizedBox(height: 16),
              _links(wrap: true),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: _brand()),
              _links(wrap: false),
            ]),
    );
  }

  Widget _brand() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('U-NITE',
              style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF245000))),
          const SizedBox(height: 2),
          Text('© 2024 U-NITE Campus Marketplace. All rights reserved.',
              style: GoogleFonts.lexend(
                  fontSize: 11, color: const Color(0xFF9E9E9E))),
        ],
      );

  Widget _links({required bool wrap}) {
    const labels = [
      'Privacy Policy',
      'Terms of Service',
      'Campus Safety',
      'Contact Support'
    ];
    final widgets = labels
        .map((l) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(l,
                  style: GoogleFonts.lexend(
                      fontSize: 13, color: const Color(0xFF616161))),
            ))
        .toList();
    return wrap
        ? Wrap(children: widgets)
        : Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }
}