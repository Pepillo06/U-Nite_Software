import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/unite_header.dart';
import 'crear_grupos.dart';
import 'studymatch_chat.dart';
import 'public_profile_page.dart';

String normalizarTexto(String texto) {
  if (texto.isEmpty) return '';

  // 1. Forzar a mayúsculas y quitar espacios al inicio/final
  String t = texto.trim().toUpperCase();

  // 2. Limpiar TODAS las variaciones de vocales con tildes usando RegExp
  t = t
      .replaceAll(RegExp(r'[ÁÀÂÄ]'), 'A')
      .replaceAll(RegExp(r'[ÉÈÊË]'), 'E')
      .replaceAll(RegExp(r'[ÍÌÎÏ]'), 'I')
      .replaceAll(RegExp(r'[ÓÒÔÖ]'), 'O')
      .replaceAll(RegExp(r'[ÚÙÛÜ]'), 'U');

  // 3. Limpiar espacios múltiples o saltos de línea intermedios
  t = t.replaceAll(RegExp(r'\s+'), ' ');

  // 4. Diccionario extendido (incluye errores comunes como "ll" en vez de "II")
  final equivalencias = {
    ' VIII': ' 8',
    ' VII': ' 7',
    ' III': ' 3',
    ' LLL': ' 3', // Error de tipeo común (L minúscula)
    ' II': ' 2',
    ' LL': ' 2', // Error de tipeo común (L minúscula)
    ' IV': ' 4',
    ' VI': ' 6',
    ' IX': ' 9',
    ' I': ' 1',
    ' L': ' 1', // Error de tipeo común (L minúscula)
    ' V': ' 5',
    ' X': ' 10',
    ' CUATRO': ' 4',
    ' TRES': ' 3',
    ' DOS': ' 2',
    ' UNO': ' 1',
  };

  // 5. Reemplazo seguro exacto al final del texto
  for (var entrada in equivalencias.entries) {
    if (t.endsWith(entrada.key)) {
      t = t.substring(0, t.length - entrada.key.length) + entrada.value;
      break;
    }
  }

  return t;
}

class StudymatchPage extends StatefulWidget {
  final String? grupoInicialId;

  const StudymatchPage({super.key, this.grupoInicialId});

  @override
  State<StudymatchPage> createState() => _StudymatchPageState();
}

class _StudymatchPageState extends State<StudymatchPage> {
  int _selectedTab = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filtroMateria;
  String? _filtroSeccion;
  String? _filtroTipo; // null = todos, 'mis_grupos', 'grupos_publicos'

  String?
  _filtroPrivacidad; // null = todos, 'publico' = públicos, 'privado' = privados

  List<_GrupoData> _grupos = [];
  bool _isLoading = true;
  // IDs de grupos donde el usuario es miembro (para tab "Mis Grupos")
  Set<String> _misGruposIds = {};
  String? _miUniversidad;

  // ─── PERSONAS ────────────────────────────────────────────────────────────
  List<_PersonaData> _estudiantes = [];
  List<_PersonaData> _amigos = [];
  List<_SolicitudData> _solicitudesPendientes = [];
  Set<String> _misAmigosIds = {};
  bool _isLoadingPersonas = false;
  // ─── SOLICITUDES DE GRUPO ────────────────────────────────────────────────
  List<_SolicitudGrupoData> _solicitudesGrupo = [];
  bool _isLoadingSolicitudesGrupo = false;
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // 1. Cargar todos los grupos
      final response = await supabase
          .from('grupos_estudio')
          .select(
            'id, nombre, descripcion, materia, seccion, max_miembros, es_privado, foto_url, creado_por',
          );

      // 2. Cargar grupos donde el usuario es miembro (a través de participantes_sala → salas_chat → grupos_estudio)
      Set<String> misIds = {};
      if (userId != null) {
        // Grupos creados por el usuario
        for (final row in (response as List)) {
          if (row['creado_por']?.toString() == userId) {
            misIds.add(row['id'].toString());
          }
        }
        // Grupos donde el usuario es participante de la sala asociada
        try {
          final participaciones = await supabase
              .from('participantes_sala')
              .select('sala_id')
              .eq('usuario_id', userId);
          final salaIds = participaciones
              .map((p) => p['sala_id'].toString())
              .toSet();
          if (salaIds.isNotEmpty) {
            final salas = await supabase
                .from('salas_chat')
                .select('id, nombre')
                .inFilter('id', salaIds.toList());
            final nombresSalas = salas
                .map((s) => s['nombre'].toString().trim().toLowerCase())
                .toSet();
            for (final row in (response as List)) {
              final nombre = (row['nombre'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              if (nombresSalas.contains(nombre)) {
                misIds.add(row['id'].toString());
              }
            }
          }
        } catch (_) {}
      }

      // 3. Contar miembros por grupo (via participantes_sala)
      final Map<String, int> conteoMiembros = {};
      try {
        final participantes = await supabase
            .from('participantes_sala')
            .select('sala_id');
        // Agrupa por sala_id para contar
        final Map<String, int> porSala = {};
        for (final p in (participantes as List)) {
          final sid = p['sala_id'].toString();
          porSala[sid] = (porSala[sid] ?? 0) + 1;
        }
        // Mapear sala → grupo por nombre
        final salas = await supabase.from('salas_chat').select('id, nombre');
        final Map<String, String> salaNameToId = {};
        for (final s in (salas as List)) {
          salaNameToId[s['nombre'].toString().trim().toLowerCase()] = s['id']
              .toString();
        }
        for (final row in (response as List)) {
          final nombre = (row['nombre'] ?? '').toString().trim().toLowerCase();
          final salaId = salaNameToId[nombre];
          if (salaId != null) {
            conteoMiembros[row['id'].toString()] = porSala[salaId] ?? 0;
          }
        }
      } catch (_) {}

      // 1. Obtener la universidad del usuario actual (se cachea en _miUniversidad)
      if (userId != null && _miUniversidad == null) {
        final userData = await supabase
            .from('usuarios')
            .select('universidad')
            .eq('id', userId)
            .single();
        _miUniversidad = userData['universidad'] as String?;
      }

      // 2. Obtener los IDs de todos los usuarios de la misma universidad
      List<String> idsCreadores = [];
      if (_miUniversidad != null) {
        final usuariosResp = await supabase
            .from('usuarios')
            .select('id')
            .eq('universidad', _miUniversidad!);
        idsCreadores = (usuariosResp as List)
            .map((u) => u['id'].toString())
            .toList();
      }

      // 3. Traer solo los grupos creados por usuarios de esa universidad
      // (con conteo de miembros incluido)
      List<_GrupoData> grupos = [];
      if (idsCreadores.isNotEmpty) {
        final responseUniv = await supabase
            .from('grupos_estudio')
            .select(
              'id, nombre, descripcion, materia, seccion, max_miembros, es_privado, foto_url, creado_por',
            )
            .inFilter('creado_por', idsCreadores);

        grupos = (responseUniv as List).map((row) {
          final gid = row['id'].toString();
          return _GrupoData.fromMap(
            row,
            miembrosCount: conteoMiembros[gid] ?? 0,
          );
        }).toList();
      }

      if (mounted) {
        setState(() {
          _grupos = grupos;
          _misGruposIds = misIds;
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

  // ─── SOLICITUDES DE GRUPO ────────────────────────────────────────────────
  Future<void> _cargarSolicitudesGrupo() async {
    if (_isLoadingSolicitudesGrupo) return;
    setState(() => _isLoadingSolicitudesGrupo = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoadingSolicitudesGrupo = false);
        return;
      }
      // Traer solicitudes pendientes de grupos creados por el usuario actual
      final resp = await supabase
          .from('solicitudes_grupo')
          .select(
            'id, grupo_id, usuario_id, estado, creado_en',
          )
          .eq('estado', 'pendiente');

      // Filtrar sólo los grupos que el usuario creó
      final misGruposCreados = _grupos
          .where((g) => g.creadoPor == userId)
          .map((g) => g.id)
          .toSet();

      final solicitudesFiltradas = (resp as List)
          .where((r) => misGruposCreados.contains(r['grupo_id']?.toString()))
          .toList();

      // Cargar datos de usuario y grupo para cada solicitud
      final List<_SolicitudGrupoData> lista = [];
      for (final row in solicitudesFiltradas) {
        final solicitanteId = row['usuario_id']?.toString() ?? '';
        final grupoId = row['grupo_id']?.toString() ?? '';

        // Datos del solicitante
        Map<String, dynamic>? userData;
        try {
          userData = await supabase
              .from('usuarios')
              .select(
                'id, primer_nombre, primer_apellido, foto_perfil_url, carrera',
              )
              .eq('id', solicitanteId)
              .single();
        } catch (_) {}

        // Nombre del grupo
        final grupoData = _grupos.firstWhere(
          (g) => g.id == grupoId,
          orElse: () => _GrupoData(
            id: grupoId,
            nombre: 'Grupo',
            descripcion: '',
            miembros: 0,
            max: 0,
            materia: '',
          ),
        );

        if (userData != null) {
          lista.add(
            _SolicitudGrupoData(
              solicitudId: row['id']?.toString() ?? '',
              grupoId: grupoId,
              nombreGrupo: grupoData.nombre,
              solicitante: _PersonaData.fromMap(userData),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _solicitudesGrupo = lista;
          _isLoadingSolicitudesGrupo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSolicitudesGrupo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error al cargar solicitudes: $e'),
          ),
        );
      }
    }
  }

  Future<void> _aceptarSolicitudGrupo(String solicitudId, String grupoId, String solicitanteId) async {
    final supabase = Supabase.instance.client;
    try {
      // 1. Actualizar estado de la solicitud a 'aceptado'
      await supabase
          .from('solicitudes_grupo')
          .update({'estado': 'aceptado'})
          .eq('id', solicitudId);

      // 2. Obtener la sala de chat asociada al grupo
      final grupo = _grupos.firstWhere((g) => g.id == grupoId, orElse: () => _GrupoData(id: '', nombre: '', descripcion: '', miembros: 0, max: 0, materia: ''));
      if (grupo.id.isEmpty) return;

      final salas = await supabase
          .from('salas_chat')
          .select('id')
          .eq('nombre', grupo.nombre)
          .eq('creado_por', grupo.creadoPor ?? '');

      if ((salas as List).isNotEmpty) {
        final salaId = salas.first['id'].toString();
        // 3. Agregar al usuario como participante de la sala
        await supabase.from('participantes_sala').upsert({
          'sala_id': salaId,
          'usuario_id': solicitanteId,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Solicitud aceptada. El usuario ya puede acceder al grupo.',
            style: GoogleFonts.lexend(color: Colors.white),
          ),
        ),
      );
      // Recargar la lista
      _cargarSolicitudesGrupo();
      _cargarGrupos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD32F2F),
          content: Text('Error al aceptar solicitud: $e'),
        ),
      );
    }
  }

  Future<void> _rechazarSolicitudGrupo(String solicitudId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('solicitudes_grupo')
          .update({'estado': 'rechazado'})
          .eq('id', solicitudId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF757575),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Solicitud rechazada.',
            style: GoogleFonts.lexend(color: Colors.white),
          ),
        ),
      );
      _cargarSolicitudesGrupo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD32F2F),
          content: Text('Error al rechazar solicitud: $e'),
        ),
      );
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  void _restablecerFiltros() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _filtroMateria = null;
      _filtroSeccion = null;
      _filtroPrivacidad = null;
      _filtroTipo = null;
    });
  }

  // ─── CARGA DE PERSONAS ───────────────────────────────────────────────────
  Future<void> _cargarEstudiantes() async {
    if (_isLoadingPersonas) return;
    setState(() => _isLoadingPersonas = true);
    try {
      final supabase = Supabase.instance.client;
      final miId = supabase.auth.currentUser?.id;

      // Obtener la universidad del usuario actual si aún no está cacheada
      if (miId != null && _miUniversidad == null) {
        final userData = await supabase
            .from('usuarios')
            .select('universidad')
            .eq('id', miId)
            .single();
        _miUniversidad = userData['universidad'] as String?;
      }

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

      // Traer solo estudiantes de la misma universidad, excluyendo al usuario actual
      var query = supabase
          .from('usuarios')
          .select(
            'id, primer_nombre, primer_apellido, foto_perfil_url, carrera, universidad',
          )
          .neq('id', miId ?? '')
          .eq('es_estudiante', true);

      final response = _miUniversidad != null
          ? await query.eq('universidad', _miUniversidad!)
          : await query;

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
          .select(
            'id, usuario_id ( id, primer_nombre, primer_apellido, foto_perfil_url, carrera )',
          )
          .eq('amigo_id', miId)
          .eq('estado', 'pendiente');

      // Amigos aceptados (ambos lados)
      final amigosResp = await supabase
          .from('amigos')
          .select(
            'estado, amigo_id ( id, primer_nombre, primer_apellido, foto_perfil_url, carrera )',
          )
          .eq('usuario_id', miId)
          .eq('estado', 'aceptados');

      final amigosResp2 = await supabase
          .from('amigos')
          .select(
            'estado, usuario_id ( id, primer_nombre, primer_apellido, foto_perfil_url, carrera )',
          )
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
        listaAmigosConComun.add(
          _PersonaData(
            id: amigo.id,
            nombre: amigo.nombre,
            apellido: amigo.apellido,
            fotoPerfil: amigo.fotoPerfil,
            carrera: amigo.carrera,
            universidad: amigo.universidad,
            amigosEnComun: enComun,
          ),
        );
      }

      final List<_SolicitudData> solicitudes = [];
      for (final row in (solicitudesResp as List)) {
        final data = row['usuario_id'];
        if (data != null) {
          solicitudes.add(
            _SolicitudData(
              solicitudId: row['id'].toString(),
              persona: _PersonaData.fromMap(data),
            ),
          );
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
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error: $e'),
          ),
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
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error: $e'),
          ),
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
      // Reglas de pestañas (Mis grupos vs Públicos)
      // Tab 1 = Mis Grupos: grupos donde el usuario es creador O miembro
      // Tab 2 = Grupos Públicos: grupos donde el usuario NO es miembro
      final esMiembro = _misGruposIds.contains(g.id);
      if (_selectedTab == 1 && !esMiembro) return false;
      if (_selectedTab == 2 && esMiembro) return false;

      // 1. Búsqueda por texto en Nombre o Descripción
      final matchSearch =
          _searchQuery.isEmpty ||
          g.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Filtro de Materia
      final matchMateria =
          _filtroMateria == null ||
          g.materia.toLowerCase().contains(_filtroMateria!.toLowerCase());

      // 3. Filtro de Sección
      final matchSeccion =
          _filtroSeccion == null ||
          'Sec ${g.seccion}'.toLowerCase().contains(
            _filtroSeccion!.toLowerCase(),
          ) ||
          g.seccion.toString() == _filtroSeccion;

      // 4. Filtro de Privacidad
      final matchPrivacidad =
          _filtroPrivacidad == null ||
          (_filtroPrivacidad == 'privado' ? g.esPrivado : !g.esPrivado);
      return matchSearch && matchMateria && matchSeccion && matchPrivacidad;
    }).toList();
  }

  Widget _buildContent({required bool isMobile, required bool isTablet}) {
    // ─── TABS DE PERSONAS ────────────────────────────────────────────────
    if (_selectedTab == 5) {
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
    if (_selectedTab == 6) {
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
    // ─── TAB SOLICITUDES DE GRUPO ────────────────────────────────────────
    if (_selectedTab == 3) {
      return _SolicitudesGrupoContent(
        isMobile: isMobile,
        solicitudesGrupo: _solicitudesGrupo,
        isLoading: _isLoadingSolicitudesGrupo,
        onAceptar: _aceptarSolicitudGrupo,
        onRechazar: _rechazarSolicitudGrupo,
      );
    }
    // ────────────────────────────────────────────────────────────────────

    final gridCols = isMobile
        ? 1
        : isTablet
        ? 2
        : 3;

    // 🔥 AQUÍ SE CORRIGE LA EXTRACCIÓN DE MATERIAS Y SECCIONES:
    final List<String> materiasUnicas =
        _grupos
            .map((g) => g.materia) // Extraemos solo el String de la materia
            .where((m) => m.isNotEmpty) // Filtramos textos vacíos por seguridad
            .toSet() // Eliminamos duplicados
            .toList()
          ..sort(); // Ordenamos alfabéticamente

    final List<String> seccionesUnicas =
        _grupos
            .map(
              (g) => g.seccion.toString(),
            ) // Extraemos solo la sección como String
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile
            ? Column(
                children: [
                  _SearchBar(
                    hintText: 'Buscar grupos',
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: _CreateButton(onTap: _showCreateDialog),
                  ),
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
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const Spacer(),
                  _CreateButton(onTap: _showCreateDialog),
                ],
              ),
        const SizedBox(height: 24),

        // ─── FILTROS ───────────────────────────────────────────────────────
        _FiltersRow(
          filtroMateria: _filtroMateria,
          filtroSeccion: _filtroSeccion,
          filtroPrivacidad: _filtroPrivacidad,
          filtroTipo: _filtroTipo,
          listaMaterias: materiasUnicas,
          listaSecciones: seccionesUnicas,
          onClearMateria: () => setState(() => _filtroMateria = null),
          onClearSeccion: () => setState(() => _filtroSeccion = null),
          onPrivacidadChanged: (v) => setState(() => _filtroPrivacidad = v),
          onTipoChanged: (v) => setState(() => _filtroTipo = v),
          onMateriaChanged: (v) => setState(() => _filtroMateria = v),
          onSeccionChanged: (v) => setState(() => _filtroSeccion = v),
          onRestablecer: _restablecerFiltros,
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
                onCrear: _showCreateDialog,
                misGruposIds: _misGruposIds,
                onEliminar: _eliminarGrupo,
              ),
      ],
    );
  }

  bool get _isPersonasTab => _selectedTab >= 4 && _selectedTab <= 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      appBar: const UniteHeader(currentIndex: 4),
      body: LayoutBuilder(
        builder: (context, constraints) {
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
                    horizontal: isMobile
                        ? 16
                        : isTablet
                        ? 24
                        : 48,
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
                                  isMobile: false,
                                  isTablet: false,
                                ),
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
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                          ],
                        ),
                ),
                const _Footer(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onTabSelect(int i) {
    // Al tocar el header "Personas", ir directo a "Amigos"
    final tab = (i == 4) ? 5 : i;
    setState(() => _selectedTab = tab);
    if (tab == 5) _cargarAmigos();
    if (tab == 6) _cargarEstudiantes();
    if (tab == 3) _cargarSolicitudesGrupo();
  }

  void _showCreateDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearGrupoPage()),
    );
    _cargarGrupos();
  }

  Future<void> _eliminarGrupo(_GrupoData grupo) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || grupo.creadoPor != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD32F2F),
          content: Text(
            'Solo el creador puede eliminar este grupo.',
            style: GoogleFonts.lexend(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar grupo',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Eliminar "${grupo.nombre}" permanentemente? Se borrarán los mensajes del chat.',
          style: GoogleFonts.lexend(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lexend(color: const Color(0xFF757575)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.lexend(
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final supabase = Supabase.instance.client;
    try {
      final salas = await supabase
          .from('salas_chat')
          .select('id')
          .eq('nombre', grupo.nombre)
          .eq('creado_por', userId);

      for (final sala in (salas as List)) {
        final salaId = sala['id'].toString();
        await supabase.from('mensajes_chat').delete().eq('sala_id', salaId);
        await supabase
            .from('participantes_sala')
            .delete()
            .eq('sala_id', salaId);
        await supabase.from('salas_chat').delete().eq('id', salaId);
      }

      await supabase.from('grupos_estudio').delete().eq('id', grupo.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Grupo "${grupo.nombre}" eliminado.',
            style: GoogleFonts.lexend(color: Colors.white),
          ),
        ),
      );
      _cargarGrupos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD32F2F),
          content: Text('Error al eliminar: $e'),
        ),
      );
    }
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

  factory _PersonaData.fromMap(
    Map<String, dynamic> map, {
    int amigosEnComun = 0,
  }) {
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

class _SolicitudGrupoData {
  final String solicitudId;
  final String grupoId;
  final String nombreGrupo;
  final _PersonaData solicitante;
  _SolicitudGrupoData({
    required this.solicitudId,
    required this.grupoId,
    required this.nombreGrupo,
    required this.solicitante,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTENIDO SOLICITUDES DE GRUPO
// ═══════════════════════════════════════════════════════════════════════════

class _SolicitudesGrupoContent extends StatelessWidget {
  final bool isMobile;
  final List<_SolicitudGrupoData> solicitudesGrupo;
  final bool isLoading;
  final Future<void> Function(String solicitudId, String grupoId, String solicitanteId) onAceptar;
  final Future<void> Function(String solicitudId) onRechazar;

  const _SolicitudesGrupoContent({
    required this.isMobile,
    required this.solicitudesGrupo,
    required this.isLoading,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
              'Solicitudes de Unión a Mis Grupos',
              style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            if (solicitudesGrupo.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${solicitudesGrupo.length}',
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Aquí aparecen las solicitudes de personas que quieren unirse a tus grupos privados.',
          style: GoogleFonts.lexend(
            fontSize: 13,
            color: const Color(0xFF9E9E9E),
          ),
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: Color(0xFFE65100)),
            ),
          )
        else if (solicitudesGrupo.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFD7CCC8)),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes solicitudes pendientes.',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: solicitudesGrupo
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SolicitudGrupoCard(
                      solicitud: s,
                      isMobile: isMobile,
                      onAceptar: () => onAceptar(s.solicitudId, s.grupoId, s.solicitante.id),
                      onRechazar: () => onRechazar(s.solicitudId),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _SolicitudGrupoCard extends StatefulWidget {
  final _SolicitudGrupoData solicitud;
  final bool isMobile;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  const _SolicitudGrupoCard({
    required this.solicitud,
    required this.isMobile,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  State<_SolicitudGrupoCard> createState() => _SolicitudGrupoCardState();
}

class _SolicitudGrupoCardState extends State<_SolicitudGrupoCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.solicitud.solicitante;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          _Avatar(url: p.fotoPerfil, nombre: p.nombreCompleto, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombreCompleto,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                if ((p.carrera ?? '').isNotEmpty)
                  Text(
                    p.carrera!,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFE65100)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Quiere unirse a: ${widget.solicitud.nombreGrupo}',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE65100),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Rechazar
                GestureDetector(
                  onTap: () async {
                    setState(() => _loading = true);
                    await Future.microtask(widget.onRechazar);
                    if (mounted) setState(() => _loading = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Text(
                      'Rechazar',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón Aceptar
                GestureDetector(
                  onTap: () async {
                    setState(() => _loading = true);
                    await Future.microtask(widget.onAceptar);
                    if (mounted) setState(() => _loading = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Aceptar',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
    final gridCols = isMobile
        ? 1
        : isTablet
        ? 2
        : 4;

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
                  SizedBox(width: double.infinity, child: _AgregarButton()),
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
    final amigosFiltrados = amigos
        .where(
          (p) =>
              searchQuery.isEmpty ||
              p.nombreCompleto.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (p.carrera ?? '').toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Solicitudes pendientes
        if (solicitudes.isNotEmpty) ...[
          Row(
            children: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
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
            ],
          ),
          const SizedBox(height: 14),
          isMobile
              ? Column(
                  children: solicitudes
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SolicitudCard(
                            solicitud: s,
                            onAceptar: onAceptar,
                            onRechazar: onRechazar,
                          ),
                        ),
                      )
                      .toList(),
                )
              : Row(
                  children: solicitudes
                      .take(3)
                      .map(
                        (s) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _SolicitudCard(
                              solicitud: s,
                              onAceptar: onAceptar,
                              onRechazar: onRechazar,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
          const SizedBox(height: 28),
        ],

        // Mis amigos
        Row(
          children: [
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
          ],
        ),
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
              ...amigosFiltrados.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PersonaCard(persona: p, esAmigo: true),
                ),
              ),
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
              return _PersonaCard(persona: amigosFiltrados[i], esAmigo: true);
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
    final filtrados = estudiantes
        .where(
          (p) =>
              searchQuery.isEmpty ||
              p.nombreCompleto.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (p.carrera ?? '').toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
        )
        .toList();

    if (filtrados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No se encontraron estudiantes.',
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ),
      );
    }

    if (gridCols == 1) {
      return Column(
        children: filtrados
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PersonaCard(
                  persona: p,
                  esAmigo: false,
                  onAgregar: onAgregar,
                ),
              ),
            )
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
                Text(
                  p.nombreCompleto,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                if ((p.carrera ?? '').isNotEmpty)
                  Text(
                    p.carrera!,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE65100),
              ),
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
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF2E7D32),
                  size: 18,
                ),
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
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF757575),
                  size: 18,
                ),
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
        label: Text(
          'Enviar Mensaje',
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF2E5900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
        child: Text(
          'Solicitud enviada',
          style: GoogleFonts.lexend(
            fontSize: 13,
            color: const Color(0xFF9E9E9E),
          ),
        ),
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
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.person_add_rounded, size: 15, color: Colors.white),
      label: Text(
        'Agregar',
        style: GoogleFonts.lexend(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFE65100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        MaterialPageRoute(builder: (_) => PublicProfilePage(userId: p.id)),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _Avatar(
                      url: p.fotoPerfil,
                      nombre: p.nombreCompleto,
                      radius: 26,
                    ),
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
                                const Icon(
                                  Icons.people_outlined,
                                  size: 12,
                                  color: Color(0xFF9E9E9E),
                                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Avatar
                    _Avatar(
                      url: p.fotoPerfil,
                      nombre: p.nombreCompleto,
                      radius: 24,
                    ),
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
                          const Icon(
                            Icons.people_outlined,
                            size: 13,
                            color: Color(0xFF9E9E9E),
                          ),
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
                    SizedBox(width: double.infinity, child: _buildButton()),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF9E9E9E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Invitar amigos',
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF212121),
                            ),
                          ),
                          Text(
                            'Comparte U-NITE con tus compañeros.',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: const Color(0xFFAFA49C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Color(0xFF9E9E9E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Invitar amigos',
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Comparte U-NITE con tus compañeros de curso.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: const Color(0xFFAFA49C),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
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
      backgroundImage: (url != null && url!.isNotEmpty)
          ? NetworkImage(url!)
          : null,
      child: (url == null || url!.isEmpty)
          ? Text(
              initials,
              style: GoogleFonts.lexend(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE65100),
              ),
            )
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/estudiantess.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 102, 0),
                    Color.fromARGB(255, 255, 125, 82),
                  ],
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
                  const Color.fromARGB(172, 205, 97, 39).withOpacity(0.92),
                  const Color(0xFF3E2723).withOpacity(0.65),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 48,
              vertical: 28,
            ),
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
        ],
      ),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
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
              horizontal: isMobile ? 20 : 48,
              vertical: 28,
            ),
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
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR NAV ITEM CON HOVER
// ═══════════════════════════════════════════════════════════════════════════

class _SidebarNavItem extends StatefulWidget {
  final _SI item;
  final int index;
  final bool isActive;
  final bool horizontal;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.index,
    required this.isActive,
    required this.horizontal,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isActive = widget.isActive;
    final horizontal = widget.horizontal;
    final compact = widget.compact;
    final isSubItem = !item.isHeader;

    // Colores según estado
    final Color textColor = isActive
        ? const Color(0xFFE65100)
        : _hovering
        ? const Color(0xFFE65100)
        : const Color(0xFF424242);

    final Color iconColor = isActive
        ? const Color(0xFFE65100)
        : _hovering
        ? const Color(0xFFE65100)
        : const Color(0xFF757575);

    final Color barColor = isActive
        ? const Color(0xFFE65100)
        : _hovering
        ? const Color(0xFFE65100).withOpacity(0.5)
        : const Color(0xFFD0C4BB);

    Color bgColor = Colors.transparent;
    if (isActive && !item.isHeader) {
      bgColor = const Color(0xFFEFE0D0);
    } else if (_hovering && !item.isHeader) {
      bgColor = const Color(0xFFEFE0D0).withOpacity(0.5);
    }

    Border? border;
    if (isActive && item.isHeader) {
      border = Border.all(color: const Color(0xFFE65100), width: 1.0);
    } else if (_hovering && item.isHeader) {
      border = Border.all(
        color: const Color(0xFFE65100).withOpacity(0.4),
        width: 1.0,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: horizontal ? null : 160,
          padding: horizontal
              ? EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 7 : 9,
                )
              : EdgeInsets.symmetric(
                  horizontal: isSubItem ? 12 : 10,
                  vertical: 9,
                ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(50),
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSubItem && !horizontal) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (item.icon != null) ...[
                Icon(item.icon, size: compact ? 15 : 17, color: iconColor),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: GoogleFonts.lexend(
                  fontSize: compact ? 12 : 14,
                  fontWeight: isActive || _hovering
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: textColor,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    _SI(icon: null, label: 'Solicitudes', isHeader: false),
    _SI(icon: Icons.people_alt_outlined, label: 'Personas', isHeader: true),
    _SI(icon: null, label: 'Amigos', isHeader: false),
    _SI(icon: null, label: 'Estudiantes', isHeader: false),
  ];

  @override
  Widget build(BuildContext context) {
    final bool showGruposSubItems = (selected >= 0 && selected <= 3);
    final bool showPersonasSubItems = (selected >= 4 && selected <= 6);

    Widget? gruposTile;
    final List<Widget> gruposSubTiles = [];
    Widget? personasTile;
    final List<Widget> personasSubTiles = [];

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final isSubItem = !item.isHeader;

      // Lógica de activación visual:
      final bool isActive = (i == 0)
          ? showGruposSubItems
          : (i == 4)
          ? showPersonasSubItems
          : (selected == i);

      final tile = _SidebarNavItem(
        item: item,
        index: i,
        isActive: isActive,
        horizontal: horizontal,
        compact: compact,
        onTap: () {
          if (i == 0 && showGruposSubItems) {
            onSelect(-1);
          } else if (i == 4 && showPersonasSubItems) {
            onSelect(-1);
          } else {
            onSelect(i); // Navegación/Apertura normal
          }
        },
      );

      final tileWithPadding = Padding(
        padding: horizontal
            ? const EdgeInsets.only(
                right: 8,
              ) // Separación un poco más amplia en el Row horizontal
            : const EdgeInsets.only(bottom: 2),
        child: tile,
      );

      if (i == 0) gruposTile = tileWithPadding;
      if (i == 1 || i == 2 || i == 3) gruposSubTiles.add(tileWithPadding);
      if (i == 4) personasTile = tileWithPadding;
      if (i == 5 || i == 6) personasSubTiles.add(tileWithPadding);
    }

    final List<Widget> tiles = [];

    // 1. Bloque de Grupos
    if (gruposTile != null) tiles.add(gruposTile);
    tiles.add(
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        child: ClipRect(
          child: showGruposSubItems
              ? (horizontal
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: gruposSubTiles,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: gruposSubTiles,
                      ))
              : (horizontal
                    ? const SizedBox(width: 0)
                    : const SizedBox(height: 0)),
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
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: personasSubTiles,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: personasSubTiles,
                      ))
              : (horizontal
                    ? const SizedBox(width: 0)
                    : const SizedBox(height: 0)),
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
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF212121)),
        decoration: InputDecoration(
          hintText: 'Buscar grupos',
          hintStyle: GoogleFonts.lexend(
            color: const Color(0xFFAFA49C),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFAFA49C),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
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
        label: Text(
          'Crear Grupo',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
        label: Text(
          'Agregar',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════
class _FiltersRow extends StatelessWidget {
  final String? filtroMateria;
  final String? filtroSeccion;
  final String? filtroPrivacidad;
  final String? filtroTipo;
  final List<String> listaMaterias;
  final List<String> listaSecciones;
  final VoidCallback onClearMateria;
  final VoidCallback onClearSeccion;
  final ValueChanged<String?> onPrivacidadChanged;
  final ValueChanged<String?> onTipoChanged;
  final ValueChanged<String?> onMateriaChanged;
  final ValueChanged<String?> onSeccionChanged;
  final VoidCallback onRestablecer;
  final bool wrap;

  const _FiltersRow({
    required this.filtroMateria,
    required this.filtroSeccion,
    required this.filtroPrivacidad,
    required this.filtroTipo,
    required this.listaMaterias,
    required this.listaSecciones,
    required this.onClearMateria,
    required this.onClearSeccion,
    required this.onPrivacidadChanged,
    required this.onTipoChanged,
    required this.onMateriaChanged,
    required this.onSeccionChanged,
    required this.onRestablecer,
    required this.wrap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      IconButton.filledTonal(
        icon: const Icon(Icons.refresh_rounded, color: Color(0xFFE65100)),
        tooltip: 'Restablecer todos los filtros',
        onPressed: onRestablecer,
        style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFF3E0)),
      ),

      // 📚 BOTÓN SEPARADO E INDEPENDIENTE PARA MATERIAS
      _MateriaFilterBtn(
        valor: filtroMateria,
        opciones: listaMaterias,
        onChanged: onMateriaChanged,
      ),

      // 🏫 BOTÓN SEPARADO E INDEPENDIENTE PARA SECCIONES
      _SeccionFilterBtn(
        valor: filtroSeccion,
        opciones: listaSecciones,
        onChanged: onSeccionChanged,
      ),

      _PrivacidadFilterBtn(
        valor: filtroPrivacidad,
        onChanged: onPrivacidadChanged,
      ),

      if (filtroMateria != null)
        _ActiveChip(label: filtroMateria!, onRemove: onClearMateria),
      if (filtroSeccion != null)
        _ActiveChip(label: 'Sec. $filtroSeccion', onRemove: onClearSeccion),
    ];

    if (wrap) {
      return Wrap(spacing: 8, runSpacing: 8, children: children);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children
            .map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(right: 8), child: c),
            )
            .toList(),
      ),
    );
  }
}

// 📚 COMPONENTE DESPLEGABLE: MATERIAS
class _MateriaFilterBtn extends StatelessWidget {
  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _MateriaFilterBtn({
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

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
          child: Row(
            children: [
              Icon(
                Icons.apps_rounded,
                size: 16,
                color: const Color(0xFF757575),
              ),
              const SizedBox(width: 8),
              Text(
                'Todas las materias',
                style: GoogleFonts.lexend(fontSize: 13),
              ),
            ],
          ),
        ),
        ...opciones.map(
          (materia) => PopupMenuItem(
            value: materia,
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: const Color(0xFF1565C0),
                ),
                const SizedBox(width: 8),
                Text(materia, style: GoogleFonts.lexend(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF90CAF9) : const Color(0xFFE3BFB1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15,
              color: isActive
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF757575),
            ),
            const SizedBox(width: 6),
            Text(
              valor ?? 'Filtrar materias',
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: isActive
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF424242),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: isActive
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF757575),
            ),
          ],
        ),
      ),
    );
  }
}

// 🏫 COMPONENTE DESPLEGABLE: SECCIONES
class _SeccionFilterBtn extends StatelessWidget {
  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _SeccionFilterBtn({
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

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
          child: Row(
            children: [
              Icon(
                Icons.apps_rounded,
                size: 16,
                color: const Color(0xFF757575),
              ),
              const SizedBox(width: 8),
              Text(
                'Todas las secciones',
                style: GoogleFonts.lexend(fontSize: 13),
              ),
            ],
          ),
        ),
        ...opciones.map(
          (seccion) => PopupMenuItem(
            value: seccion,
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: const Color(0xFF00695C),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sección $seccion',
                  style: GoogleFonts.lexend(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFA5D6A7) : const Color(0xFFE3BFB1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 15,
              color: isActive
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF757575),
            ),
            const SizedBox(width: 6),
            Text(
              valor != null ? 'Sección $valor' : 'Sección',
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: isActive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF424242),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: isActive
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF757575),
            ),
          ],
        ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF757575)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: const Color(0xFF424242),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 15,
            color: Color(0xFF757575),
          ),
        ],
      ),
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
          child: Row(
            children: [
              Icon(
                Icons.apps_rounded,
                size: 16,
                color: const Color(0xFF757575),
              ),
              const SizedBox(width: 8),
              Text('Todos', style: GoogleFonts.lexend(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'publico',
          child: Row(
            children: [
              Icon(
                Icons.lock_open_outlined,
                size: 16,
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
              Text('Públicos', style: GoogleFonts.lexend(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'privado',
          child: Row(
            children: [
              Icon(
                Icons.lock_rounded,
                size: 16,
                color: const Color(0xFFE65100),
              ),
              const SizedBox(width: 8),
              Text('Privados', style: GoogleFonts.lexend(fontSize: 13)),
            ],
          ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              valor == 'privado'
                  ? Icons.lock_rounded
                  : Icons.lock_open_outlined,
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
          ],
        ),
      ),
    );
  }
}

class _MateriaSeccionFilterBtn extends StatelessWidget {
  final String? materiaSeleccionada;
  final String? seccionSeleccionada;
  final ValueChanged<String?> onMateriaChanged;
  final ValueChanged<String?> onSeccionChanged;
  final List<String> listaMaterias;
  final List<String> listaSecciones;

  const _MateriaSeccionFilterBtn({
    required this.materiaSeleccionada,
    required this.seccionSeleccionada,
    required this.onMateriaChanged,
    required this.onSeccionChanged,
    required this.listaMaterias,
    required this.listaSecciones,
  });

  @override
  Widget build(BuildContext context) {
    // El botón se ilumina en azul si hay cualquier filtro activo
    final isActive = materiaSeleccionada != null || seccionSeleccionada != null;

    // Cambia dinámicamente el texto del botón según lo seleccionado
    String label = 'Materia / Sección';
    if (materiaSeleccionada != null && seccionSeleccionada != null) {
      label = '$materiaSeleccionada (Sec. $seccionSeleccionada)';
    } else if (materiaSeleccionada != null) {
      label = materiaSeleccionada!;
    } else if (seccionSeleccionada != null) {
      label = 'Sección $seccionSeleccionada';
    }

    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            return GestureDetector(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF90CAF9)
                        : const Color(0xFFE3BFB1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      size: 15,
                      color: isActive
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF757575),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: isActive
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: isActive
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF757575),
                    ),
                  ],
                ),
              ),
            );
          },
      menuChildren: [
        // 📚 SUBMENÚ: MATERIAS
        SubmenuButton(
          menuChildren: listaMaterias.isEmpty
              ? [
                  MenuItemButton(
                    onPressed: null,
                    child: Text(
                      'No hay materias disponibles',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ]
              : listaMaterias.map((materia) {
                  return MenuItemButton(
                    onPressed: () => onMateriaChanged(materia),
                    child: Text(
                      materia,
                      style: GoogleFonts.lexend(fontSize: 13),
                    ),
                  );
                }).toList(),
          child: Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              Text('Materia', style: GoogleFonts.lexend(fontSize: 13)),
            ],
          ),
        ),

        // 🏫 SUBMENÚ: SECCIONES
        SubmenuButton(
          menuChildren: listaSecciones.isEmpty
              ? [
                  MenuItemButton(
                    onPressed: null,
                    child: Text(
                      'No hay secciones disponibles',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ]
              : listaSecciones.map((seccion) {
                  return MenuItemButton(
                    onPressed: () => onSeccionChanged(seccion),
                    child: Text(
                      'Sección $seccion',
                      style: GoogleFonts.lexend(fontSize: 13),
                    ),
                  );
                }).toList(),
          child: Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 16,
                color: const Color(0xFF00695C),
              ),
              const SizedBox(width: 8),
              Text('Sección', style: GoogleFonts.lexend(fontSize: 13)),
            ],
          ),
        ),
      ],
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: textColor),
          ),
        ],
      ),
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
  final Set<String> misGruposIds;
  final void Function(_GrupoData grupo) onEliminar;

  const _GruposGrid({
    required this.grupos,
    required this.columns,
    required this.onCrear,
    required this.misGruposIds,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    // 🌟 CAMBIO 1: Quitamos el "+ 1" para que no cuente una tarjeta extra
    final total = grupos.length;

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
        final g = grupos[i];
        return _GrupoCard(
          grupo: g,
          esMiembro: misGruposIds.contains(g.id),
          onEliminar: () => onEliminar(g),
        );
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
  final int? seccion;
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
    this.seccion,
    this.fotoUrl,
    this.esPrivado = false,
    this.creadoPor,
  });

  factory _GrupoData.fromMap(
    Map<String, dynamic> map, {
    int miembrosCount = 0,
  }) {
    final seccionRaw = map['seccion'];
    final seccionVal = seccionRaw is int
        ? seccionRaw
        : int.tryParse(seccionRaw?.toString() ?? '');
    return _GrupoData(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre'] ?? 'Sin nombre',
      descripcion: map['descripcion'] ?? '',
      miembros: miembrosCount,
      max: map['max_miembros'] ?? 0,
      materia:
          (map['materia'] != null &&
              map['materia'].toString().trim().isNotEmpty)
          ? map['materia'].toString().trim()
          : 'Sin materia',
      seccion: seccionVal,
      fotoUrl: map['foto_url'],
      esPrivado: map['es_privado'] == true,
      creadoPor: map['creado_por']?.toString(),
    );
  }

  IconData get icono {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc'))
      return Icons.calculate_outlined;
    if (m.contains('físic') || m.contains('fisic')) return Icons.bolt_outlined;
    if (m.contains('quím') || m.contains('quim')) return Icons.science_outlined;
    if (m.contains('dato') ||
        m.contains('progr') ||
        m.contains('comp') ||
        m.contains('sistem'))
      return Icons.computer_outlined;
    if (m.contains('bio')) return Icons.biotech_outlined;
    if (m.contains('hist')) return Icons.history_edu_outlined;
    if (m.contains('econ') || m.contains('admin'))
      return Icons.bar_chart_outlined;
    return Icons.menu_book_outlined;
  }

  Color get iconBg {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc'))
      return const Color(0xFFFFF3E0);
    if (m.contains('físic') || m.contains('fisic'))
      return const Color(0xFFF3E5F5);
    if (m.contains('quím') || m.contains('quim'))
      return const Color(0xFFE8F5E9);
    if (m.contains('dato') ||
        m.contains('progr') ||
        m.contains('comp') ||
        m.contains('sistem'))
      return const Color(0xFFE3F2FD);
    if (m.contains('bio')) return const Color(0xFFE0F7FA);
    if (m.contains('hist')) return const Color(0xFFFBE9E7);
    if (m.contains('econ') || m.contains('admin'))
      return const Color(0xFFF9FBE7);
    return const Color(0xFFF5F5F5);
  }

  Color get iconColor {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc'))
      return const Color(0xFFE65100);
    if (m.contains('físic') || m.contains('fisic'))
      return const Color(0xFF6A1B9A);
    if (m.contains('quím') || m.contains('quim'))
      return const Color(0xFF2E7D32);
    if (m.contains('dato') ||
        m.contains('progr') ||
        m.contains('comp') ||
        m.contains('sistem'))
      return const Color(0xFF1565C0);
    if (m.contains('bio')) return const Color(0xFF00695C);
    if (m.contains('hist')) return const Color(0xFFBF360C);
    if (m.contains('econ') || m.contains('admin'))
      return const Color(0xFF558B2F);
    return const Color(0xFF616161);
  }

  String get seccionLabel => seccion != null ? 'Sec $seccion' : 'Sin sección';
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA GRUPO
// ═══════════════════════════════════════════════════════════════════════════

class _GrupoCard extends StatefulWidget {
  final _GrupoData grupo;
  final bool esMiembro;
  final VoidCallback? onEliminar;
  const _GrupoCard({
    required this.grupo,
    required this.esMiembro,
    this.onEliminar,
  });

  @override
  State<_GrupoCard> createState() => _GrupoCardState();
}

class _GrupoCardState extends State<_GrupoCard> {
  bool _solicitudEnviada = false;

  _GrupoData get grupo => widget.grupo;
  bool get esMiembro => widget.esMiembro;
  VoidCallback? get onEliminar => widget.onEliminar;

  @override
  void didUpdateWidget(covariant _GrupoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el usuario fue aceptado y ahora es miembro, limpiar el estado pendiente
    if (!oldWidget.esMiembro && widget.esMiembro) {
      _solicitudEnviada = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _verificarSolicitudExistente();
  }

  Future<void> _verificarSolicitudExistente() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || !grupo.esPrivado) return;
    try {
      final result = await supabase
          .from('solicitudes_grupo')
          .select('id, estado')
          .eq('grupo_id', grupo.id)
          .eq('usuario_id', userId)
          .eq('estado', 'pendiente')
          .maybeSingle();
      if (!mounted) return;
      if (result != null) setState(() => _solicitudEnviada = true);
    } catch (e) {
      debugPrint('Error verificando solicitud existente: $e');
    }
  }

  Future<void> _manejarUnirse() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Si ya es miembro, ir directo al chat
    if (esMiembro) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudymatchChatPage(
            grupoInicialId: grupo.id,
            nombreGrupo: grupo.nombre,
          ),
        ),
      );
      return;
    }

    if (grupo.esPrivado) {
      // ── Verificar solicitud pendiente ─────────────────────────────────────
      try {
        final solicitudExistente = await supabase
            .from('solicitudes_grupo')
            .select('id, estado')
            .eq('grupo_id', grupo.id)
            .eq('usuario_id', userId)
            .eq('estado', 'pendiente')
            .maybeSingle();

        if (solicitudExistente != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF5D4037),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ya tienes una solicitud pendiente para este grupo.',
                      style: GoogleFonts.lexend(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
          return;
        }
      } catch (e) {
        // Si falla la verificación, dejamos continuar para no bloquear al usuario
        debugPrint('Error verificando membresía previa: $e');
      }
      // ─────────────────────────────────────────────────────────────────────

      // Mostrar diálogo de solicitud
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.lock_rounded,
                color: Color(0xFFE65100),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Grupo privado',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'Este grupo requiere aprobación del administrador. ¿Deseas enviar una solicitud para unirte a "${grupo.nombre}"?',
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: const Color(0xFF424242),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.lexend(color: const Color(0xFF757575)),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 15),
              label: Text(
                'Solicitar',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
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

        if (!mounted) return;
        setState(() => _solicitudEnviada = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Solicitud enviada. El administrador la revisará pronto.',
              style: GoogleFonts.lexend(color: Colors.white),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        // Si el error es por duplicado (unique constraint), avisar al usuario
        final msg =
            e.toString().contains('duplicate') ||
                e.toString().contains('unique')
            ? 'Ya tienes una solicitud pendiente para este grupo.'
            : 'Error al enviar la solicitud: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(msg, style: GoogleFonts.lexend(color: Colors.white)),
          ),
        );
      }
    } else {
      // Lógica de unirse a grupo público (tu implementación existente)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudymatchChatPage(
            grupoInicialId: grupo.id.toString(),
            nombreGrupo:
                grupo.nombre, // 🌟 Le pasamos el nombre real del grupo aquí
          ),
        ),
      );
    }
  }

  bool get _soyCreador {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId != null && grupo.creadoPor == userId;
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: grupo.iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: grupo.fotoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            grupo.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              grupo.icono,
                              color: grupo.iconColor,
                              size: 30,
                            ),
                          ),
                        )
                      : Icon(grupo.icono, color: grupo.iconColor, size: 30),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_soyCreador && onEliminar != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                        tooltip: 'Eliminar grupo',
                        onPressed: onEliminar,
                      ),
                    // Badge de privacidad
                    if (grupo.esPrivado)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCC80)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: Color(0xFFE65100),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Privado',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: const Color(0xFFE65100),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _MiniTag(
                      label: grupo.materia,
                      bg: const Color(0xFFE8F5E9),
                      fg: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 4),
                    _MiniTag(
                      label: grupo.seccionLabel,
                      bg: const Color(0xFFF5F5F5),
                      fg: const Color(0xFF757575),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    grupo.nombre,
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (grupo.esPrivado) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Requiere aprobación del administrador',
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                grupo.descripcion,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: const Color(0xFF8A8A8A),
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _AvatarStack(count: grupo.miembros.clamp(1, 4)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    grupo.max > 0
                        ? '${grupo.miembros} / ${grupo.max} miembros'
                        : '${grupo.miembros} miembro${grupo.miembros == 1 ? '' : 's'}',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _MiniTag(
                  label: grupo.seccionLabel,
                  bg: const Color(0xFFF5F5F5),
                  fg: const Color(0xFF757575),
                ),
                _MiniTag(
                  label: grupo.materia,
                  bg: const Color(0xFFF5F5F5),
                  fg: const Color(0xFF757575),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: TextButton.icon(
                onPressed: esMiembro
                    ? () => _manejarUnirse()
                    : _solicitudEnviada
                    ? null
                    : () => _manejarUnirse(),
                icon: Icon(
                  esMiembro
                      ? Icons.chat_bubble_outline
                      : _solicitudEnviada
                      ? Icons.hourglass_top_rounded
                      : grupo.esPrivado
                      ? Icons.send_rounded
                      : Icons.login_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                label: Text(
                  esMiembro
                      ? 'Abrir chat'
                      : _solicitudEnviada
                      ? 'Pendiente'
                      : grupo.esPrivado
                      ? 'Solicitar unirse'
                      : 'Unirse',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: esMiembro
                      ? const Color(0xFF1565C0)
                      : _solicitudEnviada
                      ? const Color(0xFF9E9E9E)
                      : grupo.esPrivado
                      ? const Color(0xFFE65100)
                      : const Color(0xFF2E5900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF9E9E9E),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crear un grupo',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '¿No puedes encontrar un grupo de tu clase? Crea uno e invita a tus amigos.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: const Color(0xFFAFA49C),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
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
          ),
        ),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
      borderSide: const BorderSide(color: Color(0xFFE0D8D2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0D8D2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Crear nuevo grupo',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nombreCtrl,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: _dec(
                  'Nombre del grupo',
                  icon: Icons.group_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: _dec('Descripción'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: _dec(
                  'Máximo de miembros',
                  icon: Icons.people_outline,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0D8D2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.lexend(
                          color: const Color(0xFF616161),
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Crear grupo',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        border: Border(top: BorderSide(color: Color(0xFFEDE8E3))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: 28,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _brand(),
                const SizedBox(height: 16),
                _links(wrap: true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _brand()),
                _links(wrap: false),
              ],
            ),
    );
  }

  Widget _brand() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'U-NITE',
        style: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF245000),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        '© 2024 U-NITE Campus Marketplace. All rights reserved.',
        style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFF9E9E9E)),
      ),
    ],
  );

  Widget _links({required bool wrap}) {
    const labels = [
      'Privacy Policy',
      'Terms of Service',
      'Campus Safety',
      'Contact Support',
    ];
    final widgets = labels
        .map(
          (l) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              l,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: const Color(0xFF616161),
              ),
            ),
          ),
        )
        .toList();
    return wrap
        ? Wrap(children: widgets)
        : Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }
}