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

  const ChatListScreen({
    super.key,
    this.conversacionInicial,
    this.nombreInicial,
    this.otroUserIdInicial,
    this.anuncioIdInicial,
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
  bool _loading = true;

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
          .or('comprador_id.eq.$userId,vendedor_id.eq.$userId')
          .order('creado_en', ascending: false);

      final List<Map<String, dynamic>> resultado = [];
      for (final conv in data) {
        final comprador = conv['comprador'];
        final vendedor = conv['vendedor'];
        final isComprador = comprador['id'] == userId;
        final otro = isComprador ? vendedor : comprador;
        final otroNombre =
            '${otro['primer_nombre']} ${otro['primer_apellido']}';

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

        final noLeidos = await _supabase
            .from('mensajes')
            .select('id')
            .eq('conversacion_id', conv['id'])
            .eq('leido', false)
            .neq('remitente_id', userId);

        resultado.add({
          'id': conv['id'],
          'otro_nombre': otroNombre,
          'otro_id': otro['id'],
          'anuncio_id': conv['anuncio_id'],
          'preview': preview,
          'hora': hora,
          'unread': noLeidos.length,
        });
      }

      setState(() {
        _conversaciones = resultado;
        _loading = false;
      });

      if (widget.conversacionInicial != null) {
        final idx = resultado.indexWhere(
            (c) => c['id'] == widget.conversacionInicial);
        if (idx != -1) {
          setState(() => _selectedIndex = idx);
        }
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _marcarLeidosDesktop(int index) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final convId = _chatsFiltrados[index]['id'];

    // 1. Actualizar local inmediatamente
    _marcarConversacionLeida(convId);

    // 2. Marcar en Supabase ANTES de recargar
    await _supabase
        .from('mensajes')
        .update({'leido': true})
        .eq('conversacion_id', convId)
        .eq('leido', false)
        .neq('remitente_id', userId);

    // 3. Recargar — Supabase ya tiene los datos correctos
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
    if (widget.conversacionInicial != null && _loading == false) {
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
          child: _buildChatList(onTap: (i) {
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
                child: _buildChatList(
                  onTap: (i) {
                    setState(() => _selectedIndex = i);
                    _marcarLeidosDesktop(i);
                  },
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
                          key: ValueKey(_chatsFiltrados[idx]['id']),
                          conversacionId: _chatsFiltrados[idx]['id'],
                          nombreOtro: _chatsFiltrados[idx]['otro_nombre'],
                          otroUserId: _chatsFiltrados[idx]['otro_id'],
                          anuncioId: (_selectedIndex == 0 ||
                                      _chatsFiltrados[idx]['id'] == widget.conversacionInicial) &&
                                      widget.anuncioIdInicial != null
                              ? widget.anuncioIdInicial
                              : _chatsFiltrados[idx]['anuncio_id'],
                          showAppBar: false,
                        ),
        ),
      ],
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text('Mensajes',
          style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A))),
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
            prefixIcon:
                const Icon(Icons.search, color: Color(0xFF5B4137), size: 20),
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

  Widget _buildChatList({required void Function(int) onTap}) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF36900)));
    }

    final chats = _chatsFiltrados;

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, i) {
        final chat = chats[i];
        return _ChatTile(
          nombre: chat['otro_nombre']?.toString() ?? 'Usuario',
          preview: chat['preview']?.toString() ?? '',
          hora: chat['hora']?.toString() ?? '',
          isActive: i == _selectedIndex,
          isOnline: false,
          unreadCount: chat['unread'] ?? 0,
          searchQuery: _searchQuery,
          onTap: () => onTap(i),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String nombre, preview, hora, searchQuery;
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF36900),
                  child: Text(inicial,
                      style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
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

String _quitarAcentos(String texto) {
  var conAcento = 'áéíóúÁÉÍÓÚüÜ';
  var sinAcento = 'aeiouAEIOUuU';
  String resultado = texto;
  for (int i = 0; i < conAcento.length; i++) {
    resultado = resultado.replaceAll(conAcento[i], sinAcento[i]);
  }
  return resultado;
}