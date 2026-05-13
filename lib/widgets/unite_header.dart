import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../market.dart';
import '../login_page.dart';
import '../profile_page.dart';
import '../screens/chat/chat_list_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('usuarios')
          .select('primer_nombre, primer_apellido')
          .eq('id', user.id)
          .single();
      setState(() {
        _nombreCompleto =
            '${data['primer_nombre']} ${data['primer_apellido']}'.trim();
      });
    } catch (_) {}
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
                // _NavLinkActivo(label: 'StudyMatch', isActive: false, onTap: () {}),
              ],
            ),

          const Spacer(),

          // Íconos y acciones
          Row(
            children: [
              // Notificaciones
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF4A4A4A), size: 22),
                onPressed: () {},
              ),

              // Mensajes
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
                          );
                        }
                      },
                    ),
                  ),
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
                        child: Text('3',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  ),
                ],
              ),

              // Carrito
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Color(0xFF4A4A4A), size: 22),
                onPressed: () {},
              ),

              const SizedBox(width: 8),

              // Avatar + nombre
              GestureDetector(
                onTap: () {
                  if (_verificarAutenticacion()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ).then((_) => _cargarUsuario());
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE3BFB1),
                      child: const Icon(Icons.person,
                          color: Color(0xFF5B4137), size: 20),
                    ),
                    if (!isMobile && _nombreCompleto != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _nombreCompleto!,
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
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