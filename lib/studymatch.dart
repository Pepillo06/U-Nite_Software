import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

import '../widgets/unite_header.dart';
import 'crear_grupos.dart';
import 'studymatch_chat.dart'; // <-- IMPORTACIÓN DE LA PANTALLA DE CHAT AÑADIDA

class StudymatchPage extends StatefulWidget {
  const StudymatchPage({super.key});

  @override
  State<StudymatchPage> createState() => _StudymatchPageState();
}

class _StudymatchPageState extends State<StudymatchPage> {
  int _selectedTab = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filtroMateria;
  String? _filtroSeccion;

  String?
  _filtroPrivacidad; // null = todos, 'publico' = públicos, 'privado' = privados

  List<_GrupoData> _grupos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('grupos_estudio')
          .select(
            'id, nombre, descripcion, materia, seccion, max_miembros, es_privado, foto_url, creado_por',
          );

      final grupos = (response as List).map((row) {
        return _GrupoData.fromMap(row);
      }).toList();

      if (mounted) {
        setState(() {
          _grupos = grupos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error al cargar grupos: $e'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_GrupoData> get _gruposFiltrados {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return _grupos.where((g) {
      // Tab 1 = Mis Grupos: solo los creados por el usuario logueado
      // Tab 2 = Grupos Publicos: los que NO creo el usuario logueado
      if (_selectedTab == 1 && g.creadoPor != userId) return false;
      if (_selectedTab == 2 && g.creadoPor == userId) return false;

      final matchSearch =
          _searchQuery.isEmpty ||
          g.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchMateria =
          _filtroMateria == null ||
          g.materia.toLowerCase().contains(_filtroMateria!.toLowerCase());
      final matchSeccion =
          _filtroSeccion == null ||
          'Sec ${g.seccion}'.toLowerCase().contains(
            _filtroSeccion!.toLowerCase(),
          ) ||
          g.seccion.toString() == _filtroSeccion;
      final matchPrivacidad =
          _filtroPrivacidad == null ||
          (_filtroPrivacidad == 'privado' ? g.esPrivado : !g.esPrivado);

      return matchSearch && matchMateria && matchSeccion && matchPrivacidad;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      appBar: const UniteHeader(currentIndex: 4),
      body: LayoutBuilder(
        builder: (context, constraints) {
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
                    horizontal: isMobile
                        ? 16
                        : isTablet
                        ? 24
                        : 48,
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
                                onSelect: (i) =>
                                    setState(() => _selectedTab = i),
                                horizontal: false,
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: _buildContent(
                                  isMobile: false,
                                  isTablet: false,
                                ),
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
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                          ],
                        ),
                ),
                const _Footer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent({required bool isMobile, required bool isTablet}) {
    final gridCols = isMobile
        ? 1
        : isTablet
        ? 2
        : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── BÚSQUEDA AL CENTRO Y BOTÓN AL EXTREMO RECTO ───
        isMobile
            ? Column(
                children: [
                  _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: _CreateButton(onTap: _showCreateDialog),
                  ),
                ],
              )
            : Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: 600,
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const Spacer(),
                  _CreateButton(onTap: _showCreateDialog),
                ],
              ),
        const SizedBox(height: 24),

        // Filtros
        _FiltersRow(
          filtroMateria: _filtroMateria,
          filtroSeccion: _filtroSeccion,
          filtroPrivacidad: _filtroPrivacidad,
          onClearMateria: () => setState(() => _filtroMateria = null),
          onClearSeccion: () => setState(() => _filtroSeccion = null),
          onPrivacidadChanged: (v) => setState(() => _filtroPrivacidad = v),
          wrap: isMobile,
        ),
        const SizedBox(height: 20),
        // Grid
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: Color(0xFFE65100)),
                ),
              )
            : _GruposGrid(
                grupos: _gruposFiltrados,
                columns: gridCols,
                onCrear: _showCreateDialog,
              ),
      ],
    );
  }

  void _showCreateDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearGrupoPage()),
    );
    _cargarGrupos();
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/estudiantess.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 102, 0),
                    Color.fromARGB(255, 255, 125, 82),
                  ],
                ),
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
              horizontal: isMobile ? 20 : 48,
              vertical: 28,
            ),
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
        ],
      ),
    );
  }
}

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
    _SI(icon: Icons.people_alt_outlined, label: 'Personas', isHeader: true),
    _SI(icon: null, label: 'Amigos', isHeader: false),
    _SI(icon: null, label: 'Estudiantes', isHeader: false),
  ];

  @override
  Widget build(BuildContext context) {
    final bool showGruposSubItems = (selected >= 0 && selected <= 2);
    final bool showPersonasSubItems = (selected >= 3 && selected <= 5);

    Widget? gruposTile;
    final List<Widget> gruposSubTiles = [];
    Widget? personasTile;
    final List<Widget> personasSubTiles = [];

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final isSubItem = !item.isHeader;

      final bool isActive = (i == 0)
          ? showGruposSubItems
          : (i == 3)
          ? showPersonasSubItems
          : (selected == i);

      final tile = GestureDetector(
        onTap: () {
          if (i == 0 && showGruposSubItems) {
            onSelect(-1);
          } else if (i == 3 && showPersonasSubItems) {
            onSelect(-1);
          } else {
            onSelect(i);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: horizontal ? null : 160,
          padding: horizontal
              ? EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 7 : 9,
                )
              : EdgeInsets.symmetric(
                  horizontal: isSubItem ? 12 : 10,
                  vertical: 9,
                ),
          decoration: BoxDecoration(
            color: (isActive && !item.isHeader)
                ? const Color(0xFFEFE0D0)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: (isActive && item.isHeader)
                ? Border.all(color: const Color(0xFFE65100), width: 1.0)
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
                Icon(
                  item.icon,
                  size: compact ? 15 : 17,
                  color: isActive
                      ? const Color(0xFFE65100)
                      : const Color(0xFF757575),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                item.label,
                style: GoogleFonts.lexend(
                  fontSize: compact ? 12 : 14,
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

      final tileWithPadding = Padding(
        padding: horizontal
            ? const EdgeInsets.only(right: 8)
            : const EdgeInsets.only(bottom: 2),
        child: tile,
      );

      if (i == 0) gruposTile = tileWithPadding;
      if (i == 1 || i == 2) gruposSubTiles.add(tileWithPadding);
      if (i == 3) personasTile = tileWithPadding;
      if (i == 4 || i == 5) personasSubTiles.add(tileWithPadding);
    }

    final List<Widget> tiles = [];

    if (gruposTile != null) tiles.add(gruposTile);
    tiles.add(
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        child: ClipRect(
          child: showGruposSubItems
              ? (horizontal
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: gruposSubTiles,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: gruposSubTiles,
                      ))
              : (horizontal
                    ? const SizedBox(width: 0)
                    : const SizedBox(height: 0)),
        ),
      ),
    );

    if (!horizontal) tiles.add(const SizedBox(height: 6));

    if (personasTile != null) tiles.add(personasTile);
    tiles.add(
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        child: ClipRect(
          child: showPersonasSubItems
              ? (horizontal
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: personasSubTiles,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: personasSubTiles,
                      ))
              : (horizontal
                    ? const SizedBox(width: 0)
                    : const SizedBox(height: 0)),
        ),
      ),
    );

    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: tiles),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFE3BFB1), thickness: 1.2, height: 24),
        ...tiles,
        const Divider(color: Color(0xFFE3BFB1), thickness: 1.2, height: 24),
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
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF212121)),
        decoration: InputDecoration(
          hintText: 'Buscar grupos',
          hintStyle: GoogleFonts.lexend(
            color: const Color(0xFFAFA49C),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFAFA49C),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
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
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: Text(
          'Crear Grupo',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
  final String? filtroPrivacidad;
  final VoidCallback onClearMateria;
  final VoidCallback onClearSeccion;
  final ValueChanged<String?> onPrivacidadChanged;
  final bool wrap;

  const _FiltersRow({
    required this.filtroMateria,
    required this.filtroSeccion,
    required this.filtroPrivacidad,
    required this.onClearMateria,
    required this.onClearSeccion,
    required this.onPrivacidadChanged,
    required this.wrap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _FilterBtn(label: 'Filtrar materias', icon: Icons.tune_rounded),
      _FilterBtn(label: 'Sección', icon: Icons.school_outlined),
      _PrivacidadFilterBtn(
        valor: filtroPrivacidad,
        onChanged: onPrivacidadChanged,
      ),
      if (filtroMateria != null)
        _ActiveChip(label: filtroMateria!, onRemove: onClearMateria),
      if (filtroSeccion != null)
        _ActiveChip(label: filtroSeccion!, onRemove: onClearSeccion),
      if (filtroPrivacidad != null)
        _ActiveChip(
          label: filtroPrivacidad == 'privado' ? 'Privados' : 'Públicos',
          onRemove: () => onPrivacidadChanged(null),
          color: filtroPrivacidad == 'privado'
              ? const Color(0xFFFFF3E0)
              : const Color(0xFFE8F5E9),
          borderColor: filtroPrivacidad == 'privado'
              ? const Color(0xFFFFCC80)
              : const Color(0xFFA5D6A7),
          textColor: filtroPrivacidad == 'privado'
              ? const Color(0xFFE65100)
              : const Color(0xFF2E7D32),
        ),
    ];

    if (wrap) {
      return Wrap(spacing: 8, runSpacing: 8, children: children);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children
            .map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(right: 8), child: c),
            )
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF757575)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: const Color(0xFF424242),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 15,
            color: Color(0xFF757575),
          ),
        ],
      ),
    );
  }
}

class _PrivacidadFilterBtn extends StatelessWidget {
  final String? valor;
  final ValueChanged<String?> onChanged;
  const _PrivacidadFilterBtn({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => onChanged(v == 'todos' ? null : v),
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'todos',
          child: Row(
            children: [
              Icon(
                Icons.apps_rounded,
                size: 16,
                color: const Color(0xFF757575),
              ),
              const SizedBox(width: 8),
              Text('Todos', style: GoogleFonts.lexend(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'publico',
          child: Row(
            children: [
              Icon(
                Icons.lock_open_outlined,
                size: 16,
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
              Text('Públicos', style: GoogleFonts.lexend(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'privado',
          child: Row(
            children: [
              Icon(
                Icons.lock_rounded,
                size: 16,
                color: const Color(0xFFE65100),
              ),
              const SizedBox(width: 8),
              Text('Privados', style: GoogleFonts.lexend(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: valor == 'publico'
              ? const Color(0xFFE8F5E9)
              : valor == 'privado'
              ? const Color(0xFFFFF3E0)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: valor == 'publico'
                ? const Color(0xFFA5D6A7)
                : valor == 'privado'
                ? const Color(0xFFE65100)
                : const Color(0xFFE3BFB1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              valor == 'privado'
                  ? Icons.lock_rounded
                  : Icons.lock_open_outlined,
              size: 15,
              color: valor == 'publico'
                  ? const Color(0xFF2E7D32)
                  : valor == 'privado'
                  ? const Color(0xFFE65100)
                  : const Color(0xFF757575),
            ),
            const SizedBox(width: 6),
            Text(
              valor == null
                  ? 'Privacidad'
                  : valor == 'privado'
                  ? 'Privados'
                  : 'Públicos',
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: valor == 'publico'
                    ? const Color(0xFF2E7D32)
                    : valor == 'privado'
                    ? const Color(0xFFE65100)
                    : const Color(0xFF424242),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: valor == 'publico'
                  ? const Color(0xFF2E7D32)
                  : valor == 'privado'
                  ? const Color(0xFFE65100)
                  : const Color(0xFF757575),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Color color;
  final Color borderColor;
  final Color textColor;
  const _ActiveChip({
    required this.label,
    required this.onRemove,
    this.color = const Color(0xFFE8F5E9),
    this.borderColor = const Color(0xFFA5D6A7),
    this.textColor = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: textColor),
          ),
        ],
      ),
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

  const _GruposGrid({
    required this.grupos,
    required this.columns,
    required this.onCrear,
  });

  @override
  Widget build(BuildContext context) {
    final total = grupos.length + 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: total,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: columns == 1 ? double.infinity : 290,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: columns == 1 ? 1.7 : 0.85,
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
  final String id;
  final String nombre;
  final String descripcion;
  final int miembros;
  final int max;
  final String materia;
  final int seccion;
  final String? fotoUrl;
  final bool esPrivado;
  final String? creadoPor;

  _GrupoData({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.miembros,
    required this.max,
    required this.materia,
    required this.seccion,
    this.fotoUrl,
    this.esPrivado = false,
    this.creadoPor,
  });

  factory _GrupoData.fromMap(Map<String, dynamic> map) {
    return _GrupoData(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre'] ?? 'Sin nombre',
      descripcion: map['descripcion'] ?? '',
      miembros: 0,
      max: map['max_miembros'] ?? 20,
      materia: map['materia'] ?? '',
      seccion: map['seccion'] is int
          ? map['seccion']
          : int.tryParse(map['seccion']?.toString() ?? '1') ?? 1,
      fotoUrl: map['foto_url'],
      esPrivado: map['es_privado'] == true,
      creadoPor: map['creado_por']?.toString(),
    );
  }

  IconData get icono {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc'))
      return Icons.calculate_outlined;
    if (m.contains('físic') || m.contains('fisic')) return Icons.bolt_outlined;
    if (m.contains('quím') || m.contains('quim')) return Icons.science_outlined;
    if (m.contains('dato') ||
        m.contains('progr') ||
        m.contains('comp') ||
        m.contains('sistem'))
      return Icons.computer_outlined;
    if (m.contains('bio')) return Icons.biotech_outlined;
    if (m.contains('hist')) return Icons.history_edu_outlined;
    if (m.contains('econ') || m.contains('admin'))
      return Icons.bar_chart_outlined;
    return Icons.menu_book_outlined;
  }

  Color get iconBg {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc'))
      return const Color(0xFFFFF3E0);
    if (m.contains('físic') || m.contains('fisic'))
      return const Color(0xFFF3E5F5);
    if (m.contains('quím') || m.contains('quim'))
      return const Color(0xFFE8F5E9);
    if (m.contains('dato') ||
        m.contains('progr') ||
        m.contains('comp') ||
        m.contains('sistem'))
      return const Color(0xFFE3F2FD);
    if (m.contains('bio')) return const Color(0xFFE0F7FA);
    if (m.contains('hist')) return const Color(0xFFFBE9E7);
    if (m.contains('econ') || m.contains('admin'))
      return const Color(0xFFF9FBE7);
    return const Color(0xFFF5F5F5);
  }

  Color get iconColor {
    final m = materia.toLowerCase();
    if (m.contains('mat') || m.contains('cálc') || m.contains('calc'))
      return const Color(0xFFE65100);
    if (m.contains('físic') || m.contains('fisic'))
      return const Color(0xFF6A1B9A);
    if (m.contains('quím') || m.contains('quim'))
      return const Color(0xFF2E7D32);
    if (m.contains('dato') ||
        m.contains('progr') ||
        m.contains('comp') ||
        m.contains('sistem'))
      return const Color(0xFF1565C0);
    if (m.contains('bio')) return const Color(0xFF00695C);
    if (m.contains('hist')) return const Color(0xFFBF360C);
    if (m.contains('econ') || m.contains('admin'))
      return const Color(0xFF558B2F);
    return const Color(0xFF616161);
  }

  String get seccionLabel => 'Sec $seccion';
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA GRUPO
// ═══════════════════════════════════════════════════════════════════════════

class _GrupoCard extends StatelessWidget {
  final _GrupoData grupo;
  const _GrupoCard({required this.grupo});

  Future<void> _manejarUnirse(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (grupo.esPrivado) {
      // Mostrar diálogo de solicitud
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.lock_rounded,
                color: Color(0xFFE65100),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Grupo privado',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'Este grupo requiere aprobación del administrador. ¿Deseas enviar una solicitud para unirte a "${grupo.nombre}"?',
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: const Color(0xFF424242),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.lexend(color: const Color(0xFF757575)),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 15),
              label: Text(
                'Solicitar',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      try {
        await supabase.from('solicitudes_grupo').insert({
          'grupo_id': grupo.id,
          'usuario_id': userId,
          'estado': 'pendiente',
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Solicitud enviada. El administrador la revisará pronto.',
              style: GoogleFonts.lexend(color: Colors.white),
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        final msg =
            e.toString().contains('duplicate') ||
                e.toString().contains('unique')
            ? 'Ya tienes una solicitud pendiente para este grupo.'
            : 'Error al enviar la solicitud: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(msg, style: GoogleFonts.lexend(color: Colors.white)),
          ),
        );
      }
    } else {
      // ─── LÓGICA DE CHAT EN GRUPO PÚBLICO ───
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E5900),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'Abriendo chat de ${grupo.nombre}...',
            style: GoogleFonts.lexend(color: Colors.white),
          ),
        ),
      );

      // NAVEGACIÓN A LA PANTALLA DE CHAT ACTIVADA AQUÍ
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudymatchChatPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: grupo.esPrivado
              ? const Color(0xFFFFCC80)
              : const Color(0xFFF0EAE6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: grupo.iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: grupo.fotoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            grupo.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              grupo.icono,
                              color: grupo.iconColor,
                              size: 30,
                            ),
                          ),
                        )
                      : Icon(grupo.icono, color: grupo.iconColor, size: 30),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (grupo.esPrivado)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCC80)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: Color(0xFFE65100),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Privado',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: const Color(0xFFE65100),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _MiniTag(
                      label: grupo.materia,
                      bg: const Color(0xFFE8F5E9),
                      fg: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 4),
                    _MiniTag(
                      label: grupo.seccionLabel,
                      bg: const Color(0xFFF5F5F5),
                      fg: const Color(0xFF757575),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    grupo.nombre,
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (grupo.esPrivado) ...[
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: 'Requiere aprobación del administrador',
                    child: Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                grupo.descripcion,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: const Color(0xFF8A8A8A),
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _AvatarStack(count: grupo.miembros.clamp(1, 4)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${grupo.miembros} / ${grupo.max} miembros',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _MiniTag(
                  label: grupo.seccionLabel,
                  bg: const Color(0xFFF5F5F5),
                  fg: const Color(0xFF757575),
                ),
                _MiniTag(
                  label: grupo.materia,
                  bg: const Color(0xFFF5F5F5),
                  fg: const Color(0xFF757575),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _manejarUnirse(context),
                icon: Icon(
                  // ─── ÍCONO DE CHAT PARA GRUPOS PÚBLICOS ───
                  grupo.esPrivado
                      ? Icons.send_rounded
                      : Icons.chat_bubble_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                label: Text(
                  // ─── TEXTO "CHAT" PARA GRUPOS PÚBLICOS ───
                  grupo.esPrivado ? 'Solicitar unirse' : 'Chat',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: grupo.esPrivado
                      ? const Color(0xFFE65100)
                      : const Color(0xFF2E5900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
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
      child: CustomPaint(
        painter: _DashedRectPainter(color: const Color(0xFFD7CCC8)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF9E9E9E),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crear un grupo',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '¿No puedes encontrar un grupo de tu clase? Crea uno e invita a tus amigos.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: const Color(0xFFAFA49C),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════

class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  static const _colors = [
    Color(0xFFB0BEC5),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFCC80),
  ];

  @override
  Widget build(BuildContext context) {
    final n = count.clamp(1, 4);
    return SizedBox(
      width: n * 17.0 + 8,
      height: 26,
      child: Stack(
        children: List.generate(
          n,
          (i) => Positioned(
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
          ),
        ),
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
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        border: Border(top: BorderSide(color: Color(0xFFEDE8E3))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: 28,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _brand(),
                const SizedBox(height: 16),
                _links(wrap: true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _brand()),
                _links(wrap: false),
              ],
            ),
    );
  }

  Widget _brand() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'U-NITE',
        style: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF245000),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        '© 2024 U-NITE Campus Marketplace. All rights reserved.',
        style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFF9E9E9E)),
      ),
    ],
  );

  Widget _links({required bool wrap}) {
    const labels = [
      'Privacy Policy',
      'Terms of Service',
      'Campus Safety',
      'Contact Support',
    ];
    final widgets = labels
        .map(
          (l) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              l,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: const Color(0xFF616161),
              ),
            ),
          ),
        )
        .toList();
    return wrap
        ? Wrap(children: widgets)
        : Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }
}
