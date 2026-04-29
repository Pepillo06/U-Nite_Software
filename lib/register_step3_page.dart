import 'dart:ui';
import 'package:flutter/material.dart';

// Assuming login page or home page as final destination
import 'login_page.dart';

class RegisterStep3Page extends StatefulWidget {
  const RegisterStep3Page({super.key});

  @override
  State<RegisterStep3Page> createState() => _RegisterStep3PageState();
}

class _RegisterStep3PageState extends State<RegisterStep3Page> {
  final TextEditingController _universidadController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  static const Color myOrange = Color(0xFFF05100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.school, size: 60, color: myOrange),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Progress Indicator Step 3
                    _buildProgressIndicator(currentStep: 3),
                    const SizedBox(height: 30),

                    // Title
                    const Text(
                      "Datos Universitarios",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Casi terminamos. Cuéntanos sobre tus estudios.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 40),

                    // Universidad
                    _buildFormField(
                      label: "UNIVERSIDAD",
                      isRequired: true,
                      hint: "Selecciona tu universidad",
                      controller: _universidadController,
                      icon: Icons.school,
                      isDropdown: true,
                    ),
                    const SizedBox(height: 25),

                    // Carrera
                    _buildFormField(
                      label: "CARRERA / FACULTAD",
                      optionalText: "Opcional",
                      hint: "Selecciona tu carrera",
                      controller: _carreraController,
                      icon: Icons.menu_book,
                      isDropdown: true,
                    ),
                    const SizedBox(height: 25),

                    // Correo
                    _buildFormField(
                      label: "CORREO ELECTRÓNICO",
                      hint: "ejemplo@correo.com",
                      hintColor: myOrange.withOpacity(0.5),
                      controller: _correoController,
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 40),

                    // Finalizar Registro Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myOrange,
                          elevation: 0,
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
                                color: myOrange,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator({required int currentStep}) {
    // Definimos los colores marrón y gris de la imagen para que sean consistentes
    const Color myBrown = Color(0xFFE05200); // El color marrón/naranja oscuro de tu foto
    const Color myGreyInactive = Color(0xFFCFCFCF); // Un gris claro para lo inactivo

    // Función interna para construir cada una de las 3 barras
    Widget buildStepBar(int stepNumber) {
      // La barra se ilumina si es el paso actual
      bool isActive = stepNumber == currentStep;
      return Container(
        width: 60, // Ancho de la barra como en la imagen
        height: 4, // Grosor de la barra
        decoration: BoxDecoration(
          color: isActive ? myBrown : myGreyInactive,
          borderRadius: BorderRadius.circular(2), // Bordes redondeados
        ),
      );
    }

    // Función interna para construir el texto "Paso X" debajo de la barra
    Widget buildStepLabel(String label, int stepNumber) {
      // El texto se ilumina si es el paso actual
      bool isActive = stepNumber == currentStep;
      return Text(
        label,
        style: TextStyle(
          color: isActive ? myBrown : myGreyInactive,
          fontSize: 10,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }

    // Retornamos la estructura completa: barras arriba, etiquetas abajo
    return Column(
      children: [
        // Fila de las 3 barras con separadores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildStepBar(1),
            const SizedBox(width: 10), // Espacio entre barras
            buildStepBar(2),
            const SizedBox(width: 10), // Espacio entre barras
            buildStepBar(3),
          ],
        ),
        const SizedBox(height: 5), // Espacio entre barras y etiquetas
        // Fila de las 3 etiquetas con separadores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildStepLabel("Paso 1", 1),
            const SizedBox(width: 30), // Espacio para alinear el texto bajo la barra
            buildStepLabel("Paso 2", 2),
            const SizedBox(width: 30), // Espacio para alinear el texto bajo la barra
            buildStepLabel("Paso 3", 3),
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
    Color? hintColor,
    required TextEditingController controller,
    required IconData icon,
    bool isDropdown = false,
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
                  letterSpacing: 0.5,
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            if (optionalText != null)
              Text(
                optionalText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.black12, width: 1.0),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(icon, color: Colors.brown[400], size: 20), // Dark brown icon
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: isDropdown,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: hintColor ?? Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (isDropdown)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                ),
            ],
          ),
        ),
      ],
    );
  }
}