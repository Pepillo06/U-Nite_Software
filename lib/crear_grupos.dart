import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/unite_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrearGrupoPage extends StatefulWidget {
  const CrearGrupoPage({super.key});

  @override
  State<CrearGrupoPage> createState() => _CrearGrupoPageState();
}

class _CrearGrupoPageState extends State<CrearGrupoPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxMiembrosCtrl = TextEditingController();
  final _materiaCtrl = TextEditingController();
  final _seccionCtrl = TextEditingController();
  // State
  bool _esPrivado = false;
  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes; // para web
  final _picker = ImagePicker();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _coloresPrimario = Color(0xFFE65100);
  static const _colorFondo = Color(0xFFF7F4F1);
  static const _colorBorde = Color(0xFFE0D8D2);
  static const _colorTexto = Color(0xFF1A1A1A);
  static const _colorSubtexto = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _maxMiembrosCtrl.dispose();
    _materiaCtrl.dispose();
    _seccionCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearGrupo() async {
    if (_formKey.currentState!.validate()) {
      // Muestra un circulito de carga mientras guarda
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: _coloresPrimario),
        ),
      );

      try {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id;

        if (userId == null)
          throw Exception('Debes iniciar sesión para crear un grupo.');

        String? fotoUrl;

        // Si el usuario seleccionó una foto, la subimos al Storage de Supabase
        if (_imagenBytes != null) {
          final fileName = 'grupo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage
              .from('fotos-grupos')
              .uploadBinary(fileName, _imagenBytes!);
          fotoUrl = supabase.storage
              .from('fotos-grupos')
              .getPublicUrl(fileName);
        }

        final nombre = _nombreCtrl.text.trim();
        final descripcion = _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim();
        final materia = _materiaCtrl.text.trim();

        // Insertamos los datos en grupos_estudio
        await supabase.from('grupos_estudio').insert({
          'nombre': nombre,
          'descripcion': descripcion,
          'materia': materia,
          'seccion': int.tryParse(_seccionCtrl.text.trim()) ?? 1,
          'max_miembros': int.tryParse(_maxMiembrosCtrl.text.trim()) ?? 20,
          'es_privado': _esPrivado,
          'creado_por': userId,
          'foto_url': ?fotoUrl,
        });

        // Crear sala de chat vinculada con la misma información
        final salaResult = await supabase
            .from('salas_chat')
            .insert({
              'nombre': nombre,
              'materia': materia.isEmpty ? null : materia,
              'descripcion': descripcion,
              'creado_por': userId,
            })
            .select()
            .single();

        await supabase.from('participantes_sala').insert({
          'sala_id': salaResult['id'],
          'usuario_id': userId,
          'es_admin': true,
        });

        if (!mounted) return;

        Navigator.pop(context); // Cierra el diálogo de carga

        // Mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _coloresPrimario,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              '¡Grupo "${_nombreCtrl.text}" creado exitosamente 🎉',
              style: GoogleFonts.lexend(color: Colors.white),
            ),
          ),
        );

        Navigator.pop(context); // Regresa a la pantalla anterior
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Cierra el diálogo de carga si hay error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            content: Text('Error al crear el grupo: $e'),
          ),
        );
      }
    }
  }

  // ─── INPUT DECORATION ──────────────────────────────────────────────────────
  InputDecoration _dec(
    String label, {
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.lexend(fontSize: 13, color: _colorSubtexto),
    hintStyle: GoogleFonts.lexend(fontSize: 13, color: const Color(0xFFBBB5AF)),
    prefixIcon: icon != null
        ? Icon(icon, size: 18, color: const Color(0xFFAFA49C))
        : null,
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _colorBorde),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _colorBorde),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _coloresPrimario, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: const UniteHeader(currentIndex: 4),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFFE65100),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── INFORMACIÓN BÁSICA ──────────────────────────────────
                    _SectionTitle(
                      icon: Icons.info_outline,
                      label: 'Información básica',
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        children: [
                          // Foto circular centrada
                          Center(
                            child: _FotoCircular(
                              imagenBytes: _imagenBytes,
                              onTap: () async {
                                if (kIsWeb) {
                                  final input = html.FileUploadInputElement()
                                    ..accept = 'image/*'
                                    ..click();
                                  await input.onChange.first;
                                  if (input.files!.isEmpty) return;
                                  final reader = html.FileReader();
                                  reader.readAsArrayBuffer(input.files![0]);
                                  await reader.onLoad.first;
                                  final bytes = reader.result as List<int>;
                                  setState(() {
                                    _imagenBytes = Uint8List.fromList(bytes);
                                    _imagenSeleccionada = XFile('web');
                                  });
                                } else {
                                  final picked = await _picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (picked != null) {
                                    final bytes = await picked.readAsBytes();
                                    setState(() {
                                      _imagenSeleccionada = picked;
                                      _imagenBytes = bytes;
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              _imagenBytes != null
                                  ? 'Toca para cambiar'
                                  : 'Subir foto del grupo',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: _imagenBytes != null
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFFAFA49C),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Nombre
                          TextFormField(
                            controller: _nombreCtrl,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              color: _colorTexto,
                            ),
                            decoration: _dec(
                              'Nombre del grupo',
                              hint: 'Ej: Mate II sección 2 con Daza',
                              icon: Icons.group_outlined,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'El nombre es obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Descripción
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 3,
                            maxLength: 220,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              color: _colorTexto,
                            ),
                            decoration: _dec(
                              'Descripción',
                              hint:
                                  'Cuéntale a tus compañeros de qué va el grupo...',
                              icon: Icons.notes_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── MATERIA Y SECCIÓN ───────────────────────────────────
                    _SectionTitle(
                      icon: Icons.school_outlined,
                      label: 'Materia y sección',
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: isMobile
                          ? Column(
                              children: [
                                _materiaField(),
                                const SizedBox(height: 14),
                                _seccionField(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _materiaField()),
                                const SizedBox(width: 14),
                                Expanded(child: _seccionField()),
                              ],
                            ),
                    ),
                    const SizedBox(height: 28),

                    // ── CONFIGURACIÓN ───────────────────────────────────────
                    _SectionTitle(
                      icon: Icons.settings_outlined,
                      label: 'Configuración',
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        children: [
                          // Cantidad máxima de miembros
                          TextFormField(
                            controller: _maxMiembrosCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              color: _colorTexto,
                            ),
                            decoration: _dec(
                              'Máximo de miembros',
                              hint: 'Ej: 20 (máx. 50)',
                              icon: Icons.people_outline,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final n = int.tryParse(v);
                              if (n == null || n < 2) {
                                return 'Mínimo 2 miembros';
                              }
                              if (n > 50) {
                                return 'Máximo 50 miembros';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Privacidad
                          _PrivacidadToggle(
                            esPrivado: _esPrivado,
                            onChanged: (v) => setState(() => _esPrivado = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── BOTONES ─────────────────────────────────────────────
                    isMobile
                        ? Column(
                            children: [
                              _BtnCrear(onTap: _crearGrupo),
                              const SizedBox(height: 12),
                              _BtnCancelar(onTap: () => Navigator.pop(context)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _BtnCancelar(onTap: () => Navigator.pop(context)),
                              const SizedBox(width: 12),
                              _BtnCrear(onTap: _crearGrupo),
                            ],
                          ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _materiaField() => TextFormField(
    controller: _materiaCtrl,
    style: GoogleFonts.lexend(fontSize: 14, color: _colorTexto),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]')),
    ],
    decoration: _dec(
      'Materia',
      hint: 'Ej: Matemáticas II',
      icon: Icons.book_outlined,
    ),
  );

  Widget _seccionField() => TextFormField(
    controller: _seccionCtrl,
    style: GoogleFonts.lexend(fontSize: 14, color: _colorTexto),
    keyboardType: TextInputType.number,
    maxLength: 2,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(2),
    ],
    decoration: _dec(
      'Sección',
      hint: 'Ej: 02',
      icon: Icons.bookmark_outline,
    ).copyWith(counterText: ''),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS INTERNOS
// ═══════════════════════════════════════════════════════════════════════════

class _FotoCircular extends StatefulWidget {
  final Uint8List? imagenBytes;
  final VoidCallback onTap;
  const _FotoCircular({required this.imagenBytes, required this.onTap});

  @override
  State<_FotoCircular> createState() => _FotoCircularState();
}

class _FotoCircularState extends State<_FotoCircular>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _hoverCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _overlayAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
    _overlayAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _hoverCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _hoverCtrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverCtrl,
          builder: (_, __) => Transform.scale(
            scale: _scaleAnim.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Anillo exterior animado
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _hovered
                          ? const Color(0xFFE65100)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE65100).withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Imagen o fondo
                        widget.imagenBytes != null
                            ? Image.memory(
                                widget.imagenBytes!,
                                fit: BoxFit.cover,
                              )
                            : Container(color: const Color(0xFFFFF3E0)),

                        // Overlay al hacer hover
                        Opacity(
                          opacity: _overlayAnim.value * 0.10,
                          child: Container(color: const Color(0xFF3E2723)),
                        ),

                        // Ícono central al hacer hover
                        if (_hovered)
                          Center(
                            child: Opacity(
                              opacity: _overlayAnim.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.imagenBytes != null
                                        ? 'Cambiar'
                                        : 'Subir',
                                    style: GoogleFonts.lexend(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (widget.imagenBytes == null)
                          Center(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 34,
                              color: const Color(
                                0xFFE65100,
                              ).withOpacity(1 - _overlayAnim.value * 0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Botón editar
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _hovered
                          ? const Color(0xFFBF360C)
                          : const Color(0xFFE65100),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFFE65100)),
      const SizedBox(width: 7),
      Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color.fromARGB(255, 66, 66, 66),
          letterSpacing: 0.4,
        ),
      ),
    ],
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEDE8E3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _PrivacidadToggle extends StatelessWidget {
  final bool esPrivado;
  final ValueChanged<bool> onChanged;
  const _PrivacidadToggle({required this.esPrivado, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F4F1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEDE8E3)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: esPrivado
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            esPrivado ? Icons.lock_outline : Icons.lock_open_outlined,
            color: esPrivado
                ? const Color(0xFFE65100)
                : const Color(0xFF2E7D32),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                esPrivado ? 'Grupo privado' : 'Grupo público',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                esPrivado
                    ? 'Solo pueden unirse por invitación'
                    : 'Cualquier compañero puede unirse',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: esPrivado,
          onChanged: onChanged,
          activeColor: const Color(0xFFE65100),
        ),
      ],
    ),
  );
}

class _BtnCrear extends StatelessWidget {
  final VoidCallback onTap;
  const _BtnCrear({required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.of(context).size.width < 700 ? double.infinity : null,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.check_rounded, size: 18),
      label: Text(
        'Crear grupo',
        style: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    ),
  );
}

class _BtnCancelar extends StatelessWidget {
  final VoidCallback onTap;
  const _BtnCancelar({required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.of(context).size.width < 700 ? double.infinity : null,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE0D8D2)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      child: Text(
        'Cancelar',
        style: GoogleFonts.lexend(
          color: const Color.fromARGB(255, 97, 97, 97),
          fontSize: 14,
        ),
      ),
    ),
  );
}
