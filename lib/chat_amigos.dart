import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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

/// Página de chat directo (1 a 1) entre amigos.
///
/// Puede abrirse de dos formas:
/// - Indicando [amigoId] y [nombreAmigo]: la página resuelve/crea la
///   conversación directa entre el usuario actual y ese amigo.
/// - Indicando [conversacionInicialId]: abre directamente esa conversación
///   (útil al volver desde notificaciones, por ejemplo).
class ChatAmigosPage extends StatefulWidget {
  final String? amigoId;
  final String? nombreAmigo;
  final String? conversacionInicialId;

  const ChatAmigosPage({
    super.key,
    this.amigoId,
    this.nombreAmigo,
    this.conversacionInicialId,
  }) : assert(
         amigoId != null || conversacionInicialId != null,
         'Debes indicar amigoId o conversacionInicialId',
       );

  @override
  State<ChatAmigosPage> createState() => _ChatAmigosPageState();
}

class _ChatAmigosPageState extends State<ChatAmigosPage> {
  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _searchAmigoCtrl = TextEditingController();
  final TextEditingController _searchMessageCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;

  String? _currentConversacionId;
  String? _currentAmigoId;
  String _currentNombreAmigo = 'Cargando...';
  String? _currentCarrera;
  String? _currentFotoUrl;

  late Stream<List<Map<String, dynamic>>> _mensajesStream;
  late Future<List<Map<String, dynamic>>> _amigosFuture;

  final Map<String, String> _nombresUsuarios = {};

  // Toggle para mostrar/ocultar panel derecho (info del amigo)
  bool _mostrarPanelDerecho = false;

  // Búsqueda de amigos y mensajes
  String _searchAmigoQuery = '';
  String _searchMessageQuery = '';
  bool _isSearchingMessages = false;

  // IDs de usuarios bloqueados por el usuario actual
  Set<String> _usuariosBloqueados = {};

  // IDs de conversaciones ocultas/eliminadas por el usuario actual
  Set<String> _conversacionesOcultas = {};

  // Archivo adjunto pendiente de enviar
  PlatformFile? _archivoAdjunto;

  bool _isLoadingInicial = true;

  @override
  void initState() {
    super.initState();
    _amigosFuture = _cargarAmigos();
    _initMensajesStreamVacio();
    _inicializar();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _searchAmigoCtrl.dispose();
    _searchMessageCtrl.dispose();
    super.dispose();
  }

  void _initMensajesStreamVacio() {
    // Stream "vacío" mientras se resuelve la conversación, para que el
    // build no falle con un `late` field sin inicializar.
    _mensajesStream = const Stream.empty();
  }

  Future<void> _inicializar() async {
    await _cargarConversacionesOcultas();
    await _cargarUsuariosBloqueados();

    if (widget.conversacionInicialId != null) {
      await _abrirConversacionPorId(widget.conversacionInicialId!);
    } else if (widget.amigoId != null) {
      await _abrirOCrearConversacionConAmigo(
        widget.amigoId!,
        widget.nombreAmigo,
      );
    }

    if (mounted) {
      setState(() => _isLoadingInicial = false);
    }
  }

  // ---------------------------------------------------------------------
  // Carga / resolución de conversaciones
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _cargarAmigos() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // 1) Traer relaciones de amistad aceptadas en cualquiera de los dos sentidos
      final comoUsuario = await _supabase
          .from('amigos')
          .select('amigo_id, estado')
          .eq('usuario_id', user.id)
          .eq('estado', 'aceptados');

      final comoAmigo = await _supabase
          .from('amigos')
          .select('usuario_id, estado')
          .eq('amigo_id', user.id)
          .eq('estado', 'aceptados');

      final Set<String> amigoIds = {};
      for (final r in (comoUsuario as List)) {
        amigoIds.add(r['amigo_id'].toString());
      }
      for (final r in (comoAmigo as List)) {
        amigoIds.add(r['usuario_id'].toString());
      }

      if (amigoIds.isEmpty) return [];

      // 2) Traer datos de usuario de cada amigo
      final usuarios = await _supabase
          .from('usuarios')
          .select(
            'id, primer_nombre, primer_apellido, carrera, foto_perfil_url',
          )
          .inFilter('id', amigoIds.toList());

      // 3) Traer conversaciones directas (anuncio_id null) entre el usuario
      //    actual y cada amigo, para mostrar el último mensaje / no leídos.
      final misConversaciones = await _supabase
          .from('conversaciones')
          .select('id, comprador_id, vendedor_id')
          .filter('anuncio_id', 'is', null)
          .or('comprador_id.eq.${user.id},vendedor_id.eq.${user.id}');

      // Mapear amigoId -> conversacionId (si existe)
      final Map<String, String> conversacionPorAmigo = {};
      for (final c in (misConversaciones as List)) {
        final compradorId = c['comprador_id']?.toString();
        final vendedorId = c['vendedor_id']?.toString();
        String? otro;
        if (compradorId == user.id) {
          otro = vendedorId;
        } else if (vendedorId == user.id) {
          otro = compradorId;
        }
        if (otro != null && amigoIds.contains(otro)) {
          conversacionPorAmigo[otro] = c['id'].toString();
        }
      }

      // 4) Para cada amigo con conversación, traer último mensaje y
      //    conteo de mensajes no leídos enviados por el amigo.
      final List<Map<String, dynamic>> result = [];
      for (final u in (usuarios as List)) {
        final amigoId = u['id'].toString();
        final convId = conversacionPorAmigo[amigoId];

        String? ultimoMensaje;
        String? ultimaFecha;
        int noLeidos = 0;

        if (convId != null) {
          try {
            final ultimos = await _supabase
                .from('mensajes')
                .select('contenido, creado_en, remitente_id, leido')
                .eq('conversacion_id', convId)
                .order('creado_en', ascending: false)
                .limit(1);
            if (ultimos.isNotEmpty) {
              ultimoMensaje = ultimos.first['contenido']?.toString();
              ultimaFecha = ultimos.first['creado_en']?.toString();
            }

            final noLeidosRes = await _supabase
                .from('mensajes')
                .select('id')
                .eq('conversacion_id', convId)
                .eq('remitente_id', amigoId)
                .eq('leido', false);
            noLeidos = (noLeidosRes as List).length;
          } catch (_) {}
        }

        result.add({
          'id': amigoId,
          'primer_nombre': u['primer_nombre'],
          'primer_apellido': u['primer_apellido'],
          'carrera': u['carrera'],
          'foto_perfil_url': u['foto_perfil_url'],
          'conversacion_id': convId,
          'ultimo_mensaje': ultimoMensaje,
          'ultima_fecha': ultimaFecha,
          'no_leidos': noLeidos,
          'oculta': convId != null && _conversacionesOcultas.contains(convId),
        });
      }

      // Ordenar: primero los que tienen conversación reciente, luego alfabético
      result.sort((a, b) {
        final fa = a['ultima_fecha']?.toString();
        final fb = b['ultima_fecha']?.toString();
        if (fa != null && fb != null) return fb.compareTo(fa);
        if (fa != null) return -1;
        if (fb != null) return 1;
        final na = '${a['primer_nombre'] ?? ''} ${a['primer_apellido'] ?? ''}';
        final nb = '${b['primer_nombre'] ?? ''} ${b['primer_apellido'] ?? ''}';
        return na.compareTo(nb);
      });

      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> _abrirConversacionPorId(String conversacionId) async {
    try {
      final conv = await _supabase
          .from('conversaciones')
          .select('id, comprador_id, vendedor_id')
          .eq('id', conversacionId)
          .maybeSingle();

      if (conv == null) return;

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final compradorId = conv['comprador_id']?.toString();
      final vendedorId = conv['vendedor_id']?.toString();
      final otroId = compradorId == user.id ? vendedorId : compradorId;
      if (otroId == null) return;

      await _seleccionarAmigo(otroId, conversacionId: conversacionId);
    } catch (_) {}
  }

  /// Busca una conversación directa (anuncio_id = null) entre el usuario
  /// actual y [amigoId]. Si no existe, la crea.
  Future<void> _abrirOCrearConversacionConAmigo(
    String amigoId,
    String? nombrePrevio,
  ) async {
    await _seleccionarAmigo(amigoId, nombrePrevio: nombrePrevio);
  }

  Future<String> _resolverConversacion(String amigoId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    // Buscar conversación directa existente en cualquiera de los dos sentidos
    final existente1 = await _supabase
        .from('conversaciones')
        .select('id')
        .filter('anuncio_id', 'is', null)
        .eq('comprador_id', user.id)
        .eq('vendedor_id', amigoId)
        .maybeSingle();

    if (existente1 != null) return existente1['id'].toString();

    final existente2 = await _supabase
        .from('conversaciones')
        .select('id')
        .filter('anuncio_id', 'is', null)
        .eq('comprador_id', amigoId)
        .eq('vendedor_id', user.id)
        .maybeSingle();

    if (existente2 != null) return existente2['id'].toString();

    // No existe: crear una nueva conversación directa
    final nueva = await _supabase
        .from('conversaciones')
        .insert({
          'anuncio_id': null,
          'comprador_id': user.id,
          'vendedor_id': amigoId,
        })
        .select()
        .single();

    return nueva['id'].toString();
  }

  Future<void> _seleccionarAmigo(
    String amigoId, {
    String? conversacionId,
    String? nombrePrevio,
  }) async {
    setState(() {
      _isLoadingInicial = true;
      _currentAmigoId = amigoId;
      _currentNombreAmigo = nombrePrevio ?? 'Cargando...';
      _mostrarPanelDerecho = false;
    });

    try {
      // Si esta conversación está oculta para el usuario, al abrirla de
      // nuevo se "des-oculta" (vuelve a aparecer si llegan mensajes nuevos).
      final convId = conversacionId ?? await _resolverConversacion(amigoId);
      if (_conversacionesOcultas.contains(convId)) {
        await _mostrarConversacion(convId);
      }

      // Cargar datos del amigo
      final userData = await _supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido, carrera, foto_perfil_url')
          .eq('id', amigoId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _currentConversacionId = convId;
          if (userData != null) {
            final nombre =
                '${userData['primer_nombre'] ?? ''} ${userData['primer_apellido'] ?? ''}'
                    .trim();
            _currentNombreAmigo = nombre.isNotEmpty ? nombre : 'Usuario';
            _currentCarrera = userData['carrera']?.toString();
            _currentFotoUrl = userData['foto_perfil_url']?.toString();
          }
          _mensajesStream = _supabase
              .from('mensajes')
              .stream(primaryKey: ['id'])
              .eq('conversacion_id', convId)
              .order('creado_en', ascending: true);
          _isLoadingInicial = false;
        });
      }

      _marcarMensajesComoLeidos(convId);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInicial = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo abrir la conversación: $e',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _marcarMensajesComoLeidos(String conversacionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('mensajes')
          .update({'leido': true})
          .eq('conversacion_id', conversacionId)
          .neq('remitente_id', user.id)
          .eq('leido', false);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Eliminar / ocultar conversaciones (sin afectar al otro usuario)
  // ---------------------------------------------------------------------

  Future<void> _cargarConversacionesOcultas() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('conversaciones_ocultas')
          .select('conversacion_id')
          .eq('usuario_id', user.id);

      if (mounted) {
        setState(() {
          _conversacionesOcultas = (data as List)
              .map((r) => r['conversacion_id'].toString())
              .toSet();
        });
      }
    } catch (_) {
      // Si la tabla no existe todavía, simplemente no se podrá ocultar chats
      // hasta que se cree (ver instrucciones de Supabase).
    }
  }

  Future<void> _mostrarConversacion(String conversacionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('conversaciones_ocultas')
          .delete()
          .eq('conversacion_id', conversacionId)
          .eq('usuario_id', user.id);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _conversacionesOcultas.remove(conversacionId);
      });
    }
  }

  Future<void> _ocultarChat(
    String amigoId,
    String nombre,
    String? conversacionId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar chat',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Text(
          conversacionId == null
              ? 'No tienes mensajes con $nombre todavía.'
              : '¿Eliminar la conversación con $nombre de tu lista? '
                    'Solo se ocultará para ti; $nombre seguirá viéndola y '
                    'si te escribe de nuevo volverá a aparecer.',
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
          if (conversacionId != null)
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

    if (confirm != true || conversacionId == null) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('conversaciones_ocultas').upsert({
        'conversacion_id': conversacionId,
        'usuario_id': user.id,
      });

      if (!mounted) return;

      setState(() {
        _conversacionesOcultas.add(conversacionId);
        _amigosFuture = _cargarAmigos();
        // Si el chat eliminado es el que está abierto, cerrarlo
        if (_currentConversacionId == conversacionId) {
          _currentConversacionId = null;
          _currentAmigoId = null;
          _currentNombreAmigo = 'Selecciona un amigo';
          _mensajesStream = const Stream.empty();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chat con $nombre eliminado de tu lista.',
            style: GoogleFonts.lexend(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al eliminar chat: $e',
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Bloqueo de usuarios
  // ---------------------------------------------------------------------

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
          _usuariosBloqueados = (data as List)
              .map((r) => r['bloqueado_id'].toString())
              .toSet();
        });
      }
    } catch (_) {}
  }

  bool _estaBloqueado(String usuarioId) =>
      _usuariosBloqueados.contains(usuarioId);

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
          '¿Estás seguro de que deseas bloquear a $nombre? '
          'Ya no verás sus mensajes.',
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
              final user = _supabase.auth.currentUser;
              try {
                await _supabase.from('usuarios_bloqueados').insert({
                  'bloqueado_id': usuarioId,
                  'bloqueado_por': user?.id,
                });
              } catch (_) {
                // Ya bloqueado, ignorar
              }
              if (mounted) {
                setState(() => _usuariosBloqueados.add(usuarioId));
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
          '¿Deseas desbloquear a $nombre? Volverás a ver sus mensajes.',
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
                setState(() => _usuariosBloqueados.remove(usuarioId));
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

  // ---------------------------------------------------------------------
  // Reportar usuario
  // ---------------------------------------------------------------------

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
                  await _supabase.from('reportes_usuarios').insert({
                    'reportado_id': usuarioId,
                    'reportado_por': user?.id,
                    'motivo': motivo,
                    'sala_id': null,
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

  // ---------------------------------------------------------------------
  // Envío de mensajes y adjuntos
  // ---------------------------------------------------------------------

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
    final convId = _currentConversacionId;

    if ((texto.isEmpty && archivo == null) || convId == null) return;

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
      String contenido = texto;

      if (archivo != null && archivo.bytes != null) {
        final tipoArchivo = _getTipoArchivo(archivo.extension ?? '');
        final path =
            '${usuarioActual.id}/$convId/${DateTime.now().millisecondsSinceEpoch}_${archivo.name}';
        await _supabase.storage
            .from('chat_archivos')
            .uploadBinary(
              path,
              archivo.bytes!,
              fileOptions: FileOptions(
                contentType: _mimeDesdeExtension(archivo.extension ?? ''),
              ),
            );
        final url = _supabase.storage.from('chat_archivos').getPublicUrl(path);

        final marcador = tipoArchivo == 'imagen'
            ? '[imagen]$url'
            : '[archivo:${archivo.name}]$url';
        contenido = texto.isEmpty ? marcador : '$marcador\n$texto';
      }

      await _supabase.from('mensajes').insert({
        'conversacion_id': convId,
        'remitente_id': usuarioActual.id,
        'contenido': contenido,
        'leido': false,
      });

      // Si la conversación estaba oculta para mí, vuelve a mostrarse
      if (_conversacionesOcultas.contains(convId)) {
        await _mostrarConversacion(convId);
        if (mounted) {
          setState(() => _amigosFuture = _cargarAmigos());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
      }
    }
  }

  _AdjuntoParseado? _extraerAdjunto(Map<String, dynamic> msg) {
    final raw = msg['contenido']?.toString() ?? '';

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

  // ---------------------------------------------------------------------
  // UI: Burbujas de mensaje
  // ---------------------------------------------------------------------

  Widget _buildMessageBubble(
    Map<String, dynamic> msg, {
    required bool esMio,
    required String remitenteNombre,
  }) {
    final adjunto = _extraerAdjunto(msg);
    final archivoUrl = adjunto?.url;
    final tipoArchivo = adjunto?.tipo;
    final nombreArchivo = adjunto?.nombre;
    final texto =
        adjunto?.texto ??
        (adjunto == null ? msg['contenido'] as String? : null);

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
            if (texto != null && texto.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  archivoUrl != null ? 4 : 10,
                  14,
                  10,
                ),
                child: Text(
                  texto,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: esMio ? Colors.white : const Color(0xFF2E2E2E),
                  ),
                ),
              )
            else if (archivoUrl == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Text(
                  '',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: esMio ? Colors.white : const Color(0xFF2E2E2E),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UI: Panel izquierdo (lista de amigos)
  // ---------------------------------------------------------------------

  Widget _buildLeftPane() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE3BFB1))),
            ),
            child: Text(
              'Amigos',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4F1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3BFB1)),
              ),
              child: TextField(
                controller: _searchAmigoCtrl,
                onChanged: (v) {
                  setState(() => _searchAmigoQuery = v);
                },
                style: GoogleFonts.lexend(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar amigos...',
                  hintStyle: GoogleFonts.lexend(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.grey,
                  ),
                  suffixIcon: _searchAmigoQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 14,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchAmigoCtrl.clear();
                              _searchAmigoQuery = '';
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _amigosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE65100)),
                  );
                }

                final todos = snapshot.data ?? [];
                final amigos = todos.where((a) {
                  // Ocultar conversaciones eliminadas por el usuario
                  final convId = a['conversacion_id']?.toString();
                  if (convId != null &&
                      _conversacionesOcultas.contains(convId)) {
                    return false;
                  }
                  final nombre =
                      '${a['primer_nombre'] ?? ''} ${a['primer_apellido'] ?? ''}'
                          .toLowerCase();
                  final q = _searchAmigoQuery.toLowerCase();
                  return nombre.contains(q);
                }).toList();

                if (amigos.isEmpty) {
                  return Center(
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
                            _searchAmigoQuery.isEmpty
                                ? 'Aún no tienes amigos agregados'
                                : 'No se encontraron amigos',
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
                  itemCount: amigos.length,
                  itemBuilder: (context, index) {
                    final amigo = amigos[index];
                    final id = amigo['id'].toString();
                    final nombre =
                        '${amigo['primer_nombre'] ?? ''} ${amigo['primer_apellido'] ?? ''}'
                            .trim();
                    final isSelected = id == _currentAmigoId;
                    final noLeidos = (amigo['no_leidos'] ?? 0) as int;
                    final fotoUrl = amigo['foto_perfil_url']?.toString();

                    return Material(
                      color: isSelected
                          ? const Color(0xFFFFF3E0)
                          : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? const Color(0xFFE65100)
                              : Colors.grey.shade300,
                          backgroundImage:
                              (fotoUrl != null && fotoUrl.isNotEmpty)
                              ? NetworkImage(fotoUrl)
                              : null,
                          child: (fotoUrl == null || fotoUrl.isEmpty)
                              ? Text(
                                  nombre.isNotEmpty
                                      ? nombre[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.lexend(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          nombre.isNotEmpty ? nombre : 'Usuario',
                          style: GoogleFonts.lexend(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          amigo['ultimo_mensaje']?.toString() ??
                              amigo['carrera']?.toString() ??
                              'Sin mensajes',
                          style: GoogleFonts.lexend(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (noLeidos > 0)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE65100),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$noLeidos',
                                  style: GoogleFonts.lexend(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red.shade300,
                              ),
                              tooltip: 'Eliminar chat',
                              onPressed: () => _ocultarChat(
                                id,
                                nombre.isNotEmpty ? nombre : 'Usuario',
                                amigo['conversacion_id']?.toString(),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _seleccionarAmigo(
                          id,
                          conversacionId: amigo['conversacion_id']?.toString(),
                          nombrePrevio: nombre,
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

  // ---------------------------------------------------------------------
  // UI: Panel central (mensajes)
  // ---------------------------------------------------------------------

  Widget _buildMiddlePane(bool isDesktop) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final amigoId = _currentAmigoId;
    final convId = _currentConversacionId;

    if (amigoId == null || convId == null) {
      return Expanded(
        child: Container(
          color: const Color(0xFFF7F4F1),
          child: Center(
            child: _isLoadingInicial
                ? const CircularProgressIndicator(color: Color(0xFFE65100))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Selecciona un amigo para empezar a chatear',
                        style: GoogleFonts.lexend(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    final estaBloqueado = _estaBloqueado(amigoId);

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
                            setState(() => _searchMessageQuery = v);
                          },
                        ),
                      ),
                    )
                  else ...[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE65100),
                      backgroundImage:
                          (_currentFotoUrl != null &&
                              _currentFotoUrl!.isNotEmpty)
                          ? NetworkImage(_currentFotoUrl!)
                          : null,
                      child:
                          (_currentFotoUrl == null || _currentFotoUrl!.isEmpty)
                          ? Text(
                              _currentNombreAmigo.isNotEmpty
                                  ? _currentNombreAmigo[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentNombreAmigo,
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentCarrera != null &&
                              _currentCarrera!.isNotEmpty)
                            Text(
                              _currentCarrera!,
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Color(0xFF4A4A4A),
                      ),
                      tooltip: 'Buscar en la conversación',
                      onPressed: () {
                        setState(() => _isSearchingMessages = true);
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF4A4A4A),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'reportar') {
                          _reportarUsuario(amigoId, _currentNombreAmigo);
                        } else if (value == 'bloquear') {
                          _bloquearUsuario(amigoId, _currentNombreAmigo);
                        } else if (value == 'desbloquear') {
                          _desbloquearUsuario(amigoId, _currentNombreAmigo);
                        } else if (value == 'eliminar_chat') {
                          _ocultarChat(amigoId, _currentNombreAmigo, convId);
                        } else if (value == 'info') {
                          setState(() {
                            _mostrarPanelDerecho = !_mostrarPanelDerecho;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Color(0xFFE65100),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ver información',
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
                              Text(
                                'Reportar',
                                style: GoogleFonts.lexend(fontSize: 13),
                              ),
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
                                const Icon(
                                  Icons.block,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bloquear',
                                  style: GoogleFonts.lexend(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'eliminar_chat',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Eliminar chat',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Lista de mensajes
            Expanded(
              child: estaBloqueado
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Has bloqueado a $_currentNombreAmigo.\nNo puedes ver ni enviar mensajes.',
                              style: GoogleFonts.lexend(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _desbloquearUsuario(
                                amigoId,
                                _currentNombreAmigo,
                              ),
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
                      ),
                    )
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _mensajesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE65100),
                            ),
                          );
                        }

                        var mensajes = snapshot.data ?? [];

                        if (_searchMessageQuery.isNotEmpty) {
                          final q = _searchMessageQuery.toLowerCase();
                          mensajes = mensajes.where((m) {
                            final contenido = (m['contenido'] ?? '')
                                .toString()
                                .toLowerCase();
                            return contenido.contains(q);
                          }).toList();
                        }

                        if (mensajes.isEmpty) {
                          return Center(
                            child: Text(
                              _searchMessageQuery.isNotEmpty
                                  ? 'No se encontraron mensajes'
                                  : 'Aún no hay mensajes.\n¡Envía el primero!',
                              style: GoogleFonts.lexend(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: mensajes.length,
                          itemBuilder: (context, index) {
                            final msg = mensajes[index];
                            final remitenteId = msg['remitente_id']?.toString();
                            final esMio = remitenteId == currentUserId;

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
                                _currentNombreAmigo,
                              ),
                              builder: (context, snap) {
                                final nombre = snap.data ?? 'Cargando...';
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
                  if (estaBloqueado)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No puedes enviar mensajes a un usuario bloqueado.',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFBF9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE3BFB1),
                              ),
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

  // ---------------------------------------------------------------------
  // UI: Panel derecho (información del amigo)
  // ---------------------------------------------------------------------

  Widget _buildDetalleRow({
    required IconData icon,
    String? texto,
    String placeholder = '',
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
            hasValue ? texto : placeholder,
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

  Widget _buildRightPane() {
    final amigoId = _currentAmigoId;
    final estaBloqueado = amigoId != null && _estaBloqueado(amigoId);

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información',
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
                    setState(() => _mostrarPanelDerecho = false);
                  },
                  tooltip: 'Cerrar panel',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE3BFB1)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFFE65100),
                          backgroundImage:
                              (_currentFotoUrl != null &&
                                  _currentFotoUrl!.isNotEmpty)
                              ? NetworkImage(_currentFotoUrl!)
                              : null,
                          child:
                              (_currentFotoUrl == null ||
                                  _currentFotoUrl!.isEmpty)
                              ? Text(
                                  _currentNombreAmigo.isNotEmpty
                                      ? _currentNombreAmigo[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentNombreAmigo,
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
                    icon: Icons.school_outlined,
                    texto: _currentCarrera,
                    placeholder: 'Sin carrera registrada',
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE3BFB1)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: estaBloqueado
                        ? OutlinedButton.icon(
                            onPressed: () => _desbloquearUsuario(
                              amigoId!,
                              _currentNombreAmigo,
                            ),
                            icon: const Icon(
                              Icons.lock_open,
                              size: 18,
                              color: Color(0xFF2E7D32),
                            ),
                            label: Text(
                              'Desbloquear',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () =>
                                _bloquearUsuario(amigoId!, _currentNombreAmigo),
                            icon: const Icon(
                              Icons.block,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: Text(
                              'Bloquear',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w600,
                              ),
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
                      onPressed: () =>
                          _reportarUsuario(amigoId!, _currentNombreAmigo),
                      icon: const Icon(
                        Icons.report_problem_outlined,
                        size: 18,
                        color: Colors.orange,
                      ),
                      label: Text(
                        'Reportar',
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
                      onPressed: () => _ocultarChat(
                        amigoId!,
                        _currentNombreAmigo,
                        _currentConversacionId,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: Text(
                        'Eliminar Chat',
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
              if (_mostrarPanelDerecho && isDesktop) _buildRightPane(),
            ],
          );
        },
      ),
    );
  }
}
