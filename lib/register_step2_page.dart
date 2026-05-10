import 'dart:ui';
import 'package:flutter/material.dart';
import 'register_step3_page.dart';

class RegisterStep2Page extends StatefulWidget {
  const RegisterStep2Page({super.key});

  @override
  State<RegisterStep2Page> createState() => _RegisterStep2PageState();
}

// ───────────────────────────────────────────────────────────────
// Paleta de colores
// ───────────────────────────────────────────────────────────────
class UColors {
  static const orange = Color(0xFFF36900);
  static const orangeLight = Color(0xFFF57b00);
  static const orangeDark = Color(0xFFF05600);
  static const sectionPink = Color(0xFFFDE8E0);
  static const textDark = Color(0xFF1A1A1A);
  static const textGray = Color(0xFF5B4137);
  static const white = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEEEEEE);
  static const greenIcon = Color(0xFF4CAF7D);
  static const blueIcon = Color(0xFF5B8DEF);
  static const footerBg = Color(0xFFF5F5F5);
  static const greenDark = Color(0xFF245000);
  static const Color heroBackground = Color.fromARGB(255, 255, 204, 167);
}

class _RegisterStep2PageState extends State<RegisterStep2Page> {
  int _selectedProfile = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Si el ancho es menor a 850, activamos el modo móvil
          bool isMobile = constraints.maxWidth < 850;

          return Stack(
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
                child: Container(
                  width: isMobile ? constraints.maxWidth * 0.95 : 850,
                  // En Web el bloque es tieso y alto para que luzcan las tarjetas largas
                  height: isMobile ? null : 750, 
                  constraints: BoxConstraints(
                    maxWidth: 850,
                    maxHeight: isMobile ? constraints.maxHeight * 0.9 : 650,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  padding: EdgeInsets.all(isMobile ? 20.0 : 40.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: isMobile ? 60 : 80,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 60, color: UColors.orangeDark),
                      ),
                      const SizedBox(height: 20),
                      _buildProgressIndicator(currentStep: 2),
                      const SizedBox(height: 25),
                      Text(
                        "Selecciona tu perfil",
                        style: TextStyle(fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      const Text("¿Cómo planeas usar U-NITE?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 30),

                      // Scroll interno para las tarjetas
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildResponsiveCard(0, "Comprador", "Busco comprar libros, herramientas y materiales universitarios.", Icons.person, Colors.green.withOpacity(0.2), Colors.green[800]!, isMobile),
                              _buildResponsiveCard(1, "Vendedor", "Quiero publicar artículos u ofrecer materiales a otros estudiantes.", Icons.local_offer, UColors.orangeDark.withOpacity(0.2), UColors.orangeDark, isMobile),
                              _buildResponsiveCard(2, "Estudiante", "Quiero conectar para grupos de estudio o proyectos de materias.", Icons.groups, Colors.blue.withOpacity(0.2), Colors.blue[800]!, isMobile),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildNextButton(),
                    ],
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
          );
        },
      ),
    );
  }

  // --- MÉTODOS CORREGIDOS ---

  Widget _buildResponsiveCard(int index, String title, String desc, IconData icon, Color bg, Color icColor, bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 220,
      child: _buildProfileCard(
        index: index,
        title: title,
        description: desc,
        iconData: icon,
        iconBgColor: bg,
        iconColor: icColor,
        isMobile: isMobile, 
      ),
    );
  }

  Widget _buildProfileCard({
    required int index,
    required String title,
    required String description,
    required IconData iconData,
    required Color iconBgColor,
    required Color iconColor,
    required bool isMobile,
  }) {
    bool isSelected = _selectedProfile == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedProfile = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isMobile ? null : 245, 
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F0) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? UColors.orangeDark : const Color.fromARGB(255, 255, 255, 255), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // CENTRA TODO VERTICALMENTE
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              child: Icon(iconData, color: iconColor, size: 28),
            ),
            const SizedBox(height: 25),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 15),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      height: 50,
      width: 250,
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterStep3Page())),
        style: ElevatedButton.styleFrom(backgroundColor: UColors.orangeDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Siguiente Paso", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator({required int currentStep}) {
    const Color myGreyInactive = Color(0xFFCFCFCF);
    Widget buildStepBar(int n) => Container(width: 60, height: 4, decoration: BoxDecoration(color: n == currentStep ? UColors.orangeDark : myGreyInactive, borderRadius: BorderRadius.circular(2)));
    Widget buildStepLabel(String t, int n) => Text(t, style: TextStyle(color: n == currentStep ? UColors.orangeDark : myGreyInactive, fontSize: 10, fontWeight: n == currentStep ? FontWeight.bold : FontWeight.normal));

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [buildStepBar(1), const SizedBox(width: 10), buildStepBar(2), const SizedBox(width: 10), buildStepBar(3)]),
        const SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [buildStepLabel("Paso 1 ", 1), const SizedBox(width: 30), buildStepLabel("  Paso 2", 2), const SizedBox(width: 30), buildStepLabel("   Paso 3", 3)]),
      ],
    );
  }
}