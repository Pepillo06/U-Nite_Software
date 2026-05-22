import 'dart:ui';
import 'package:flutter/material.dart';
import 'market.dart';
import 'theme.dart';
import 'login_page.dart';
import 'user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterStep3Page extends StatefulWidget {
  final UserRegistrationModel model;
  const RegisterStep3Page({super.key, required this.model});

  @override
  State<RegisterStep3Page> createState() => _RegisterStep3PageState();
}


class _RegisterStep3PageState extends State<RegisterStep3Page> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Variables para controlar las selecciones
  String? _selectedUniversidad;
  String? _selectedCarrera;
  String? _universidadError;
  String? _carreraError;
  String? _correoError;
  String? _passwordError;

  // Listado de Universidades
  final List<String> _universidades = [
    "No estoy estudiando actualmente",
    "Universidad Metropolitana",
  ];

  // Mapa de Carreras de la UNIMET
  final List<String> _carrerasUnimet = [
    "Ingeniería de Sistemas",
    "Ingeniería Eléctrica",
    "Ingeniería Mecánica",
    "Ingeniería Civil",
    "Ingeniería de Producción",
    "Ingeniería Química",
    "Administración de Empresas",
    "Contaduría Pública",
    "Economía",
    "Derecho",
    "Psicología",
    "Idiomas Modernos",
    "Estudios Liberales",
    "Diseño Gráfico",
    "Educación",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Detectamos si es móvil
          bool isMobile = constraints.maxWidth < 600;

          return Stack(
            children: [
              // --- FONDO ---
              Positioned.fill(
                child: Image.asset(
                  'assets/background.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),

              // --- CONTENIDO ---
              Center(
                child: Container(
                  width: isMobile ? constraints.maxWidth * 0.9 : 500,
                  // Mantenemos el alto fijo en Web para evitar saltos visuales
                  height: isMobile ? null : 720,
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: isMobile ? constraints.maxHeight * 0.9 : 650,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isMobile ? 25.0 : 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/logo.png',
                        height: isMobile ? 60 : 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.school,
                              size: 60,
                              color: UColors.orangeDark,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Progress Indicator
                      _buildProgressIndicator(currentStep: 3),
                      const SizedBox(height: 30),

                      // --- TÍTULO (Centrado dinámico) ---
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          "Datos Universitarios",
                          textAlign: TextAlign
                              .center, // <-- Forzamos el centrado siempre
                          style: TextStyle(
                            fontSize:
                                28, // Puedes dejarlo fijo o usar el isMobile de antes
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Casi terminamos. Cuéntanos sobre tus estudios.",
                        textAlign: TextAlign
                            .center, // <-- Forzamos el centrado siempre
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // SECCIÓN DE SCROLL INTERNO
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              // Universidad
                              _buildFormField(
                                label: "UNIVERSIDAD",
                                isRequired: true,
                                hint: "Selecciona tu universidad",
                                icon: Icons.school,
                                errorText: _universidadError,
                                isDropdown: true,
                                dropdownItems: _universidades,
                                selectedValue: _selectedUniversidad,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedUniversidad = value;
                                    _selectedCarrera =
                                        null; // Reiniciar carrera si cambia la universidad
                                  });
                                },
                              ),
                              const SizedBox(height: 25),

                              // Carrera (Se habilita solo si es la UNIMET)
                              _buildFormField(
                                label: "CARRERA / FACULTAD",
                                optionalText:
                                    _selectedUniversidad ==
                                        "Universidad Metropolitana"
                                    ? null
                                    : "No disponible",
                                hint:
                                    _selectedUniversidad ==
                                        "Universidad Metropolitana"
                                    ? "Selecciona tu carrera"
                                    : "N/A",
                                icon: Icons.menu_book,
                                errorText: _carreraError,
                                isDropdown: true,
                                // Solo mostramos carreras si seleccionó UNIMET
                                dropdownItems:
                                    _selectedUniversidad ==
                                        "Universidad Metropolitana"
                                    ? _carrerasUnimet
                                    : [],
                                selectedValue: _selectedCarrera,
                                onChanged:
                                    _selectedUniversidad ==
                                        "Universidad Metropolitana"
                                    ? (value) => setState(
                                        () => _selectedCarrera = value,
                                      )
                                    : null, // Deshabilitado si no es la UNIMET
                              ),
                              const SizedBox(height: 25),
                              _buildFormField(
                                label: "CORREO ELECTRÓNICO",
                                hint: "ejemplo@correo.com",
                                //hintColor: UColors.orangeDark.withOpacity(0.5),
                                controller: _correoController,
                                icon: Icons.email,
                                errorText: _correoError,
                              ),
                              const SizedBox(height: 20),
                              _buildFormField(
                                label: "CONTRASEÑA",
                                isRequired: true,
                                hint: "Crea una contraseña segura",
                                icon: Icons.lock,
                                errorText: _passwordError,
                                controller: _passwordController,
                                isPassword: true, // Nueva propiedad que usaremos abajo
                                obscureText: _obscurePassword,
                                onSuffixIconPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Botón Finalizar
                      _buildFinalizeButton(),
                    ],
                  ),
                ),
              ),

              // Botón Volver
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFinalizeButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            _universidadError = _selectedUniversidad == null ? "Selecciona una universidad" : null;
            
            // Validamos carrera solo si seleccionó UNIMET
            if (_selectedUniversidad == "Universidad Metropolitana") {
              _carreraError = _selectedCarrera == null ? "Selecciona tu carrera" : null;
            } else {
              _carreraError = null;
            }

            _correoError = _correoController.text.trim().isEmpty ? "El correo es obligatorio" : null;

            // --- NUEVA VALIDACIÓN ---
            final password = _passwordController.text;
            final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
            final hasNumbers = RegExp(r'[0-9]').hasMatch(password);

            if (password.isEmpty) {
              _passwordError = "La contraseña es obligatoria";
            } else if (password.length < 8) {
              _passwordError = "Mínimo 8 caracteres";
            } else if (!hasLetters || !hasNumbers) {
              _passwordError = "Debe incluir letras y números";
            } else {
              _passwordError = null;
            }
          });

          // Si hay algún error, detenemos la ejecución
          if (_universidadError != null || _carreraError != null || 
              _correoError != null || _passwordError != null) {
            return;
          }
          // Mostramos un indicador de carga para que el usuario no de clic mil veces
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          if (_passwordController.text.length < 6) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("La contraseña debe tener al menos 6 caracteres")),
            );
            return; // Detiene la ejecución aquí
          }

          final supabase = Supabase.instance.client;

          try {
            // 1. Crear el usuario en Supabase Auth
            // widget.model tiene los datos de los pasos anteriores
            // correoController tiene el del paso actual
            
            final AuthResponse res = await supabase.auth.signUp(
              email: _correoController.text.trim(),
              password: _passwordController.text.trim(),
              data: {
                'primer_nombre': widget.model.nombre,
                'primer_apellido': widget.model.apellido,
                'cedula': widget.model.cedula,
                'universidad': _selectedUniversidad, 
                'carrera': _selectedCarrera, 
              },
            );

            final String? userId = res.user?.id;

            if (userId != null) {
              final bool esVendedor = widget.model.perfilSeleccionado == 1;
              final bool esEstudiante = widget.model.perfilSeleccionado == 2;

              // 3. Hacemos un UPDATE en vez de un INSERT
              await supabase
                  .from('usuarios')
                  .update({     
                    'es_estudiante': esEstudiante, // Cambiará a TRUE si aplica
                    'es_vendedor': esVendedor,     // Cambiará a TRUE si aplica
                  })
                  .eq('id', userId);

              // Cerramos el indicador de carga
              if (!mounted) return;
              Navigator.of(context).pop();

              // 3. Éxito: Vamos al Login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            }
          } catch (e) {
            // Si algo falla, cerramos la carga y mostramos el error
            if (!mounted) return;
            Navigator.of(context).pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error al registrar: ${e.toString()}"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: UColors.orangeDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Finalizar Registro",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: UColors.orangeDark,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator({required int currentStep}) {
    const Color myGreyInactive = Color(0xFFCFCFCF);
    Widget buildStepBar(int n) => Container(
      width: 60,
      height: 4,
      decoration: BoxDecoration(
        color: n == currentStep ? UColors.orangeDark : myGreyInactive,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    Widget buildStepLabel(String t, int n) => Text(
      t,
      style: TextStyle(
        color: n == currentStep ? UColors.orangeDark : myGreyInactive,
        fontSize: 10,
        fontWeight: n == currentStep ? FontWeight.bold : FontWeight.normal,
      ),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildStepBar(1),
            const SizedBox(width: 10),
            buildStepBar(2),
            const SizedBox(width: 10),
            buildStepBar(3),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildStepLabel("Paso 1 ", 1),
            const SizedBox(width: 30),
            buildStepLabel("  Paso 2", 2),
            const SizedBox(width: 30),
            buildStepLabel("   Paso 3", 3),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    bool isRequired = false,
    String? optionalText,
    required String hint,
    required IconData icon,
    bool isDropdown = false,
    List<String>? dropdownItems,
    String? selectedValue,
    ValueChanged<String?>? onChanged,
    TextEditingController? controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixIconPressed,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
            if (optionalText != null)
              Text(
                optionalText,
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: errorText != null ? Colors.redAccent : Colors.black12, 
              width: errorText != null ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                color: errorText != null ? Colors.redAccent : Colors.brown[400], 
                size: 20
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isDropdown
                    ? DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedValue,
                          hint: Text(
                            hint,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black38,
                            ),
                          ),
                          isExpanded: true,
                          items: dropdownItems?.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: onChanged,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      )
                    : TextFormField(
                        controller: controller,
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: const TextStyle(
                            color: Colors.black38,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          suffixIcon: isPassword 
                            ? IconButton(
                                icon: Icon(
                                  obscureText ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.black38,
                                  size: 20,
                                ),
                                onPressed: onSuffixIconPressed,
                              )
                            : null,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 8),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
