import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/unite_header.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _chats = const [
    {'nombre': 'Elena Martínez', 'preview': '¿Sigue disponible la calculadora?', 'hora': '14:20', 'online': true, 'unread': 0},
    {'nombre': 'Javier Ruiz', 'preview': '¡Perfecto, nos vemos en la biblio!', 'hora': 'Ayer', 'online': false, 'unread': 0},
    {'nombre': 'Sofía Castro', 'preview': 'Gracias por el libro de química.', 'hora': 'Lunes', 'online': false, 'unread': 3},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F9),
      appBar: const UniteHeader(currentIndex: 2),
      body: isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSidebarHeader(),
        _buildSearchBar(),
        Expanded(
          child: _buildChatList(onTap: (i) {
            setState(() => _selectedIndex = i);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(nombreOtro: _chats[i]['nombre']),
            ));
          }),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE3BFB1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebarHeader(),
              _buildSearchBar(),
              Expanded(
                child: _buildChatList(
                  onTap: (i) => setState(() => _selectedIndex = i),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ChatScreen(
            nombreOtro: _chats[_selectedIndex]['nombre'],
            showAppBar: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        'Mensajes',
        style: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3BFB1)),
        ),
        child: TextField(
          style: GoogleFonts.lexend(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar chats...',
            hintStyle: GoogleFonts.lexend(
              color: const Color(0xFF5B4137),
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search,
                color: Color(0xFF5B4137), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList({required void Function(int) onTap}) {
    return ListView.builder(
      itemCount: _chats.length,
      itemBuilder: (context, i) {
        final chat = _chats[i];
        return _ChatTile(
          nombre: chat['nombre'],
          preview: chat['preview'],
          hora: chat['hora'],
          isActive: i == _selectedIndex,
          isOnline: chat['online'],
          unreadCount: chat['unread'],
          onTap: () => onTap(i),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String nombre, preview, hora;
  final bool isActive, isOnline;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatTile({
    required this.nombre,
    required this.preview,
    required this.hora,
    required this.isActive,
    required this.isOnline,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isActive ? const Color(0xFFFFDBCE) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF36900),
                  child: Text(
                    inicial,
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 1, right: 1,
                    child: Container(
                      width: 11, height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF306B18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        hora,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: const Color(0xFF5B4137),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF306B18),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$unreadCount',
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: const Color(0xFF5B4137),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}