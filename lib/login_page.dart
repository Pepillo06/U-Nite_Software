import 'dart:ui'; // Necesario para ImageFilter.blur
import 'package:flutter/material.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
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

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  static const Color myOrange = Color(0xFFF05100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Capa de desenfoque
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          // 3. Contenido Central
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Tarjeta Blanca ---
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 30),
                        
                        // Logo insertado dentro de la tarjeta
                        Image.asset(
                          'assets/logo.png',
                          height: 80, // Ajusta el tamaño según prefieras
                          fit: BoxFit.contain,
                        ),
                        
                        const SizedBox(height: 30),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- CAMPO CORREO ELECTRÓNICO ---
                              const Text(
                                "CORREO ELECTRÓNICO",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 14),
                                decoration: _myInputDecoration(
                                  hint: 'ejemplo@universidad.edu',
                                  icon: Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // --- CAMPO CONTRASEÑA ---
                              Row(
                                children: [
                                  const Text(
                                    "CONTRASEÑA",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(50, 20),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                    child: const Text(
                                      "¿Olvidaste tu contraseña?",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: UColors.orangeDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscureText,
                                style: const TextStyle(fontSize: 14),
                                decoration: _myInputDecoration(
                                  hint: '.........',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.black38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscureText = !_obscureText),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // --- BOTÓN ENTRAR ---
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: UColors.orangeDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    "Ingresar",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: Colors.black12, indent: 40, endIndent: 40),
                        
                        // Link de Registro
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterPage()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "¿No tienes cuenta? ",
                                style: TextStyle(color: Colors.black54, fontSize: 14),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Registro',
                                    style: TextStyle(
                                      color: UColors.orangeDark,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Términos Legales
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      "Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.white70),
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

  InputDecoration _myInputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.black38, size: 20),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
      fillColor: Color(0xFFF9F9F9),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: UColors.orangeDark, width: 1.5),
      ),
      suffixIcon: suffixIcon,
    );
  }
}