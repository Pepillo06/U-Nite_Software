import 'dart:ui';
import 'package:flutter/material.dart';
import 'market.dart';
import 'theme.dart';

class RegisterStep3Page extends StatefulWidget {
  const RegisterStep3Page({super.key});

  @override
  State<RegisterStep3Page> createState() => _RegisterStep3PageState();
}


class _RegisterStep3PageState extends State<RegisterStep3Page> {
  final TextEditingController _correoController = TextEditingController();

  // Variables para controlar las selecciones
  String? _selectedUniversidad;
  String? _selectedCarrera;

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
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MarketPage()),
            (route) => false,
          );
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
            border: Border.all(color: Colors.black12, width: 1.0),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.brown[400], size: 20),
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
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: const TextStyle(
                            color: Colors.black38,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
