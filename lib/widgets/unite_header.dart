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
import 'premium_plans_page.dart'; // ← Importar la pantalla de planes

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
  bool _esPremium = false;
  int _mensajesPendientes = 0;
  int _notificacionesPendientes = 0;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarMensajesPendientes();
    _cargarNotificacionesPendientes();
    _suscribirseAMensajes();
    _suscribirseANotificaciones();
    _suscribirseAPremium();
  }

  // Escucha en tiempo real el cambio de es_premium en la tabla usuarios
  void _suscribirseAPremium() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _supabase
        .channel('header_premium_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'usuarios',
          callback: (payload) {
            final newRow = payload.newRecord;
            // Verificamos que el update es del usuario actual
            if (newRow['id'] == userId &&
                newRow['es_premium'] == true &&
                mounted) {
              setState(() => _esPremium = true);
            }
          },
        )
        .subscribe();
  }

  Future<void> _cargarUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido, foto_perfil_url, es_premium')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nombreCompleto =
              "${data['primer_nombre'] ?? ''} ${data['primer_apellido'] ?? ''}";
          _fotoPerfilUrl = data['foto_perfil_url'];
          _esPremium = data['es_premium'] == true;
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
      setState(() => _mensajesPendientes = result ?? 0);
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
      setState(() => _notificacionesPendientes = data.length);
    } catch (_) {}
  }

  void _suscribirseAMensajes() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _supabase
        .channel('header_mensajes_$userId')
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
        )
        .subscribe();
  }

  void _suscribirseANotificaciones() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _supabase
        .channel('header_notif_$userId')
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
        .subscribe();
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
          _LogoAnimado(
            isMobile: isMobile,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketPage()),
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
              // Notificaciones con badge
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
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6100),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$_notificacionesPendientes',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Mensajes con badge
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
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6100),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$_mensajesPendientes',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 4),

              // ══════════════════════════════════════
              // BOTÓN PREMIUM — solo si NO es premium
              // ══════════════════════════════════════
              if (!_esPremium)
                _PremiumButton(
                  isMobile: isMobile,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PremiumPlansPage()),
                    );
                  },
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
                  } else if (value == 'premium') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PremiumPlansPage()),
                    );
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
                  PopupMenuItem(
                    value: 'premium',
                    child: Row(
                      children: [
                        Icon(
                          _esPremium
                              ? Icons.swap_horiz_rounded
                              : Icons.diamond_outlined,
                          size: 18,
                          color: const Color(0xFFFCA027),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _esPremium ? 'Cambiar suscripción' : 'Ser Premium',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            color: const Color(0xFFFCA027),
                            fontWeight: FontWeight.w600,
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
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      if (!isMobile && _nombreCompleto != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar desktop con badge premium
                            Stack(
                              clipBehavior: Clip.none,
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
                                if (_esPremium)
                                  const Positioned(
                                    bottom: -3,
                                    right: -3,
                                    child: _PremiumBadge(),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$_nombreCompleto",
                                  style: GoogleFonts.lexend(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                if (_esPremium)
                                  Text(
                                    '✦ Premium',
                                    style: GoogleFonts.lexend(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFCA027),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                      ] else if (isMobile) ...[
                        // Avatar móvil con badge premium
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
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
                            if (_esPremium)
                              const Positioned(
                                bottom: -3,
                                right: -3,
                                child: _PremiumBadge(),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BADGE PREMIUM (sobre el avatar)
// ═══════════════════════════════════════════════════════
class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFC7827), Color(0xFFFFDC18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6100).withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.diamond_rounded,
        size: 10,
        color: Colors.white,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BOTÓN PREMIUM CON ANIMACIÓN
// ═══════════════════════════════════════════════════════
class _PremiumButton extends StatefulWidget {
  final bool isMobile;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnim = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // En móvil mostramos solo el icono de diamante
    if (widget.isMobile) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? [const Color(0xFFFC7827), const Color(0xFFFFDC18)]
                    : _hovered
                        ? [const Color(0xFFFF7800), const Color(0xFFFFAA00)]
                        : [const Color(0xFFFF6100), const Color(0xFFFF9500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6100)
                      .withOpacity(_hovered ? 0.4 : 0.25),
                  blurRadius: _hovered ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.diamond_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Desktop: botón completo con texto
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? [const Color(0xFFFC7827), const Color(0xFFFFDC18)]
                    : _hovered
                        ? [const Color.fromARGB(255, 252, 167, 39), const Color.fromARGB(255, 255, 228, 79)]
                        : [const Color(0xFFFC7827), const Color(0xFFFFDC18)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6100)
                      .withOpacity(_hovered ? 0.45 : 0.25),
                  blurRadius: _hovered ? 16 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: _hovered ? 0.05 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.diamond_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Premium',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// NAV LINKS
// ═══════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════
// LOGO CON ANIMACIÓN HOVER
// ═══════════════════════════════════════════════════════
class _LogoAnimado extends StatefulWidget {
  final bool isMobile;
  final VoidCallback onTap;

  const _LogoAnimado({required this.isMobile, required this.onTap});

  @override
  State<_LogoAnimado> createState() => _LogoAnimadoState();
}

class _LogoAnimadoState extends State<_LogoAnimado>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _rotateAnim = Tween<double>(begin: 0.0, end: -0.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _controller.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Row(
                children: [
                  Transform.rotate(
                    angle: _rotateAnim.value,
                    child: Image.asset(
                      'images/Logo_U-NITE_SoloU.png',
                      height: 36,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        color: Color(0xFFF36900),
                        size: 36,
                      ),
                    ),
                  ),
                  if (!widget.isMobile) ...[
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _hovering
                            ? const Color(0xFFF36900)
                            : const Color(0xFF245000),
                      ),
                      child: const Text('U-NITE'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}