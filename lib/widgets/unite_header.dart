import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../market.dart';
import '../login_page.dart';
import '../profile_page.dart';
import '../home_page.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/notifications_screen.dart';
import '../studymatch.dart';

class UniteHeader extends StatefulWidget implements PreferredSizeWidget {
  final int currentIndex;

  const UniteHeader({
    super.key,
    this.currentIndex = -1,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<UniteHeader> createState() => _UniteHeaderState();
}

class _UniteHeaderState extends State<UniteHeader> {
  final _supabase = Supabase.instance.client;
  String? _nombreCompleto;
  String? _fotoPerfilUrl;
  int _mensajesPendientes = 0;
  int _notificacionesPendientes = 0;
  RealtimeChannel? _canalMensajes;
  RealtimeChannel? _canalNotifs;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarMensajesPendientes();
    _cargarNotificacionesPendientes();
    _suscribirseAMensajes();
    _suscribirseANotificaciones();
  }

  @override
  void dispose() {
    if (_canalMensajes != null) _supabase.removeChannel(_canalMensajes!);
    if (_canalNotifs != null) _supabase.removeChannel(_canalNotifs!);
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido, foto_perfil_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nombreCompleto =
              "${data['primer_nombre'] ?? ''} ${data['primer_apellido'] ?? ''}";
          _fotoPerfilUrl = data['foto_perfil_url'];
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos del usuario en header: $e');
    }
  }

  Future<void> _cargarMensajesPendientes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final result = await _supabase
          .rpc('mensajes_pendientes', params: {'user_id': userId});
      if (mounted) setState(() => _mensajesPendientes = result ?? 0);
    } catch (e) {
      debugPrint('Error mensajes pendientes: $e');
    }
  }

  Future<void> _cargarNotificacionesPendientes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('notificaciones')
          .select('id')
          .eq('usuario_id', userId)
          .eq('leida', false);
      if (mounted) setState(() => _notificacionesPendientes = data.length);
    } catch (_) {}
  }

  void _suscribirseAMensajes() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    // Canal único para mensajes del header
    _canalMensajes = _supabase
        .channel('header_msg_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          callback: (_) => _cargarMensajesPendientes(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'mensajes',
          callback: (_) => _cargarMensajesPendientes(),
        );
    _canalMensajes!.subscribe();
  }

  void _suscribirseANotificaciones() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    // Canal único para notificaciones del header — escucha insert, update y delete
    _canalNotifs = _supabase
        .channel('header_notif_badge_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notificaciones',
          callback: (_) => _cargarNotificacionesPendientes(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notificaciones',
          callback: (_) => _cargarNotificacionesPendientes(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notificaciones',
          callback: (_) => _cargarNotificacionesPendientes(),
        );
    _canalNotifs!.subscribe();
  }

  bool _verificarAutenticacion() {
    if (_supabase.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para realizar esta acción'),
          backgroundColor: Color(0xFFF36900),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketPage()),
            ),
            child: Row(
              children: [
                Image.asset(
                  'images/Logo_U-NITE_SoloU.png',
                  height: 36,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFF36900),
                    size: 36,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Text(
                    'U-NITE',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF245000),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Nav links
          if (!isMobile)
            Row(
              children: [
                _NavLinkActivo(
                  label: 'UniExchange',
                  isActive: widget.currentIndex == 1,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MarketPage()),
                  ),
                ),
                const SizedBox(width: 32),
                _NavLinkActivo(
                  label: 'Studymatch',
                  isActive: widget.currentIndex == 4,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudymatchPage()),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),

          const Spacer(),

          // Íconos y acciones
          Row(
            children: [
              // ─── Notificaciones con badge más grande ──────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: widget.currentIndex == 3
                        ? const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFFF6100),
                                width: 3,
                              ),
                            ),
                          )
                        : null,
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: widget.currentIndex == 3
                            ? const Color(0xFFFF6100)
                            : const Color(0xFF4A4A4A),
                        size: 22,
                      ),
                      onPressed: () {
                        if (_verificarAutenticacion()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()),
                          ).then((_) => _cargarNotificacionesPendientes());
                        }
                      },
                    ),
                  ),
                  if (_notificacionesPendientes > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 18,   // ← más grande
                        height: 18,  // ← más grande
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6100),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _notificacionesPendientes > 9
                                ? '9+'
                                : '$_notificacionesPendientes',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ─── Mensajes con badge más grande ───────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: widget.currentIndex == 2
                        ? const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFFF6100),
                                width: 3,
                              ),
                            ),
                          )
                        : null,
                    child: IconButton(
                      icon: Icon(
                        Icons.forum_outlined,
                        color: widget.currentIndex == 2
                            ? const Color(0xFFFF6100)
                            : const Color(0xFF4A4A4A),
                        size: 22,
                      ),
                      onPressed: () {
                        if (_verificarAutenticacion()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChatListScreen()),
                          ).then((_) => _cargarMensajesPendientes());
                        }
                      },
                    ),
                  ),
                  if (_mensajesPendientes > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 18,   // ← más grande
                        height: 18,  // ← más grande
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6100),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _mensajesPendientes > 9
                                ? '9+'
                                : '$_mensajesPendientes',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 8),

              // Avatar + nombre con dropdown
              PopupMenuButton<String>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                color: Colors.white,
                elevation: 8,
                onSelected: (value) async {
                  if (value == 'perfil') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ).then((_) => _cargarUsuario());
                  } else if (value == 'cerrar_sesion') {
                    await _supabase.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'perfil',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 18, color: Color(0xFF4A4A4A)),
                        const SizedBox(width: 10),
                        Text(
                          'Ver perfil',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'cerrar_sesion',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_outlined,
                            size: 18, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Text(
                          'Cerrar sesión',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Row(
                  children: [
                    if (!isMobile && _nombreCompleto != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 21,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _fotoPerfilUrl != null &&
                                    _fotoPerfilUrl!.isNotEmpty
                                ? NetworkImage(_fotoPerfilUrl!)
                                : null,
                            child: _fotoPerfilUrl == null ||
                                    _fotoPerfilUrl!.isEmpty
                                ? const Icon(Icons.person,
                                    size: 18, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$_nombreCompleto",
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                    ] else if (isMobile) ...[
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _fotoPerfilUrl != null &&
                                _fotoPerfilUrl!.isNotEmpty
                            ? NetworkImage(_fotoPerfilUrl!)
                            : null,
                        child: _fotoPerfilUrl == null ||
                                _fotoPerfilUrl!.isEmpty
                            ? const Icon(Icons.person,
                                size: 18, color: Colors.grey)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: GoogleFonts.lexend(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _hovered
                ? const Color(0xFFF36900)
                : const Color(0xFF4A4A4A),
          ),
        ),
      ),
    );
  }
}

class _NavLinkActivo extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLinkActivo({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavLinkActivo> createState() => _NavLinkActivoState();
}

class _NavLinkActivoState extends State<_NavLinkActivo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight:
                    widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isActive || _hovered
                    ? const Color(0xFFF36900)
                    : const Color(0xFF4A4A4A),
              ),
            ),
            if (widget.isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 3,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}