import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/unite_header.dart';
import 'crear_grupos.dart'; 


class StudymatchPage extends StatefulWidget {
  const StudymatchPage({super.key});

  @override
  State<StudymatchPage> createState() => _StudymatchPageState();
}

class _StudymatchPageState extends State<StudymatchPage> {
  int _selectedTab = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filtroMateria = 'Matemáticas II';
  String? _filtroSeccion = 'Sección 2';

  final List<_GrupoData> _grupos = const [
    _GrupoData(
      nombre: 'Mate II sección 2',
      descripcion: 'Matemáticas 2 con Daza, sección 2 los martes y jueves',
      miembros: 13, max: 29,
      materia: 'Matemáticas II', seccion: 'Sec 2',
      icono: Icons.calculate_outlined,
      iconBg: Color(0xFFFFF3E0), iconColor: Color(0xFFE65100),
    ),
    _GrupoData(
      nombre: 'Estructura de Datos con panas',
      descripcion: 'Materia con Fernando los lunes y ...',
      miembros: 2, max: 5,
      materia: 'Estructura de Datos', seccion: 'Sec 1',
      icono: Icons.computer_outlined,
      iconBg: Color(0xFFE3F2FD), iconColor: Color(0xFF1565C0),
    ),
    _GrupoData(
      nombre: 'Química General 1',
      descripcion: 'Por qué hay química en Ing de Sistemas ??',
      miembros: 5, max: 8,
      materia: 'Química General I', seccion: 'Sec 3',
      icono: Icons.science_outlined,
      iconBg: Color(0xFFE8F5E9), iconColor: Color(0xFF2E7D32),
    ),
    _GrupoData(
      nombre: 'Física II con Daza',
      descripcion: 'Sección 1 - martes y jueves 10:30 - 12:00',
      miembros: 3, max: 4,
      materia: 'Física II', seccion: 'Sec 1',
      icono: Icons.bolt_outlined,
      iconBg: Color(0xFFF3E5F5), iconColor: Color(0xFF6A1B9A),
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_GrupoData> get _gruposFiltrados => _grupos.where((g) {
        final matchSearch = _searchQuery.isEmpty ||
            g.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchMateria = _filtroMateria == null ||
            g.materia.contains(_filtroMateria!.split(' ')[0]);
        return matchSearch && matchMateria;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      appBar: const UniteHeader(currentIndex: 4),
      body: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isMobile = w < 600;
        final isTablet = w >= 600 && w < 1024;
        final isDesktop = w >= 1024;

        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 32,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 32,
                  0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: _HeroBanner(isMobile: isMobile),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : isTablet ? 24 : 48,
                  vertical: 24,
                ),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 200,
                            child: _Sidebar(
                              selected: _selectedTab,
                              onSelect: (i) => setState(() => _selectedTab = i),
                              horizontal: false,
                            ),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: _buildContent(
                                  isMobile: false, isTablet: false),
                            ),      
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Sidebar(
                            selected: _selectedTab,
                            onSelect: (i) => setState(() => _selectedTab = i),
                            horizontal: true,
                            compact: isMobile,
                          ),
                          const SizedBox(height: 20),
                          _buildContent(
                              isMobile: isMobile, isTablet: isTablet),
                        ],
                      ),
              ),
              const _Footer(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContent({required bool isMobile, required bool isTablet}) {
    final gridCols = isMobile ? 1 : isTablet ? 2 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── BÚSQUEDA AL CENTRO Y BOTÓN AL EXTREMO RECTO ───
        isMobile
            ? Column(
                children: [
                  _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v)),
                  const SizedBox(height: 10),
                  SizedBox(
                      width: double.infinity,
                      child: _CreateButton(onTap: _showCreateDialog)),
                ],
              )
            : Row(
                children: [
                  const Spacer(), // 👈 PRIMER SPACER: Empuja el buscador desde la izquierda
                  
                  // Tu barra de búsqueda con el ancho fijo que definiste
                  SizedBox(
                    width: 600,
                    child: _SearchBar(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v)),
                  ),
                  
                  const Spacer(), // 👈 SEGUNDO SPACER: Garantiza el mismo espacio exacto a la derecha
                  
                  // El botón se mantiene pegado al extremo derecho del contenedor
                  _CreateButton(onTap: _showCreateDialog),
                ],
              ),
        const SizedBox(height: 24), // Un poco más de espacio de separación con los filtros
        
        // Filtros
        _FiltersRow(
          filtroMateria: _filtroMateria,
          filtroSeccion: _filtroSeccion,
          onClearMateria: () => setState(() => _filtroMateria = null),
          onClearSeccion: () => setState(() => _filtroSeccion = null),
          wrap: isMobile,
        ),
        const SizedBox(height: 20),
        // Grid
        _GruposGrid(
            grupos: _gruposFiltrados,
            columns: gridCols,
            onCrear: _showCreateDialog),
      ],
    );
  }

  void _showCreateDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearGrupoPage()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO BANNER
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final bool isMobile;
  const _HeroBanner({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isMobile ? 200 : 260,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(
          'assets/estudiantess.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 255, 102, 0), Color.fromARGB(255, 255, 125, 82)]),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                const Color.fromARGB(172, 205, 97, 39).withOpacity(0.92),
                const Color(0xFF3E2723).withOpacity(0.65),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 48, vertical: 28),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isMobile
                      ? 'Encuentra tu perfecto\ngrupo de estudio'
                      : 'Encuentra tu perfecto grupo\nde estudio',
                  style: GoogleFonts.lexend(
                    fontSize: isMobile ? 22 : 35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: isMobile ? double.infinity : 340,
                  child: Text(
                    'Conéctate con compañeros de tu misma sección y materia y aprueben juntos.',
                    style: GoogleFonts.lexend(
                      fontSize: isMobile ? 13 : 17,
                      color: Colors.white.withOpacity(0.88),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR (MODIFICADO)
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR (CON ANIMACIÓN FLUIDA)
// ═══════════════════════════════════════════════════════════════════════════

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final bool horizontal;
  final bool compact;

  const _Sidebar({
    required this.selected,
    required this.onSelect,
    this.horizontal = false,
    this.compact = false,
  });

  static const _items = [
    _SI(icon: Icons.grid_view_rounded, label: 'Grupos', isHeader: true),
    _SI(icon: null, label: 'Mis Grupos', isHeader: false),
    _SI(icon: null, label: 'Grupos Públicos', isHeader: false),
    _SI(icon: Icons.people_alt_outlined, label: 'Amigos', isHeader: true),
  ];

  @override
  Widget build(BuildContext context) {
    final bool showSubItems = (selected == 0 || selected == 1 || selected == 2);

    // Separamos los widgets en componentes para poder animar los subgrupos juntos
    Widget? gruposTile;
    final List<Widget> subTiles = [];
    Widget? amigosTile;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final isSubItem = !item.isHeader;

      final bool isActive = (i == 0) 
          ? (selected == 0 || selected == 1 || selected == 2) 
          : (selected == i);

      final tile = GestureDetector(
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 160,
          padding: horizontal
              ? EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14, vertical: compact ? 7 : 9)
              : EdgeInsets.symmetric(
                  horizontal: isSubItem ? 12 : 10, vertical: 9),
          decoration: BoxDecoration(
            color: (isActive && i != 0 && i != 3) ? const Color(0xFFEFE0D0) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: (isActive && (i == 0 || i == 3)) 
                ? Border.all(
                    color: const Color(0xFFE65100),
                    width: 1.0,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSubItem && !horizontal) ...[
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE65100)
                        : const Color(0xFFD0C4BB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (item.icon != null) ...[
                Icon(item.icon,
                    size: compact ? 15 : 17,
                    color: isActive
                        ? const Color(0xFFE65100)
                        : const Color(0xFF757575)),
                const SizedBox(width: 6),
              ],
              Text(
                item.label,
                style: GoogleFonts.lexend(
                  fontSize: compact ? 13 : 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFFE65100)
                      : const Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      );

      // Preparamos el diseño del elemento con su respectivo espaciado
      final tileWithPadding = Padding(
        padding: horizontal 
            ? const EdgeInsets.only(right: 6) 
            : const EdgeInsets.only(bottom: 2),
        child: tile,
      );

      // Clasificamos cada botón según su índice
      if (i == 0) gruposTile = tileWithPadding;
      if (i == 1 || i == 2) subTiles.add(tileWithPadding);
      if (i == 3) amigosTile = tileWithPadding;
    }

    // --- CONSTRUCCIÓN DEL MENÚ CON ANIMACIÓN ---
    final List<Widget> tiles = [];
    
    if (gruposTile != null) tiles.add(gruposTile);

    // Widget mágico que anima el tamaño fluidamente
    tiles.add(
      AnimatedSize(
        duration: const Duration(milliseconds: 300), // Duración ideal para interfaces
        curve: Curves.fastOutSlowIn,                // Una curva súper fluida y moderna
        child: ClipRect(                            // Evita que los subgrupos se desborden mientras se encogen
          child: showSubItems
              ? (horizontal 
                  ? Row(mainAxisSize: MainAxisSize.min, children: subTiles)
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: subTiles))
              : (horizontal 
                  ? const SizedBox(width: 0) 
                  : const SizedBox(height: 0)), // Se encoge a tamaño cero
        ),
      ),
    );

    if (amigosTile != null) tiles.add(amigosTile);

    // Retorno estructural final
    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: tiles),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        const Divider(
          color: Color(0xFFE3BFB1),
          thickness: 1.2,
          height: 24,
        ),
        ...tiles,
        const Divider(
          color: Color(0xFFE3BFB1),
          thickness: 1.2,
          height: 24,
        ),
      ],
    );
  }
}

class _SI {
  final IconData? icon;
  final String label;
  final bool isHeader;
  const _SI({required this.icon, required this.label, required this.isHeader});
}

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═══════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3BFB1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 1))
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style:
            GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF212121)),
        decoration: InputDecoration(
          hintText: 'Buscar grupos',
          hintStyle: GoogleFonts.lexend(
              color: const Color(0xFFAFA49C), fontSize: 14),
          prefixIcon: const Icon(Icons.search,
              color: Color(0xFFAFA49C), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44, // 👈 LE PASAMOS LOS MISMOS 44 PIXELS DE ALTO QUE TIENE TU BUSCADOR
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: Text('Crear Grupo',
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          // Cambiamos a solo horizontal para que Flutter autocentre el texto verticalmente en los 44px
          padding: const EdgeInsets.symmetric(horizontal: 20), 
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════

class _FiltersRow extends StatelessWidget {
  final String? filtroMateria;
  final String? filtroSeccion;
  final VoidCallback onClearMateria;
  final VoidCallback onClearSeccion;
  final bool wrap;

  const _FiltersRow({
    required this.filtroMateria,
    required this.filtroSeccion,
    required this.onClearMateria,
    required this.onClearSeccion,
    required this.wrap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _FilterBtn(label: 'Filtrar materias', icon: Icons.tune_rounded),
      _FilterBtn(label: 'Sección', icon: Icons.school_outlined),
      if (filtroMateria != null)
        _ActiveChip(label: filtroMateria!, onRemove: onClearMateria),
      if (filtroSeccion != null)
        _ActiveChip(label: filtroSeccion!, onRemove: onClearSeccion),
    ];

    if (wrap) {
      return Wrap(spacing: 8, runSpacing: 8, children: children);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children
            .map((c) =>
                Padding(padding: const EdgeInsets.only(right: 8), child: c))
            .toList(),
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FilterBtn({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3BFB1)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: const Color(0xFF757575)),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.lexend(
                fontSize: 13, color: const Color(0xFF424242))),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down_rounded,
            size: 15, color: Color(0xFF757575)),
      ]),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: GoogleFonts.lexend(
                fontSize: 12,
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded,
              size: 13, color: Color(0xFF2E7D32)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID
// ═══════════════════════════════════════════════════════════════════════════

class _GruposGrid extends StatelessWidget {
  final List<_GrupoData> grupos;
  final int columns;
  final VoidCallback onCrear;

  const _GruposGrid(
      {required this.grupos,
      required this.columns,
      required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final total = grupos.length + 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: total,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: columns == 1 ? 1.7 : 0.72,
      ),
      itemBuilder: (_, i) {
        if (i == grupos.length) return _CrearCard(onTap: onCrear);
        return _GrupoCard(grupo: grupos[i]);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO
// ═══════════════════════════════════════════════════════════════════════════

class _GrupoData {
  final String nombre;
  final String descripcion;
  final int miembros;
  final int max;
  final String materia;
  final String seccion;
  final IconData icono;
  final Color iconBg;
  final Color iconColor;

  const _GrupoData({
    required this.nombre,
    required this.descripcion,
    required this.miembros,
    required this.max,
    required this.materia,
    required this.seccion,
    required this.icono,
    required this.iconBg,
    required this.iconColor,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA GRUPO
// ═══════════════════════════════════════════════════════════════════════════

class _GrupoCard extends StatelessWidget {
  final _GrupoData grupo;
  const _GrupoCard({required this.grupo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: grupo.iconBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(grupo.icono, color: grupo.iconColor, size: 22),
              ),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _MiniTag(
                    label: grupo.materia,
                    bg: const Color(0xFFE8F5E9),
                    fg: const Color(0xFF2E7D32)),
                const SizedBox(height: 4),
                _MiniTag(
                    label: grupo.seccion,
                    bg: const Color(0xFFF5F5F5),
                    fg: const Color(0xFF757575)),
              ]),
            ]),
            const SizedBox(height: 10),
            Text(grupo.nombre,
                style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Expanded(
              child: Text(grupo.descripcion,
                  style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: const Color(0xFF8A8A8A),
                      height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
            Row(children: [
              _AvatarStack(count: grupo.miembros.clamp(1, 4)),
              const SizedBox(width: 8),
              Flexible(
                child: Text('${grupo.miembros} / ${grupo.max} miembros',
                    style: GoogleFonts.lexend(
                        fontSize: 11, color: const Color(0xFF9E9E9E)),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 5, runSpacing: 5, children: [
              _MiniTag(
                  label: grupo.seccion,
                  bg: const Color(0xFFF5F5F5),
                  fg: const Color(0xFF757575)),
              _MiniTag(
                  label: grupo.materia,
                  bg: const Color(0xFFF5F5F5),
                  fg: const Color(0xFF757575)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5900),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text('Unirse',
                    style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA CREAR
// ═══════════════════════════════════════════════════════════════════════════

class _CrearCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CrearCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFF36900).withOpacity(0.35), width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded,
                color: Color(0xFF9E9E9E), size: 24),
          ),
          const SizedBox(height: 12),
          Text('Crear un grupo',
              style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121))),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '¿No puedes encontrar un grupo de tu clase? Crea uno e invita a tus amigos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: const Color(0xFFAFA49C),
                  height: 1.45),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════

class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  static const _colors = [
    Color(0xFFB0BEC5), Color(0xFF90CAF9),
    Color(0xFFA5D6A7), Color(0xFFFFCC80),
  ];

  @override
  Widget build(BuildContext context) {
    final n = count.clamp(1, 4);
    return SizedBox(
      width: n * 17.0 + 8,
      height: 26,
      child: Stack(
        children: List.generate(n, (i) => Positioned(
          left: i * 16.0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _colors[i % _colors.length],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        )),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _MiniTag({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: GoogleFonts.lexend(
              fontSize: 11, color: fg, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIÁLOGO CREAR GRUPO
// ═══════════════════════════════════════════════════════════════════════════

class _CrearGrupoDialog extends StatefulWidget {
  const _CrearGrupoDialog();

  @override
  State<_CrearGrupoDialog> createState() => _CrearGrupoDialogState();
}

class _CrearGrupoDialogState extends State<_CrearGrupoDialog> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lexend(fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0D8D2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0D8D2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFE65100), width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('Crear nuevo grupo',
                      style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A)))),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ]),
            const SizedBox(height: 20),
            TextField(
                controller: _nombreCtrl,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration:
                    _dec('Nombre del grupo', icon: Icons.group_outlined)),
            const SizedBox(height: 14),
            TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: _dec('Descripción')),
            const SizedBox(height: 14),
            TextField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.lexend(fontSize: 14),
                decoration: _dec('Máximo de miembros',
                    icon: Icons.people_outline)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0D8D2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text('Cancelar',
                      style: GoogleFonts.lexend(
                          color: const Color(0xFF616161))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text('Crear grupo',
                      style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEDE8E3)))),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 48, vertical: 28),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _brand(),
              const SizedBox(height: 16),
              _links(wrap: true),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: _brand()),
              _links(wrap: false),
            ]),
    );
  }

  Widget _brand() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('U-NITE',
              style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF245000))),
          const SizedBox(height: 2),
          Text('© 2024 U-NITE Campus Marketplace. All rights reserved.',
              style: GoogleFonts.lexend(
                  fontSize: 11, color: const Color(0xFF9E9E9E))),
        ],
      );

  Widget _links({required bool wrap}) {
    const labels = [
      'Privacy Policy', 'Terms of Service', 'Campus Safety', 'Contact Support'
    ];
    final widgets = labels
        .map((l) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(l,
                  style: GoogleFonts.lexend(
                      fontSize: 13, color: const Color(0xFF616161))),
            ))
        .toList();
    return wrap
        ? Wrap(children: widgets)
        : Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }
}