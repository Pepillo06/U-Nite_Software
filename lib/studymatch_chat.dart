import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/unite_header.dart';

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
  final _supabase = Supabase.instance.client;

  late String _currentSalaId;
  late String _currentNombreGrupo;

  late Stream<List<Map<String, dynamic>>> _mensajesStream;
  late Future<List<Map<String, dynamic>>> _salasFuture;

  final Map<String, String> _nombresUsuarios = {};

  String _materia = 'Cargando...';
  String _fecha = 'Cargando...';
  String? _creadorId;

  // Toggle para mostrar/ocultar panel derecho
  bool _mostrarPanelDerecho = false;

  // Lista de miembros del grupo
  List<Map<String, dynamic>> _miembros = [];

  @override
  void initState() {
    super.initState();
    _currentSalaId = widget.grupoInicialId;
    _currentNombreGrupo = widget.nombreGrupo;

    _initMensajesStream();
    _cargarInfoSala();
    _cargarMiembros();

    _salasFuture = _cargarSalas();
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

      return List<Map<String, dynamic>>.from(salas);
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
      final response = await _supabase
          .from('salas_chat')
          .select('materia, created_at, creado_por')
          .eq('id', _currentSalaId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _materia = response != null && response['materia'] != null
            ? response['materia']
            : 'No especificada';
        _fecha = response != null && response['created_at'] != null
            ? DateTime.parse(
                response['created_at'],
              ).toLocal().toString().split(' ')[0]
            : 'Desconocida';
        _creadorId = response?['creado_por']?.toString();
      });
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

  Future<void> _cargarMiembros() async {
    try {
      final participantes = await _supabase
          .from('participantes_sala')
          .select('usuario_id')
          .eq('sala_id', _currentSalaId);

      List<Map<String, dynamic>> miembrosData = [];
      for (final p in participantes) {
        final userId = p['usuario_id'].toString();
        try {
          final userData = await _supabase
              .from('usuarios')
              .select('id, primer_nombre, primer_apellido, correo')
              .eq('id', userId)
              .maybeSingle();
          if (userData != null) {
            miembrosData.add(userData);
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
    if (texto.isEmpty) return;

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

    try {
      await _supabase.from('mensajes_chat').insert({
        'sala_id': _currentSalaId,
        'texto': texto,
        'remitente_id': usuarioActual.id,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
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
                    // Agregar al usuario como participante de la sala
                    await _supabase.from('participantes_sala').upsert({
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

  Widget _buildMessageBubble(
    Map<String, dynamic> msg, {
    required bool esMio,
    required String remitenteNombre,
  }) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            if (!esMio)
              Text(
                remitenteNombre,
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE65100),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              msg['texto'] ?? '',
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: esMio ? Colors.white : const Color(0xFF2E2E2E),
              ),
            ),
          ],
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Todos los Chats',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE3BFB1)),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _salasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE65100)),
                  );
                }
                final salas = snapshot.data ?? [];
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
                            'No tienes chats aún',
                            style: GoogleFonts.lexend(
                              color: Colors.grey.shade500,
                            ),
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
                    return ListTile(
                      tileColor: isSelected
                          ? const Color(0xFFFFF3E0)
                          : Colors.white,
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? const Color(0xFFE65100)
                            : Colors.grey.shade300,
                        child: Text(
                          sala['nombre'] != null && sala['nombre'].isNotEmpty
                              ? sala['nombre'][0].toUpperCase()
                              : 'G',
                          style: GoogleFonts.lexend(
                            color: isSelected ? Colors.white : Colors.black87,
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
                      onTap: () => _seleccionarSala(
                        sala['id'].toString(),
                        sala['nombre'] ?? 'Sala',
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
    final esCreador = (_creadorId != null && currentUserId == _creadorId);

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
                        Text(
                          '${_miembros.length} miembros',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
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
                  // Botón de tres puntos → toggle panel derecho
                  IconButton(
                    icon: Icon(
                      _mostrarPanelDerecho ? Icons.close : Icons.more_vert,
                      color: const Color(0xFF4A4A4A),
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarPanelDerecho = !_mostrarPanelDerecho;
                      });
                    },
                    tooltip: _mostrarPanelDerecho
                        ? 'Cerrar info'
                        : 'Información del grupo',
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

                  final mensajes = snapshot.data ?? [];
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
                            'No hay mensajes aún.\n¡Sé el primero en escribir!',
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
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF0EAE6))),
              ),
              child: Row(
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
                          hintText: 'Escribe un mensaje aquí...',
                          hintStyle: GoogleFonts.lexend(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
            ),
          ],
        ),
      ),
    );
  }

  // PANEL DERECHO: Detalles del grupo + Miembros
  Widget _buildRightPane() {
    final currentUserId = _supabase.auth.currentUser?.id;
    final esCreador = (_creadorId != null && currentUserId == _creadorId);

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
                  Row(
                    children: [
                      const Icon(
                        Icons.book_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _materia,
                          style: GoogleFonts.lexend(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fecha,
                          style: GoogleFonts.lexend(fontSize: 14),
                        ),
                      ),
                    ],
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
                    ..._miembros.map((miembro) {
                      final miembroId = miembro['id'].toString();
                      final nombre =
                          '${miembro['primer_nombre'] ?? ''} ${miembro['primer_apellido'] ?? ''}'
                              .trim();
                      final correo = miembro['correo'] ?? '';
                      final esTuMismo = miembroId == currentUserId;
                      final esCreadorMiembro = miembroId == _creadorId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: esTuMismo
                              ? const Color(0xFFFFF8F0)
                              : const Color(0xFFFDFBF9),
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
                                nombre.isNotEmpty
                                    ? nombre[0].toUpperCase()
                                    : '?',
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
                                            color: const Color(
                                              0xFFE65100,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: GoogleFonts.lexend(
                                              fontSize: 10,
                                              color: const Color(0xFFE65100),
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
                            // Botón de expulsar (solo para el creador, y no puede expulsarse a sí mismo)
                            if (esCreador && !esTuMismo)
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
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'expulsar',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.person_remove,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Expulsar',
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
                    }),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE3BFB1)),
                  const SizedBox(height: 16),

                  // Botones de acción
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
