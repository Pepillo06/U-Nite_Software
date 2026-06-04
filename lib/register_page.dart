import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_step2_page.dart';
import 'theme.dart';
import 'user_model.dart';
import 'login_page.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {
  final UserRegistrationModel registrationModel = UserRegistrationModel();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  // 1. ACTUALIZA TU FUNCIÓN _goToStep2 PARA ASIGNAR EL VALOR CORRECTO
  void _goToStep2() {
    setState(() {
      _nombreError = _nombreController.text.trim().isEmpty 
          ? "* El nombre es obligatorio" 
          : null;
      _apellidoError = _apellidoController.text.trim().isEmpty 
          ? "* El apellido es obligatorio" 
          : null;
      _cedulaError = _cedulaController.text.trim().isEmpty 
          ? "* La cédula es obligatoria" 
          : null;
      _fechaError = _fechaController.text.trim().isEmpty 
          ? "* La fecha es obligatoria" 
          : null;
    });

    if (_nombreError != null || 
        _apellidoError != null || 
        _cedulaError != null || 
        _fechaError != null) {
      return;
    }

    registrationModel.nombre = _nombreController.text.trim();
    registrationModel.apellido = _apellidoController.text.trim();
    registrationModel.cedula = _cedulaController.text.trim();
    // Aquí se guarda el texto con formato YYYY-MM-DD que ya tendrá el controlador
    registrationModel.fechaNacimiento = _fechaController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterStep2Page(model: registrationModel),
      ),
    );
  }

  String? _nombreError;
  String? _apellidoError;
  String? _cedulaError;
  String? _fechaError;

  bool _showCalendar = false;
  DateTime _selectedDate = DateTime.now();

  static const Color myOrange = Color(0xFFF05100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Evita que el teclado redimensione el fondo y dañe el layout en móvil
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Detectamos si es móvil por el ancho o si el alto es muy reducido
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

              Positioned(
                top: 40,  // Ajusta según el notch o status bar
                left: 20,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                  ),
                ),
              ),

              // --- CONTENIDO ---
              Center(
                child: Container(
                  width: isMobile ? constraints.maxWidth * 0.9 : 500,
                  // CAMBIO AQUÍ: Definimos un alto fijo para Web para que no crezca
                  height: isMobile ? null : 650,
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    // En móvil usamos el 85% de la pantalla para que no se corte por el teclado
                    maxHeight: isMobile ? constraints.maxHeight * 0.85 : 700,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
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
                  padding: EdgeInsets.all(isMobile ? 20.0 : 40.0),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // La columna interna se ajusta
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: isMobile ? 60 : 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.school, size: 60, color: myOrange),
                      ),
                      const SizedBox(height: 20),
                      _buildProgressIndicator(currentStep: 1),
                      const SizedBox(height: 20),
                      Text(
                        "Registro de Usuario",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 28,
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
                      const SizedBox(height: 15),

                      // EL SCROLL INTERNO AHORA SE COMERÁ EL ESPACIO DEL CALENDARIO
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: [
                              _buildResponsiveNameFields(isMobile),
                              const SizedBox(height: 20),
                              _buildFormField(
                                  "Fecha de Nacimiento",
                                  "Selecciona tu fecha",
                                  controller: _fechaController,
                                  errorText: _fechaError,
                                  icon: Icons.calendar_today_outlined,
                                  readOnly: true,
                                  onTap: () async {
                                    // Abre el DatePicker nativo de Flutter, mucho más amigable
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime(2005), // Año sugerido de inicio
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.light(
                                              primary: UColors.orangeDark, // Cambia el color del header al de tu app
                                              onPrimary: Colors.white,
                                              onSurface: Colors.black87,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );

                                    if (pickedDate != null) {
                                      setState(() {
                                        _fechaError = null; // Limpiamos el error
                                        // Formato YYYY-MM-DD recomendado por tu compañero de Base de Datos
                                        _fechaController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                      });
                                    }
                                  },
                                ),
                              if (_showCalendar) _buildCalendarWidget(),
                              const SizedBox(height: 20),
                              _buildFormField(
                                "Cédula de Identidad",
                                "Ej. 26123456",
                                controller: _cedulaController,
                                errorText: _cedulaError,
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(8),
                                ],
                                onChanged: (val) =>
                                    setState(() => _cedulaError = null),
                                onForbiddenCharacter: () => setState(
                                  () =>
                                      _cedulaError = "*Valor de campo inválido",
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      _buildNextButton(),

                      const SizedBox(height: 15),
                      const Divider(color: Colors.black12, indent: 40, endIndent: 40),
                      
                      // Link de Registro
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "¿Ya tienes cuenta? ",
                              style: TextStyle(color: Colors.black54, fontSize: 14),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Inicia Sesión',
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
              ),
            ],
          );
        },
      ),
    );
  }

  // Maneja el Row en Web y Column en Móvil para Nombre/Apellido
  Widget _buildResponsiveNameFields(bool isMobile) {
    List<Widget> fields = [
      Expanded(
        flex: isMobile ? 0 : 1,
        child: _buildFormField(
          "Nombre",
          "Ej. Juan",
          controller: _nombreController,
          errorText: _nombreError,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
            ),
          ],
          onChanged: (val) => setState(() => _nombreError = null),
          onForbiddenCharacter: () =>
              setState(() => _nombreError = "*Valor de campo inválido"),
        ),
      ),
      SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 20 : 0),
      Expanded(
        flex: isMobile ? 0 : 1,
        child: _buildFormField(
          "Apellido",
          "Ej. Pérez",
          controller: _apellidoController,
          errorText: _apellidoError,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
            ),
          ],
          onChanged: (val) => setState(() => _apellidoError = null),
          onForbiddenCharacter: () =>
              setState(() => _apellidoError = "*Valor de campo inválido"),
        ),
      ),
    ];

    return isMobile
        ? Column(
            children: fields
                .map((e) => e is Expanded ? (e).child : e)
                .toList(),
          )
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: fields);
  }

  Widget _buildCalendarWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: CalendarDatePicker(
        initialDate: _selectedDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        onDateChanged: (DateTime date) {
          setState(() {
            _selectedDate = date;
            _fechaController.text =
                "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
            _showCalendar = false;
          });
        },
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // Cambiamos el código interno por la llamada a la función corregida
        onPressed: _goToStep2, 
        style: ElevatedButton.styleFrom(
          backgroundColor: UColors.orangeDark,
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
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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

  Widget _buildFormField(
    String label,
    String hint, {
    required TextEditingController controller,
    String? errorText,
    IconData? icon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    VoidCallback? onTapOutside,
    VoidCallback? onForbiddenCharacter,
    Function(String)? onChanged,
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
        KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent && event.character != null) {
              if (label == "Nombre" || label == "Apellido") {
                if (RegExp(
                  r'[0-9!@#<>?":_`~;[\]\\|=+)(*&^%$]',
                ).hasMatch(event.character!)) {
                  onForbiddenCharacter?.call();
                }
              }
              if (label == "Cédula de Identidad") {
                if (!RegExp(r'[0-9]').hasMatch(event.character!)) {
                  onForbiddenCharacter?.call();
                }
              }
            }
          },
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            onTapOutside: (e) {
              FocusScope.of(context).unfocus();
              onTapOutside?.call();
            },
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              errorStyle: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
              ),
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 2.0,
                ),
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
        ),
      ],
    );
  }
}
