import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:u_nite_software/widgets/unite_header.dart';
import 'package:u_nite_software/screens/chat/chat_list_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notificaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificaciones();
    _suscribirse();
  }

  Future<void> _loadNotificaciones() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('notificaciones')
          .select()
          .eq('usuario_id', userId)
          .order('creado_en', ascending: false);
      setState(() {
        _notificaciones = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _suscribirse() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _supabase
        .channel('notificaciones_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notificaciones',
          callback: (_) => _loadNotificaciones(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notificaciones',
          callback: (_) => _loadNotificaciones(),
        )
        .subscribe();
  }

  Future<void> _marcarComoLeida(String id) async {
    await _supabase
        .from('notificaciones')
        .update({'leida': true})
        .eq('id', id);
    _loadNotificaciones();
  }

  Future<void> _marcarTodasLeidas() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('notificaciones')
        .update({'leida': true})
        .eq('usuario_id', userId)
        .eq('leida', false);
    _loadNotificaciones();
  }

  Future<void> _eliminarNotificacion(String id) async {
    await _supabase.from('notificaciones').delete().eq('id', id);
    _loadNotificaciones();
  }

  Future<void> _limpiarTodas() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('notificaciones')
        .delete()
        .eq('usuario_id', userId);
    _loadNotificaciones();
  }

  void _onTapNotificacion(Map<String, dynamic> notif) async {
    await _marcarComoLeida(notif['id']);
    final datos = notif['datos'] as Map<String, dynamic>? ?? {};
    final tipo = notif['tipo'] as String? ?? '';

    if (!mounted) return;

    if (tipo == 'mensaje' || tipo == 'contacto') {
      final conversacionId = datos['conversacion_id']?.toString();
      final nombreOtro = datos['nombre_otro']?.toString() ?? 'Usuario';
      final otroUserId = datos['otro_user_id']?.toString() ?? '';
      final anuncioId = datos['anuncio_id']?.toString();
      if (conversacionId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatListScreen(
              conversacionInicial: conversacionId,
              nombreInicial: nombreOtro,
              otroUserIdInicial: otroUserId,
              anuncioIdInicial: anuncioId,
            ),
          ),
        );
      }
    }
  }

  IconData _getIcono(String tipo) {
    switch (tipo) {
      case 'mensaje':
        return Icons.chat_bubble_outline;
      case 'contacto':
        return Icons.store_outlined;
      case 'trueque':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String tipo) {
    switch (tipo) {
      case 'mensaje':
        return const Color(0xFFF36900);
      case 'contacto':
        return const Color(0xFF245000);
      case 'trueque':
        return const Color(0xFF1976D2);
      default:
        return const Color(0xFF5B4137);
    }
  }

  String _formatFecha(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = _notificaciones.where((n) => n['leida'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F9),
      appBar: const UniteHeader(currentIndex: 3),
      body: Column(
        children: [
          // Header de la sección
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notificaciones',
                        style: GoogleFonts.lexend(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A))),
                    if (noLeidas > 0)
                      Text('$noLeidas sin leer',
                          style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: const Color(0xFFF36900),
                              fontWeight: FontWeight.w500)),
                  ],
                ),
                const Spacer(),
                if (_notificaciones.isNotEmpty) ...[
                  TextButton(
                    onPressed: _marcarTodasLeidas,
                    child: Text('Marcar todas leídas',
                        style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: const Color(0xFFF36900),
                            fontWeight: FontWeight.w500)),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Limpiar notificaciones',
                              style: GoogleFonts.lexend(
                                  fontWeight: FontWeight.w700)),
                          content: Text(
                              '¿Eliminar todas las notificaciones?',
                              style: GoogleFonts.lexend()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancelar',
                                  style: GoogleFonts.lexend()),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _limpiarTodas();
                              },
                              child: Text('Eliminar',
                                  style: GoogleFonts.lexend(
                                      color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text('Limpiar todo',
                        style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE3BFB1)),
          // Lista
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFF36900)))
                : _notificaciones.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 64,
                                color: const Color(0xFF5B4137)
                                    .withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('No tienes notificaciones',
                                style: GoogleFonts.lexend(
                                    color: const Color(0xFF5B4137),
                                    fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _notificaciones.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: Color(0xFFE3BFB1)),
                        itemBuilder: (context, i) {
                          final notif = _notificaciones[i];
                          final leida = notif['leida'] == true;
                          final tipo = notif['tipo']?.toString() ?? '';
                          return Dismissible(
                            key: Key(notif['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) =>
                                _eliminarNotificacion(notif['id']),
                            child: InkWell(
                              onTap: () => _onTapNotificacion(notif),
                              child: Container(
                                color: leida
                                    ? Colors.white
                                    : const Color(0xFFFFF3EE),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Ícono
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _getColor(tipo)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getIcono(tipo),
                                        color: _getColor(tipo),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Contenido
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif['titulo'] ?? '',
                                                  style: GoogleFonts.lexend(
                                                    fontSize: 14,
                                                    fontWeight: leida
                                                        ? FontWeight.w500
                                                        : FontWeight.w700,
                                                    color: const Color(
                                                        0xFF1A1A1A),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatFecha(notif[
                                                    'creado_en']),
                                                style: GoogleFonts.lexend(
                                                    fontSize: 11,
                                                    color: const Color(
                                                        0xFF5B4137)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif['mensaje'] ?? '',
                                            style: GoogleFonts.lexend(
                                                fontSize: 13,
                                                color:
                                                    const Color(0xFF5B4137),
                                                height: 1.4),
                                          ),
                                          if (!leida) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF36900),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}