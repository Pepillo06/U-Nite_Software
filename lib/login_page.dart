import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. IMPORTAMOS SUPABASE
import 'register_page.dart';
import 'market.dart';
import 'theme.dart';
import 'test_landing_page.dart'; // 2. IMPORTAMOS TU PÁGINA DE PRUEBAS

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}



class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  
  // --- AÑADIMOS ESTA VARIABLE PARA CONTROLAR EL ESTADO DE CARGA ---
  bool _isLoading = false;

  // --- FUNCIÓN QUE CONECTA CON SUPABASE AL PRESIONAR EL BOTÓN ---
  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu correo y contraseña')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Encendemos la animación de carga
    });

    try {
      // Hacemos la petición a Supabase
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Si todo sale bien y el widget sigue visible, navegamos a la landing page
      if (res.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TestLandingPage()),
        );
      }
    } on AuthException catch (error) {
      // Atrapa errores específicos de login (contraseña incorrecta, correo no existe, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message), 
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Cualquier otro error inesperado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un error inesperado al iniciar sesión'), 
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Apagamos la animación de carga
        });
      }
    }
  }

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

                              // --- BOTÓN ENTRAR (AQUÍ CONECTAMOS LA LÓGICA) ---
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  // Deshabilitamos el botón si está cargando para evitar doble clic
                                  onPressed: _isLoading ? null : _iniciarSesion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: UColors.orangeDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  // Mostramos el indicador de carga o el texto
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
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
      fillColor: const Color(0xFFF9F9F9),
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