import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

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
  // Preview del producto en el input (estilo WhatsApp)
  bool _mostrarPreviewProducto = false;
  String _estadoConexion = '';

  @override
  void initState() {
    super.initState();
    _loadMensajes();
    _loadAnuncio();
    _suscribirse();
    _cargarEstadoConexion();
  }

  Future<void> _cargarEstadoConexion() async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select('ultima_conexion')
          .eq('id', widget.otroUserId)
          .maybeSingle();

      if (data == null || data['ultima_conexion'] == null) {
        setState(() => _estadoConexion = 'Sin conexión reciente');
        return;
      }

      final ultima = DateTime.parse(data['ultima_conexion']).toLocal();
      final ahora = DateTime.now();
      final diferencia = ahora.difference(ultima);

      if (diferencia.inMinutes < 2) {
        setState(() => _estadoConexion = 'En línea');
      } else if (diferencia.inHours < 24 && ultima.day == ahora.day) {
        final hora =
            '${ultima.hour.toString().padLeft(2, '0')}:${ultima.minute.toString().padLeft(2, '0')}';
        setState(() => _estadoConexion = 'Última vez conectado hoy a las $hora');
      } else if (diferencia.inDays == 1) {
        final hora =
            '${ultima.hour.toString().padLeft(2, '0')}:${ultima.minute.toString().padLeft(2, '0')}';
        setState(() => _estadoConexion = 'Última vez conectado ayer a las $hora');
      } else {
        setState(() =>
            _estadoConexion = 'Última vez conectado ${ultima.day}/${ultima.month}');
      }
    } catch (_) {
      setState(() => _estadoConexion = 'En línea');
    }
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
    try {
      await _supabase
          .from('notificaciones')
          .update({'leida': true})
          .eq('usuario_id', userId)
          .eq('leida', false)
          .filter('datos->>conversacion_id', 'eq', widget.conversacionId);
    } catch (_) {}
  }

  Future<void> _loadAnuncio() async {
    if (widget.anuncioId == null) return;
    final data = await _supabase
        .from('anuncios_marketplace')
        .select('titulo, detalles_modalidades, vendedor_id')
        .eq('id', widget.anuncioId!)
        .maybeSingle();
    if (data != null) {
      setState(() {
        _anuncio = data;
        // Solo mostrar preview si el usuario actual NO es el vendedor
        final userId = _supabase.auth.currentUser?.id;
        final vendedorId = data['vendedor_id']?.toString() ?? '';
        _mostrarPreviewProducto = userId != vendedorId;
      });
    }
  }

  String _getPrecioAnuncio() {
    if (_anuncio == null) return '';
    final modalidades =
        _anuncio!['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    if (modalidades.containsKey('venta')) {
      final precio = modalidades['venta']['precio'];
      return '\$${(precio as num?)?.toStringAsFixed(2) ?? '0.00'}';
    }
    if (modalidades.containsKey('alquiler')) {
      final alquiler = modalidades['alquiler'];
      if (alquiler is List && alquiler.isNotEmpty) {
        final costo = alquiler[0]['costo'];
        final unidad = alquiler[0]['unidad_tiempo'] ?? '';
        return '\$${(costo as num?)?.toStringAsFixed(2) ?? '0.00'}/$unidad';
      }
    }
    if (modalidades.containsKey('trueque')) return 'Trueque';
    return 'Consultar';
  }

  String _getImagenAnuncio() {
    if (_anuncio == null) return '';
    final modalidades =
        _anuncio!['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    final imagenes = modalidades['imagenes'] as List<dynamic>? ?? [];
    return imagenes.isNotEmpty ? imagenes[0].toString() : '';
  }

  void _suscribirse() {
    _supabase
        .channel('mensajes_${widget.conversacionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversacion_id',
            value: widget.conversacionId,
          ),
          callback: (payload) async {
            // Recargar todos los mensajes para asegurar consistencia
            final data = await _supabase
                .from('mensajes')
                .select()
                .eq('conversacion_id', widget.conversacionId)
                .order('creado_en', ascending: true);
            if (mounted) {
              setState(() {
                _mensajes = List<Map<String, dynamic>>.from(data);
              });
              _scrollToBottom();
              await _marcarComoLeidos();
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

    // Si hay preview de producto activa, incluir referencia al producto
    String contenido = text;
    if (_mostrarPreviewProducto && _anuncio != null) {
      final titulo = _anuncio!['titulo'] ?? '';
      final precio = _getPrecioAnuncio();
      final imagen = _getImagenAnuncio();
      contenido = '[producto:$titulo|$precio|$imagen]$text';
      setState(() => _mostrarPreviewProducto = false);
    }

    await _supabase.from('mensajes').insert({
      'conversacion_id': widget.conversacionId,
      'remitente_id': userId,
      'contenido': contenido,
    });

    try {
      final otroUserId = widget.otroUserId;
      final userData = await _supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido')
          .eq('id', userId)
          .maybeSingle();
      final nombreRemitente = userData != null
          ? '${userData['primer_nombre']} ${userData['primer_apellido']}'
          : 'Alguien';

      await _supabase.from('notificaciones').insert({
        'usuario_id': otroUserId,
        'tipo': 'mensaje',
        'titulo': 'Nuevo mensaje de $nombreRemitente',
        'mensaje': text.length > 50 ? '${text.substring(0, 50)}...' : text,
        'leida': false,
        'datos': {
          'conversacion_id': widget.conversacionId,
          'nombre_otro': nombreRemitente,
          'otro_user_id': userId,
          'anuncio_id': widget.anuncioId,
        },
      });
    } catch (_) {}
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
            backgroundColor: const Color(0xFFF36900),
            duration: const Duration(seconds: 10),
          ),
        );
      }

      final extension = file.extension ?? 'bin';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '$userId/$fileName';

      await _supabase.storage
          .from('chat_archivos')
          .uploadBinary(path, file.bytes!);

      final url = _supabase.storage
          .from('chat_archivos')
          .getPublicUrl(path);

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final esImagen = ['jpg', 'jpeg', 'png', 'gif', 'webp']
          .contains(extension.toLowerCase());

      final contenido =
          esImagen ? '[imagen]$url' : '[archivo:${file.name}]$url';

      await _supabase.from('mensajes').insert({
        'conversacion_id': widget.conversacionId,
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

  bool get _estaEnLinea => _estadoConexion == 'En línea';

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

  Widget _buildEstadoConexionWidget() {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _estaEnLinea
                ? const Color(0xFF306B18)
                : const Color(0xFF9E9E9E),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _estadoConexion.isEmpty ? '...' : _estadoConexion,
          style: GoogleFonts.lexend(
            fontSize: 11,
            color: _estaEnLinea
                ? const Color(0xFF306B18)
                : const Color(0xFF9E9E9E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              bottom: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _estaEnLinea
                      ? const Color(0xFF306B18)
                      : const Color(0xFF9E9E9E),
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
            _buildEstadoConexionWidget(),
          ],
        ),
      ],
    );
  }

  // Header desktop SIN el card del producto
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
                bottom: 0,
                right: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _estaEnLinea
                        ? const Color(0xFF306B18)
                        : const Color(0xFF9E9E9E),
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
              _buildEstadoConexionWidget(),
            ],
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  // Preview del producto estilo WhatsApp encima del input
  Widget _buildPreviewProducto() {
    if (!_mostrarPreviewProducto || _anuncio == null) return const SizedBox();
    final titulo = _anuncio!['titulo'] ?? '';
    final precio = _getPrecioAnuncio();
    final imagen = _getImagenAnuncio();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F3),
        border: const Border(
          top: BorderSide(color: Color(0xFFE3BFB1)),
          left: BorderSide(color: Color(0xFFF36900), width: 3),
        ),
      ),
      child: Row(
        children: [
          if (imagen.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                imagen,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFFE3BFB1),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: Color(0xFF5B4137), size: 20),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE3BFB1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: Color(0xFF5B4137), size: 20),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  precio,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF36900),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF5B4137)),
            onPressed: () => setState(() => _mostrarPreviewProducto = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPreviewProducto(),
        Container(
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
        ),
      ],
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
              color: _pressed
                  ? Colors.transparent
                  : const Color(0xFFCC4D00),
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

  // Parsea el prefijo [producto:titulo|precio|imagen]
  Map<String, String>? _parsearProducto() {
    if (!texto.startsWith('[producto:')) return null;
    final endIdx = texto.indexOf(']');
    if (endIdx == -1) return null;
    final partes = texto.substring(10, endIdx).split('|');
    if (partes.length < 2) return null;
    return {
      'titulo': partes[0],
      'precio': partes[1],
      'imagen': partes.length > 2 ? partes[2] : '',
      'texto': texto.substring(endIdx + 1),
    };
  }

  Widget _buildContenidoMensaje(BuildContext context) {
    // Mensaje con referencia a producto
    final producto = _parsearProducto();
    if (producto != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview del producto
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFFFF9070).withOpacity(0.4)
                  : const Color(0xFFD0CFC9),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: isMe
                      ? const Color(0xFFFF6100)
                      : const Color(0xFF5B4137),
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (producto['imagen']!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      producto['imagen']!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.shopping_bag_outlined, size: 16),
                    ),
                  )
                else
                  const Icon(Icons.shopping_bag_outlined, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto['titulo']!,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isMe
                              ? const Color(0xFF370E00)
                              : const Color(0xFF1B1C1C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        producto['precio']!,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isMe
                              ? const Color(0xFFCC4D00)
                              : const Color(0xFF5B4137),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (producto['texto']!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              producto['texto']!,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: isMe
                    ? const Color(0xFF370E00)
                    : const Color(0xFF1B1C1C),
                height: 1.5,
              ),
            ),
          ],
        ],
      );
    }

    if (texto.startsWith('[imagen]')) {
      final url = texto.replaceFirst('[imagen]', '');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            '📎 Imagen no disponible',
            style: GoogleFonts.lexend(fontSize: 13),
          ),
        ),
      );
    }

    if (texto.startsWith('[archivo:')) {
      final match = RegExp(r'\[archivo:(.+?)\](.+)').firstMatch(texto);
      final nombre = match?.group(1) ?? 'Archivo';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file,
              size: 16,
              color: isMe
                  ? const Color(0xFF370E00)
                  : const Color(0xFF1B1C1C)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              nombre,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: isMe
                    ? const Color(0xFF370E00)
                    : const Color(0xFF1B1C1C),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      texto,
      style: GoogleFonts.lexend(
        fontSize: 14,
        color: isMe ? const Color(0xFF370E00) : const Color(0xFF1B1C1C),
        height: 1.5,
      ),
    );
  }

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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: _buildContenidoMensaje(context),
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