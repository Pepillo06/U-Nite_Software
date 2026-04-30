import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Estados de error
  String? _nombreError;
  String? _apellidoError;
  String? _cedulaError;

  bool _showCalendar = false;
  DateTime _selectedDate = DateTime.now();

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
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 700, // Altura máxima para que la tarjeta no se salga de la pantalla
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                  Image.asset(
                    'assets/logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.school, size: 60, color: myOrange),
                  ),
                  const SizedBox(height: 30),
                  _buildProgressIndicator(currentStep: 1),
                  const SizedBox(height: 20),
                  const Text(
                    "Registro de Usuario",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Para empezar, necesitamos conocerte un poco mejor.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // ESTA ES LA PARTE QUE HACE EL SCROLL INTERNO
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  "Nombre",
                                  "Ej. Juan",
                                  controller: _nombreController,
                                  errorText: _nombreError,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                                  ],
                                  onTapOutside: () => setState(() => _nombreError = null),
                                  onChanged: (val) => setState(() => _nombreError = null),
                                  onForbiddenCharacter: () {
                                    setState(() => _nombreError = "*Valor de campo inválido");
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildFormField(
                                  "Apellido",
                                  "Ej. Pérez",
                                  controller: _apellidoController,
                                  errorText: _apellidoError,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                                  ],
                                  onTapOutside: () => setState(() => _apellidoError = null),
                                  onChanged: (val) => setState(() => _apellidoError = null),
                                  onForbiddenCharacter: () {
                                    setState(() => _apellidoError = "*Valor de campo inválido");
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildFormField(
                            "Fecha de Nacimiento",
                            "dd/mm/yyyy",
                            controller: _fechaController,
                            icon: Icons.calendar_today_outlined,
                            readOnly: true,
                            onTap: () {
                              setState(() {
                                _showCalendar = !_showCalendar;
                              });
                            },
                          ),
                          if (_showCalendar)
                            Container(
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
                            ),
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
                            onTapOutside: () => setState(() => _cedulaError = null),
                            onChanged: (val) => setState(() => _cedulaError = null),
                            onForbiddenCharacter: () {
                              setState(() => _cedulaError = "*Valor de campo inválido");
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Botón Siguiente (Se mantiene fijo abajo de la tarjeta)
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Siguiente Paso", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ],
                      ),
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

  Widget _buildProgressIndicator({required int currentStep}) {
    const Color myBrown = Color(0xFFE05200);
    const Color myGreyInactive = Color(0xFFCFCFCF);
    Widget buildStepBar(int n) => Container(width: 60, height: 4, decoration: BoxDecoration(color: n == currentStep ? myBrown : myGreyInactive, borderRadius: BorderRadius.circular(2)));
    Widget buildStepLabel(String t, int n) => Text(t, style: TextStyle(color: n == currentStep ? myBrown : myGreyInactive, fontSize: 10, fontWeight: n == currentStep ? FontWeight.bold : FontWeight.normal));

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [buildStepBar(1), const SizedBox(width: 10), buildStepBar(2), const SizedBox(width: 10), buildStepBar(3)]),
        const SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [buildStepLabel("Paso 1 ", 1), const SizedBox(width: 30), buildStepLabel("  Paso 2", 2), const SizedBox(width: 30), buildStepLabel("   Paso 3", 3)]),
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (event) {
            if (event is RawKeyDownEvent && event.character != null) {
              if (label == "Nombre" || label == "Apellido") {
                if (RegExp(r'[0-9!@#<>?":_`~;[\]\\|=+)(*&^%$]').hasMatch(event.character!)) {
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
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.black12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.black12)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.redAccent, width: 2.0)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: myOrange, width: 1.5)),
              suffixIcon: icon != null ? Icon(icon, color: Colors.black38, size: 20) : null,
            ),
          ),
        ),
      ],
    );
  }
}