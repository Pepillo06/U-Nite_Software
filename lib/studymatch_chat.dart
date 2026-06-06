import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart'; // IMPORTANTE PARA ARCHIVOS
// Asegúrate de importar tu UniteHeader correcto según tu estructura
import '../widgets/unite_header.dart';

class StudymatchChatPage extends StatefulWidget {
  const StudymatchChatPage({super.key});

  @override
  State<StudymatchChatPage> createState() => _StudymatchChatPageState();
}

class _StudymatchChatPageState extends State<StudymatchChatPage> {
  int _selectedTab = 0; // 0: Mis Grupos
  int _selectedChat = 0; // 0: Cálculo II, 1: Design Systems, 2: CS 50

  // SIMULACIÓN DE DATOS DE MENSAJES (Para probar el estado vacío)
  final Map<int, List<Map<String, dynamic>>> _chatMessages = {
    0: [
      {'type': 'system', 'text': 'Hoy, 10:30 AM'},
      {'type': 'system', 'text': 'María se ha unido al grupo'},
      {
        'type': 'incoming',
        'name': 'Carlos',
        'text':
            '¿Alguien pudo resolver el ejercicio 4 de la guía? Me da un resultado súper raro con la integral.',
        'time': '10:42 AM',
      },
      {
        'type': 'outgoing',
        'text':
            'Sí, me dio 4π. Creo que el truco estaba en usar coordenadas polares desde el principio. Te paso foto de mi desarrollo en un rato.',
        'time': '10:45 AM',
      },
    ],
    1: [], // CHAT VACÍO PARA MOSTRAR EL MENSAJE DE "AÚN NO HAY MENSAJES"
    2: [
      {'type': 'system', 'text': '12 de Marzo'},
      {
        'type': 'outgoing',
        'text': 'Perfecto, nos vemos a las 3 en la biblioteca.',
        'time': '02:15 PM',
      },
    ],
  };

  // LÓGICA 1: ABRIR EXPLORADOR DE ARCHIVOS con manejo seguro
  Future<void> _abrirExploradorArchivos() async {
    // Permite al usuario seleccionar un archivo; si cancela, simplemente retorna sin error
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
    );

    // Si el usuario canceló la selección, result será null
    if (result == null || result.files.isEmpty) {
      return; // No hacer nada y evitar excepciones
    }

    // Obtenemos el nombre del primer archivo seleccionado
    String fileName = result.files.first.name;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2E5900),
        content: Text('Archivo seleccionado: $fileName preparado para enviar.'),
      ),
    );
  }

  // LÓGICA 2: MOSTRAR INFORMACIÓN DEL GRUPO (REPORTAR/BLOQUEAR)
  void _mostrarInfoGrupo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Información del Grupo',
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cálculo II - Sec 3',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    color: const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Materia: Cálculo II\nSección: 3\nDescripción: Grupo de estudio para apoyarnos con las guías del profesor Silva.',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const Divider(height: 30),
                Text(
                  'Miembros (8)',
                  style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Expanded(
                  // Lista de miembros simulada
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      List<String> nombres = [
                        'Tú (Admin)',
                        'Carlos',
                        'María',
                        'Pedro',
                      ];
                      bool esElUsuarioActual = index == 0;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          backgroundImage: NetworkImage(
                            'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'men' : 'women'}/${30 + index}.jpg',
                          ),
                        ),
                        title: Text(
                          nombres[index],
                          style: GoogleFonts.lexend(fontSize: 14),
                        ),
                        trailing: esElUsuarioActual
                            ? null
                            : PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                color: Colors.white,
                                onSelected: (value) {
                                  if (value == 'reportar') {
                                    _accionMiembro('Reportado', nombres[index]);
                                  }
                                  if (value == 'bloquear') {
                                    _accionMiembro('Bloqueado', nombres[index]);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'perfil',
                                    child: Text('Ver perfil'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reportar',
                                    child: Text('Reportar usuario'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'bloquear',
                                    child: Text(
                                      'Bloquear del grupo',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: GoogleFonts.lexend(color: const Color(0xFF757575)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _accionMiembro(String accion, String nombre) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Usuario $nombre ha sido $accion.'),
        backgroundColor: accion == 'Bloqueado'
            ? Colors.red
            : const Color(0xFFE65100),
      ),
    );
  }

  // LÓGICA 3: MANTENER PRESIONADO UN MENSAJE
  void _mostrarOpcionesMensaje(String textoMensaje, bool esMio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: Text(
                'Copiar texto',
                style: GoogleFonts.lexend(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Texto copiado al portapapeles'),
                  ),
                );
              },
            ),
            if (!esMio) // Solo se reportan mensajes de otros
              ListTile(
                leading: const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.red,
                ),
                title: Text(
                  'Reportar mensaje',
                  style: GoogleFonts.lexend(fontSize: 14, color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensaje reportado a los administradores'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> mensajesActuales =
        _chatMessages[_selectedChat] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF9),
      appBar: const UniteHeader(currentIndex: 4),
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

                const Spacer(),

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
                                  subtitle: 'Grupo creado. ¡Rompe el hielo!',
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
                                    color: _selectedChat == 0
                                        ? const Color(0xFF2196F3)
                                        : _selectedChat == 1
                                        ? const Color(0xFFAED581)
                                        : const Color(0xFFBCAAA4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _selectedChat == 0
                                        ? Icons.functions
                                        : _selectedChat == 1
                                        ? Icons.design_services
                                        : Icons.code,
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
                                        _selectedChat == 0
                                            ? 'Cálculo II - Sec 3'
                                            : _selectedChat == 1
                                            ? 'Design Systems 101'
                                            : 'CS 50 Prep',
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
                                const SizedBox(width: 5),

                                // ─── MENU DE OPCIONES DE GRUPO (3 PUNTITOS) ───
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Color(0xFF757575),
                                    size: 22,
                                  ),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (String result) {
                                    if (result == 'info') {
                                      _mostrarInfoGrupo();
                                    } else if (result == 'archivos') {
                                      // TODO: Navegar a vista de archivos
                                    } else if (result == 'salir') {
                                      // TODO: Lógica para abandonar
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'info',
                                          child: Text('Información del grupo'),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'archivos',
                                          child: Text('Archivos y enlaces'),
                                        ),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem<String>(
                                          value: 'salir',
                                          child: Text(
                                            'Abandonar grupo',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ),

                          // ─── ÁREA DE MENSAJES (Manejo de estado vacío) ───
                          Expanded(
                            child: mensajesActuales.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.chat_bubble_outline,
                                            size: 50,
                                            color: Color(0xFFBDBDBD),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aún no hay mensajes en este grupo.',
                                          style: GoogleFonts.lexend(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF616161),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '¡Rompe el hielo y di hola!',
                                          style: GoogleFonts.lexend(
                                            fontSize: 13,
                                            color: const Color(0xFF9E9E9E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(24),
                                    itemCount: mensajesActuales.length,
                                    itemBuilder: (context, index) {
                                      var msj = mensajesActuales[index];

                                      if (msj['type'] == 'system') {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                msj['text'],
                                                style: GoogleFonts.lexend(
                                                  fontSize: 11,
                                                  color: const Color(
                                                    0xFF757575,
                                                  ),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else if (msj['type'] == 'incoming') {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 20,
                                          ),
                                          child: _IncomingMessage(
                                            name: msj['name'],
                                            text: msj['text'],
                                            time: msj['time'],
                                            onLongPress: () =>
                                                _mostrarOpcionesMensaje(
                                                  msj['text'],
                                                  false,
                                                ),
                                          ),
                                        );
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 20,
                                          ),
                                          child: _OutgoingMessage(
                                            text: msj['text'],
                                            time: msj['time'],
                                            onLongPress: () =>
                                                _mostrarOpcionesMensaje(
                                                  msj['text'],
                                                  true,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                          ),

                          // ─── BARRA DE INPUT ───
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
                                  // ─── ICONO PARA ABRIR ARCHIVOS ───
                                  IconButton(
                                    icon: const Icon(
                                      Icons.attach_file,
                                      color: Color(0xFF757575),
                                    ),
                                    onPressed: _abrirExploradorArchivos,
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
  final VoidCallback onLongPress; // <-- AÑADIDO

  const _IncomingMessage({
    required this.name,
    required this.text,
    required this.time,
    required this.onLongPress,
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
              GestureDetector(
                // <-- AÑADIDO GESTURE DETECTOR
                onLongPress: onLongPress,
                child: Container(
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
  final VoidCallback onLongPress; // <-- AÑADIDO

  const _OutgoingMessage({
    required this.text,
    required this.time,
    required this.onLongPress,
  });

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
              GestureDetector(
                // <-- AÑADIDO GESTURE DETECTOR
                onLongPress: onLongPress,
                child: Container(
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
