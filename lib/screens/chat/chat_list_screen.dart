import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/unite_header.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String? conversacionInicial;
  final String? nombreInicial;
  final String? otroUserIdInicial;
  final String? anuncioIdInicial;
  final bool abrirMisTrueques; // ← nuevo parámetro

  const ChatListScreen({
    super.key,
    this.conversacionInicial,
    this.nombreInicial,
    this.otroUserIdInicial,
    this.anuncioIdInicial,
    this.abrirMisTrueques = false, // ← default false
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _supabase = Supabase.instance.client;
  int _selectedIndex = -1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _conversaciones = [];
  List<Map<String, dynamic>> _solicitudesTrueque = [];
  bool _loading = true;
  bool _bandejaTruequeExpandida = false;
  bool _navegacionInicialHecha = false;
  String? _conversacionActivaId;
  // Evitar que el popup de solicitudes se abra doble
  bool _solicitudesDialogAbierto = false;

  void _marcarConversacionLeida(String conversacionId) {
    setState(() {
      final idx = _conversaciones.indexWhere((c) => c['id'] == conversacionId);
      if (idx != -1) {
        _conversaciones[idx] = {
          ..._conversaciones[idx],
          'unread': 0,
        };
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadConversaciones();
    _loadSolicitudesTrueque();
    // Si viene desde "Ver mis trueques", abrir el popup automáticamente
    if (widget.abrirMisTrueques) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarSolicitudesEnviadas();
      });
    }
  }

  Future<void> _loadSolicitudesTrueque() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('solicitudes_trueque')
          .select('id, objeto_ofrecido, estado, creado_en, anuncio_id, solicitante_id')
          .eq('receptor_id', userId)
          .eq('estado', 'pendiente')
          .order('creado_en', ascending: false);

      final List<Map<String, dynamic>> resultado = [];
      for (final sol in data) {
        final solicitanteData = await _supabase
            .from('usuarios')
            .select('id, primer_nombre, primer_apellido')
            .eq('id', sol['solicitante_id'])
            .maybeSingle();

        final anuncioData = await _supabase
            .from('anuncios_marketplace')
            .select('titulo')
            .eq('id', sol['anuncio_id'])
            .maybeSingle();

        resultado.add({
          ...sol,
          'solicitante': solicitanteData,
          'anuncio': anuncioData,
        });
      }

      setState(() => _solicitudesTrueque = resultado);
    } catch (e) {
      debugPrint('Error cargando solicitudes trueque: $e');
    }
  }

  Future<void> _responderTrueque(String solicitudId, String nuevoEstado,
      String solicitanteId, String tituloAnuncio) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('solicitudes_trueque')
          .update({'estado': nuevoEstado})
          .eq('id', solicitudId);

      final vendedorData = await _supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido')
          .eq('id', userId)
          .maybeSingle();
      final nombreVendedor = vendedorData != null
          ? '${vendedorData['primer_nombre']} ${vendedorData['primer_apellido']}'
          : 'El vendedor';

      final mensajeNotif = nuevoEstado == 'aceptado'
          ? '$nombreVendedor aceptó tu propuesta de trueque por "$tituloAnuncio"'
          : '$nombreVendedor rechazó tu propuesta de trueque por "$tituloAnuncio"';

      await _supabase.from('notificaciones').insert({
        'usuario_id': solicitanteId,
        'tipo': 'trueque',
        'titulo': nuevoEstado == 'aceptado'
            ? '¡Propuesta de trueque aceptada!'
            : 'Propuesta de trueque rechazada',
        'mensaje': mensajeNotif,
        'leida': false,
        'datos': {
          'solicitante_id': solicitanteId,
          'nombre_otro': nombreVendedor,
        },
      });

      if (nuevoEstado == 'aceptado') {
        final existentes = await _supabase
            .from('conversaciones')
            .select('id')
            .eq('comprador_id', solicitanteId)
            .eq('vendedor_id', userId);

        String conversacionId;
        if (existentes.isNotEmpty) {
          conversacionId = existentes.first['id'];
        } else {
          final nueva = await _supabase
              .from('conversaciones')
              .insert({
                'comprador_id': solicitanteId,
                'vendedor_id': userId,
              })
              .select('id')
              .single();
          conversacionId = nueva['id'];
        }

        await _supabase.from('mensajes').insert({
          'conversacion_id': conversacionId,
          'remitente_id': userId,
          'contenido':
              '✅ ¡He aceptado tu propuesta de trueque por "$tituloAnuncio"! Podemos coordinar los detalles aquí.',
        });

        final solicitanteData = await _supabase
            .from('usuarios')
            .select('primer_nombre, primer_apellido')
            .eq('id', solicitanteId)
            .maybeSingle();
        final nombreSolicitante = solicitanteData != null
            ? '${solicitanteData['primer_nombre']} ${solicitanteData['primer_apellido']}'
            : 'Usuario';

        await _loadSolicitudesTrueque();
        await _loadConversaciones();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChatListScreen(
                conversacionInicial: conversacionId,
                nombreInicial: nombreSolicitante,
                otroUserIdInicial: solicitanteId,
              ),
            ),
          );
        }
      } else {
        await _loadSolicitudesTrueque();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trueque rechazado.', style: GoogleFonts.lexend()),
              backgroundColor: const Color(0xFF5B4137),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadConversaciones() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        setState(() {
          _conversaciones = [
            {
              'id': '2fcd05b9-b3b6-41f2-997b-29b37ee03775',
              'otro_nombre': 'Sofia De Jesus',
              'otro_id': '6e56e4ce-ac95-4fb8-b08a-edc493b13d5b',
              'foto_otro': '',
              'preview': '¿Podríamos vernos mañana en el campus?',
              'hora': '01:20',
              'unread': 0,
            }
          ];
          _loading = false;
        });
        return;
      }

      final data = await _supabase
          .from('conversaciones')
          .select('''
            id, anuncio_id, creado_en,
            comprador:comprador_id(id, primer_nombre, primer_apellido),
            vendedor:vendedor_id(id, primer_nombre, primer_apellido)
          ''')
          .or('comprador_id.eq.$userId,vendedor_id.eq.$userId');

      final List<Map<String, dynamic>> resultado = [];
      for (final conv in data) {
        final comprador = conv['comprador'];
        final vendedor = conv['vendedor'];
        final isComprador = comprador['id'] == userId;
        final otro = isComprador ? vendedor : comprador;
        final otroNombre =
            '${otro['primer_nombre']} ${otro['primer_apellido']}';

        // Cargar foto de perfil del otro usuario
        String fotoOtro = '';
        try {
          final fotoData = await _supabase
              .from('usuarios')
              .select('foto_perfil_url')
              .eq('id', otro['id'])
              .maybeSingle();
          fotoOtro = fotoData?['foto_perfil_url']?.toString() ?? '';
        } catch (_) {}

        final mensajes = await _supabase
            .from('mensajes')
            .select('contenido, creado_en')
            .eq('conversacion_id', conv['id'])
            .order('creado_en', ascending: false)
            .limit(1);

        final preview = mensajes.isNotEmpty
            ? mensajes[0]['contenido']
            : 'Sin mensajes aún';

        final hora = mensajes.isNotEmpty
            ? _formatHora(mensajes[0]['creado_en'])
            : '';

        // Timestamp para ordenar — usar el del último mensaje o el de creación
        final ultimoTimestamp = mensajes.isNotEmpty
            ? mensajes[0]['creado_en']
            : conv['creado_en'];

        final noLeidos = await _supabase
            .from('mensajes')
            .select('id')
            .eq('conversacion_id', conv['id'])
            .eq('leido', false)
            .neq('remitente_id', userId);

        String? urgenciaNivel;
        try {
          final urgenciaData = await _supabase
              .from('solicitudes_urgencia')
              .select('nivel_urgencia')
              .eq('anuncio_id', conv['anuncio_id'])
              .eq('comprador_id', comprador['id'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (urgenciaData != null) {
            urgenciaNivel = urgenciaData['nivel_urgencia'];
          }
        } catch (_) {}

        resultado.add({
          'id': conv['id'],
          'otro_nombre': otroNombre,
          'otro_id': otro['id'],
          'foto_otro': fotoOtro, // ← foto de perfil del otro usuario
          'anuncio_id': conv['anuncio_id'],
          'preview': preview,
          'hora': hora,
          'unread': noLeidos.length,
          'ultimo_timestamp': ultimoTimestamp,
          'urgencia': urgenciaNivel,
        });
      }

      int valorUrgencia(String? urg) {
        if (urg == 'alta') return 3;
        if (urg == 'media') return 2;
        if (urg == 'baja') return 1;
        return 0;
      }

      resultado.sort((a, b) {
        final uA = valorUrgencia(a['urgencia'] as String?);
        final uB = valorUrgencia(b['urgencia'] as String?);
        if (uA != uB) return uB.compareTo(uA); // Prioriza el número mayor (alta)
        return 0; // Si tienen igual urgencia, mantiene el orden de fecha
      });

      // Ordenar por último mensaje de más reciente a más antiguo
      resultado.sort((a, b) {
        final ta = DateTime.tryParse(a['ultimo_timestamp'] ?? '') ?? DateTime(0);
        final tb = DateTime.tryParse(b['ultimo_timestamp'] ?? '') ?? DateTime(0);
        return tb.compareTo(ta);
      });

      setState(() {
        _conversaciones = resultado;
        _loading = false;
      });

      // Si hay una conversación seleccionada manualmente, mantenerla
      if (_conversacionActivaId != null) {
        final idx = resultado.indexWhere((c) => c['id'] == _conversacionActivaId);
        if (idx != -1) setState(() => _selectedIndex = idx);
      } else if (widget.conversacionInicial != null) {
        final idx = resultado.indexWhere((c) => c['id'] == widget.conversacionInicial);
        if (idx != -1) setState(() => _selectedIndex = idx);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _marcarLeidosDesktop(int index) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final convId = _chatsFiltrados[index]['id'];
    _marcarConversacionLeida(convId);
    await _supabase
        .from('mensajes')
        .update({'leido': true})
        .eq('conversacion_id', convId)
        .eq('leido', false)
        .neq('remitente_id', userId);
    if (mounted) await _loadConversaciones();
  }

  String _formatHora(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    if (dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (dt.day == now.day - 1) {
      return 'Ayer';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  List<Map<String, dynamic>> get _chatsFiltrados {
    if (_searchQuery.isEmpty) return _conversaciones;
    return _conversaciones.where((conv) {
      final nombre = _quitarAcentos(conv['otro_nombre'].toString());
      final preview = _quitarAcentos(conv['preview'].toString());
      final query = _quitarAcentos(_searchQuery);
      return nombre.contains(query) || preview.contains(query);
    }).toList();
  }

  // ─── Mostrar popup de solicitudes enviadas — evita doble apertura ─────────
  Future<void> _mostrarSolicitudesEnviadas() async {
    // Evitar que se abra doble si ya está abierto
    if (_solicitudesDialogAbierto) return;
    _solicitudesDialogAbierto = true;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _solicitudesDialogAbierto = false;
      return;
    }

    // Cargar solicitudes enviadas por el usuario actual
    final data = await _supabase
        .from('solicitudes_trueque')
        .select('id, objeto_ofrecido, estado, creado_en, anuncio_id, receptor_id')
        .eq('solicitante_id', userId)
        .eq('estado', 'pendiente')
        .order('creado_en', ascending: false);

    final List<Map<String, dynamic>> solicitudes = [];
    for (final sol in data) {
      final anuncioData = await _supabase
          .from('anuncios_marketplace')
          .select('titulo')
          .eq('id', sol['anuncio_id'])
          .maybeSingle();
      final receptorData = await _supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido')
          .eq('id', sol['receptor_id'])
          .maybeSingle();
      solicitudes.add({
        ...sol,
        'anuncio': anuncioData,
        'receptor': receptorData,
      });
    }

    if (!mounted) {
      _solicitudesDialogAbierto = false;
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _DialogSolicitudesEnviadas(
        solicitudes: solicitudes,
        onEditar: (sol) async {
          Navigator.pop(ctx);
          await _editarSolicitudTrueque(sol);
        },
        onCancelar: (solId) async {
          await _supabase
              .from('solicitudes_trueque')
              .delete()
              .eq('id', solId);
          if (mounted) {
            Navigator.pop(ctx);           // cierra el popup actual
            _solicitudesDialogAbierto = false; // resetear flag ANTES de reabrir
            _mostrarSolicitudesEnviadas();     // reabrir con datos actualizados
          }
        },
      ),
    );

    // Al cerrar el dialog, resetear el flag
    _solicitudesDialogAbierto = false;
  }

  // ─── Dialog para editar una solicitud enviada — fondo blanco ─────────────
  Future<void> _editarSolicitudTrueque(Map<String, dynamic> solicitud) async {
    final tituloAnuncio = solicitud['anuncio']?['titulo'] ?? 'Producto';
    final controller =
        TextEditingController(text: solicitud['objeto_ofrecido'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFF245000)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Editar Propuesta',
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w700, fontSize: 17)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Producto: $tituloAnuncio',
                style: GoogleFonts.lexend(
                    fontSize: 13, color: const Color(0xFF5B4137))),
            const SizedBox(height: 12),
            Text('Tu oferta:',
                style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              style: GoogleFonts.lexend(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Describe qué ofreces a cambio...',
                hintStyle: GoogleFonts.lexend(
                    color: const Color(0xFF8F7065), fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3BFB1))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF245000), width: 2)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.lexend(color: const Color(0xFF5B4137))),
          ),
          ElevatedButton(
            onPressed: () async {
              final nueva = controller.text.trim();
              if (nueva.isEmpty) return;
              await _supabase
                  .from('solicitudes_trueque')
                  .update({'objeto_ofrecido': nueva})
                  .eq('id', solicitud['id']);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Propuesta actualizada',
                      style: GoogleFonts.lexend()),
                  backgroundColor: const Color(0xFF245000),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF245000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Guardar',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F9),
      appBar: const UniteHeader(currentIndex: 2),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    if (widget.conversacionInicial != null &&
        _loading == false &&
        !_navegacionInicialHecha) {
      _navegacionInicialHecha = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversacionId: widget.conversacionInicial!,
              nombreOtro: widget.nombreInicial ?? 'Vendedor',
              otroUserId: widget.otroUserIdInicial ?? '',
              anuncioId: widget.anuncioIdInicial,
            ),
          ),
        ).then((_) => _loadConversaciones());
      });
    }

    return Column(
      children: [
        _buildSidebarHeader(),
        _buildSearchBar(),
        Expanded(
          child: ListView(
            children: [
              if (_solicitudesTrueque.isNotEmpty) _buildBandejaTrueque(),
              ..._buildChatListItems(onTap: (i) {
                setState(() => _selectedIndex = i);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversacionId: _chatsFiltrados[i]['id'],
                      nombreOtro: _chatsFiltrados[i]['otro_nombre'],
                      otroUserId: _chatsFiltrados[i]['otro_id'],
                      anuncioId: _chatsFiltrados[i]['anuncio_id'],
                    ),
                  ),
                ).then((_) => _loadConversaciones());
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final idx = _selectedIndex.clamp(
        0, _chatsFiltrados.isEmpty ? 0 : _chatsFiltrados.length - 1);
    return Row(
      children: [
        Container(
          width: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE3BFB1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebarHeader(),
              _buildSearchBar(),
              Expanded(
                child: ListView(
                  children: [
                    if (_solicitudesTrueque.isNotEmpty) _buildBandejaTrueque(),
                    ..._buildChatListItems(
                      onTap: (i) {
                        setState(() {
                          _selectedIndex = i;
                          _conversacionActivaId = _chatsFiltrados[i]['id'];
                        });
                        _marcarLeidosDesktop(i);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF36900)))
              : _chatsFiltrados.isEmpty
                  ? Center(
                      child: Text('No hay conversaciones',
                          style: GoogleFonts.lexend(
                              color: const Color(0xFF5B4137), fontSize: 15)))
                  : _selectedIndex == -1
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined,
                                  size: 48,
                                  color: const Color(0xFF5B4137)
                                      .withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'Selecciona un chat para comenzar',
                                style: GoogleFonts.lexend(
                                    color: const Color(0xFF5B4137),
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ChatScreen(
                          key: ValueKey('${_chatsFiltrados[idx]['id']}_${_chatsFiltrados[idx]['anuncio_id'] ?? ''}'),
                          conversacionId: _chatsFiltrados[idx]['id'],
                          nombreOtro: _chatsFiltrados[idx]['otro_nombre'],
                          otroUserId: _chatsFiltrados[idx]['otro_id'],
                          anuncioId: _conversacionActivaId == null &&
                                  widget.anuncioIdInicial != null
                              ? widget.anuncioIdInicial
                              : _chatsFiltrados[idx]['anuncio_id'],
                          showAppBar: false,
                        ),
        ),
      ],
    );
  }

  Widget _buildBandejaTrueque() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(
              () => _bandejaTruequeExpandida = !_bandejaTruequeExpandida),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F0),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF245000).withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFF245000), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Solicitudes de Trueque',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF245000),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF245000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_solicitudesTrueque.length}',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _bandejaTruequeExpandida
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF245000),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_bandejaTruequeExpandida)
          ..._solicitudesTrueque.map((sol) {
            final solicitante = sol['solicitante'];
            final nombreSolicitante = solicitante != null
                ? '${solicitante['primer_nombre']} ${solicitante['primer_apellido']}'
                : 'Usuario';
            final anuncio = sol['anuncio'];
            final tituloAnuncio = anuncio?['titulo'] ?? 'Producto';
            final objetoOfrecido = sol['objeto_ofrecido'] ?? '';
            final solicitanteId = solicitante?['id'] ?? '';

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF245000).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF245000),
                        child: Text(
                          nombreSolicitante.isNotEmpty
                              ? nombreSolicitante[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreSolicitante,
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'por "$tituloAnuncio"',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: const Color(0xFF5B4137),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (objetoOfrecido.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE3BFB1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded,
                              size: 14, color: Color(0xFFF36900)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              objetoOfrecido,
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: const Color(0xFF1A1A1A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _responderTrueque(sol['id'],
                              'rechazado', solicitanteId, tituloAnuncio),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5B4137),
                            side: const BorderSide(
                                color: Color(0xFF5B4137)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.lexend(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Rechazar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _responderTrueque(sol['id'],
                              'aceptado', solicitanteId, tituloAnuncio),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF245000),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.lexend(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Aceptar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        if (_bandejaTruequeExpandida) const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFFE3BFB1)),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildChatListItems({required void Function(int) onTap}) {
    if (_loading) {
      return [
        const Center(
            child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFFF36900)),
        ))
      ];
    }

    final chats = _chatsFiltrados;

    if (chats.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.forum_outlined,
                    size: 40,
                    color: const Color(0xFF5B4137).withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('No hay conversaciones',
                    style: GoogleFonts.lexend(
                        color: const Color(0xFF5B4137), fontSize: 14)),
              ],
            ),
          ),
        )
      ];
    }

    return List.generate(chats.length, (i) {
      final chat = chats[i];
      return _ChatTile(
        nombre: chat['otro_nombre']?.toString() ?? 'Usuario',
        fotoUrl: chat['foto_otro']?.toString() ?? '',
        preview: chat['preview']?.toString() ?? '',
        hora: chat['hora']?.toString() ?? '',
        isActive: i == _selectedIndex,
        isOnline: false,
        unreadCount: chat['unread'] ?? 0,
        urgencia: chat['urgencia'],
        searchQuery: _searchQuery,
        onTap: () => onTap(i),
      );
    });
  }

  // ─── Header del sidebar con botón de solicitudes enviadas ─────────────────
  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        children: [
          Text('Mensajes',
              style: GoogleFonts.lexend(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A))),
          const Spacer(),
          // Botón para ver solicitudes de trueque enviadas por el comprador
          TextButton.icon(
            onPressed: _mostrarSolicitudesEnviadas,
            icon: const Icon(Icons.swap_horiz_rounded,
                color: Color(0xFF245000), size: 16),
            label: Text('Mis trueques',
                style: GoogleFonts.lexend(
                    fontSize: 11,
                    color: const Color(0xFF245000),
                    fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF0F7F0),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3BFB1)),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.lexend(
              fontSize: 14, color: const Color(0xFF1A1A1A)),
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Buscar chats...',
            hintStyle: GoogleFonts.lexend(
                color: const Color(0xFF5B4137), fontSize: 14),
            prefixIcon: const Icon(Icons.search,
                color: Color(0xFF5B4137), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        color: Color(0xFF5B4137), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// ─── Tile de chat ─────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String nombre, preview, hora, searchQuery;
  final String fotoUrl;
  final String? urgencia;
  final bool isActive, isOnline;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatTile({
    required this.nombre,
    required this.preview,
    required this.hora,
    required this.isActive,
    required this.isOnline,
    required this.unreadCount,
    required this.onTap,
    required this.fotoUrl,
    this.urgencia,
    this.searchQuery = '',
  });

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style, overflow: TextOverflow.ellipsis);
    }
    final textNormalizado = _quitarAcentos(text);
    final queryNormalizada = _quitarAcentos(query);
    final index = textNormalizado.indexOf(queryNormalizada);
    if (index == -1) {
      return Text(text, style: style, overflow: TextOverflow.ellipsis);
    }
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: const Color(0xFFFFB598),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isActive ? const Color(0xFFFFDBCE) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                // Avatar con foto de perfil o inicial
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF36900),
                  backgroundImage:
                      fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                  child: fotoUrl.isEmpty
                      ? Text(inicial,
                          style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16))
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF306B18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildHighlightedText(
                          nombre,
                          searchQuery,
                          GoogleFonts.lexend(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF1A1A1A)),
                        ),
                      ),
                      if (urgencia != null && urgencia!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            urgencia == 'alta'
                                ? '🔴'
                                : (urgencia == 'media' ? '🟡' : '🟢'),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      Text(hora,
                          style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: const Color(0xFF5B4137))),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: Color(0xFF306B18),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('$unreadCount',
                                style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  _buildHighlightedText(
                    preview,
                    searchQuery,
                    GoogleFonts.lexend(
                        fontSize: 12,
                        color: const Color(0xFF5B4137),
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400),
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

// ─── Dialog de solicitudes enviadas por el comprador — fondo blanco ──────────
class _DialogSolicitudesEnviadas extends StatelessWidget {
  final List<Map<String, dynamic>> solicitudes;
  final void Function(Map<String, dynamic>) onEditar;
  final void Function(String) onCancelar;

  const _DialogSolicitudesEnviadas({
    required this.solicitudes,
    required this.onEditar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: Color(0xFF245000)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Mis Solicitudes Enviadas',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w700, fontSize: 17)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: solicitudes.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded,
                        size: 48,
                        color: const Color(0xFF5B4137).withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('No tienes solicitudes pendientes',
                        style: GoogleFonts.lexend(
                            color: const Color(0xFF5B4137), fontSize: 14)),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: solicitudes.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Color(0xFFE3BFB1)),
                itemBuilder: (context, i) {
                  final sol = solicitudes[i];
                  final tituloAnuncio =
                      sol['anuncio']?['titulo'] ?? 'Producto';
                  final receptor = sol['receptor'];
                  final nombreReceptor = receptor != null
                      ? '${receptor['primer_nombre']} ${receptor['primer_apellido']}'
                      : 'Vendedor';
                  final objetoOfrecido = sol['objeto_ofrecido'] ?? '';

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF245000),
                              child: Text(
                                nombreReceptor.isNotEmpty
                                    ? nombreReceptor[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tituloAnuncio,
                                      style: GoogleFonts.lexend(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A1A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text('Vendedor: $nombreReceptor',
                                      style: GoogleFonts.lexend(
                                          fontSize: 11,
                                          color: const Color(0xFF5B4137))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Container con fondo verde claro
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF245000).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.swap_horiz_rounded,
                                  size: 14, color: Color(0xFF245000)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(objetoOfrecido,
                                    style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        color: const Color(0xFF1A1A1A)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // ─── Botón cancelar con confirmación ─────────
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (confirmCtx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      title: Text('¿Cancelar trueque?',
                                          style: GoogleFonts.lexend(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16)),
                                      content: Text(
                                        '¿Estás seguro de que deseas cancelar tu propuesta por "$tituloAnuncio"?',
                                        style: GoogleFonts.lexend(
                                            fontSize: 13,
                                            color: const Color(0xFF5B4137),
                                            height: 1.4),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(confirmCtx),
                                          child: Text('No, mantener',
                                              style: GoogleFonts.lexend(
                                                  color: const Color(
                                                      0xFF5B4137))),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                                confirmCtx); // cierra confirmación
                                            onCancelar(
                                                sol['id']); // ejecuta cancelar
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10)),
                                          ),
                                          child: Text('Sí, cancelar',
                                              style: GoogleFonts.lexend(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  textStyle: GoogleFonts.lexend(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Cancelar trueque'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => onEditar(sol),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF245000),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  textStyle: GoogleFonts.lexend(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Editar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ─── Función auxiliar para quitar acentos ────────────────────────────────────
String _quitarAcentos(String texto) {
  var conAcento = 'áéíóúÁÉÍÓÚüÜ';
  var sinAcento = 'aeiouAEIOUuU';
  String resultado = texto;
  for (int i = 0; i < conAcento.length; i++) {
    resultado = resultado.replaceAll(conAcento[i], sinAcento[i]);
  }
  return resultado;
}