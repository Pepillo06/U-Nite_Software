import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/unite_header.dart';
// Importación condicional: usa dart:html solo en web, stub en otras plataformas.
import 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart';

class _AdjuntoParseado {
  final String url;
  final String tipo;
  final String nombre;
  final String? texto;

  const _AdjuntoParseado({
    required this.url,
    required this.tipo,
    required this.nombre,
    this.texto,
  });
}

class StudymatchChatPage extends StatefulWidget {
  final String grupoInicialId;
  final String nombreGrupo;

  const StudymatchChatPage({
    super.key,
    required this.grupoInicialId,
    required this.nombreGrupo,
  });

  @override
  State<StudymatchChatPage> createState() => _StudymatchChatPageState();
}

class _StudymatchChatPageState extends State<StudymatchChatPage> {
  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _searchGroupCtrl = TextEditingController();
  final TextEditingController _searchMessageCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;

  late String _currentSalaId;
  late String _currentNombreGrupo;

  late Stream<List<Map<String, dynamic>>> _mensajesStream;
  late Future<List<Map<String, dynamic>>> _salasFuture;
  late Future<List<Map<String, dynamic>>> _salasPublicasFuture;

  final Map<String, String> _nombresUsuarios = {};

  String _materia = 'Cargando...';
  String _fecha = 'Cargando...';
  String? _creadorId;

  // Toggle para mostrar/ocultar panel derecho
  bool _mostrarPanelDerecho = false;

  // Tab seleccionada en navegación izquierda
  int _selectedNavTab = 0;

  // Búsqueda de grupos y mensajes
  String _searchGroupQuery = '';
  String _searchMessageQuery = '';
  bool _isSearchingMessages = false;

  // Lista de miembros del grupo
  List<Map<String, dynamic>> _miembros = [];

  // IDs de usuarios bloqueados por el usuario actual
  Set<String> _usuariosBloqueados = {};

  // Si el usuario actual es admin de esta sala
  bool _esAdminActual = false;

  // Archivo adjunto pendiente de enviar
  PlatformFile? _archivoAdjunto;
  String? _descripcionGrupo;
  bool _editandoDescripcion = false;
  TextEditingController? _descEditCtrl;
  String? _grupoEstudioId;

  @override
  void initState() {
    super.initState();
    _currentSalaId = widget.grupoInicialId;
    _currentNombreGrupo = widget.nombreGrupo;
    // Inicializar de inmediato para que el build no falle con late fields
    _initMensajesStream();
    _salasFuture = _cargarSalas();
    _salasPublicasFuture = _cargarSalasPublicas();
    _inicializarSalaYDatos();
  }

  Future<void> _inicializarSalaYDatos() async {
    final salaIdAntes = _currentSalaId;
    await _resolverSalaDesdeGrupo();
    await _eliminarSalasDuplicadas();
    if (!mounted) return;
    if (_currentSalaId != salaIdAntes) {
      _initMensajesStream();
    }
    _cargarInfoSala();
    _cargarMiembros();
    _cargarUsuariosBloqueados();
    setState(() {
      _salasFuture = _cargarSalas();
      _salasPublicasFuture = _cargarSalasPublicas();
    });
    _sincronizarGruposEstudio();
  }

  /// Convierte un ID de grupos_estudio al ID real de salas_chat (si aplica).
  Future<void> _resolverSalaDesdeGrupo() async {
    final id = widget.grupoInicialId;

    try {
      final salaDirecta = await _supabase
          .from('salas_chat')
          .select('id, nombre')
          .eq('id', id)
          .maybeSingle();

      if (salaDirecta != null) {
        _currentSalaId = salaDirecta['id'].toString();
        _currentNombreGrupo =
            salaDirecta['nombre']?.toString() ?? widget.nombreGrupo;
        return;
      }

      final grupo = await _supabase
          .from('grupos_estudio')
          .select('id, nombre, materia, descripcion, creado_por')
          .eq('id', id)
          .maybeSingle();

      if (grupo == null) return;

      _grupoEstudioId = grupo['id'].toString();
      final nombre = grupo['nombre'].toString().trim();
      final creadorId = grupo['creado_por']?.toString();
      _currentNombreGrupo = nombre;

      final salasMismoNombre = await _supabase
          .from('salas_chat')
          .select('id, nombre, creado_por, descripcion')
          .ilike('nombre', nombre);

      Map<String, dynamic>? salaElegida;
      for (final s in (salasMismoNombre as List)) {
        if (creadorId != null && s['creado_por']?.toString() == creadorId) {
          salaElegida = Map<String, dynamic>.from(s);
          break;
        }
      }
      salaElegida ??= salasMismoNombre.isNotEmpty
          ? Map<String, dynamic>.from(salasMismoNombre.first)
          : null;

      if (salaElegida != null) {
        _currentSalaId = salaElegida['id'].toString();
        final descSala = salaElegida['descripcion']?.toString();
        final descGrupo = grupo['descripcion']?.toString();
        if ((descSala == null || descSala.trim().isEmpty) &&
            descGrupo != null &&
            descGrupo.trim().isNotEmpty) {
          await _supabase
              .from('salas_chat')
              .update({'descripcion': descGrupo.trim()})
              .eq('id', _currentSalaId);
        }
        return;
      }

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final nuevaSala = await _supabase
          .from('salas_chat')
          .insert({
            'nombre': nombre,
            'materia': grupo['materia'],
            'descripcion': grupo['descripcion'],
            'creado_por': creadorId ?? user.id,
          })
          .select()
          .single();

      _currentSalaId = nuevaSala['id'].toString();
      await _supabase.from('participantes_sala').insert({
        'sala_id': _currentSalaId,
        'usuario_id': creadorId ?? user.id,
        'es_admin': true,
      });
    } catch (_) {}
  }

  /// Fusiona y elimina salas duplicadas (mismo nombre + mismo creador).
  Future<void> _eliminarSalasDuplicadas() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final misSalas = await _supabase
          .from('salas_chat')
          .select('id, nombre, creado_por, created_at')
          .eq('creado_por', user.id);

      final Map<String, List<Map<String, dynamic>>> porClave = {};
      for (final s in (misSalas as List)) {
        final clave =
            '${s['nombre'].toString().trim().toLowerCase()}|${s['creado_por']}';
        porClave.putIfAbsent(clave, () => []).add(Map<String, dynamic>.from(s));
      }

      for (final grupo in porClave.values) {
        if (grupo.length < 2) continue;

        grupo.sort((a, b) {
          final da = a['created_at']?.toString() ?? '';
          final db = b['created_at']?.toString() ?? '';
          return da.compareTo(db);
        });

        final salaPrincipal = grupo.first;
        final idPrincipal = salaPrincipal['id'].toString();

        for (final duplicada in grupo.skip(1)) {
          final idDup = duplicada['id'].toString();
          if (idDup == idPrincipal) continue;

          try {
            final participantes = await _supabase
                .from('participantes_sala')
                .select('usuario_id, es_admin')
                .eq('sala_id', idDup);

            for (final p in (participantes as List)) {
              final uid = p['usuario_id'].toString();
              final yaExiste = await _supabase
                  .from('participantes_sala')
                  .select('usuario_id, es_admin')
                  .eq('sala_id', idPrincipal)
                  .eq('usuario_id', uid)
                  .maybeSingle();

              if (yaExiste == null) {
                await _supabase.from('participantes_sala').insert({
                  'sala_id': idPrincipal,
                  'usuario_id': uid,
                  'es_admin': p['es_admin'] == true,
                });
              } else if (p['es_admin'] == true &&
                  yaExiste['es_admin'] != true) {
                await _supabase
                    .from('participantes_sala')
                    .update({'es_admin': true})
                    .eq('sala_id', idPrincipal)
                    .eq('usuario_id', uid);
              }
            }

            await _supabase
                .from('mensajes_chat')
                .update({'sala_id': idPrincipal})
                .eq('sala_id', idDup);

            await _supabase
                .from('participantes_sala')
                .delete()
                .eq('sala_id', idDup);
            await _supabase.from('salas_chat').delete().eq('id', idDup);

            if (_currentSalaId == idDup) {
              _currentSalaId = idPrincipal;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _searchGroupCtrl.dispose();
    _searchMessageCtrl.dispose();
    _descEditCtrl?.dispose();
    super.dispose();
  }

  // Sincroniza grupos_estudio con salas_chat automáticamente
  // Usa el ID del grupo como referencia para evitar duplicados
  Future<void> _sincronizarGruposEstudio() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Traer grupos creados por este usuario en grupos_estudio
      final gruposEstudio = await _supabase
          .from('grupos_estudio')
          .select('id, nombre, materia, descripcion, creado_por')
          .eq('creado_por', user.id);

      if (gruposEstudio.isEmpty) return;

      // 2. Traer TODAS las salas para comparar por nombre (evitar duplicados exactos)
      final salasExistentes = await _supabase
          .from('salas_chat')
          .select('id, nombre, creado_por');

      // Índice: nombre lowercase → sala
      final Map<String, Map<String, dynamic>> salasPorNombre = {};
      for (final s in (salasExistentes as List)) {
        final key = s['nombre'].toString().trim().toLowerCase();
        salasPorNombre[key] = s;
      }

      // 3. Por cada grupo que no tenga sala con el mismo nombre Y mismo creador, crearla
      for (final grupo in (gruposEstudio as List)) {
        final nombre = grupo['nombre'].toString().trim();
        final key = nombre.toLowerCase();

        // Si ya existe una sala con ese nombre creada por este usuario, no crear otra
        final existing = salasPorNombre[key];
        if (existing != null && existing['creado_por'].toString() == user.id) {
          // Asegurar que el creador sea participante admin en esa sala
          try {
            final salaId = existing['id'].toString();
            final yaParticipante = await _supabase
                .from('participantes_sala')
                .select('usuario_id, es_admin')
                .eq('sala_id', salaId)
                .eq('usuario_id', user.id)
                .maybeSingle();
            if (yaParticipante == null) {
              await _supabase.from('participantes_sala').insert({
                'sala_id': salaId,
                'usuario_id': user.id,
                'es_admin': true,
              });
            } else if (yaParticipante['es_admin'] != true) {
              await _supabase
                  .from('participantes_sala')
                  .update({'es_admin': true})
                  .eq('sala_id', salaId)
                  .eq('usuario_id', user.id);
            }
            final descGrupo = grupo['descripcion']?.toString();
            if (descGrupo != null && descGrupo.trim().isNotEmpty) {
              await _supabase
                  .from('salas_chat')
                  .update({'descripcion': descGrupo.trim()})
                  .eq('id', salaId);
            }
          } catch (_) {}
          continue;
        }

        // No existe sala con ese nombre para este creador → crear
        try {
          final salaResult = await _supabase
              .from('salas_chat')
              .insert({
                'nombre': nombre,
                'materia': grupo['materia'],
                'descripcion': grupo['descripcion'],
                'creado_por': user.id,
              })
              .select()
              .single();

          // Agregar creador como admin en participantes_sala
          await _supabase.from('participantes_sala').insert({
            'sala_id': salaResult['id'],
            'usuario_id': user.id,
            'es_admin': true,
          });
        } catch (_) {}
      }

      // 4. Recargar salas después de sincronizar
      if (mounted) {
        setState(() {
          _salasFuture = _cargarSalas();
          _salasPublicasFuture = _cargarSalasPublicas();
        });
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _cargarSalas() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // 1) Salas donde es participante
      final participaciones = await _supabase
          .from('participantes_sala')
          .select('sala_id')
          .eq('usuario_id', user.id);

      final Set<String> salaIds = participaciones
          .map((p) => p['sala_id'].toString())
          .toSet();

      // 2) Salas donde envió mensajes
      final mensajesEnviados = await _supabase
          .from('mensajes_chat')
          .select('sala_id')
          .eq('remitente_id', user.id);

      for (final m in mensajesEnviados) {
        salaIds.add(m['sala_id'].toString());
      }

      if (salaIds.isEmpty) return [];

      final salas = await _supabase
          .from('salas_chat')
          .select()
          .inFilter('id', salaIds.toList())
          .order('created_at', ascending: false);

      final adminParticipaciones = await _supabase
          .from('participantes_sala')
          .select('sala_id, es_admin')
          .eq('usuario_id', user.id)
          .eq('es_admin', true);

      final adminSalaIds = (adminParticipaciones as List)
          .map((p) => p['sala_id'].toString())
          .toSet();

      return (salas as List).map((s) {
        final m = Map<String, dynamic>.from(s);
        m['soy_admin'] =
            adminSalaIds.contains(s['id'].toString()) ||
            s['creado_por']?.toString() == user.id;
        return m;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _cargarSalasPublicas() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // Salas públicas donde el usuario NO es participante
      final participaciones = await _supabase
          .from('participantes_sala')
          .select('sala_id')
          .eq('usuario_id', user.id);

      final misIds = participaciones
          .map((p) => p['sala_id'].toString())
          .toSet();

      final todasSalas = await _supabase
          .from('salas_chat')
          .select()
          .order('created_at', ascending: false);

      // Mostrar salas en las que el usuario NO está
      return List<Map<String, dynamic>>.from(
        todasSalas,
      ).where((s) => !misIds.contains(s['id'].toString())).toList();
    } catch (e) {
      return [];
    }
  }

  void _initMensajesStream() {
    _mensajesStream = _supabase
        .from('mensajes_chat')
        .stream(primaryKey: ['id'])
        .eq('sala_id', _currentSalaId)
        .order('created_at', ascending: true);
  }

  void _seleccionarSala(String salaId, String nombre) {
    setState(() {
      _currentSalaId = salaId;
      _currentNombreGrupo = nombre;
      _mostrarPanelDerecho = false;
      _initMensajesStream();
      _cargarInfoSala();
      _cargarMiembros();
    });
  }

  Future<void> _cargarInfoSala() async {
    try {
      // 1) Intentar cargar de salas_chat
      var response = await _supabase
          .from('salas_chat')
          .select('materia, created_at, creado_por, nombre, descripcion')
          .eq('id', _currentSalaId)
          .maybeSingle();

      // Si no existe la sala, mostrar lo que tenemos del widget
      if (response == null) {
        if (mounted) {
          setState(() {
            _materia = 'Sin materia';
            _fecha = 'Desconocida';
            _creadorId = null;
            _descripcionGrupo = null;
          });
        }
        return;
      }

      final user = _supabase.auth.currentUser;
      final creadorId = response['creado_por']?.toString();

      // 3) PRIMERO: reparar permisos del creador en participantes_sala
      if (creadorId != null) {
        try {
          final existing = await _supabase
              .from('participantes_sala')
              .select('usuario_id, es_admin')
              .eq('sala_id', _currentSalaId)
              .eq('usuario_id', creadorId)
              .maybeSingle();
          if (existing == null) {
            // El creador no está en participantes — insertarlo como admin
            await _supabase.from('participantes_sala').insert({
              'sala_id': _currentSalaId,
              'usuario_id': creadorId,
              'es_admin': true,
            });
          } else if (existing['es_admin'] != true) {
            // El creador existe pero sin flag admin — corregirlo
            await _supabase
                .from('participantes_sala')
                .update({'es_admin': true})
                .eq('sala_id', _currentSalaId)
                .eq('usuario_id', creadorId);
          }
        } catch (_) {}
      }

      // 4) DESPUÉS de reparar: leer es_admin del usuario actual
      // Si el usuario actual ES el creador, siempre es admin (sin consulta extra)
      bool esAdminActual = false;
      if (user != null) {
        if (user.id == creadorId) {
          // El creador siempre tiene admin — ya lo garantizamos arriba
          esAdminActual = true;
        } else {
          try {
            final participante = await _supabase
                .from('participantes_sala')
                .select('usuario_id, es_admin')
                .eq('sala_id', _currentSalaId)
                .eq('usuario_id', user.id)
                .maybeSingle();
            if (participante != null) {
              esAdminActual = participante['es_admin'] == true;
            }
          } catch (_) {}
        }
      }

      if (!mounted) return;

      setState(() {
        _esAdminActual = esAdminActual;
        _materia =
            (response['materia'] != null &&
                response['materia'].toString().trim().isNotEmpty)
            ? response['materia'].toString().trim()
            : 'Sin materia';
        if (response['created_at'] != null) {
          final dt = DateTime.parse(response['created_at']).toLocal();
          final meses = [
            'ene',
            'feb',
            'mar',
            'abr',
            'may',
            'jun',
            'jul',
            'ago',
            'sep',
            'oct',
            'nov',
            'dic',
          ];
          _fecha = '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
        } else {
          _fecha = 'Desconocida';
        }
        _creadorId = creadorId;
        _descripcionGrupo = response['descripcion']?.toString();
        if (response['nombre'] != null) {
          _currentNombreGrupo = response['nombre'];
        }
      });

      if (_descripcionGrupo == null || _descripcionGrupo!.trim().isEmpty) {
        await _cargarDescripcionDesdeGrupoEstudio();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _materia = 'No especificada';
          _fecha = 'Desconocida';
          _creadorId = null;
        });
      }
    }
  }

  Future<void> _cargarDescripcionDesdeGrupoEstudio() async {
    try {
      Map<String, dynamic>? grupo;
      if (_grupoEstudioId != null) {
        grupo = await _supabase
            .from('grupos_estudio')
            .select('descripcion')
            .eq('id', _grupoEstudioId!)
            .maybeSingle();
      } else {
        grupo = await _supabase
            .from('grupos_estudio')
            .select('descripcion')
            .eq('nombre', _currentNombreGrupo)
            .eq('creado_por', _creadorId ?? '')
            .maybeSingle();
      }

      final desc = grupo?['descripcion']?.toString();
      if (desc != null && desc.trim().isNotEmpty && mounted) {
        setState(() => _descripcionGrupo = desc.trim());
        await _supabase
            .from('salas_chat')
            .update({'descripcion': desc.trim()})
            .eq('id', _currentSalaId);
      }
    } catch (_) {}
  }

  Future<void> _cargarUsuariosBloqueados() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('usuarios_bloqueados')
          .select('bloqueado_id')
          .eq('bloqueado_por', user.id);

      if (mounted) {
        setState(() {
          _usuariosBloqueados = data
              .map((r) => r['bloqueado_id'].toString())
              .toSet();
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _filtrarMensajesBloqueados(
    List<Map<String, dynamic>> mensajes,
  ) {
    if (_usuariosBloqueados.isEmpty) return mensajes;

    return mensajes.where((m) {
      final remitenteId = m['remitente_id']?.toString();
      if (remitenteId == null) return true;
      return !_usuariosBloqueados.contains(remitenteId);
    }).toList();
  }

  bool _estaBloqueado(String usuarioId) =>
      _usuariosBloqueados.contains(usuarioId);

  Future<List<Map<String, dynamic>>> _obtenerUsuariosBloqueadosConNombre() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('usuarios_bloqueados')
          .select('bloqueado_id')
          .eq('bloqueado_por', user.id);

      final List<Map<String, dynamic>> result = [];
      for (final r in data) {
        final id = r['bloqueado_id'].toString();
        String nombre = 'Usuario';
        try {
          final userData = await _supabase
              .from('usuarios')
              .select('primer_nombre, primer_apellido')
              .eq('id', id)
              .maybeSingle();
          if (userData != null) {
            nombre =
                '${userData['primer_nombre'] ?? ''} ${userData['primer_apellido'] ?? ''}'
                    .trim();
            if (nombre.isEmpty) nombre = 'Usuario';
          }
        } catch (_) {}
        result.add({'id': id, 'nombre': nombre});
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> _ejecutarDesbloqueo(String usuarioId, {String? nombre}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('usuarios_bloqueados')
          .delete()
          .eq('bloqueado_id', usuarioId)
          .eq('bloqueado_por', user.id);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _usuariosBloqueados.remove(usuarioId);
      });
      if (nombre != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$nombre desbloqueado. Volverás a ver sus mensajes.',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _cargarMiembros() async {
    try {
      final participantes = await _supabase
          .from('participantes_sala')
          .select('usuario_id, es_admin')
          .eq('sala_id', _currentSalaId);

      List<Map<String, dynamic>> miembrosData = [];
      for (final p in participantes) {
        final userId = p['usuario_id'].toString();
        final esAdminMiembro = p['es_admin'] == true;
        try {
          final userData = await _supabase
              .from('usuarios')
              .select('id, primer_nombre, primer_apellido, correo')
              .eq('id', userId)
              .maybeSingle();
          if (userData != null) {
            final merged = Map<String, dynamic>.from(userData);
            merged['es_admin'] = esAdminMiembro;
            miembrosData.add(merged);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _miembros = miembrosData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _miembros = [];
        });
      }
    }
  }

  Future<String> _obtenerNombre(String? userId, String? fallbackName) async {
    if (userId == null) return fallbackName ?? 'Usuario';
    if (_nombresUsuarios.containsKey(userId)) return _nombresUsuarios[userId]!;

    try {
      final response = await _supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final nombre = response['primer_nombre'] ?? 'Usuario';
        final apellido = response['primer_apellido'] ?? '';
        final completo = '$nombre $apellido'.trim();
        _nombresUsuarios[userId] = completo;
        return completo;
      }
    } catch (_) {}

    final nombreFinal = fallbackName ?? 'Usuario';
    _nombresUsuarios[userId] = nombreFinal;
    return nombreFinal;
  }

  Future<void> _enviarMensaje() async {
    final texto = _messageCtrl.text.trim();
    final archivo = _archivoAdjunto;

    if (texto.isEmpty && archivo == null) return;

    final usuarioActual = _supabase.auth.currentUser;
    if (usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para enviar mensajes'),
        ),
      );
      return;
    }

    _messageCtrl.clear();
    setState(() => _archivoAdjunto = null);

    try {
      String? archivoUrl;
      String? tipoArchivo;
      String? nombreArchivo;

      if (archivo != null && archivo.bytes != null) {
        tipoArchivo = _getTipoArchivo(archivo.extension ?? '');
        nombreArchivo = archivo.name;
        final path =
            '${usuarioActual.id}/$_currentSalaId/${DateTime.now().millisecondsSinceEpoch}_${archivo.name}';
        await _supabase.storage
            .from('chat_archivos')
            .uploadBinary(
              path,
              archivo.bytes!,
              fileOptions: FileOptions(
                contentType: _mimeDesdeExtension(archivo.extension ?? ''),
              ),
            );
        archivoUrl = _supabase.storage.from('chat_archivos').getPublicUrl(path);
      }

      final basePayload = {
        'sala_id': _currentSalaId,
        'remitente_id': usuarioActual.id,
      };

      if (archivoUrl != null) {
        try {
          await _supabase.from('mensajes_chat').insert({
            ...basePayload,
            'texto': texto.isEmpty ? null : texto,
            'archivo_url': archivoUrl,
            'tipo_archivo': tipoArchivo,
            'nombre_archivo': nombreArchivo,
          });
        } on PostgrestException catch (e) {
          if (e.code != 'PGRST204') rethrow;
          await _supabase.from('mensajes_chat').insert({
            ...basePayload,
            'texto': _textoConAdjunto(
              url: archivoUrl,
              tipo: tipoArchivo!,
              nombre: nombreArchivo!,
              caption: texto,
            ),
          });
        }
      } else {
        await _supabase.from('mensajes_chat').insert({
          ...basePayload,
          'texto': texto,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
      }
    }
  }

  String _textoConAdjunto({
    required String url,
    required String tipo,
    required String nombre,
    required String caption,
  }) {
    final marcador = tipo == 'imagen'
        ? '[imagen]$url'
        : '[archivo:$nombre]$url';
    if (caption.isEmpty) return marcador;
    return '$marcador\n$caption';
  }

  _AdjuntoParseado? _extraerAdjunto(Map<String, dynamic> msg) {
    final urlCol = msg['archivo_url']?.toString();
    if (urlCol != null && urlCol.isNotEmpty) {
      return _AdjuntoParseado(
        url: urlCol,
        tipo: msg['tipo_archivo']?.toString() ?? 'archivo',
        nombre: msg['nombre_archivo']?.toString() ?? 'Archivo',
        texto: msg['texto']?.toString(),
      );
    }

    final raw = msg['texto']?.toString() ?? '';
    if (raw.startsWith('[imagen]')) {
      final rest = raw.substring('[imagen]'.length);
      final nl = rest.indexOf('\n');
      if (nl >= 0) {
        return _AdjuntoParseado(
          url: rest.substring(0, nl).trim(),
          tipo: 'imagen',
          nombre: 'imagen',
          texto: rest.substring(nl + 1).trim(),
        );
      }
      return _AdjuntoParseado(
        url: rest.trim(),
        tipo: 'imagen',
        nombre: 'imagen',
      );
    }

    final match = RegExp(r'^\[archivo:([^\]]+)\](\S+)').firstMatch(raw);
    if (match != null) {
      final nombre = match.group(1) ?? 'Archivo';
      final url = match.group(2) ?? '';
      final despues = raw.substring(match.end);
      final caption = despues.startsWith('\n')
          ? despues.substring(1).trim()
          : null;
      return _AdjuntoParseado(
        url: url,
        tipo: _getTipoArchivo(
          nombre.contains('.') ? nombre.split('.').last : '',
        ),
        nombre: nombre,
        texto: caption?.isNotEmpty == true ? caption : null,
      );
    }

    return null;
  }

  void _abrirArchivo(String url) {
    if (kIsWeb) {
      openUrlInNewTab(url);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archivo: $url', style: GoogleFonts.lexend())),
    );
  }

  String _getTipoArchivo(String ext) {
    const imagenes = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'bmp',
      'svg',
    ];
    const videos = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'wmv', 'm4v'];
    const audios = ['mp3', 'wav', 'ogg', 'aac', 'flac', 'm4a'];
    const docs = [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
      'rtf',
      'odt',
      'ods',
      'csv',
    ];
    final e = ext.toLowerCase().replaceAll('.', '');
    if (imagenes.contains(e)) return 'imagen';
    if (videos.contains(e)) return 'video';
    if (audios.contains(e)) return 'audio';
    if (docs.contains(e)) return 'documento';
    return 'archivo';
  }

  String _mimeDesdeExtension(String ext) {
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'txt': 'text/plain',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip': 'application/zip',
    };
    return map[ext.toLowerCase()] ?? 'application/octet-stream';
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No se pudo leer el archivo. Intenta con uno más pequeño.',
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      setState(() => _archivoAdjunto = file);
    }
  }

  Future<void> _guardarDescripcion(String nuevaDesc) async {
    try {
      await _supabase
          .from('salas_chat')
          .update({'descripcion': nuevaDesc})
          .eq('id', _currentSalaId);

      try {
        if (_grupoEstudioId != null) {
          await _supabase
              .from('grupos_estudio')
              .update({'descripcion': nuevaDesc})
              .eq('id', _grupoEstudioId!);
        } else if (_creadorId != null) {
          await _supabase
              .from('grupos_estudio')
              .update({'descripcion': nuevaDesc})
              .eq('nombre', _currentNombreGrupo)
              .eq('creado_por', _creadorId!);
        }
      } catch (_) {}

      setState(() {
        _descripcionGrupo = nuevaDesc;
        _editandoDescripcion = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Descripción actualizada.',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  void _invitarPorCorreo() {
    final TextEditingController emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Invitar persona por correo',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'ejemplo@correo.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              final correo = emailCtrl.text.trim();
              if (correo.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  // Buscar ID del usuario por correo
                  final userSearch = await _supabase
                      .from('usuarios')
                      .select('id, primer_nombre')
                      .eq('correo', correo)
                      .maybeSingle();

                  if (userSearch != null) {
                    // Verificar que la sala existe en salas_chat; si no, crearla
                    var salaExiste = await _supabase
                        .from('salas_chat')
                        .select('id')
                        .eq('id', _currentSalaId)
                        .maybeSingle();

                    if (salaExiste == null) {
                      // La sala no existe en salas_chat: crearla con el nombre actual
                      try {
                        final user = _supabase.auth.currentUser;
                        await _supabase.from('salas_chat').insert({
                          'id': _currentSalaId,
                          'nombre': _currentNombreGrupo,
                          'materia': _materia != 'No especificada'
                              ? _materia
                              : null,
                          'creado_por': user?.id,
                        });
                        salaExiste = {'id': _currentSalaId};
                      } catch (insertErr) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No se pudo registrar la sala. Intenta de nuevo.',
                                style: GoogleFonts.lexend(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    }

                    // Verificar si ya es participante para evitar duplicados
                    final yaParticipa = await _supabase
                        .from('participantes_sala')
                        .select('usuario_id')
                        .eq('sala_id', _currentSalaId)
                        .eq('usuario_id', userSearch['id'])
                        .maybeSingle();

                    if (yaParticipa != null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${userSearch['primer_nombre']} ya es miembro de este grupo.',
                              style: GoogleFonts.lexend(),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    // Agregar al usuario como participante de la sala
                    await _supabase.from('participantes_sala').insert({
                      'sala_id': _currentSalaId,
                      'usuario_id': userSearch['id'],
                    });

                    await _supabase.from('notificaciones_chat').insert({
                      'usuario_id': userSearch['id'],
                      'tipo': 'invitacion',
                      'titulo': 'Invitación a chat grupal',
                      'mensaje':
                          'Te han invitado a unirte a la sala $_currentNombreGrupo',
                      'datos': {
                        'sala_id': _currentSalaId,
                        'nombre_grupo': _currentNombreGrupo,
                      },
                      'leida': false,
                    });

                    // Recargar miembros
                    _cargarMiembros();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invitación enviada a ${userSearch['primer_nombre']} exitosamente.',
                            style: GoogleFonts.lexend(),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No se encontró un usuario con ese correo.',
                            style: GoogleFonts.lexend(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al invitar: $e')),
                    );
                  }
                }
              }
            },
            child: Text(
              'Enviar invitación',
              style: GoogleFonts.lexend(color: const Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _expulsarMiembro(String usuarioId, String nombre) async {
    // Validación: solo admins pueden expulsar sin restricción.
    // Un no-admin necesita que el usuario tenga al menos 2 reportes previos.
    if (!_esAdminActual) {
      try {
        final reportes = await _supabase
            .from('reportes_usuarios')
            .select('id')
            .eq('reportado_id', usuarioId);
        if (reportes.length < 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Solo un administrador puede expulsar miembros sin reportes previos. $nombre necesita al menos 2 reportes (actualmente tiene ${reportes.length}).',
                  style: GoogleFonts.lexend(),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } catch (_) {}
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Expulsar miembro',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que quieres sacar a $nombre del grupo?',
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Expulsar',
              style: GoogleFonts.lexend(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase
            .from('participantes_sala')
            .delete()
            .eq('sala_id', _currentSalaId)
            .eq('usuario_id', usuarioId);

        _cargarMiembros();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$nombre ha sido expulsado del grupo.',
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al expulsar: $e')));
        }
      }
    }
  }

  void _reportarUsuario(String usuarioId, String nombre) {
    final TextEditingController motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reportar a $nombre',
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Indica el motivo del reporte:',
                style: GoogleFonts.lexend(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: motivoCtrl,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ej. Comportamiento indebido, spam...',
                  hintStyle: GoogleFonts.lexend(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE65100),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El reporte será enviado a los administradores para revisión.',
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: GoogleFonts.lexend(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                final motivo = motivoCtrl.text.trim();
                if (motivo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Por favor escribe el motivo del reporte.',
                        style: GoogleFonts.lexend(),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);

                try {
                  final user = _supabase.auth.currentUser;
                  // Solo registrar el reporte — NO expulsar automáticamente
                  await _supabase.from('reportes_usuarios').insert({
                    'reportado_id': usuarioId,
                    'reportado_por': user?.id,
                    'motivo': motivo,
                    'sala_id': _currentSalaId,
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Reporte enviado. Los administradores lo revisarán.',
                          style: GoogleFonts.lexend(),
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al enviar reporte: $e',
                          style: GoogleFonts.lexend(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Enviar Reporte',
                style: GoogleFonts.lexend(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bloquearUsuario(String usuarioId, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bloquear a $nombre',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas bloquear a $nombre? Ya no verás sus mensajes en esta sala.',
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final user = _supabase.auth.currentUser;
                await _supabase.from('usuarios_bloqueados').insert({
                  'bloqueado_id': usuarioId,
                  'bloqueado_por': user?.id,
                });
              } catch (e) {
                // Si ya está bloqueado (duplicate key), ignorar silenciosamente
              }

              if (mounted) {
                setState(() {
                  _usuariosBloqueados.add(usuarioId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$nombre bloqueado. Ya no verás sus mensajes.',
                      style: GoogleFonts.lexend(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(
              'Bloquear',
              style: GoogleFonts.lexend(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _desbloquearUsuario(String usuarioId, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Desbloquear a $nombre',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Deseas desbloquear a $nombre? Volverás a ver sus mensajes en esta sala.',
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _ejecutarDesbloqueo(usuarioId, nombre: nombre);
            },
            child: Text(
              'Desbloquear',
              style: GoogleFonts.lexend(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarUsuariosBloqueadosDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Usuarios bloqueados',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _obtenerUsuariosBloqueadosConNombre(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFE65100)),
                  ),
                );
              }

              final bloqueados = snapshot.data ?? [];
              if (bloqueados.isEmpty) {
                return Text(
                  'No tienes usuarios bloqueados.',
                  style: GoogleFonts.lexend(color: Colors.grey),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: bloqueados.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final usuario = bloqueados[index];
                  final id = usuario['id'].toString();
                  final nombre = usuario['nombre'].toString();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade400,
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      nombre,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await _ejecutarDesbloqueo(id, nombre: nombre);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(
                        'Desbloquear',
                        style: GoogleFonts.lexend(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cerrar',
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarEliminarMiembroDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final currentUserId = _supabase.auth.currentUser?.id;
        final listMiembrosExcluyendoCreador = _miembros
            .where((m) => m['id'].toString() != currentUserId)
            .toList();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Eliminar miembro del grupo',
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
          ),
          content: listMiembrosExcluyendoCreador.isEmpty
              ? Text(
                  'No hay otros miembros en este grupo.',
                  style: GoogleFonts.lexend(),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: listMiembrosExcluyendoCreador.length,
                    itemBuilder: (context, index) {
                      final m = listMiembrosExcluyendoCreador[index];
                      final id = m['id'].toString();
                      final nombreCompleto =
                          '${m['primer_nombre'] ?? ''} ${m['primer_apellido'] ?? ''}'
                              .trim();
                      return Material(
                        color: Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: Text(
                              nombreCompleto.isNotEmpty
                                  ? nombreCompleto[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.lexend(color: Colors.black87),
                            ),
                          ),
                          title: Text(
                            nombreCompleto,
                            style: GoogleFonts.lexend(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.person_remove,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _expulsarMiembro(id, nombreCompleto);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cerrar',
                style: GoogleFonts.lexend(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarInfoGrupoDialog() {
    final currentUserId = _supabase.auth.currentUser?.id;
    final esCreador =
        (_creadorId != null && currentUserId == _creadorId) || _esAdminActual;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFFE65100),
                          child: Text(
                            _currentNombreGrupo.isNotEmpty
                                ? _currentNombreGrupo[0].toUpperCase()
                                : 'G',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentNombreGrupo,
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Detalles',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetalleRow(
                    icon: Icons.book_outlined,
                    texto:
                        (_materia.isNotEmpty &&
                            _materia != 'Sin materia' &&
                            _materia != 'Cargando...')
                        ? _materia
                        : null,
                    placeholder: 'Sin materia',
                  ),
                  const SizedBox(height: 10),
                  _buildDetalleRow(
                    icon: Icons.calendar_today_outlined,
                    texto: (_fecha != 'Desconocida' && _fecha != 'Cargando...')
                        ? 'Creado el $_fecha'
                        : null,
                    placeholder: 'Fecha desconocida',
                  ),
                  const SizedBox(height: 10),
                  _buildDetalleRow(
                    icon: Icons.admin_panel_settings_outlined,
                    texto: _textoAdministradores().isNotEmpty
                        ? _textoAdministradores()
                        : null,
                    placeholder: 'Sin administradores',
                    prefixLabel: 'Admins: ',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Descripción',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (_descripcionGrupo?.isNotEmpty == true)
                        ? _descripcionGrupo!
                        : 'Sin descripción',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: (_descripcionGrupo?.isNotEmpty == true)
                          ? const Color(0xFF444444)
                          : Colors.grey,
                      fontStyle: (_descripcionGrupo?.isNotEmpty == true)
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE3BFB1)),
                  const SizedBox(height: 16),
                  Text(
                    'Miembros (${_miembros.length})',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_miembros.isEmpty)
                    Text(
                      'No hay miembros registrados.',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    )
                  else
                    ..._miembros.map(
                      (m) => _buildMemberTile(m, currentUserId, esCreador),
                    ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE3BFB1)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarUsuariosBloqueadosDialog();
                      },
                      icon: const Icon(Icons.block, size: 18, color: Colors.red),
                      label: Text(
                        _usuariosBloqueados.isEmpty
                            ? 'Usuarios bloqueados'
                            : 'Usuarios bloqueados (${_usuariosBloqueados.length})',
                        style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFFE3BFB1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _invitarPorCorreo();
                      },
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: Text(
                        'Invitar por correo',
                        style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        backgroundColor: const Color(0xFFF2EFED),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _abandonarChat();
                      },
                      icon: const Icon(
                        Icons.exit_to_app,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: Text(
                        'Abandonar Chat',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: const Color(0xFFF2EFED),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_puedeEliminarGrupo()) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _eliminarGrupo();
                        },
                        icon: const Icon(
                          Icons.delete_forever_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Eliminar grupo',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _textoAdministradores() {
    final admins = _miembros.where((m) => m['es_admin'] == true).toList();
    if (admins.isEmpty && _creadorId != null) {
      final creador = _miembros.firstWhere(
        (m) => m['id'].toString() == _creadorId,
        orElse: () => {},
      );
      final nombre =
          '${creador['primer_nombre'] ?? ''} ${creador['primer_apellido'] ?? ''}'
              .trim();
      return nombre.isNotEmpty ? nombre : 'Administrador';
    }
    return admins
        .map((m) {
          final n = '${m['primer_nombre'] ?? ''} ${m['primer_apellido'] ?? ''}'
              .trim();
          return n.isNotEmpty ? n : 'Usuario';
        })
        .join(', ');
  }

  Widget _buildMemberTile(
    Map<String, dynamic> miembro,
    String? currentUserId,
    bool esCreador,
  ) {
    final miembroId = miembro['id'].toString();
    final nombre =
        '${miembro['primer_nombre'] ?? ''} ${miembro['primer_apellido'] ?? ''}'
            .trim();
    final correo = miembro['correo'] ?? '';
    final esTuMismo = miembroId == currentUserId;
    final esCreadorMiembro = miembroId == _creadorId;
    final esAdminMiembro = miembro['es_admin'] == true;
    final estaBloqueado = _estaBloqueado(miembroId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: esTuMismo ? const Color(0xFFFFF8F0) : const Color(0xFFFDFBF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esTuMismo
              ? const Color(0xFFE65100).withOpacity(0.3)
              : const Color(0xFFEDE8E4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: esCreadorMiembro
                ? const Color(0xFFE65100)
                : Colors.grey.shade400,
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        esTuMismo ? '$nombre (Tú)' : nombre,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (esCreadorMiembro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Creador',
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (esAdminMiembro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Admin',
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (estaBloqueado) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Bloqueado',
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (correo.isNotEmpty)
                  Text(
                    correo,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!esTuMismo)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: Colors.black38,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'expulsar') {
                  _expulsarMiembro(miembroId, nombre);
                } else if (value == 'reportar') {
                  _reportarUsuario(miembroId, nombre);
                } else if (value == 'bloquear') {
                  _bloquearUsuario(miembroId, nombre);
                } else if (value == 'desbloquear') {
                  _desbloquearUsuario(miembroId, nombre);
                } else if (value == 'agregar_amigo') {
                  _agregarAmigo(miembroId, nombre);
                } else if (value == 'eliminar_grupo') {
                  _expulsarMiembro(miembroId, nombre);
                } else if (value == 'dar_admin') {
                  _darAdmin(miembroId, nombre);
                } else if (value == 'quitar_admin') {
                  _quitarAdmin(miembroId, nombre);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'agregar_amigo',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_add_outlined,
                        size: 18,
                        color: Color(0xFFE65100),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Agregar amigo',
                        style: GoogleFonts.lexend(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reportar',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.report_problem_outlined,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text('Reportar', style: GoogleFonts.lexend(fontSize: 13)),
                    ],
                  ),
                ),
                if (estaBloqueado)
                  PopupMenuItem(
                    value: 'desbloquear',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_open,
                          size: 18,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Desbloquear',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  PopupMenuItem(
                    value: 'bloquear',
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Bloquear',
                          style: GoogleFonts.lexend(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (_esAdminActual && !esCreadorMiembro && !esAdminMiembro)
                  PopupMenuItem(
                    value: 'dar_admin',
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dar permisos Admin',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_esAdminActual && esAdminMiembro && !esCreadorMiembro)
                  PopupMenuItem(
                    value: 'quitar_admin',
                    child: Row(
                      children: [
                        Icon(
                          Icons.remove_moderator_outlined,
                          size: 18,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quitar Admin',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_esAdminActual && !esCreadorMiembro)
                  PopupMenuItem(
                    value: 'eliminar_grupo',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_remove,
                          size: 18,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eliminar del grupo',
                          style: GoogleFonts.lexend(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _agregarAmigo(String usuarioId, String nombre) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Verificar si ya son amigos (tabla amigos: usuario_id + amigo_id)
      final yaAmigo1 = await _supabase
          .from('amigos')
          .select('id')
          .eq('usuario_id', user.id)
          .eq('amigo_id', usuarioId)
          .maybeSingle();

      final yaAmigo2 = yaAmigo1 == null
          ? await _supabase
                .from('amigos')
                .select('id')
                .eq('usuario_id', usuarioId)
                .eq('amigo_id', user.id)
                .maybeSingle()
          : null;

      if (yaAmigo1 != null || yaAmigo2 != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ya eres amigo de $nombre.',
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. Verificar si ya hay solicitud pendiente (tabla solicitudes_amistad)
      final solicitud1 = await _supabase
          .from('solicitudes_amistad')
          .select('id')
          .eq('remitente_id', user.id)
          .eq('destinatario_id', usuarioId)
          .maybeSingle();

      final solicitud2 = solicitud1 == null
          ? await _supabase
                .from('solicitudes_amistad')
                .select('id')
                .eq('remitente_id', usuarioId)
                .eq('destinatario_id', user.id)
                .maybeSingle()
          : null;

      if (solicitud1 != null || solicitud2 != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ya existe una solicitud pendiente con $nombre.',
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 3. Enviar solicitud de amistad
      await _supabase.from('solicitudes_amistad').insert({
        'remitente_id': user.id,
        'destinatario_id': usuarioId,
        'estado': 'pendiente',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitud de amistad enviada a $nombre.',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al agregar amigo: $e')));
      }
    }
  }

  Future<void> _darAdmin(String usuarioId, String nombre) async {
    if (!_esAdminActual) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solo un administrador puede dar permisos de admin.',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Dar permisos de Admin',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Deseas dar permisos de administrador a $nombre? Podrá expulsar miembros y editar el grupo.',
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Dar Admin',
              style: GoogleFonts.lexend(
                color: const Color(0xFFE65100),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = _supabase.auth.currentUser;

        await _supabase
            .from('participantes_sala')
            .update({'es_admin': true})
            .eq('sala_id', _currentSalaId)
            .eq('usuario_id', usuarioId);

        // El admin actual conserva sus permisos (ambos son administradores)
        if (user != null) {
          final yoParticipante = await _supabase
              .from('participantes_sala')
              .select('usuario_id')
              .eq('sala_id', _currentSalaId)
              .eq('usuario_id', user.id)
              .maybeSingle();

          if (yoParticipante == null) {
            await _supabase.from('participantes_sala').insert({
              'sala_id': _currentSalaId,
              'usuario_id': user.id,
              'es_admin': true,
            });
          } else {
            await _supabase
                .from('participantes_sala')
                .update({'es_admin': true})
                .eq('sala_id', _currentSalaId)
                .eq('usuario_id', user.id);
          }
        }

        if (mounted) setState(() => _esAdminActual = true);
        _cargarMiembros();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$nombre ahora es administrador del grupo.',
                style: GoogleFonts.lexend(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al dar admin: $e')));
        }
      }
    }
  }

  Future<void> _quitarAdmin(String usuarioId, String nombre) async {
    if (!_esAdminActual) return;

    // No puede quitarse admin a sí mismo si es el creador
    final esCreador = usuarioId == _creadorId;
    if (esCreador) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pueden quitar los permisos al creador del grupo.',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await _supabase
          .from('participantes_sala')
          .update({'es_admin': false})
          .eq('sala_id', _currentSalaId)
          .eq('usuario_id', usuarioId);

      _cargarMiembros();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se quitaron los permisos de admin a $nombre.',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _abandonarChat() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Abandonar chat',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que quieres abandonar "$_currentNombreGrupo"?',
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Abandonar',
              style: GoogleFonts.lexend(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase
            .from('participantes_sala')
            .delete()
            .eq('sala_id', _currentSalaId)
            .eq('usuario_id', user.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al abandonar: $e')));
        }
      }
    }
  }

  bool _puedeEliminarGrupo() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    return _esAdminActual || (_creadorId != null && user.id == _creadorId);
  }

  Future<void> _eliminarGrupo() async {
    if (!_puedeEliminarGrupo()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solo un administrador puede eliminar el grupo.',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar grupo',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Eliminar "$_currentNombreGrupo" permanentemente? Se borrarán los mensajes y no se podrá recuperar.',
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.lexend(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.lexend(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final salaId = _currentSalaId;
    final nombreGrupo = _currentNombreGrupo;
    final creadorId = _creadorId;

    try {
      await _supabase.from('mensajes_chat').delete().eq('sala_id', salaId);
      await _supabase.from('participantes_sala').delete().eq('sala_id', salaId);
      await _supabase.from('salas_chat').delete().eq('id', salaId);

      try {
        var query = _supabase
            .from('grupos_estudio')
            .delete()
            .eq('nombre', nombreGrupo);
        if (creadorId != null) {
          query = query.eq('creado_por', creadorId);
        }
        await query;
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _salasFuture = _cargarSalas();
        _salasPublicasFuture = _cargarSalasPublicas();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Grupo "$nombreGrupo" eliminado.',
            style: GoogleFonts.lexend(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      final salas = await _cargarSalas();
      if (!mounted) return;
      if (salas.isNotEmpty) {
        _seleccionarSala(
          salas.first['id'].toString(),
          salas.first['nombre']?.toString() ?? 'Grupo',
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar grupo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarCrearGrupoDialog() {
    final nombreCtrl = TextEditingController();
    final materiaCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.group_add, color: Color(0xFFE65100), size: 22),
              const SizedBox(width: 8),
              Text(
                'Crear nuevo grupo',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  style: GoogleFonts.lexend(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Nombre del grupo',
                    labelStyle: GoogleFonts.lexend(fontSize: 13),
                    hintText: 'Ej: Mate II sección 2',
                    hintStyle: GoogleFonts.lexend(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(Icons.group_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE65100),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: materiaCtrl,
                  style: GoogleFonts.lexend(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Materia',
                    labelStyle: GoogleFonts.lexend(fontSize: 13),
                    hintText: 'Ej: Matemáticas II',
                    hintStyle: GoogleFonts.lexend(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(Icons.book_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE65100),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descripcionCtrl,
                  maxLines: 3,
                  style: GoogleFonts.lexend(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: GoogleFonts.lexend(fontSize: 13),
                    hintText: 'Objetivo del grupo, horarios, etc.',
                    hintStyle: GoogleFonts.lexend(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description_outlined, size: 18),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE65100),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: GoogleFonts.lexend(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final nombre = nombreCtrl.text.trim();
                      final materia = materiaCtrl.text.trim();
                      final descripcion = descripcionCtrl.text.trim();

                      if (nombre.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'El nombre del grupo es obligatorio',
                              style: GoogleFonts.lexend(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final user = _supabase.auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Debes iniciar sesión'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        // Insertar en salas_chat y grupos_estudio
                        final result = await _supabase
                            .from('salas_chat')
                            .insert({
                              'nombre': nombre,
                              'materia': materia.isEmpty ? null : materia,
                              'descripcion': descripcion.isEmpty
                                  ? null
                                  : descripcion,
                              'creado_por': user.id,
                            })
                            .select()
                            .single();

                        final salaId = result['id'].toString();

                        await _supabase.from('grupos_estudio').insert({
                          'nombre': nombre,
                          'materia': materia.isEmpty ? 'Sin materia' : materia,
                          'descripcion': descripcion.isEmpty
                              ? null
                              : descripcion,
                          'creado_por': user.id,
                          'seccion': 1,
                          'max_miembros': 20,
                          'es_privado': false,
                        });

                        // Agregar al creador como participante y admin
                        await _supabase.from('participantes_sala').insert({
                          'sala_id': salaId,
                          'usuario_id': user.id,
                          'es_admin': true,
                        });

                        if (!mounted) return;
                        Navigator.pop(ctx);

                        // Actualizar lista de salas y seleccionar la nueva
                        setState(() {
                          _salasFuture = _cargarSalas();
                          _salasPublicasFuture = _cargarSalasPublicas();
                          _esAdminActual = true;
                          _descripcionGrupo = descripcion.isEmpty
                              ? null
                              : descripcion;
                        });
                        _seleccionarSala(salaId, nombre);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '¡Grupo "$nombre" creado exitosamente! 🎉',
                              style: GoogleFonts.lexend(),
                            ),
                            backgroundColor: const Color(0xFFE65100),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al crear grupo: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Crear grupo',
                      style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msg, {
    required bool esMio,
    required String remitenteNombre,
  }) {
    final adjunto = _extraerAdjunto(msg);
    final archivoUrl = adjunto?.url;
    final tipoArchivo = adjunto?.tipo;
    final nombreArchivo = adjunto?.nombre;
    final texto = adjunto?.texto ?? msg['texto'] as String?;

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: esMio ? const Color(0xFFE65100) : Colors.white,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: esMio
                ? const Radius.circular(0)
                : const Radius.circular(12),
            bottomLeft: esMio
                ? const Radius.circular(12)
                : const Radius.circular(0),
          ),
          border: esMio ? null : Border.all(color: const Color(0xFFE3BFB1)),
        ),
        child: Column(
          crossAxisAlignment: esMio
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Imagen/video/documento adjunto
            if (archivoUrl != null) ...[
              if (tipoArchivo == 'imagen')
                GestureDetector(
                  onTap: () => _abrirArchivo(archivoUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      archivoUrl,
                      width: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => _abrirArchivo(archivoUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tipoArchivo == 'video'
                              ? Icons.videocam_outlined
                              : tipoArchivo == 'audio'
                              ? Icons.audiotrack_outlined
                              : Icons.insert_drive_file_outlined,
                          size: 20,
                          color: esMio
                              ? Colors.white70
                              : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            nombreArchivo ?? 'Archivo',
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: esMio
                                  ? Colors.white
                                  : const Color(0xFF2E2E2E),
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            // Texto del mensaje
            if (texto != null && texto.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  archivoUrl != null ? 4 : 10,
                  14,
                  10,
                ),
                child: Column(
                  crossAxisAlignment: esMio
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!esMio)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          remitenteNombre,
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    Text(
                      texto,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: esMio ? Colors.white : const Color(0xFF2E2E2E),
                      ),
                    ),
                  ],
                ),
              )
            else if (archivoUrl == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: esMio
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!esMio)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          remitenteNombre,
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    Text(
                      '',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: esMio ? Colors.white : const Color(0xFF2E2E2E),
                      ),
                    ),
                  ],
                ),
              )
            else if (!esMio && texto == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                child: Text(
                  remitenteNombre,
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(String label, int index) {
    final isSelected = _selectedNavTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedNavTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFFE65100)
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFFE65100)
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // PANEL IZQUIERDO: Lista de chats
  Widget _buildLeftPane() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      child: Column(
        children: [
          // Tabs de navegación: Mis Grupos / Grupos Públicos / Amigos
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE3BFB1))),
            ),
            child: Row(
              children: [
                _buildNavTab('Mis Grupos', 0),
                _buildNavTab('Grupos Públicos', 1),
                _buildNavTab('Amigos', 2),
              ],
            ),
          ),
          // Barra de búsqueda de grupos
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4F1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3BFB1)),
              ),
              child: TextField(
                controller: _searchGroupCtrl,
                onChanged: (v) {
                  setState(() {
                    _searchGroupQuery = v;
                  });
                },
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar grupos...',
                  hintStyle: GoogleFonts.lexend(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.grey,
                  ),
                  suffixIcon: _searchGroupQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 14,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchGroupCtrl.clear();
                              _searchGroupQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE3BFB1)),
          Expanded(
            child: _selectedNavTab == 2
                // Tab "Amigos": placeholder
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Próximamente\npodrás ver tus amigos aquí',
                            style: GoogleFonts.lexend(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _selectedNavTab == 0
                        ? _salasFuture
                        : _salasPublicasFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE65100),
                          ),
                        );
                      }
                      final allSalas = snapshot.data ?? [];
                      final salas = allSalas.where((sala) {
                        final name = (sala['nombre'] ?? '')
                            .toString()
                            .toLowerCase();
                        final subject = (sala['materia'] ?? '')
                            .toString()
                            .toLowerCase();
                        final q = _searchGroupQuery.toLowerCase();
                        return name.contains(q) || subject.contains(q);
                      }).toList();

                      if (salas.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchGroupQuery.isEmpty
                                      ? (_selectedNavTab == 0
                                            ? 'No tienes chats aún'
                                            : 'No hay grupos públicos disponibles')
                                      : 'No se encontraron grupos',
                                  style: GoogleFonts.lexend(
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: salas.length,
                        itemBuilder: (context, index) {
                          final sala = salas[index];
                          final isSelected = sala['id'] == _currentSalaId;
                          final esAdminSala = sala['soy_admin'] == true;
                          return Material(
                            color: isSelected
                                ? const Color(0xFFFFF3E0)
                                : Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? const Color(0xFFE65100)
                                    : Colors.grey.shade300,
                                child: Text(
                                  sala['nombre'] != null &&
                                          sala['nombre'].isNotEmpty
                                      ? sala['nombre'][0].toUpperCase()
                                      : 'G',
                                  style: GoogleFonts.lexend(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              title: Text(
                                sala['nombre'] ?? 'Sin nombre',
                                style: GoogleFonts.lexend(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                sala['materia'] ?? 'Sin materia',
                                style: GoogleFonts.lexend(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: _selectedNavTab == 0 && esAdminSala
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red.shade400,
                                      ),
                                      tooltip: 'Eliminar grupo',
                                      onPressed: () {
                                        _seleccionarSala(
                                          sala['id'].toString(),
                                          sala['nombre'] ?? 'Sala',
                                        );
                                        _eliminarGrupo();
                                      },
                                    )
                                  : null,
                              onTap: () => _seleccionarSala(
                                sala['id'].toString(),
                                sala['nombre'] ?? 'Sala',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // PANEL CENTRAL: Mensajes
  Widget _buildMiddlePane(bool isDesktop) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final esCreador =
        (_creadorId != null && currentUserId == _creadorId) || _esAdminActual;

    return Expanded(
      child: Container(
        color: const Color(0xFFF7F4F1),
        child: Column(
          children: [
            // Cabecera superior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE3BFB1))),
              ),
              child: Row(
                children: [
                  // Botón de salir del chat
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF4A4A4A),
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Salir del chat',
                  ),
                  const SizedBox(width: 4),
                  if (_isSearchingMessages)
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4F1),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: const Color(0xFFE3BFB1)),
                        ),
                        child: TextField(
                          controller: _searchMessageCtrl,
                          autofocus: true,
                          style: GoogleFonts.lexend(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Buscar mensajes...',
                            hintStyle: GoogleFonts.lexend(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 16,
                              color: Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSearchingMessages = false;
                                  _searchMessageCtrl.clear();
                                  _searchMessageQuery = '';
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _searchMessageQuery = v;
                            });
                          },
                        ),
                      ),
                    )
                  else ...[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE65100),
                      child: Text(
                        _currentNombreGrupo.isNotEmpty
                            ? _currentNombreGrupo[0].toUpperCase()
                            : 'G',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentNombreGrupo,
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: _mostrarInfoGrupoDialog,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              '${_miembros.length} miembros',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: Colors.black54,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Lupa de buscar mensajes
                  if (!_isSearchingMessages)
                    IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF4A4A4A)),
                      onPressed: () {
                        setState(() {
                          _isSearchingMessages = true;
                        });
                      },
                      tooltip: 'Buscar mensajes',
                    ),
                  // Botón de invitar (siempre visible)
                  IconButton(
                    icon: const Icon(
                      Icons.person_add_alt_1,
                      color: Color(0xFFE65100),
                    ),
                    onPressed: _invitarPorCorreo,
                    tooltip: 'Invitar persona',
                  ),
                  // Botón de eliminar miembro (solo si es creador)
                  if (esCreador)
                    IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: _mostrarEliminarMiembroDialog,
                      tooltip: 'Eliminar miembro',
                    ),
                  // Botón de tres puntos
                  IconButton(
                    icon: Icon(
                      _mostrarPanelDerecho && isDesktop
                          ? Icons.close
                          : Icons.more_vert,
                      color: const Color(0xFF4A4A4A),
                    ),
                    onPressed: () {
                      if (isDesktop) {
                        setState(() {
                          _mostrarPanelDerecho = !_mostrarPanelDerecho;
                        });
                      } else {
                        _mostrarInfoGrupoDialog();
                      }
                    },
                    tooltip: 'Información del grupo',
                  ),
                ],
              ),
            ),
            // Stream de mensajes
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _mensajesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE65100),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar mensajes: ${snapshot.error}',
                      ),
                    );
                  }

                  final allMensajes =
                      _filtrarMensajesBloqueados(snapshot.data ?? []);
                  final mensajes = _searchMessageQuery.isEmpty
                      ? allMensajes
                      : allMensajes.where((m) {
                          final text = (m['texto'] ?? '')
                              .toString()
                              .toLowerCase();
                          return text.contains(
                            _searchMessageQuery.toLowerCase(),
                          );
                        }).toList();

                  if (mensajes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchMessageQuery.isEmpty
                                ? 'No hay mensajes aún.\n¡Sé el primero en escribir!'
                                : 'No se encontraron mensajes',
                            style: GoogleFonts.lexend(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) {
                      final msg = mensajes[index];
                      final remitenteId = msg['remitente_id'] as String?;

                      final esMio =
                          (remitenteId != null &&
                              remitenteId == currentUserId) ||
                          msg['remitente'] == 'Yo';

                      if (esMio) {
                        return _buildMessageBubble(
                          msg,
                          esMio: true,
                          remitenteNombre: '',
                        );
                      }

                      return FutureBuilder<String>(
                        future: _obtenerNombre(
                          remitenteId,
                          msg['remitente'] as String?,
                        ),
                        builder: (context, snapshot) {
                          final nombre = snapshot.data ?? 'Cargando...';
                          return _buildMessageBubble(
                            msg,
                            esMio: false,
                            remitenteNombre: nombre,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            // Input de mensajes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF0EAE6))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview archivo adjunto
                  if (_archivoAdjunto != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE65100).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getTipoArchivo(_archivoAdjunto!.extension ?? '') ==
                                    'imagen'
                                ? Icons.image_outlined
                                : _getTipoArchivo(
                                        _archivoAdjunto!.extension ?? '',
                                      ) ==
                                      'video'
                                ? Icons.videocam_outlined
                                : Icons.insert_drive_file_outlined,
                            size: 18,
                            color: const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _archivoAdjunto!.name,
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: const Color(0xFF333333),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(_archivoAdjunto!.size / 1024).toStringAsFixed(0)} KB',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _archivoAdjunto = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  // Fila de texto + enviar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFBF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE3BFB1)),
                          ),
                          child: TextField(
                            controller: _messageCtrl,
                            style: GoogleFonts.lexend(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              hintStyle: GoogleFonts.lexend(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  Icons.attach_file,
                                  color: _archivoAdjunto != null
                                      ? const Color(0xFFE65100)
                                      : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: _seleccionarArchivo,
                                tooltip: 'Adjuntar imagen, video o documento',
                              ),
                            ),
                            onSubmitted: (_) => _enviarMensaje(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE65100),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _enviarMensaje,
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

  Widget _buildDetalleRow({
    required IconData icon,
    String? texto,
    String placeholder = '',
    String prefixLabel = '',
  }) {
    final hasValue = texto != null && texto.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: hasValue ? Colors.black54 : Colors.grey.shade400,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            hasValue ? '$prefixLabel$texto' : placeholder,
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: hasValue ? const Color(0xFF333333) : Colors.grey.shade400,
              fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // PANEL DERECHO: Detalles del grupo + Miembros
  Widget _buildRightPane() {
    final currentUserId = _supabase.auth.currentUser?.id;
    final esCreador =
        (_creadorId != null && currentUserId == _creadorId) || _esAdminActual;

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información del grupo',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarPanelDerecho = false;
                    });
                  },
                  tooltip: 'Cerrar panel',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE3BFB1)),
          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar y nombre del grupo
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFFE65100),
                          child: Text(
                            _currentNombreGrupo.isNotEmpty
                                ? _currentNombreGrupo[0].toUpperCase()
                                : 'G',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentNombreGrupo,
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detalles
                  Text(
                    'Detalles',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Materia
                  // Materia
                  _buildDetalleRow(
                    icon: Icons.book_outlined,
                    texto:
                        (_materia.isNotEmpty &&
                            _materia != 'Sin materia' &&
                            _materia != 'Cargando...')
                        ? _materia
                        : null,
                    placeholder: 'Sin materia',
                  ),
                  const SizedBox(height: 10),
                  // Fecha
                  _buildDetalleRow(
                    icon: Icons.calendar_today_outlined,
                    texto: (_fecha != 'Desconocida' && _fecha != 'Cargando...')
                        ? 'Creado el $_fecha'
                        : null,
                    placeholder: 'Fecha desconocida',
                  ),
                  const SizedBox(height: 10),
                  // Administradores
                  _buildDetalleRow(
                    icon: Icons.admin_panel_settings_outlined,
                    texto: _textoAdministradores().isNotEmpty
                        ? _textoAdministradores()
                        : null,
                    placeholder: 'Sin administradores',
                    prefixLabel: 'Admins: ',
                  ),
                  const SizedBox(height: 10),
                  // Miembros count
                  _buildDetalleRow(
                    icon: Icons.people_outlined,
                    texto:
                        '${_miembros.length} miembro${_miembros.length == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 16),
                  // Descripción editable
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Descripción',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_esAdminActual)
                        IconButton(
                          icon: Icon(
                            _editandoDescripcion
                                ? Icons.check
                                : Icons.edit_outlined,
                            size: 16,
                            color: _editandoDescripcion
                                ? Colors.green
                                : const Color(0xFFE65100),
                          ),
                          onPressed: () {
                            if (_editandoDescripcion) {
                              _guardarDescripcion(
                                _descEditCtrl?.text.trim() ??
                                    _descripcionGrupo ??
                                    '',
                              );
                            } else {
                              _descEditCtrl = TextEditingController(
                                text: _descripcionGrupo ?? '',
                              );
                              setState(() => _editandoDescripcion = true);
                            }
                          },
                          tooltip: _editandoDescripcion
                              ? 'Guardar'
                              : 'Editar descripción',
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_editandoDescripcion && _esAdminActual)
                    TextField(
                      controller: _descEditCtrl,
                      maxLines: 3,
                      style: GoogleFonts.lexend(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Describe el grupo...',
                        hintStyle: GoogleFonts.lexend(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE3BFB1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE65100),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    )
                  else
                    Text(
                      (_descripcionGrupo?.isNotEmpty == true)
                          ? _descripcionGrupo!
                          : 'Sin descripción',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: (_descripcionGrupo?.isNotEmpty == true)
                            ? const Color(0xFF444444)
                            : Colors.grey,
                        fontStyle: (_descripcionGrupo?.isNotEmpty == true)
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE3BFB1)),
                  const SizedBox(height: 16),

                  // Miembros del grupo
                  Text(
                    'Miembros (${_miembros.length})',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_miembros.isEmpty)
                    Text(
                      'No hay miembros registrados.',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    )
                  else
                    ..._miembros.map(
                      (miembro) =>
                          _buildMemberTile(miembro, currentUserId, esCreador),
                    ),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE3BFB1)),
                  const SizedBox(height: 16),

                  // Botones de acción
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _mostrarUsuariosBloqueadosDialog,
                      icon: const Icon(Icons.block, size: 18, color: Colors.red),
                      label: Text(
                        _usuariosBloqueados.isEmpty
                            ? 'Usuarios bloqueados'
                            : 'Usuarios bloqueados (${_usuariosBloqueados.length})',
                        style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFFE3BFB1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _invitarPorCorreo,
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: Text(
                        'Invitar por correo',
                        style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        backgroundColor: const Color(0xFFF2EFED),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _abandonarChat,
                      icon: const Icon(
                        Icons.exit_to_app,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: Text(
                        'Abandonar Chat',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: const Color(0xFFF2EFED),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_puedeEliminarGrupo()) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _eliminarGrupo,
                        icon: const Icon(
                          Icons.delete_forever_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Eliminar grupo',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      appBar: const UniteHeader(currentIndex: 4),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return Row(
            children: [
              if (isDesktop) _buildLeftPane(),
              _buildMiddlePane(isDesktop),
              // Panel derecho SOLO se muestra si el toggle está activo
              if (_mostrarPanelDerecho && isDesktop) _buildRightPane(),
            ],
          );
        },
      ),
    );
  }
}
