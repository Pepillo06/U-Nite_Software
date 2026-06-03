import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../screens/chat/chat_list_screen.dart';
import '../urgencia_dialog.dart';
import '../profile_page.dart';
import '../public_profile_page.dart';

// ============================================================
// DIÁLOGO PRINCIPAL DE DETALLE DE ANUNCIO (REDISEÑADO)
// ============================================================
class DetalleAnuncioDialog extends StatefulWidget {
  final Map<String, dynamic> anuncio;

  const DetalleAnuncioDialog({super.key, required this.anuncio});

  @override
  State<DetalleAnuncioDialog> createState() => _DetalleAnuncioDialogState();
}

class _DetalleAnuncioDialogState extends State<DetalleAnuncioDialog> {
  int _imagenSeleccionada = 0;
  Map<String, dynamic>? _vendedorData;
  bool _cargandoVendedor = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosVendedor();
  }

  // ─── Carga de datos del vendedor ─────────────────────────────────────────
  Future<void> _cargarDatosVendedor() async {
    final vendedorId = widget.anuncio['vendedor_id']?.toString() ?? '';
    if (vendedorId.isEmpty) {
      if (mounted) setState(() => _cargandoVendedor = false);
      return;
    }
    try {
      // Traemos solo los campos que sabemos que existen en la tabla usuarios
      final data = await Supabase.instance.client
          .from('usuarios')
          .select('primer_nombre, primer_apellido, foto_perfil_url, calificacion_promedio, total_ventas')
          .eq('id', vendedorId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _vendedorData = data;
          _cargandoVendedor = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando vendedor: $e');
      // Si falla (ej: columnas no existen), intentamos con solo nombre
      try {
        final data = await Supabase.instance.client
            .from('usuarios')
            .select('primer_nombre, primer_apellido, foto_perfil_url')
            .eq('id', vendedorId)
            .maybeSingle();
        if (mounted) {
          setState(() {
            _vendedorData = data;
            _cargandoVendedor = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _cargandoVendedor = false);
      }
    }
  }

  // ─── Helpers de datos ────────────────────────────────────────────────────
  Map<String, dynamic> get _modalidades =>
      widget.anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};

  List<String> get _imagenes {
    final raw = _modalidades['imagenes'];
    if (raw == null) return [];
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  bool get _tieneVenta => _modalidades.containsKey('venta') && _modalidades['venta'] != null;
  bool get _tieneAlquiler => _modalidades.containsKey('alquiler') && _modalidades['alquiler'] != null;
  bool get _tieneTrueque => _modalidades.containsKey('trueque') && _modalidades['trueque'] != null;

  String get _precioVenta {
    final precio = _modalidades['venta']?['precio'];
    return '\$${(precio as num?)?.toStringAsFixed(2) ?? '0.00'}';
  }

  List<Map<String, dynamic>> get _opcionesAlquiler {
    final alquiler = _modalidades['alquiler'];
    if (alquiler is List) {
      return alquiler.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  String get _descripcionTrueque {
    final trueque = _modalidades['trueque'];
    if (trueque is Map) return trueque['descripcion']?.toString() ?? '';
    return '';
  }

  // FIX PRINCIPAL: campus_pickup puede ser bool (true) en artículos viejos,
  // o List en artículos nuevos. Manejamos ambos casos de forma segura.
  List<String> get _campusPickup {
    final raw = _modalidades['campus_pickup'];
    if (raw == null) return [];
    if (raw is bool) return [];
    if (raw is List) return raw.whereType<String>().where((s) => s.isNotEmpty).toList();
    return [];
  }

  // ─── Verificación de auth ─────────────────────────────────────────────────
  bool _verificarAutenticacion(BuildContext context) {
    if (Supabase.instance.client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para realizar esta acción'),
          backgroundColor: UColors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  // ─── Navegar al perfil del vendedor ──────────────────────────────────────
  void _irAlPerfilVendedor(BuildContext context) {
    final vendedorId = widget.anuncio['vendedor_id']?.toString() ?? '';
    if (vendedorId.isEmpty) return;

    Navigator.pop(context); // Cierra el popup primero

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null && currentUser.id == vendedorId) {
      // Es el propio usuario → perfil propio con edición
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProfilePage()));
    } else {
      // Es otro usuario → perfil público sin botón de editar
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => PublicProfilePage(userId: vendedorId)));
    }
  }

  // ─── Contactar Vendedor (lógica 100% intacta) ─────────────────────────────
  Future<void> _contactarVendedor(BuildContext context) async {
    if (!_verificarAutenticacion(context)) return;
    final urgencia = await mostrarDialogUrgencia(context);
    if (urgencia == null || !context.mounted) return;

    final supabase = Supabase.instance.client;
    final compradorId = supabase.auth.currentUser!.id;
    final vendedorId = widget.anuncio['vendedor_id']?.toString() ?? '';
    final anuncioId = widget.anuncio['id']?.toString();
    final titulo = widget.anuncio['titulo'] ?? '';

    if (vendedorId.isEmpty || vendedorId == compradorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes contactarte contigo mismo')),
      );
      return;
    }
    try {
      await supabase.from('solicitudes_urgencia').insert({
        'comprador_id': compradorId,
        'vendedor_id': vendedorId,
        'anuncio_id': anuncioId,
        'nivel_urgencia': urgencia,
        'estado': 'pendiente',
      });
    } catch (e) {
      debugPrint('Error guardando urgencia: $e');
    }
    try {
      final existentes = await supabase
          .from('conversaciones')
          .select('id')
          .eq('comprador_id', compradorId)
          .eq('vendedor_id', vendedorId);

      String conversacionId;
      final esNueva = existentes.isEmpty;
      if (!esNueva) {
        conversacionId = existentes.first['id'];
        await supabase
            .from('conversaciones')
            .update({'anuncio_id': anuncioId}).eq('id', conversacionId);
      } else {
        final nueva = await supabase
            .from('conversaciones')
            .insert({
              'comprador_id': compradorId,
              'vendedor_id': vendedorId,
              'anuncio_id': anuncioId,
            })
            .select('id')
            .single();
        conversacionId = nueva['id'];
      }

      final vendedorInfo = await supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido')
          .eq('id', vendedorId)
          .maybeSingle();
      final nombreVendedor = vendedorInfo != null
          ? '${vendedorInfo['primer_nombre']} ${vendedorInfo['primer_apellido']}'
          : 'Vendedor';

      if (esNueva) {
        final compradorInfo = await supabase
            .from('usuarios')
            .select('primer_nombre, primer_apellido')
            .eq('id', compradorId)
            .maybeSingle();
        final nombreComprador = compradorInfo != null
            ? '${compradorInfo['primer_nombre']} ${compradorInfo['primer_apellido']}'
            : 'Un usuario';
        try {
          await supabase.from('notificaciones').insert({
            'usuario_id': vendedorId,
            'tipo': 'contacto',
            'titulo': 'Nuevo mensaje sobre tu producto',
            'mensaje': '$nombreComprador preguntó por "$titulo"',
            'leida': false,
            'datos': {
              'conversacion_id': conversacionId,
              'nombre_otro': nombreVendedor,
              'otro_user_id': compradorId,
              'anuncio_id': anuncioId,
              'urgencia': urgencia,
            },
          });
        } catch (_) {}
      }

      if (!context.mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(MaterialPageRoute(
        builder: (_) => ChatListScreen(
          conversacionInicial: conversacionId,
          nombreInicial: nombreVendedor,
          otroUserIdInicial: vendedorId,
          anuncioIdInicial: anuncioId,
        ),
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ─── Diálogo de Trueque — fondo blanco ───────────────────────────────────
  void _mostrarDialogTrueque(BuildContext context) {
    final titulo = widget.anuncio['titulo'] ?? '';
    final ofertaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // ← fondo blanco
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Color(0xFF245000)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Proponer Trueque',
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: const Color(0xFF1A1A1A))),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_descripcionTrueque.isNotEmpty) ...[
              Text('El vendedor busca:',
                  style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5B4137))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3F3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE3BFB1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        color: Color(0xFFF36900), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_descripcionTrueque,
                          style: GoogleFonts.lexend(
                              fontSize: 13, color: const Color(0xFF1A1A1A))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text('¿Qué ofreces a cambio de "$titulo"?',
                style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            TextField(
              controller: ofertaController,
              maxLines: 3,
              style: GoogleFonts.lexend(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ej: Tengo una calculadora científica...',
                hintStyle: GoogleFonts.lexend(
                    color: const Color(0xFF8F7065), fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3BFB1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF245000), width: 2),
                ),
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
              final oferta = ofertaController.text.trim();
              if (oferta.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('Describe qué ofreces a cambio',
                      style: GoogleFonts.lexend()),
                  backgroundColor: const Color(0xFFF36900),
                ));
                return;
              }
              Navigator.pop(ctx);
              await _enviarSolicitudTrueque(context, oferta);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF245000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Enviar Propuesta',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarSolicitudTrueque(
      BuildContext context, String objetoOfrecido) async {
    final supabase = Supabase.instance.client;
    final compradorId = supabase.auth.currentUser?.id;
    if (compradorId == null) return;

    final vendedorId = widget.anuncio['vendedor_id']?.toString() ?? '';
    final anuncioId = widget.anuncio['id']?.toString();
    final titulo = widget.anuncio['titulo'] ?? '';

    if (vendedorId.isEmpty || vendedorId == compradorId) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes proponer trueque contigo mismo')));
      return;
    }
    try {
      final existente = await supabase
          .from('solicitudes_trueque')
          .select('id')
          .eq('anuncio_id', anuncioId!)
          .eq('solicitante_id', compradorId)
          .eq('estado', 'pendiente');

      if (existente.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Ya tienes una propuesta pendiente para este producto',
                style: GoogleFonts.lexend()),
            backgroundColor: const Color(0xFFF36900),
          ));
        }
        return;
      }

      await supabase.from('solicitudes_trueque').insert({
        'anuncio_id': anuncioId,
        'solicitante_id': compradorId,
        'receptor_id': vendedorId,
        'objeto_ofrecido': objetoOfrecido,
        'estado': 'pendiente',
      });

      final compradorData = await supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido')
          .eq('id', compradorId)
          .maybeSingle();
      final nombreComprador = compradorData != null
          ? '${compradorData['primer_nombre']} ${compradorData['primer_apellido']}'
          : 'Un usuario';

      // Notificación al vendedor
      await supabase.from('notificaciones').insert({
        'usuario_id': vendedorId,
        'tipo': 'trueque',
        'titulo': 'Nueva propuesta de trueque',
        'mensaje': '$nombreComprador ofrece "$objetoOfrecido" por "$titulo"',
        'leida': false,
        'datos': {
          'anuncio_id': anuncioId,
          'solicitante_id': compradorId,
          'nombre_otro': nombreComprador,
        },
      });

      // Notificación al comprador de que su solicitud fue enviada
      await supabase.from('notificaciones').insert({
        'usuario_id': compradorId,
        'tipo': 'trueque',
        'titulo': 'Solicitud de trueque enviada',
        'mensaje':
            'Tu propuesta por "$titulo" fue enviada. Te avisaremos cuando el vendedor responda.',
        'leida': false,
        'datos': {
          'anuncio_id': anuncioId,
        },
      });

      // Dialog de confirmación al comprador — compacto, fondo blanco, con X
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close,
                            size: 16, color: Color(0xFF5B4137)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Color(0xFF245000), size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '¡Propuesta enviada!',
                      style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu propuesta por "$titulo" fue enviada. Te notificaremos cuando el vendedor responda.',
                      style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: const Color(0xFF5B4137),
                          height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5B4137),
                          side: const BorderSide(color: Color(0xFFE3BFB1)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text('Cerrar',
                            style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ─── BUILD PRINCIPAL ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940, maxHeight: 590),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 580;
              return isWide
                  ? _buildWideLayout(context)
                  : _buildNarrowLayout(context);
            },
          ),
        ),
      ),
    );
  }

  // ─── Layout ancho (desktop) ───────────────────────────────────────────────
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel izquierdo: imágenes
        Expanded(
          flex: 9,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: Container(
              color: const Color(0xFFF4F4F4),
              child: _buildImagePanel(),
            ),
          ),
        ),
        // Panel derecho: información
        Expanded(
          flex: 11,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCloseButton(context),
                  const SizedBox(height: 6),
                  _buildInfoContent(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Layout estrecho (móvil) ──────────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildCloseButton(context)],
            ),
          ),
          Container(
            color: const Color(0xFFF4F4F4),
            padding: const EdgeInsets.all(16),
            child: _buildImagePanel(),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: _buildInfoContent(context),
          ),
        ],
      ),
    );
  }

  // ─── Botón cerrar ─────────────────────────────────────────────────────────
  Widget _buildCloseButton(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFFEEEEEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 16, color: Color(0xFF555555)),
        ),
      ),
    );
  }

  // ─── Panel de imágenes ────────────────────────────────────────────────────
  Widget _buildImagePanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Imagen principal
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _imagenes.isNotEmpty
                  ? Image.network(
                      _imagenes[_imagenSeleccionada],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 48, color: Colors.grey)),
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported,
                          size: 48, color: Colors.grey)),
            ),
          ),
          // Miniaturas
          if (_imagenes.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imagenes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final sel = _imagenSeleccionada == i;
                  return GestureDetector(
                    onTap: () => setState(() => _imagenSeleccionada = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel ? UColors.orange : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(_imagenes[i], fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Contenido informativo ────────────────────────────────────────────────
  Widget _buildInfoContent(BuildContext context) {
    final titulo = widget.anuncio['titulo'] ?? '';
    final descripcion = widget.anuncio['descripcion'] ?? '';
    final categoria = widget.anuncio['categoria'] ?? '';
    final estado = widget.anuncio['estado_producto'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges
        if (categoria.isNotEmpty || estado.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (categoria.isNotEmpty) _buildBadge(categoria, isCategoria: true),
              if (estado.isNotEmpty)
                _buildBadge(estado[0].toUpperCase() + estado.substring(1)),
            ],
          ),
        const SizedBox(height: 10),

        // Título
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // ── PRECIO VENTA ────────────────────────────────────────────────────
        if (_tieneVenta) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _precioVenta,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF245000),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Venta Final',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF245000)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // ── TRUEQUE ─────────────────────────────────────────────────────────
        if (_tieneTrueque) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 242, 255, 231),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color.fromARGB(255, 181, 212, 155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    color: UColors.greenDark, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _descripcionTrueque.isNotEmpty
                        ? 'Intercambio por: $_descripcionTrueque'
                        : 'Acepta intercambio / trueque',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: UColors.greenDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── ALQUILER ────────────────────────────────────────────────────────
        if (_tieneAlquiler && _opcionesAlquiler.isNotEmpty) ...[
          ..._opcionesAlquiler.map((opt) {
            final costo =
                (opt['costo'] as num?)?.toStringAsFixed(2) ?? '0.00';
            final unidad = opt['unidad_tiempo']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.schedule_outlined,
                      size: 15, color: Color(0xFF888888)),
                  const SizedBox(width: 5),
                  Text(
                    'Alquiler disponible: \$$costo / $unidad',
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF555555)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],

        // ── DESCRIPCIÓN ─────────────────────────────────────────────────────
        if (descripcion.isNotEmpty) ...[
          const Divider(height: 20, color: Color(0xFFEEEEEE)),
          const Text(
            'Descripción',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 5),
          Text(
            descripcion,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12.5, height: 1.55, color: Color(0xFF444444)),
          ),
        ],

        // ── PUNTO DE ENTREGA ────────────────────────────────────────────────
        if (_campusPickup.isNotEmpty) ...[
          const SizedBox(height: 20),
          ..._campusPickup.map((campus) => _buildCampusCard(campus)),
        ],

        // ── VENDEDOR ────────────────────────────────────────────────────────
        const SizedBox(height: 14),
        _buildVendedorSection(context),

        // ── BOTONES ─────────────────────────────────────────────────────────
        const SizedBox(height: 14),
        _buildBotonesAccion(context),
      ],
    );
  }

  // ─── Badge categoría / estado ─────────────────────────────────────────────
  Widget _buildBadge(String label, {bool isCategoria = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCategoria
            ? const Color(0xFF245000).withOpacity(0.11)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isCategoria
              ? const Color(0xFF245000)
              : const Color(0xFF555555),
        ),
      ),
    );
  }

  // ─── Sección del vendedor ─────────────────────────────────────────────────
  Widget _buildVendedorSection(BuildContext context) {
    if (_cargandoVendedor) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: UColors.orange),
          ),
        ),
      );
    }

    final nombre = _vendedorData != null
        ? '${_vendedorData!['primer_nombre'] ?? ''} ${_vendedorData!['primer_apellido'] ?? ''}'
            .trim()
        : 'Vendedor desconocido';

    final fotoUrl = _vendedorData?['foto_perfil_url']?.toString() ?? '';
    final calificacion =
        (_vendedorData?['calificacion_promedio'] as num?)?.toDouble();
    final totalVentas =
        (_vendedorData?['total_ventas'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => _irAlPerfilVendedor(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFDDDDDD),
              backgroundImage:
                  fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
              child: fotoUrl.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (calificacion != null && calificacion > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFF36900)),
                        const SizedBox(width: 3),
                        Text(
                          '${calificacion.toStringAsFixed(1)} ($totalVentas ventas)',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              'Ver perfil',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: UColors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tarjeta de campus/punto de entrega ───────────────────────────────────
  Widget _buildCampusCard(String campus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: UColors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 18, color: UColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Punto de Entrega',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  campus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Botones de acción ────────────────────────────────────────────────────
  Widget _buildBotonesAccion(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _contactarVendedor(context),
                  icon: const Icon(Icons.chat_bubble_outline, size: 17),
                  label: const Text('Contactar Vendedor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        if (_tieneTrueque) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                if (!_verificarAutenticacion(context)) return;
                _mostrarDialogTrueque(context);
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 17),
              label: const Text('Proponer Trueque'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF245000),
                side: const BorderSide(color: Color(0xFF245000), width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}