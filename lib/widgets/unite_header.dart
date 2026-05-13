import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../market.dart';
import '../screens/chat/chat_list_screen.dart';

class UniteHeader extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  const UniteHeader({super.key, this.currentIndex = -1});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3BFB1))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  height: 40,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFF36900),
                    size: 40,
                  ),
                ),
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
            ),
          ),

          const Spacer(),

          // Nav links
          Row(
            children: [
              _NavLink(
                label: 'UniExchange',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarketPage()),
                ),
              ),
              const SizedBox(width: 32),
 //             _NavLink(label: 'StudyMatch', onTap: () {}),
            ],
          ),

          const Spacer(),

          // Íconos derecha
          Row(
            children: [
              // Chat con badge
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: currentIndex == 2
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
                              color: currentIndex == 2
                                  ? const Color(0xFFFF6100)
                                  : const Color(0xFF4A4A4A),
                              size: 24,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChatListScreen()),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6, right: 6,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6100),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('3',
                                  style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Notificaciones
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF4A4A4A), size: 24),
                onPressed: () {},
              ),
              const SizedBox(width: 4),

              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE3BFB1),
                child: const Icon(Icons.person,
                    color: Color(0xFF5B4137), size: 20),
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