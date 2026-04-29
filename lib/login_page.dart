import 'dart:ui'; // Necesario para ImageFilter.blur

import 'package:flutter/material.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  static const Color myOrange = Color(0xFFF05100);
  static const Color myGreyText = Color(0xFF8E8E8E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CAMBIO IMPORTANTE 2: USAMOS STACK PARA EL FONDO ---
      body: Stack(
        children: [
          // 1. Imagen de fondo (Hasta atrás)
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg', // ** CAMBIAR NOMBRE DE IMAGEN AQUÍ **
              fit: BoxFit.cover, // Para que la imagen cubra toda la pantalla
            ),
          ),

          // 2. Capa borrosa (ImageFilter.blur)
          Positioned.fill(
            child: BackdropFilter(
              // Sigma controla qué tan borroso se ve. 10.0 es un buen punto de partida.
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              // El contenedor vacío encima del desenfoque es necesario para que funcione.
              child: Container(
                color: Colors.black.withOpacity(0.3), // Oscurecemos un poco el fondo para contraste.
              ),
            ),
          ),

          // 3. Contenido central (Tu formulario, hasta adelante)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Sección superior (Logo y título - SIN CAMBIOS) ---
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "U-NITE",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Todo lo que necesitas para tu carrera en un solo lugar",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- La tarjeta blanca del formulario (MODIFICADA) ---
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 400),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Padding solo para la parte superior de los campos
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- CAMPO CORREO ELECTRÓNICO ---
                              const Text(
                                "CORREO ELECTRÓNICO",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 14),
                                decoration: _myInputDecoration(
                                  hint: 'ejemplo@universidad.edu',
                                  icon: Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 25),

                              // --- CAMPO CONTRASEÑA ---
                              Row(
                                children: [
                                  const Text(
                                    "CONTRASEÑA",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      // Lógica para recuperar contraseña
                                    },
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(50, 20),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap
                                    ),
                                    child: const Text(
                                      "¿Olvidaste tu contraseña?",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: myOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
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
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 35),

                              // --- BOTÓN ENTRAR ---
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Lógica de inicio de sesión
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: myOrange,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    "Entrar",
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

                        // --- CAMBIO IMPORTANTE 1: MOVEMOS EL REGISTRO ADENTRO ---
                        // 1. Línea divisoria sutil
                        const Divider(
                          color: Colors.black12,
                          height: 1, 
                          thickness: 1,
                          indent: 50,    // Espacio vacío a la izquierda
                          endIndent: 50, // Espacio vacío a la derecha
                        ),

                        // 2. El texto de registro centrado y con padding
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
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
                                  // Ahora el color base es gris porque el fondo es blanco.
                                  style: TextStyle(color: Colors.black54, fontSize: 14),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Registro',
                                      style: TextStyle(
                                        color: myOrange,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40), // Espacio extra abajo

                  // --- Términos de servicio (Fuera de la tarjeta) ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Espacio final
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Método auxiliar para decoración de inputs (SIN CAMBIOS) ---
  InputDecoration _myInputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Icon(icon, color: Colors.black38, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
      fillColor: Colors.grey[50],
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.black12, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.black12, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: myOrange, width: 1.5),
      ),
      suffixIcon: suffixIcon,
    );
  }
}