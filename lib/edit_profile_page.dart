import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  
  // --- CONTROL DE SCROLL Y NAVEGACIÓN ---
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _personalKey = GlobalKey();
  final GlobalKey _academicKey = GlobalKey();
  final GlobalKey _vendedorKey = GlobalKey();
  final GlobalKey _seguridadKey = GlobalKey();
  String _activeSection = 'personal';

  // Estados
  bool _isLoadingData = true;
  bool _isSaving = false;
  String? _currentProfileUrl;
  String? _userId;

  // Controladores
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _universidadController = TextEditingController();
  final _carreraController = TextEditingController();
  final _semestreController = TextEditingController(); // Nuevo controlador
  final _biografiaAcademicaController = TextEditingController();
  final _biografiaVentasController = TextEditingController();
  DateTime? _selectedFechaNacimiento;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _universidadController.dispose();
    _carreraController.dispose();
    _semestreController.dispose();
    _biografiaAcademicaController.dispose();
    _biografiaVentasController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key, String sectionId) {
    setState(() => _activeSection = sectionId);
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      _userId = user.id;
      final data = await _supabase.from('usuarios').select().eq('id', _userId!).single();

      setState(() {
        _currentProfileUrl = data['profile_image_url'];
        _nombreController.text = data['primer_nombre'] ?? '';
        _apellidoController.text = data['primer_apellido'] ?? '';
        _cedulaController.text = data['cedula']?.toString() ?? '';
        _universidadController.text = data['universidad'] ?? '';
        _carreraController.text = data['carrera'] ?? '';
        _semestreController.text = data['semestre']?.toString() ?? '';
        _biografiaAcademicaController.text = data['biografia'] ?? '';
        _biografiaVentasController.text = data['biografia_ventas'] ?? '';
        
        if (data['fecha_nacimiento'] != null) {
          _selectedFechaNacimiento = DateTime.parse(data['fecha_nacimiento']);
        }
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al cargar datos: $e")));
      }
    }
  }

  // --- FUNCIÓN DE ACTUALIZACIÓN EN SUPABASE ---
  Future<void> _updateUserData() async {
    setState(() => _isSaving = true);
    try {
      await _supabase.from('usuarios').update({
        'primer_nombre': _nombreController.text.trim(),
        'primer_apellido': _apellidoController.text.trim(),
        'universidad': _universidadController.text.trim(),
        'carrera': _carreraController.text.trim(),
        //'semestre': int.tryParse(_semestreController.text),
        'biografia': _biografiaAcademicaController.text.trim(),
        //'biografia_ventas': _biografiaVentasController.text.trim(),
        //'fecha_nacimiento': _selectedFechaNacimiento?.toIso8601String(),
      }).eq('id', _userId!);
      //Navigator.pop(context, true);  //Esto es lo que hace que se recargue el nombre en el profile_page

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Perfil actualizado con éxito!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFF05600))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // BOTÓN DE ACCIÓN PARA GUARDAR
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _updateUserData,
        backgroundColor: const Color(0xFFF05600),
        label: _isSaving 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("Actualizar Datos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: _isSaving ? null : const Icon(Icons.save, color: Colors.white),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- COLUMNA IZQUIERDA: MENÚ ---
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 30, 20, 30),
            child: Column( // Envolvemos el Container en una Column
              mainAxisSize: MainAxisSize.min,
              children: [
                // BOTÓN DE REGRESAR
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context, true), // O Navigator.push si prefieres recargar
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                    label: const Text("Volver al perfil", style: TextStyle(color: Colors.black54)),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(Icons.person_outline, "Información Personal", "personal", _personalKey),
                      _buildMenuItem(Icons.school_outlined, "Perfil Académico", "academico", _academicKey),
                      _buildMenuItem(Icons.storefront_outlined, "Perfil Vendedor", "vendedor", _vendedorKey),
                      _buildMenuItem(Icons.lock_outline, "Privacidad y Seguridad", "seguridad", _seguridadKey),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- COLUMNA DERECHA: CONTENIDO ---
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 30, 40, 30),
              child: Column(
                children: [
                  _buildCardSection(
                    key: _personalKey,
                    title: "Información Personal",
                    child: Column(
                      children: [
                        _buildBannerAvatarEditor(),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(child: _buildInputField("Nombre", _nombreController)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildInputField("Apellido", _apellidoController)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: _buildDateField("Fecha de nacimiento")),
                            const SizedBox(width: 20),
                            Expanded(child: _buildInputField("Cédula de Identidad", _cedulaController, enabled: false)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildCardSection(
                    key: _academicKey,
                    title: "Perfil Académico",
                    icon: Icons.school,
                    iconColor: const Color(0xFF1B5E20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildInputField("Universidad", _universidadController)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildInputField("Carrera", _carreraController)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildInputField("Semestre (Ej: 6)", _semestreController),
                        const SizedBox(height: 15),
                        _buildInputField("Biografía Académica", _biografiaAcademicaController, maxLines: 3),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildCardSection(
                    key: _vendedorKey,
                    title: "Perfil de Ventas (UniExchange)",
                    icon: Icons.local_offer,
                    iconColor: const Color(0xFF1B5E20),
                    child: Column(
                      children: [
                        _buildInputField("Biografía de Perfil de Ventas", _biografiaVentasController, maxLines: 3),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Inventario Activo", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 15),
                        const Center(child: Text("No tienes artículos en venta", style: TextStyle(color: Colors.grey))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildCardSection(
                    key: _seguridadKey,
                    title: "Privacidad y Seguridad",
                    child: Column(
                      children: [
                        _buildActionTile(Icons.key_outlined, "Cambiar Contraseña", "Actualiza tus credenciales de seguridad"),
                        const Divider(height: 1),
                        _buildActionTile(Icons.notifications_none_outlined, "Preferencias de Notificación", "Gestiona alertas push y correos"),
                        const Divider(height: 1),
                        _buildActionTile(Icons.no_accounts_outlined, "Desactivar Cuenta", "Oculta tu perfil temporalmente", isDestructive: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildMenuItem(IconData icon, String title, String id, GlobalKey key) {
    bool isActive = _activeSection == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => _scrollToSection(key, id),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF05600) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isActive ? Colors.white : Colors.black54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({required GlobalKey key, required String title, required Widget child, IconData? icon, Color? iconColor}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: iconColor ?? Colors.black87, size: 24), const SizedBox(width: 10)],
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool enabled = true, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedFechaNacimiento ?? DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _selectedFechaNacimiento = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFechaNacimiento == null ? "DD/MM/YYYY" : DateFormat('dd/MM/yyyy').format(_selectedFechaNacimiento!),
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.black87),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDestructive ? Colors.redAccent : Colors.black87)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }

  Widget _buildBannerAvatarEditor() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: NetworkImage("https://images.unsplash.com/photo-1497633762265-9d179a990aa6?q=80&w=1000"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 45,
              backgroundImage: _currentProfileUrl != null ? NetworkImage(_currentProfileUrl!) : null,
              backgroundColor: Colors.grey[200],
              child: _currentProfileUrl == null ? const Icon(Icons.person, size: 40) : null,
            ),
          ),
        ),
      ],
    );
  }
}