import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../../widgets/unite_header.dart';
import '../../../theme.dart';

class ChatGrupoScreen extends StatefulWidget {
  final String grupoId;
  final String nombreGrupo;
  final String? fotoUrl;

  const ChatGrupoScreen({
    super.key,
    required this.grupoId,
    required this.nombreGrupo,
    this.fotoUrl,
  });

  @override
  State<ChatGrupoScreen> createState() => _ChatGrupoScreenState();
}

class _ChatGrupoScreenState extends State<ChatGrupoScreen> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _mensajes = [];
  Map<String, Map<String, dynamic>> _usuariosCached = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMensajes();
    _suscribirse();
  }

  Future<void> _loadMensajes() async {
    try {
      final data = await _supabase
          .from('mensajes_grupo_estudio')
          .select()
          .eq('grupo_id', widget.grupoId)
          .order('creado_en', ascending: true);

      final mensajes = List<Map<String, dynamic>>.from(data);

      // Cargar información de usuarios remitentes ausentes en caché
      final userIds = mensajes.map((m) => m['remitente_id']?.toString()).toSet();
      for (final id in userIds) {
        if (id != null && !_usuariosCached.containsKey(id)) {
          final uData = await _supabase
              .from('usuarios')
              .select('primer_nombre, primer_apellido, foto_perfil_url')
              .eq('id', id)
              .maybeSingle();
          if (uData != null) {
            _usuariosCached[id] = uData;
          }
        }
      }

      if (mounted) {
        setState(() {
          _mensajes = mensajes;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _suscribirse() {
    _supabase
        .channel('mensajes_grupo_${widget.grupoId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes_grupo_estudio',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'grupo_id',
            value: widget.grupoId,
          ),
          callback: (payload) async {
            final nuevoMsg = payload.newRecord;
            final remitenteId = nuevoMsg['remitente_id']?.toString();

            if (remitenteId != null && !_usuariosCached.containsKey(remitenteId)) {
              final uData = await _supabase
                  .from('usuarios')
                  .select('primer_nombre, primer_apellido, foto_perfil_url')
                  .eq('id', remitenteId)
                  .maybeSingle();
              if (uData != null) {
                _usuariosCached[remitenteId] = uData;
              }
            }

            if (mounted) {
              setState(() {
                _mensajes.add(nuevoMsg);
              });
              _scrollToBottom();
            }
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
    if (userId == null) return;

    await _supabase.from('mensajes_grupo_estudio').insert({
      'grupo_id': widget.grupoId,
      'remitente_id': userId,
      'contenido': text,
    });
  }

  Future<void> _adjuntarArchivo() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subiendo archivo...', style: GoogleFonts.lexend()),
            backgroundColor: const Color(0xFFFF6100),
          ),
        );
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = 'grupos/${widget.grupoId}/$fileName';

      await _supabase.storage
          .from('chat_archivos')
          .uploadBinary(path, file.bytes!);

      final url = _supabase.storage
          .from('chat_archivos')
          .getPublicUrl(path);

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final extension = file.extension ?? 'bin';
      final esImagen = ['jpg', 'jpeg', 'png', 'gif', 'webp']
          .contains(extension.toLowerCase());

      final contenido =
          esImagen ? '[imagen]$url' : '[archivo:${file.name}]$url';

      await _supabase.from('mensajes_grupo_estudio').insert({
        'grupo_id': widget.grupoId,
        'remitente_id': userId,
        'contenido': contenido,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatHora(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getNombreUsuario(String id) {
    if (_usuariosCached.containsKey(id)) {
      final u = _usuariosCached[id]!;
      return '${u['primer_nombre'] ?? ''} ${u['primer_apellido'] ?? ''}';
    }
    return 'Estudiante';
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser?.id;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      appBar: isMobile ? const UniteHeader(currentIndex: 4) : null,
      body: Column(
        children: [
          if (!isMobile) const UniteHeader(currentIndex: 4),
          _buildGroupHeader(),
          _buildDaySeparator(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6100)))
                : _mensajes.isEmpty
                    ? Center(
                        child: Text(
                          'Sé el primero en saludar al grupo 👋',
                          style: GoogleFonts.lexend(
                            color: const Color(0xFF5B4137),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, i) {
                          final msg = _mensajes[i];
                          final isMe = msg['remitente_id'] == myId;
                          return _BurbujaMensajeGrupo(
                            remitenteNombre: isMe ? 'Tú' : _getNombreUsuario(msg['remitente_id']?.toString() ?? ''),
                            texto: msg['contenido'] ?? '',
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

  Widget _buildGroupHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Color(0xFFE65100)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFFF3E0),
            backgroundImage: widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty
                ? NetworkImage(widget.fotoUrl!)
                : null,
            child: widget.fotoUrl == null || widget.fotoUrl!.isEmpty
                ? const Icon(Icons.group_outlined, color: Color(0xFFE65100))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nombreGrupo,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Grupo de estudio',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: const Color(0xFF757575),
                  ),
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
              child: Text(
                'Hoy',
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  color: const Color(0xFF5B4137),
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                  hintText: 'Escribe un mensaje en el grupo...',
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
          boxShadow: _pressed
              ? []
              : [
                  const BoxShadow(
                    color: Color(0xFFCC4D00),
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: const Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _BurbujaMensajeGrupo extends StatelessWidget {
  final String remitenteNombre;
  final String texto;
  final String hora;
  final bool isMe;

  const _BurbujaMensajeGrupo({
    required this.remitenteNombre,
    required this.texto,
    required this.hora,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final bool esImagen = texto.startsWith('[imagen]');
    final bool esArchivo = texto.startsWith('[archivo:');

    Widget msgWidget = Text(
      texto,
      style: GoogleFonts.lexend(
        fontSize: 14,
        color: const Color(0xFF1A1A1A),
      ),
    );

    if (esImagen) {
      final url = texto.replaceFirst('[imagen]', '');
      msgWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
        ),
      );
    } else if (esArchivo) {
      final match = RegExp(r'\[archivo:(.*?)\](.*)').firstMatch(texto);
      final nombre = match?.group(1) ?? 'Archivo';
      msgWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              nombre,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                color: const Color(0xFFE65100),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe ? const Color(0xFFFFE0B2) : const Color(0xFFE3BFB1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  remitenteNombre,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E5900),
                  ),
                ),
              ),
            msgWidget,
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                hora,
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  color: const Color(0xFF8A8A8A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
