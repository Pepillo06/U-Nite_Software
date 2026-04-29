import 'dart:ui';
import 'package:flutter/material.dart';
import 'register_step2_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  static const Color myOrange = Color(0xFFF05100);
  static const Color myGreyText = Color(0xFF8E8E8E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si no hay imagen
                return Container(color: Colors.grey);
              },
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

          // Contenido centrado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 40.0,
              ),
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
                    Image.asset(
                      'assets/logo.png',
                      height: 60,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.school, size: 60, color: myOrange),
                    ),
                    const SizedBox(height: 5),
                    const SizedBox(height: 30),

                    // Progress indicators
                    _buildProgressIndicator(currentStep: 1),
                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      "Registro de Usuario",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Para empezar, necesitamos conocerte un poco mejor.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 40),

                    // Form Fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            "Nombre",
                            "Ej. Juan",
                            controller: _nombreController,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildFormField(
                            "Apellido",
                            "Ej. Pérez",
                            controller: _apellidoController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      "Fecha de Nacimiento",
                      "mm/dd/yyyy",
                      controller: _fechaController,
                      icon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      "Cédula de Identidad",
                      "V-00000000",
                      controller: _cedulaController,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterStep2Page()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Siguiente Paso",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Footer text
                    RichText(
                      text: const TextSpan(
                        text: "¿Tienes dudas? ",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                        children: [
                          TextSpan(
                            text: "Contactar a Soporte",
                            style: TextStyle(
                              color: myOrange,
                              fontWeight: FontWeight.bold,
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

          // Back button (Optional, but good for navigation)
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

  Widget _buildFormField(
    String label,
    String hint, {
    required TextEditingController controller,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.black12, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.black12, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: myOrange, width: 1.5),
            ),
            suffixIcon: icon != null
                ? Icon(icon, color: Colors.black38, size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}
