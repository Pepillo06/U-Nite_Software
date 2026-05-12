import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart'; // Importamos la pantalla del perfil

class TestLandingPage extends StatefulWidget {
  const TestLandingPage({super.key});

  @override
  State<TestLandingPage> createState() => _TestLandingPageState();
}

class _TestLandingPageState extends State<TestLandingPage> {
  // Instancia de Supabase
  final supabase = Supabase.instance.client;
  String? primerNombre;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Hacemos un SELECT a la tabla 'usuarios' buscando el ID del usuario actual
      final response = await supabase
          .from('usuarios')
          .select('primer_nombre')
          .eq('id', user.id)
          .single();

      setState(() {
        primerNombre = response['primer_nombre'] as String?;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar el nombre: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el color naranja de tu paleta (UColors.orangeDark)
    const Color orangeDark = Color(0xFFF05600);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Landing Page (Prueba)'),
        backgroundColor: orangeDark,
        foregroundColor: Colors.white,
        actions: [
          // Botón para cerrar sesión útil para hacer pruebas con varias cuentas
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                // Si tienes la ruta de login configurada, redirige allí:
                // Navigator.of(context).pushReplacementNamed('/login');
                Navigator.of(context).pop(); 
              }
            },
          )
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: orangeDark)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¡Sesión iniciada exitosamente!',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hola, ${primerNombre ?? "Usuario"}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    icon: const Icon(Icons.person),
                    label: const Text(
                      'Entrar al Perfil de Usuario',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      // Navegamos a la pantalla de Perfil
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}