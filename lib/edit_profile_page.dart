import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'dart:typed_data';

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
  Uint8List? _newProfileImageBytes;
  String? _userId;
  List<Map<String, dynamic>> _misAnuncios = [];
  bool _isLoadingAnuncios = true;

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
    _loadMisAnuncios();
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
      final data = await _supabase
          .from('usuarios')
          .select()
          .eq('id', _userId!)
          .single();

      setState(() {
        _currentProfileUrl = data['foto_perfil_url'];
        _nombreController.text = data['primer_nombre'] ?? '';
        _apellidoController.text = data['primer_apellido'] ?? '';
        _cedulaController.text = data['cedula']?.toString() ?? '';
        _universidadController.text = data['universidad'] ?? '';
        _carreraController.text = data['carrera'] ?? '';
        _semestreController.text = data['semestre']?.toString() ?? '';
        _biografiaAcademicaController.text = data['biografia_academica'] ?? '';
        _biografiaVentasController.text = data['biografia_vendedor'] ?? '';
        _newProfileImageBytes = null;

        if (data['fecha_nacimiento'] != null) {
          _selectedFechaNacimiento = DateTime.parse(data['fecha_nacimiento']);
        }
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al cargar datos: $e")));
      }
    }
  }

  Future<void> _loadMisAnuncios() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final data = await _supabase
          .from('anuncios_marketplace')
          .select()
          .eq('vendedor_id', user.id)
          .eq('disponible', true)
          .order('fecha_publicacion', ascending: false);
      setState(() {
        _misAnuncios = List<Map<String, dynamic>>.from(data);
        _isLoadingAnuncios = false;
      });
    } catch (e) {
      setState(() => _isLoadingAnuncios = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      // Abrir selector de archivo (funciona en web y móvil)
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() => _newProfileImageBytes = bytes);

      // Subir al bucket 'avatars'
      final path = '$_userId/avatar.jpg';
      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // URL determinista + cache-buster para que el browser siempre recargue
      final baseUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      final publicUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('usuarios')
          .update({'foto_perfil_url': publicUrl})
          .eq('id', _userId!);

      setState(() => _currentProfileUrl = publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir la foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- FUNCIÓN DE ACTUALIZACIÓN EN SUPABASE ---
  Future<void> _updateUserData() async {
    setState(() => _isSaving = true);
    try {
      await _supabase
          .from('usuarios')
          .update({
            'primer_nombre': _nombreController.text.trim(),
            'primer_apellido': _apellidoController.text.trim(),
            'universidad': _universidadController.text.trim(),
            'carrera': _carreraController.text.trim(),
            //'semestre': int.tryParse(_semestreController.text),
            'biografia_academica': _biografiaAcademicaController.text.trim(),
            'biografia_vendedor': _biografiaVentasController.text.trim(),
            //'fecha_nacimiento': _selectedFechaNacimiento?.toIso8601String(),
          })
          .eq('id', _userId!);
      //Navigator.pop(context, true);  //Esto es lo que hace que se recargue el nombre en el profile_page

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Perfil actualizado con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF05600)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // BOTÓN DE ACCIÓN PARA GUARDAR
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _updateUserData,
        backgroundColor: const Color(0xFFF05600),
        label: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Actualizar Datos",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        icon: _isSaving ? null : const Icon(Icons.save, color: Colors.white),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- COLUMNA IZQUIERDA: MENÚ ---
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 30, 20, 30),
            child: Column(
              // Envolvemos el Container en una Column
              mainAxisSize: MainAxisSize.min,
              children: [
                // BOTÓN DE REGRESAR
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      true,
                    ), // O Navigator.push si prefieres recargar
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                    label: const Text(
                      "Volver al perfil",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        Icons.person_outline,
                        "Información Personal",
                        "personal",
                        _personalKey,
                      ),
                      _buildMenuItem(
                        Icons.school_outlined,
                        "Perfil Académico",
                        "academico",
                        _academicKey,
                      ),
                      _buildMenuItem(
                        Icons.storefront_outlined,
                        "Perfil Vendedor",
                        "vendedor",
                        _vendedorKey,
                      ),
                      _buildMenuItem(
                        Icons.lock_outline,
                        "Privacidad y Seguridad",
                        "seguridad",
                        _seguridadKey,
                      ),
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
                            Expanded(
                              child: _buildInputField(
                                "Nombre",
                                _nombreController,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildInputField(
                                "Apellido",
                                _apellidoController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField("Fecha de nacimiento"),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildInputField(
                                "Cédula de Identidad",
                                _cedulaController,
                                enabled: false,
                              ),
                            ),
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
                            Expanded(
                              child: _buildInputField(
                                "Universidad",
                                _universidadController,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildInputField(
                                "Carrera",
                                _carreraController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          "Semestre (Ej: 6)",
                          _semestreController,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          "Biografía Académica",
                          _biografiaAcademicaController,
                          maxLines: 3,
                        ),
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
                        _buildInputField(
                          "Biografía de Perfil de Ventas",
                          _biografiaVentasController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Inventario Activo",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _isLoadingAnuncios
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF05600),
                                ),
                              )
                            : _misAnuncios.isEmpty
                            ? const Center(
                                child: Text(
                                  "No tienes artículos en venta",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 15,
                                      mainAxisSpacing: 15,
                                      childAspectRatio: 1.4,
                                    ),
                                itemCount: _misAnuncios.length,
                                itemBuilder: (context, index) {
                                  final anuncio = _misAnuncios[index];
                                  final modalidades =
                                      anuncio['detalles_modalidades']
                                          as Map<String, dynamic>? ??
                                      {};
                                  final imagenes =
                                      modalidades['imagenes']
                                          as List<dynamic>? ??
                                      [];
                                  final tieneImagen = imagenes.isNotEmpty;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFEEEEEE),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Imagen con badge de categoría
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                              child: tieneImagen
                                                  ? Image.network(
                                                      imagenes[0],
                                                      height: 130,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      height: 130,
                                                      width: double.infinity,
                                                      color: const Color(
                                                        0xFFF0F0F0,
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      ),
                                                    ),
                                            ),
                                            if (anuncio['categoria'] != null)
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    anuncio['categoria'],
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        // Info
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                anuncio['titulo'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                anuncio['descripcion'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton(
                                                  onPressed: () {},
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6,
                                                        ),
                                                    side: const BorderSide(
                                                      color: Color(0xFFCCCCCC),
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    textStyle: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "Editar Artículo",
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildCardSection(
                    key: _seguridadKey,
                    title: "Privacidad y Seguridad",
                    child: Column(
                      children: [
                        _buildActionTile(
                          Icons.key_outlined,
                          "Cambiar Contraseña",
                          "Actualiza tus credenciales de seguridad",
                        ),
                        const Divider(height: 1),
                        _buildActionTile(
                          Icons.notifications_none_outlined,
                          "Preferencias de Notificación",
                          "Gestiona alertas push y correos",
                        ),
                        const Divider(height: 1),
                        _buildActionTile(
                          Icons.no_accounts_outlined,
                          "Desactivar Cuenta",
                          "Oculta tu perfil temporalmente",
                          isDestructive: true,
                        ),
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
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required GlobalKey key,
    required String title,
    required Widget child,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? Colors.black87, size: 24),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedFechaNacimiento ?? DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null)
              setState(() => _selectedFechaNacimiento = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFechaNacimiento == null
                      ? "DD/MM/YYYY"
                      : DateFormat(
                          'dd/MM/yyyy',
                        ).format(_selectedFechaNacimiento!),
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.redAccent : Colors.black87,
        ),
      ),
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
              image: NetworkImage(
                "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?q=80&w=1000",
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: 20,
          child: GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: _newProfileImageBytes != null
                          ? MemoryImage(_newProfileImageBytes!)
                          : (_currentProfileUrl != null
                                ? NetworkImage(_currentProfileUrl!)
                                      as ImageProvider
                                : null),
                      backgroundColor: Colors.grey[200],
                      child:
                          (_newProfileImageBytes == null &&
                              _currentProfileUrl == null)
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                  // Badge de cámara
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF05600),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
