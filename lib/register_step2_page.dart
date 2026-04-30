import 'dart:ui';
import 'package:flutter/material.dart';
import 'register_step3_page.dart';

class RegisterStep2Page extends StatefulWidget {
  const RegisterStep2Page({super.key});

  @override
  State<RegisterStep2Page> createState() => _RegisterStep2PageState();
}

class _RegisterStep2PageState extends State<RegisterStep2Page> {
  static const Color myOrange = Color(0xFFF05100);
  int _selectedProfile = 1; // 0 for Comprador, 1 for Vendedor, 2 for Estudiante

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey),
            ),
          ),
          // Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 40.0,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 800), // Aumentado para acomodar 3 tarjetas
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
                      height: 80,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.school, size: 60, color: myOrange),
                    ),
                    const SizedBox(height: 30),

                    // Progress Indicator Step 2
                    _buildProgressIndicator(currentStep: 2),
                    const SizedBox(height: 30),

                    // Title
                    const Text(
                      "Selecciona tu perfil",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "¿Cómo planeas usar U-NITE?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Profile Selection Cards
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: 220, // Ancho fijo para mantener simetría
                          child: _buildProfileCard(
                            index: 0,
                            title: "Comprador",
                            description:
                                "Busco comprar libros, herramientas, materiales de uso universitario cerca del campus.",
                            iconData: Icons.person,
                            iconBgColor: Colors.green.withOpacity(0.2),
                            iconColor: Colors.green[800]!,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: _buildProfileCard(
                            index: 1,
                            title: "Vendedor",
                            description:
                                "Quiero publicar artículos, ofrecer materiales o realizar intercambios con otros estudiantes.",
                            iconData: Icons.local_offer,
                            iconBgColor: myOrange.withOpacity(0.2),
                            iconColor: myOrange,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: _buildProfileCard(
                            index: 2,
                            title: "Estudiante",
                            description:
                                "Quiero conectar con otros estudiantes para hacer grupos de estudio, apoyarnos en clase o realizar proyectos de materias.",
                            iconData: Icons.groups,
                            iconBgColor: Colors.blue.withOpacity(0.2),
                            iconColor: Colors.blue[800]!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Siguiente Paso Button
                    SizedBox(
                      height: 45,
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterStep3Page(),
                            ),
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
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
          // Back button
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
    const Color myBrown = Color(0xFFE05200);
    const Color myGreyInactive = Color(0xFFCFCFCF);

    Widget buildStepBar(int stepNumber) {
      bool isActive = stepNumber == currentStep;
      return Container(
        width: 60,
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? myBrown : myGreyInactive,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    Widget buildStepLabel(String label, int stepNumber) {
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
            buildStepLabel("Paso 1", 1),
            const SizedBox(width: 30),
            buildStepLabel("Paso 2", 2),
            const SizedBox(width: 30),
            buildStepLabel("Paso 3", 3),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required int index,
    required String title,
    required String description,
    required IconData iconData,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    bool isSelected = _selectedProfile == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProfile = index;
        });
      },
      child: Container(
        height: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFEFEF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? myOrange : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: myOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}