import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🌟 Agregamos la importación de Supabase

class StudymatchChatPage extends StatefulWidget {
  final String grupoInicialId;
  final String nombreGrupo; // 🌟 Agregamos esta línea

  // 🌟 Actualizamos el constructor para pedir el nombre obligatoriamente
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

  // 🌟 Instancia de Supabase
  final _supabase = Supabase.instance.client;

  // 🌟 Stream para escuchar mensajes en tiempo real
  late final Stream<List<Map<String, dynamic>>> _mensajesStream;

  @override
  void initState() {
    super.initState();
    // 🌟 Configuramos el Stream apuntando a la tabla y columna reales
    _mensajesStream = _supabase
        .from('mensajes_chat') // Tabla correcta
        .stream(primaryKey: ['id'])
        .eq('sala_id', widget.grupoInicialId) // Columna de enlace real 🚀
        .order('created_at', ascending: true);
  }

  Future<void> _enviarMensaje() async {
    final texto = _messageCtrl.text.trim();
    if (texto.isEmpty) return;

    // 🌟 1. Obtenemos el ID del usuario que tiene la sesión iniciada en la app
    final usuarioActual = _supabase.auth.currentUser;

    // Si por alguna razón no hay sesión iniciada, no enviamos nada para evitar errores
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
      // 2. Insertamos en la base de datos de forma dinámica
      await _supabase.from('mensajes_chat').insert({
        'sala_id': widget.grupoInicialId,
        'texto': texto,
        'remitente_id': usuarioActual
            .id, // 🌟 ¡Aquí se pasa el ID real del usuario conectado!
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nombreGrupo, // 🌟 ¡Y listo! Aquí se pintará el nombre real
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🌟 Área dinámica de mensajes usando StreamBuilder
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _mensajesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE65100)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar mensajes: ${snapshot.error}'),
                  );
                }

                final mensajes = snapshot.data ?? [];

                if (mensajes.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay mensajes aún. ¡Sé el primero en escribir!',
                      style: GoogleFonts.lexend(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final msg = mensajes[index];
                    final esMio = msg['remitente'] == 'Yo';

                    return Align(
                      alignment: esMio
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
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
                          border: esMio
                              ? null
                              : Border.all(color: const Color(0xFFE3BFB1)),
                        ),
                        child: Column(
                          crossAxisAlignment: esMio
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!esMio)
                              Text(
                                msg['remitente'] ?? 'Usuario',
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
                                color: esMio
                                    ? Colors.white
                                    : const Color(0xFF2E2E2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Barra inferior para escribir
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
    );
  }
}
