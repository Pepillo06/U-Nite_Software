import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/unite_header.dart';
import '../market.dart';

// ═══════════════════════════════════════════════════════
// CHECKOUT PAGE
// ═══════════════════════════════════════════════════════
class CheckoutPage extends StatefulWidget {
  final String planNombre;
  final double monto;
  final bool esAnual;

  const CheckoutPage({
    super.key,
    required this.planNombre,
    required this.monto,
    required this.esAnual,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {
  final _fechaController = TextEditingController();
  final _celularController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _referenciaController = TextEditingController();
  String _bancoSeleccionado = 'Banesco';
  String _prefijoCelular = '0412';
  bool _enviando = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Datos banco receptor (ficticios/demo)
  static const _bancoDatos = {
    'banco': 'Banesco',
    'cedula': 'V-12.345.678',
    'telefono': '0412-1234567',
  };

  static const _bancos = [
    'Banesco',
    'Banco de Venezuela',
    'Mercantil',
    'BBVA Provincial',
    'Banco Nacional de Crédito (BNC)',
    'Bicentenario del Pueblo',
    'Banco del Tesoro',
    'Banco Exterior',
    'Banco Caroní',
    'Banco Fondo Común (BFC)',
    'Banco Activo',
    'Bancamiga',
    'Banco de la Fuerza Armada (BANFANB)',
    'Banco Agrícola de Venezuela',
    'Banco del Libro',
    'Banco Venezolano de Crédito',
    'Banco Plaza',
    'Banplus',
    'Citibank Venezuela',
    'Delsur Banco Universal',
    'Helm Bank Venezuela',
    'Institución financiera Mi Banco',
    'Sofitasa Banco Universal',
    'Banco 100% Banco',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fechaController.dispose();
    _celularController.dispose();
    _cedulaController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  void _copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copiado al portapapeles',
          style: GoogleFonts.lexend(fontSize: 13),
        ),
        backgroundColor: const Color(0xFFFF6100),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _finalizar() async {
    // Validaciones básicas
    if (_fechaController.text.isEmpty ||
        _celularController.text.isEmpty ||
        _cedulaController.text.isEmpty ||
        _referenciaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor, completa todos los campos.',
            style: GoogleFonts.lexend(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) throw Exception('Usuario no autenticado');

      // Parsear fecha (formato mm/dd/yyyy → yyyy-mm-dd para Postgres)
      final partes = _fechaController.text.split('/');
      final fechaIso =
          '${partes[2]}-${partes[0].padLeft(2, '0')}-${partes[1].padLeft(2, '0')}';

      // 1. Insertar el registro en pagos_premium
      await supabase.from('pagos_premium').insert({
        'usuario_id': userId,
        'tipo_plan': widget.planNombre,
        'es_anual': widget.esAnual,
        'monto': widget.monto,
        'fecha_pago': fechaIso,
        'banco_origen': _bancoSeleccionado,
        'prefijo_celular': _prefijoCelular,
        'celular_emisor': _celularController.text.trim(),
        'cedula_emisor': _cedulaController.text.trim(),
        'ultimos4_ref': _referenciaController.text.trim(),
        'estado': 'pendiente',
      });

      // 2. Activar es_premium = true en la tabla usuarios
      //    (El equipo también puede aprobarlo manualmente via aprobar_pago_premium())
      await supabase
          .from('usuarios')
          .update({'es_premium': true}).eq('id', userId);

      if (!mounted) return;
      setState(() => _enviando = false);

      showDialog(
        context: context,
        builder: (_) => _ConfirmacionDialog(
          planNombre: widget.planNombre,
          onIrAlInicio: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MarketPage()),
              (route) => false,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al procesar el pago: ${e.toString()}',
            style: GoogleFonts.lexend(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: const UniteHeader(currentIndex: -1),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : isTablet ? 32 : 64,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Volver
                _VolverButton(onTap: () => Navigator.pop(context)),
                const SizedBox(height: 24),

                // Título
                Text(
                  'Finaliza tu suscripción Premium',
                  style: GoogleFonts.lexend(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Completa los detalles de tu pago móvil para activar los beneficios universitarios.',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 32),

                // Layout principal
                isMobile
                    ? Column(
                        children: [
                          _DatosTransferenciaCard(
                            datos: _bancoDatos,
                            onCopiar: _copiar,
                          ),
                          const SizedBox(height: 20),
                          _ReportarPagoCard(
                            fechaController: _fechaController,
                            celularController: _celularController,
                            cedulaController: _cedulaController,
                            referenciaController: _referenciaController,
                            monto: widget.monto,
                            bancoSeleccionado: _bancoSeleccionado,
                            bancos: _bancos,
                            onBancoChanged: (b) =>
                                setState(() => _bancoSeleccionado = b!),
                            prefijoCelular: _prefijoCelular,
                            onPrefijoChanged: (p) =>
                                setState(() => _prefijoCelular = p!),
                          ),
                          const SizedBox(height: 20),
                          _ResumenOrdenCard(
                            planNombre: widget.planNombre,
                            monto: widget.monto,
                            esAnual: widget.esAnual,
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: _FinalizarButton(
                                enviando: _enviando,
                                onTap: _finalizar,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Al confirmar, nuestro equipo validará el pago en un máximo de 2 horas.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Izquierda: datos transferencia
                          Expanded(
                            flex: 3,
                            child: _DatosTransferenciaCard(
                              datos: _bancoDatos,
                              onCopiar: _copiar,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Centro: reportar pago
                          Expanded(
                            flex: 4,
                            child: _ReportarPagoCard(
                              fechaController: _fechaController,
                              celularController: _celularController,
                              cedulaController: _cedulaController,
                              referenciaController: _referenciaController,
                              monto: widget.monto,
                              bancoSeleccionado: _bancoSeleccionado,
                              bancos: _bancos,
                              onBancoChanged: (b) =>
                                  setState(() => _bancoSeleccionado = b!),
                              prefijoCelular: _prefijoCelular,
                              onPrefijoChanged: (p) =>
                                  setState(() => _prefijoCelular = p!),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Derecha: resumen + botón finalizar (debajo de Soporte 24/7)
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _ResumenOrdenCard(
                                  planNombre: widget.planNombre,
                                  monto: widget.monto,
                                  esAnual: widget.esAnual,
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 380),
                                    child: _FinalizarButton(
                                      enviando: _enviando,
                                      onTap: _finalizar,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    'Al confirmar, nuestro equipo validará el pago en un máximo de 2 horas.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lexend(
                                      fontSize: 12,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BADGE SSL
// ═══════════════════════════════════════════════════════
class _SslBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined,
              size: 14, color: Color(0xFF22C55E)),
          const SizedBox(width: 5),
          Text(
            'ENCRIPTADO SSL',
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF22C55E),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// VOLVER BUTTON
// ═══════════════════════════════════════════════════════
class _VolverButton extends StatefulWidget {
  final VoidCallback onTap;
  const _VolverButton({required this.onTap});

  @override
  State<_VolverButton> createState() => _VolverButtonState();
}

class _VolverButtonState extends State<_VolverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSlide(
              offset: Offset(_hovered ? -0.15 : 0, 0),
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: _hovered
                    ? const Color(0xFFFF6100)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Volver al plan',
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: _hovered
                    ? const Color(0xFFFF6100)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CARD: DATOS PARA TRANSFERIR
// ═══════════════════════════════════════════════════════
class _DatosTransferenciaCard extends StatelessWidget {
  final Map<String, String> datos;
  final void Function(String) onCopiar;

  const _DatosTransferenciaCard({
    required this.datos,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icono: Icons.account_balance_outlined,
            iconBg: const Color(0xFFFFF0E8),
            iconColor: const Color(0xFFFF6100),
            titulo: 'Datos para Transferir',
          ),
          const SizedBox(height: 20),

          _DatoItem(
            label: 'BANCO',
            valor: datos['banco']!,
          ),
          const SizedBox(height: 12),
          _DatoItem(
            label: 'CÉDULA / RIF',
            valor: datos['cedula']!,
            copiable: true,
            onCopiar: () => onCopiar(datos['cedula']!),
          ),
          const SizedBox(height: 12),
          _DatoItem(
            label: 'TELÉFONO',
            valor: datos['telefono']!,
            copiable: true,
            onCopiar: () => onCopiar(datos['telefono']!),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF22C55E).withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFF22C55E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recuerda realizar el pago antes de llenar el formulario de reporte.',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: const Color(0xFF166534),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoItem extends StatefulWidget {
  final String label;
  final String valor;
  final bool copiable;
  final VoidCallback? onCopiar;

  const _DatoItem({
    required this.label,
    required this.valor,
    this.copiable = false,
    this.onCopiar,
  });

  @override
  State<_DatoItem> createState() => _DatoItemState();
}

class _DatoItemState extends State<_DatoItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) =>
          widget.copiable ? setState(() => _hovered = true) : null,
      onExit: (_) =>
          widget.copiable ? setState(() => _hovered = false) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFFF8F5) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered
                ? const Color(0xFFFF6100).withOpacity(0.3)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.lexend(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.valor,
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            if (widget.copiable)
              GestureDetector(
                onTap: widget.onCopiar,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? const Color(0xFFFF6100).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.copy_outlined,
                    size: 18,
                    color: _hovered
                        ? const Color(0xFFFF6100)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CARD: REPORTAR PAGO
// ═══════════════════════════════════════════════════════
class _ReportarPagoCard extends StatelessWidget {
  final TextEditingController fechaController;
  final TextEditingController celularController;
  final TextEditingController cedulaController;
  final TextEditingController referenciaController;
  final double monto;
  final String bancoSeleccionado;
  final List<String> bancos;
  final ValueChanged<String?> onBancoChanged;
  final String prefijoCelular;
  final ValueChanged<String?> onPrefijoChanged;

  const _ReportarPagoCard({
    required this.fechaController,
    required this.celularController,
    required this.cedulaController,
    required this.referenciaController,
    required this.monto,
    required this.bancoSeleccionado,
    required this.bancos,
    required this.onBancoChanged,
    required this.prefijoCelular,
    required this.onPrefijoChanged,
  });

  // Prefijos venezolanos válidos
  static const _prefijos = [
    '0412', '0414', '0416', '0424', '0426',
  ];

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icono: Icons.receipt_long_outlined,
            iconBg: const Color(0xFFEEFFEE),
            iconColor: const Color(0xFF22C55E),
            titulo: 'Reportar Pago',
          ),
          const SizedBox(height: 20),

          _CheckoutLabel('FECHA DE PAGO'),
          const SizedBox(height: 6),
          _DateInput(controller: fechaController),

          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CELULAR con prefijo dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CheckoutLabel('CELULAR EMISOR'),
                    const SizedBox(height: 6),
                    _CelularInput(
                      controller: celularController,
                      prefijo: prefijoCelular,
                      prefijos: _prefijos,
                      onPrefijoChanged: onPrefijoChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // CÉDULA: solo números, máx 8 dígitos (cédula venezolana)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CheckoutLabel('CÉDULA EMISOR'),
                    const SizedBox(height: 6),
                    _OrangeInput(
                      controller: cedulaController,
                      hint: '12345678',
                      maxLength: 8,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _CheckoutLabel('MONTO (USD/BS.)'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE0C8)),
            ),
            child: Text(
              '\$${monto.toStringAsFixed(2)}',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF6100),
              ),
            ),
          ),

          const SizedBox(height: 16),
          _CheckoutLabel('BANCO DE ORIGEN'),
          const SizedBox(height: 6),
          _BancoDropdown(
            bancos: bancos,
            seleccionado: bancoSeleccionado,
            onChanged: onBancoChanged,
          ),

          const SizedBox(height: 16),
          _CheckoutLabel('ÚLTIMOS 4 DÍGITOS DE REFERENCIA'),
          const SizedBox(height: 6),
          _OrangeInput(
            controller: referenciaController,
            hint: '0000',
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CARD: RESUMEN DE ORDEN
// ═══════════════════════════════════════════════════════
class _ResumenOrdenCard extends StatelessWidget {
  final String planNombre;
  final double monto;
  final bool esAnual;

  const _ResumenOrdenCard({
    required this.planNombre,
    required this.monto,
    required this.esAnual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Imagen banner (placeholder con gradiente)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PREMIUM PLUS',
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Text(
                    'U-NITE Elite',
                    style: GoogleFonts.lexend(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Decoración abstracta
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6100).withOpacity(0.15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _CheckoutCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESUMEN DE LA ORDEN',
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),

              _ResumenItem(
                icono: Icons.check_circle_outline,
                iconColor: const Color(0xFFFF6100),
                label: 'Ventas ilimitadas',
                valor: 'Incluido',
              ),
              const SizedBox(height: 10),
              _ResumenItem(
                icono: Icons.bolt_outlined,
                iconColor: const Color(0xFFEAB308),
                label: 'Bump de visibilidad',
                valor: 'Incluido',
              ),
              const SizedBox(height: 10),
              _ResumenItem(
                icono: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF6366F1),
                label: 'Chat prioritario',
                valor: 'Incluido',
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                    height: 1, color: const Color(0xFFE5E7EB)),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL A PAGAR',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${monto.toStringAsFixed(2)}',
                    style: GoogleFonts.lexend(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      esAnual ? '/semestre' : '/mes',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _CheckoutCard(
          child: Column(
            children: [
              _TrustItem(
                icono: Icons.security_outlined,
                titulo: 'Transacción Protegida',
                subtitulo: 'Validación manual de seguridad.',
              ),
              const SizedBox(height: 12),
              _TrustItem(
                icono: Icons.headset_mic_outlined,
                titulo: 'Soporte 24/7',
                subtitulo: 'Ayuda inmediata via Campus Support.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final IconData icono;
  final Color iconColor;
  final String label;
  final String valor;

  const _ResumenItem({
    required this.icono,
    required this.iconColor,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        Text(
          valor,
          style: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const _TrustItem({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, size: 18, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            Text(
              subtitulo,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// BOTÓN FINALIZAR
// ═══════════════════════════════════════════════════════
class _FinalizarButton extends StatefulWidget {
  final bool enviando;
  final VoidCallback onTap;

  const _FinalizarButton({required this.enviando, required this.onTap});

  @override
  State<_FinalizarButton> createState() => _FinalizarButtonState();
}

class _FinalizarButtonState extends State<_FinalizarButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = _pressed
        ? const Color(0xFFCC4D00)
        : _hovered
            ? const Color(0xFFE55A00)
            : const Color(0xFFFF6100);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (!widget.enviando) widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6100)
                    .withOpacity(_hovered ? 0.35 : 0.2),
                blurRadius: _hovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.enviando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Finalizar Suscripción',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════
class _CheckoutCard extends StatelessWidget {
  final Widget child;
  const _CheckoutCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icono;
  final Color iconBg;
  final Color iconColor;
  final String titulo;

  const _CardHeader({
    required this.icono,
    required this.iconBg,
    required this.iconColor,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          titulo,
          style: GoogleFonts.lexend(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _CheckoutLabel extends StatelessWidget {
  final String text;
  const _CheckoutLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.lexend(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }
}

// Input con efecto naranja al focus
class _OrangeInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _OrangeInput({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<_OrangeInput> createState() => _OrangeInputState();
}

class _OrangeInputState extends State<_OrangeInput> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6100).withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        style: GoogleFonts.lexend(
          fontSize: 14,
          color: const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.lexend(
            fontSize: 14,
            color: const Color(0xFFD1D5DB),
          ),
          counterText: '',
          filled: true,
          fillColor: _focused
              ? const Color(0xFFFFFBF8)
              : const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFFF6100), width: 2),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CELULAR INPUT con prefijo dropdown
// ═══════════════════════════════════════════════════════
class _CelularInput extends StatefulWidget {
  final TextEditingController controller;
  final String prefijo;
  final List<String> prefijos;
  final ValueChanged<String?> onPrefijoChanged;

  const _CelularInput({
    required this.controller,
    required this.prefijo,
    required this.prefijos,
    required this.onPrefijoChanged,
  });

  @override
  State<_CelularInput> createState() => _CelularInputState();
}

class _CelularInputState extends State<_CelularInput> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Un número venezolano tiene 11 dígitos en total (ej. 0412-1234567)
    // Los 4 primeros los pone el dropdown, quedan 7 para escribir
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6100).withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          // Dropdown prefijo
          Container(
            decoration: BoxDecoration(
              color: _focused
                  ? const Color(0xFFFFFBF8)
                  : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              border: Border(
                top: BorderSide(
                  color: _focused
                      ? const Color(0xFFFF6100)
                      : const Color(0xFFE5E7EB),
                  width: _focused ? 2 : 1,
                ),
                left: BorderSide(
                  color: _focused
                      ? const Color(0xFFFF6100)
                      : const Color(0xFFE5E7EB),
                  width: _focused ? 2 : 1,
                ),
                bottom: BorderSide(
                  color: _focused
                      ? const Color(0xFFFF6100)
                      : const Color(0xFFE5E7EB),
                  width: _focused ? 2 : 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.prefijo,
                onChanged: widget.onPrefijoChanged,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: Color(0xFF6B7280)),
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
                items: widget.prefijos
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p,
                              style: GoogleFonts.lexend(fontSize: 13)),
                        ))
                    .toList(),
              ),
            ),
          ),
          // Divisor
          Container(
            width: 1,
            height: 48,
            color: _focused
                ? const Color(0xFFFF6100).withOpacity(0.4)
                : const Color(0xFFE5E7EB),
          ),
          // Campo numérico (7 dígitos restantes)
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              maxLength: 7,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: const Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: '1234567',
                hintStyle: GoogleFonts.lexend(
                  fontSize: 14,
                  color: const Color(0xFFD1D5DB),
                ),
                counterText: '',
                filled: true,
                fillColor: _focused
                    ? const Color(0xFFFFFBF8)
                    : const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF6100), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Date input
class _DateInput extends StatefulWidget {
  final TextEditingController controller;
  const _DateInput({required this.controller});

  @override
  State<_DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<_DateInput> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF6100),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      widget.controller.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6100).withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        readOnly: true,
        onTap: () => _pickDate(context),
        style: GoogleFonts.lexend(fontSize: 14, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: 'mm/dd/yyyy',
          hintStyle: GoogleFonts.lexend(
              fontSize: 14, color: const Color(0xFFD1D5DB)),
          suffixIcon: const Icon(Icons.calendar_today_outlined,
              size: 18, color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor:
              _focused ? const Color(0xFFFFFBF8) : const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFFF6100), width: 2),
          ),
        ),
      ),
    );
  }
}

// Dropdown de bancos
class _BancoDropdown extends StatefulWidget {
  final List<String> bancos;
  final String seleccionado;
  final ValueChanged<String?> onChanged;

  const _BancoDropdown({
    required this.bancos,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  State<_BancoDropdown> createState() => _BancoDropdownState();
}

class _BancoDropdownState extends State<_BancoDropdown> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6100).withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: DropdownButtonFormField<String>(
          value: widget.seleccionado,
          onChanged: widget.onChanged,
          style: GoogleFonts.lexend(
              fontSize: 14, color: const Color(0xFF1A1A1A)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280)),
          decoration: InputDecoration(
            filled: true,
            fillColor:
                _focused ? const Color(0xFFFFFBF8) : const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFFF6100), width: 2),
            ),
          ),
          items: widget.bancos
              .map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b,
                        style: GoogleFonts.lexend(fontSize: 14)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// DIALOG DE CONFIRMACIÓN — animado, verde, tamaño controlado
// ═══════════════════════════════════════════════════════
class _ConfirmacionDialog extends StatefulWidget {
  final String planNombre;
  final VoidCallback onIrAlInicio;
  const _ConfirmacionDialog({required this.planNombre, required this.onIrAlInicio});

  @override
  State<_ConfirmacionDialog> createState() => _ConfirmacionDialogState();
}

class _ConfirmacionDialogState extends State<_ConfirmacionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _checkAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _checkAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.75, curve: Curves.elasticOut),
    );
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono animado con check verde
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo exterior decorativo (halo)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFDCFCE7),
                        ),
                      ),
                      // Círculo interior
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                      // Check animado
                      ScaleTransition(
                        scale: _checkAnim,
                        child: const Icon(
                          Icons.check_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Título con slide + fade
                AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: FadeTransition(opacity: _fadeAnim, child: child),
                  ),
                  child: Text(
                    '¡Pago reportado!',
                    style: GoogleFonts.lexend(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value * 1.3),
                    child: FadeTransition(opacity: _fadeAnim, child: child),
                  ),
                  child: Text(
                    'Tu pago para el plan ${widget.planNombre} fue recibido correctamente. Nuestro equipo lo validará en las próximas 2 horas.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Chip de estado verde
                AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (_, child) =>
                      ScaleTransition(scale: _scaleAnim, child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Text(
                          'Validación en máx. 2 horas',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Botón ir al inicio — verde
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el diálogo
                      widget.onIrAlInicio();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.hovered)
                            ? const Color(0xFF16A34A).withOpacity(0.15)
                            : null,
                      ),
                    ),
                    child: Text(
                      'Ir al inicio',
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}