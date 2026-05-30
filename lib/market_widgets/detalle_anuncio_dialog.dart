import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart'; // Ajusta la ruta si tus estilos están en otra carpeta
import '../screens/chat/chat_list_screen.dart';
import '../urgencia_dialog.dart';

class DetalleAnuncioDialog extends StatelessWidget {
  final Map<String, dynamic> anuncio;

  const DetalleAnuncioDialog({super.key, required this.anuncio});

  // --- MÉTODOS AUXILIARES EXTRAÍDOS ---
  String _getPrecio() {
    final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    if (modalidades.containsKey('venta')) {
      final precio = modalidades['venta']['precio'];
      return '\$${(precio as num?)?.toStringAsFixed(2) ?? '0.00'}';
    } else if (modalidades.containsKey('alquiler')) {
      final alquiler = modalidades['alquiler'];
      if (alquiler is List && alquiler.isNotEmpty) {
        final costo = alquiler[0]['costo'];
        final unidad = alquiler[0]['unidad_tiempo'] ?? '';
        return '\$${(costo as num?)?.toStringAsFixed(2) ?? '0.00'}/$unidad';
      }
    } else if (modalidades.containsKey('trueque')) {
      return 'Trueque';
    }
    return 'Consultar';
  }

  bool _verificarAutenticacion(BuildContext context) {
    if (Supabase.instance.client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para realizar esta acción'),
          backgroundColor: UColors.orange,
        ),
      );
      // Nota: Si usas LoginPage() aquí, asegúrate de importar su archivo correspondiente.
      // Si prefieres no arrastrar dependencias de login, puedes manejarlo con un Navigator.pop
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    final imagenes = (modalidades['imagenes'] as List<dynamic>? ?? []).cast<String>();
    final titulo = anuncio['titulo'] ?? '';
    final descripcion = anuncio['descripcion'] ?? '';
    final categoria = anuncio['categoria'] ?? '';
    final estado = anuncio['estado_producto'] ?? '';
    final precio = _getPrecio();

    int imagenSeleccionada = 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final imageSection = Column(
              children: [
                // Imagen principal
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imagenes.isNotEmpty
                        ? Image.network(
                            imagenes[imagenSeleccionada],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey,
                          ),
                  ),
                ),
                // Miniaturas
                if (imagenes.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imagenes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        return GestureDetector(
                          onTap: () => setStateDialog(() => imagenSeleccionada = i),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: imagenSeleccionada == i ? UColors.orange : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(imagenes[i], fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );

            final infoSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    if (categoria.isNotEmpty) _Badge(label: categoria),
                    if (estado.isNotEmpty)
                      _Badge(label: estado[0].toUpperCase() + estado.substring(1)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  precio,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: UColors.greenDark,
                  ),
                ),
                const SizedBox(height: 24),
                if (descripcion.isNotEmpty) ...[
                  const Text(
                    'Descripción',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF444444)),
                  ),
                  const SizedBox(height: 24),
                ],
                // Botón contactar vendedor
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!_verificarAutenticacion(context)) return;
                      final urgencia = await mostrarDialogUrgencia(context);
                      if (urgencia == null || !context.mounted) return;
                      
                      final supabase = Supabase.instance.client;
                      final compradorId = supabase.auth.currentUser!.id;
                      final vendedorId = anuncio['vendedor_id']?.toString() ?? '';
                      final anuncioId = anuncio['id']?.toString();
                      
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
                              .update({'anuncio_id': anuncioId})
                              .eq('id', conversacionId);
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
                        
                        final vendedorData = await supabase
                            .from('usuarios')
                            .select('primer_nombre, primer_apellido')
                            .eq('id', vendedorId)
                            .maybeSingle();
                        final nombreVendedor = vendedorData != null
                            ? '${vendedorData['primer_nombre']} ${vendedorData['primer_apellido']}'
                            : 'Vendedor';
                        
                        if (esNueva) {
                          final compradorData = await supabase
                              .from('usuarios')
                              .select('primer_nombre, primer_apellido')
                              .eq('id', compradorId)
                              .maybeSingle();
                          final nombreComprador = compradorData != null
                              ? '${compradorData['primer_nombre']} ${compradorData['primer_apellido']}'
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
                        
                        final nav = Navigator.of(context);
                        nav.pop(); // Cierra el diálogo de detalles
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Contactar Vendedor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                // Botón Proponer Trueque
                if (modalidades.containsKey('trueque')) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _mostrarDialogTrueque(context, anuncio),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Proponer Trueque'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF245000),
                        side: const BorderSide(color: Color(0xFF245000), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ],
            );

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F5F5),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: imageSection),
                              const SizedBox(width: 32),
                              Expanded(flex: 4, child: infoSection),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              imageSection,
                              const SizedBox(height: 24),
                              infoSection,
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- MÉTODOS Y DIÁLOGOS ADICIONALES (TRUEQUE) ---
  void _mostrarDialogTrueque(BuildContext context, Map<String, dynamic> anuncio) {
    final modalidades = anuncio['detalles_modalidades'] as Map<String, dynamic>? ?? {};
    final descripcionTrueque = modalidades['trueque']?['descripcion']?.toString() ?? '';
    final titulo = anuncio['titulo'] ?? '';
    final ofertaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Color(0xFF245000)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Proponer Trueque',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (descripcionTrueque.isNotEmpty) ...[
              Text(
                'El vendedor busca:',
                style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF5B4137)),
              ),
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
                    const Icon(Icons.swap_horiz_rounded, color: Color(0xFFF36900), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        descripcionTrueque,
                        style: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFF1A1A1A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              '¿Qué ofreces a cambio de "$titulo"?',
              style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ofertaController,
              maxLines: 3,
              style: GoogleFonts.lexend(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ej: Tengo una calculadora científica...',
                hintStyle: GoogleFonts.lexend(color: const Color(0xFF8F7065), fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3BFB1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF245000), width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.lexend(color: const Color(0xFF5B4137))),
          ),
          ElevatedButton(
            onPressed: () async {
              final oferta = ofertaController.text.trim();
              if (oferta.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Describe qué ofreces a cambio', style: GoogleFonts.lexend()),
                    backgroundColor: const Color(0xFFF36900),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await _enviarSolicitudTrueque(context, anuncio, oferta);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF245000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Enviar Propuesta', style: GoogleFonts.lexend(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarSolicitudTrueque(
    BuildContext context,
    Map<String, dynamic> anuncio,
    String objetoOfrecido,
  ) async {
    final supabase = Supabase.instance.client;
    final compradorId = supabase.auth.currentUser?.id;
    if (compradorId == null) return;

    final vendedorId = anuncio['vendedor_id']?.toString() ?? '';
    final anuncioId = anuncio['id']?.toString();
    final titulo = anuncio['titulo'] ?? '';

    if (vendedorId.isEmpty || vendedorId == compradorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes proponer trueque contigo mismo')),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ya tienes una propuesta pendiente para este producto', style: GoogleFonts.lexend()),
              backgroundColor: const Color(0xFFF36900),
            ),
          );
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Propuesta enviada! El vendedor te responderá pronto.', style: GoogleFonts.lexend()),
            backgroundColor: const Color(0xFF245000),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// Sub-widget Badge local necesario
class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}