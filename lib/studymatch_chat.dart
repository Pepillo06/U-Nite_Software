import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Asegúrate de importar tu UniteHeader
import '../widgets/unite_header.dart';

class StudymatchChatPage extends StatefulWidget {
  const StudymatchChatPage({super.key});

  @override
  State<StudymatchChatPage> createState() => _StudymatchChatPageState();
}

class _StudymatchChatPageState extends State<StudymatchChatPage> {
  int _selectedTab = 0; // 0: Mis Grupos
  int _selectedChat = 0; // 0: Cálculo II

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF9), // Color de fondo general base
      appBar: const UniteHeader(currentIndex: 4), // Studymatch activo
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── NUEVA FILA SUPERIOR (PESTAÑAS Y ACCIONES) ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFDFBF9),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0EAE6), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                _TopTabItem(
                  label: 'Mis Grupos',
                  isActive: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 8),
                _TopTabItem(
                  label: 'Grupos Públicos',
                  isActive: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                const SizedBox(width: 8),
                _TopTabItem(
                  label: 'Amigos',
                  isActive: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),

                const Spacer(), // Empuja los iconos a la derecha
                // Iconos de agregar/eliminar personas
                IconButton(
                  tooltip: 'Agregar a grupo',
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  color: const Color(0xFF757575),
                  hoverColor: const Color(0xFFFFF3E0),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Eliminar de grupo',
                  icon: const Icon(Icons.person_remove_alt_1_outlined),
                  color: const Color(0xFF757575),
                  hoverColor: const Color(0xFFFFF3E0),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ─── CONTENEDOR PRINCIPAL DE CHATS ───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE3BFB1), width: 1),
                ),
                child: Row(
                  children: [
                    // ─── COLUMNA IZQUIERDA: LISTA DE CHATS ───
                    Container(
                      width: 320,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE3BFB1), width: 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Buscador y Botón
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: TextField(
                                    style: GoogleFonts.lexend(fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar...',
                                      hintStyle: GoogleFonts.lexend(
                                        color: const Color(0xFF9E9E9E),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Color(0xFF9E9E9E),
                                        size: 18,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Crear Grupo',
                                      style: GoogleFonts.lexend(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE65100),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE3BFB1)),

                          // Lista de chats
                          Expanded(
                            child: ListView(
                              children: [
                                _ChatListItem(
                                  icon: Icons.functions,
                                  iconBg: const Color(0xFF2196F3),
                                  title: 'Cálculo II - Sec 3',
                                  subtitle: 'Carlos: ¿Alguien hizo el ej 4?',
                                  time: '10:42 AM',
                                  unreadCount: 3,
                                  isActive: _selectedChat == 0,
                                  onTap: () =>
                                      setState(() => _selectedChat = 0),
                                ),
                                _ChatListItem(
                                  icon: Icons.design_services,
                                  iconBg: const Color(0xFFAED581),
                                  title: 'Design Systems 101',
                                  subtitle: 'Ana compartió un archivo',
                                  time: 'Ayer',
                                  isActive: _selectedChat == 1,
                                  onTap: () =>
                                      setState(() => _selectedChat = 1),
                                ),
                                _ChatListItem(
                                  icon: Icons.code,
                                  iconBg: const Color(0xFFBCAAA4),
                                  title: 'CS 50 Prep',
                                  subtitle: 'Tú: Perfecto, nos vemos.',
                                  time: 'Mar 12',
                                  isActive: _selectedChat == 2,
                                  onTap: () =>
                                      setState(() => _selectedChat = 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── COLUMNA DERECHA: ÁREA DE CHAT ACTIVO ───
                    Expanded(
                      child: Column(
                        children: [
                          // Header del Chat
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE3BFB1),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.functions,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cálculo II - Sec 3',
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF212121),
                                        ),
                                      ),
                                      Text(
                                        '8 miembros • 3 en línea',
                                        style: GoogleFonts.lexend(
                                          fontSize: 12,
                                          color: const Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _MiniAvatarStack(),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.search,
                                  color: Color(0xFF757575),
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.more_vert,
                                  color: Color(0xFF757575),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),

                          // Área de Mensajes
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Hoy, 10:30 AM',
                                      style: GoogleFonts.lexend(
                                        fontSize: 11,
                                        color: const Color(0xFF757575),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'María se ha unido al grupo',
                                    style: GoogleFonts.lexend(
                                      fontSize: 12,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Mensaje de otro usuario
                                _IncomingMessage(
                                  name: 'Carlos',
                                  text:
                                      '¿Alguien pudo resolver el ejercicio 4 de la guía? Me da un resultado súper raro con la integral.',
                                  time: '10:42 AM',
                                ),
                                const SizedBox(height: 20),

                                // Mensaje propio
                                _OutgoingMessage(
                                  text:
                                      'Sí, me dio 4π. Creo que el truco estaba en usar coordenadas polares desde el principio. Te paso foto de mi desarrollo en un rato.',
                                  time: '10:45 AM',
                                ),
                              ],
                            ),
                          ),

                          // Barra de Input
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F7F5),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: const Color(0xFFE3BFB1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.attach_file,
                                      color: Color(0xFF757575),
                                    ),
                                    onPressed: () {},
                                  ),
                                  Expanded(
                                    child: TextField(
                                      style: GoogleFonts.lexend(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Escribe un mensaje...',
                                        hintStyle: GoogleFonts.lexend(
                                          color: const Color(0xFF9E9E9E),
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE65100),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        onPressed: () {},
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES REUTILIZABLES
// ═══════════════════════════════════════════════════════════════════════════

class _TopTabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TopTabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF3E0) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFFE65100) : const Color(0xFF616161),
          ),
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  final int unreadCount;
  final bool isActive;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unreadCount = 0,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEBE5DF) : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: const Color(0xFF212121),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: unreadCount > 0
                              ? const Color(0xFF212121)
                              : const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? const Color(0xFF424242)
                                : const Color(0xFF757575),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE65100),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
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

class _IncomingMessage extends StatelessWidget {
  final String name;
  final String text;
  final String time;

  const _IncomingMessage({
    required this.name,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(
            'https://randomuser.me/api/portraits/men/32.jpg',
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: const Color(0xFFE3BFB1)),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: const Color(0xFF212121),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 80),
      ],
    );
  }
}

class _OutgoingMessage extends StatelessWidget {
  final String text;
  final String time;

  const _OutgoingMessage({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 80),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEFE9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: const Color(0xFFF3D8C9)),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: const Color(0xFF212121),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniAvatarStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 4,
            child: CircleAvatar(
              radius: 10,
              backgroundImage: NetworkImage(
                'https://randomuser.me/api/portraits/men/32.jpg',
              ),
            ),
          ),
          const Positioned(
            left: 18,
            child: CircleAvatar(
              radius: 10,
              backgroundImage: NetworkImage(
                'https://randomuser.me/api/portraits/women/44.jpg',
              ),
            ),
          ),
          Positioned(
            left: 36,
            child: Text(
              '+6',
              style: GoogleFonts.lexend(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF616161),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
