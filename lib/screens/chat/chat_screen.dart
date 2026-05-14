import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String conversacionId;
  final String nombreOtro;
  final String otroUserId;
  final String? anuncioId;
  final bool showAppBar;

  const ChatScreen({
    super.key,
    required this.conversacionId,
    required this.nombreOtro,
    required this.otroUserId,
    this.anuncioId,
    this.showAppBar = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _mensajes = [];
  Map<String, dynamic>? _anuncio;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMensajes();
    _loadAnuncio();
    _suscribirse();
  }

  Future<void> _loadMensajes() async {
    final data = await _supabase
        .from('mensajes')
        .select()
        .eq('conversacion_id', widget.conversacionId)
        .order('creado_en', ascending: true);
    setState(() {
      _mensajes = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
    _scrollToBottom();
    await _marcarComoLeidos();
  }

  Future<void> _marcarComoLeidos() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('mensajes')
        .update({'leido': true})
        .eq('conversacion_id', widget.conversacionId)
        .eq('leido', false)
        .neq('remitente_id', userId);
  }

  Future<void> _loadAnuncio() async {
    if (widget.anuncioId == null) return;
    final data = await _supabase
        .from('anuncios_marketplace')
        .select('titulo, precio_monto, precio_moneda')
        .eq('id', widget.anuncioId!)
        .maybeSingle();
    if (data != null) setState(() => _anuncio = data);
  }

  void _suscribirse() {
    _supabase
        .channel('mensajes:${widget.conversacionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversacion_id',
            value: widget.conversacionId,
          ),
          callback: (payload) {
            setState(() => _mensajes.add(payload.newRecord));
            _scrollToBottom();
            _marcarComoLeidos();
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _mensajes.add({
          'contenido': text,
          'remitente_id': 'yo',
          'creado_en': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();
      return;
    }

    await _supabase.from('mensajes').insert({
      'conversacion_id': widget.conversacionId,
      'remitente_id': userId,
      'contenido': text,
    });
  }

  Future<void> _adjuntarArchivo() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Función de archivos disponible en la app móvil',
          style: GoogleFonts.lexend(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFFF36900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatHora(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser?.id;
    final inicial = widget.nombreOtro.isNotEmpty
        ? widget.nombreOtro[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F9),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: const Color(0xFFE3BFB1), height: 1),
              ),
              leadingWidth: 40,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: Color(0xFF1A1A1A)),
                onPressed: () => Navigator.pop(context),
              ),
              title: _buildChatHeaderTitle(inicial),
            )
          : null,
      body: Column(
        children: [
          if (!widget.showAppBar) _buildDesktopChatHeader(inicial),
          _buildDaySeparator(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF36900)))
                : _mensajes.isEmpty
                    ? Center(
                        child: Text('Sé el primero en escribir 👋',
                            style: GoogleFonts.lexend(
                                color: const Color(0xFF5B4137), fontSize: 14)))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, i) {
                          final msg = _mensajes[i];
                          final isMe = msg['remitente_id'] == myId;
                          return _BurbujaMensaje(
                            texto: msg['contenido'],
                            hora: _formatHora(msg['creado_en']),
                            isMe: isMe,
                          );
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatHeaderTitle(String inicial) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF36900),
              child: Text(inicial,
                  style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF306B18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nombreOtro,
                style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A))),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF306B18), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text('En línea',
                    style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: const Color(0xFF306B18),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopChatHeader(String inicial) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF36900),
                child: Text(inicial,
                    style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF306B18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.nombreOtro,
                  style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A))),
              Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFF306B18), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text('En línea',
                      style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: const Color(0xFF306B18),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (_anuncio != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3BFB1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3BFB1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: Color(0xFF5B4137), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_anuncio!['titulo'] ?? '',
                          style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A))),
                      Text(
                        '\$${_anuncio!['precio_monto']} ${_anuncio!['precio_moneda'] ?? ''}',
                        style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF36900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE3BFB1))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEDED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Hoy',
                  style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: const Color(0xFF5B4137),
                      fontWeight: FontWeight.w500)),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE3BFB1))),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded,
                color: Color(0xFF5B4137), size: 22),
            onPressed: _adjuntarArchivo,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE3BFB1)),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.lexend(
                    fontSize: 14, color: const Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: GoogleFonts.lexend(
                      color: const Color(0xFF5B4137), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _enviar(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(onPressed: _enviar),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class _SendButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _SendButton({required this.onPressed});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _pressed ? 4 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6100),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            bottom: BorderSide(
              color: _pressed ? Colors.transparent : const Color(0xFFCC4D00),
              width: _pressed ? 0 : 4,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ENVIAR',
                style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2)),
            const SizedBox(width: 6),
            const Icon(Icons.send_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _BurbujaMensaje extends StatelessWidget {
  final String texto, hora;
  final bool isMe;

  const _BurbujaMensaje({
    required this.texto,
    required this.hora,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFFFFB598)
                  : const Color(0xFFE9E8E7),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(texto,
                style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: isMe
                        ? const Color(0xFF370E00)
                        : const Color(0xFF1B1C1C),
                    height: 1.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(hora,
                style: GoogleFonts.lexend(
                    fontSize: 10, color: const Color(0xFF8F7065))),
          ),
        ],
      ),
    );
  }
}