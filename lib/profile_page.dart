import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_page.dart';
import 'market.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _perfilFuture;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _obtenerDatosPerfil();
  }

  Future<Map<String, dynamic>> _obtenerDatosPerfil() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No se encontró una sesión activa');
    }

    // Traemos toda la fila correspondiente a este usuario
    final data = await supabase
        .from('usuarios')
        .select()
        .eq('id', user.id)
        .single();

    return data;
  }

  @override
  Widget build(BuildContext context) {
    // Colores basados en tu diseño original
    const Color orangeDark = Color(0xFFF05600);
    const Color cardBorder = Color(0xFFEEEEEE);
    const Color sectionPink = Color(0xFFFDE8E0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: orangeDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            tooltip: 'Editar Perfil',
            onPressed: () async {
              // Navegamos a la pantalla de edición
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
              if (result == true) {
                _obtenerDatosPerfil(); // <--- Recarga el FutureBuilder
              }

              // Si el resultado es true, significa que se guardaron cambios,
              // recargamos la información del perfil.
              if (result == true) {
                setState(() {
                  _perfilFuture = _obtenerDatosPerfil();
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: orangeDark),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error al cargar los datos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No hay información disponible.'));
          }

          // Mapeamos los datos devueltos por la base de datos
          final perfil = snapshot.data!;
          final String nombre = perfil['primer_nombre'] ?? '';
          final String apellido = perfil['primer_apellido'] ?? '';
          final String cedula = perfil['cedula']?.toString() ?? 'No registrada';
          final String correo = perfil['correo'] ?? 'No registrado';
          final String universidad = perfil['universidad'] ?? 'No registrada';
          final String carrera = perfil['carrera'] ?? 'No registrada';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Avatar circular
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: sectionPink,
                  child: Icon(Icons.person, size: 60, color: orangeDark),
                ),
                const SizedBox(height: 16),
                // Nombre Completo
                Text(
                  '$nombre $apellido'.trim(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                // Correo electrónico
                Text(
                  correo,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                // Tarjeta con la lista de datos universitarios y personales
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFilaDato(
                        Icons.badge,
                        'Cédula de Identidad',
                        cedula,
                      ),
                      const Divider(height: 1, color: cardBorder),
                      _buildFilaDato(Icons.school, 'Universidad', universidad),
                      const Divider(height: 1, color: cardBorder),
                      _buildFilaDato(
                        Icons.menu_book,
                        'Carrera / Facultad',
                        carrera,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget auxiliar para pintar cada fila del perfil
  Widget _buildFilaDato(IconData icono, String etiqueta, String valor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icono, color: const Color(0xFFF05600)),
      title: Text(
        etiqueta,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      subtitle: Text(
        valor,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
