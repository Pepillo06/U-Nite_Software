import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/unite_header.dart';
import 'checkout_page.dart';

// ═══════════════════════════════════════════════════════
// MODELOS
// ═══════════════════════════════════════════════════════
class PlanModel {
  final String id;
  final String nombre;
  final double precioMensual;
  final double precioAnual;
  final List<PlanFeature> features;
  final bool esMasPopular;
  final Color borderColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color? buttonBorderColor;

  const PlanModel({
    required this.id,
    required this.nombre,
    required this.precioMensual,
    required this.precioAnual,
    required this.features,
    this.esMasPopular = false,
    required this.borderColor,
    required this.buttonColor,
    required this.buttonTextColor,
    this.buttonBorderColor,
  });
}

class PlanFeature {
  final String texto;
  final bool disponible;
  const PlanFeature(this.texto, {this.disponible = true});
}

// ═══════════════════════════════════════════════════════
// PÁGINA PRINCIPAL
// ═══════════════════════════════════════════════════════
class PremiumPlansPage extends StatefulWidget {
  const PremiumPlansPage({super.key});

  @override
  State<PremiumPlansPage> createState() => _PremiumPlansPageState();
}

class _PremiumPlansPageState extends State<PremiumPlansPage>
    with SingleTickerProviderStateMixin {
  bool _esAnual = true;
  String? _planActualId; // id del plan que el usuario ya tiene
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  static const _planes = [
    PlanModel(
      id: 'basico',
      nombre: 'Básico',
      precioMensual: 0,
      precioAnual: 0,
      borderColor: Color.fromARGB(255, 255, 255, 255),
      buttonColor: Colors.white,
      buttonTextColor: Color(0xFFFF6100),
      buttonBorderColor: Color(0xFFFF6100),
      features: [
        PlanFeature('Listados estándar'),
        PlanFeature('Chat comunitario'),
        PlanFeature('Listados destacados', disponible: false),
      ],
    ),
    PlanModel(
      id: 'pro',
      nombre: 'Estudiante Pro',
      precioMensual: 9.99,
      precioAnual: 7.99,
      esMasPopular: true,
      borderColor: Color(0xFFFF6100),
      buttonColor: Color(0xFFFF6100),
      buttonTextColor: Colors.white,
      features: [
        PlanFeature('5 listados destacados / mes'),
        PlanFeature('Badge "Vendedor Verificado"'),
        PlanFeature('Acceso anticipado a libros'),
        PlanFeature('Filtros Priority StudyMatch'),
      ],
    ),
    PlanModel(
      id: 'legend',
      nombre: 'Campus Legend',
      precioMensual: 19.99,
      precioAnual: 15.99,
      borderColor: Color.fromARGB(255, 255, 255, 255),
      buttonColor: Colors.white,
      buttonTextColor: Color(0xFFFF6100),
      buttonBorderColor: Color(0xFFFF6100),
      features: [
        PlanFeature('Listados destacados ilimitados'),
        PlanFeature('Badge Legend exclusivo'),
        PlanFeature('Soporte Prioritario 24/7'),
        PlanFeature('Cero comisiones de venta'),
        PlanFeature('Estadísticas avanzadas'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _cargarPlanActual();
  }

  // Consulta el último pago aprobado del usuario para saber su plan actual
  // Consulta el plan actual del usuario combinando es_premium + último pago
// Consulta el plan actual del usuario combinando es_premium + último pago
Future<void> _cargarPlanActual() async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  try {
    // 1. Verificar si el usuario es premium
    final userData = await supabase
        .from('usuarios')
        .select('es_premium')
        .eq('id', userId)
        .maybeSingle();

    final esPremium = userData?['es_premium'] == true;

    if (!esPremium) {
      // No es premium → plan básico
      if (mounted) setState(() => _planActualId = 'basico');
      return;
    }

    // 2. Sí es premium → buscar su último pago (aprobado o pendiente)
    //    "pendiente" puede existir porque el checkout lo activa antes de la revisión manual
    final data = await supabase
        .from('pagos_premium')
        .select('tipo_plan')
        .eq('usuario_id', userId)
        .inFilter('estado', ['aprobado', 'pendiente'])
        .order('creado_en', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data != null && mounted) {
      final tipoPlan = data['tipo_plan'] as String?;
      const map = {
        'Básico': 'basico',
        'Estudiante Pro': 'pro',
        'Campus Legend': 'legend',
      };
      setState(() => _planActualId = map[tipoPlan] ?? 'basico');
    } else if (mounted) {
      // Es premium pero no encontramos pago → asumir básico o pro por defecto
      setState(() => _planActualId = 'basico');
    }
  } catch (_) {
    if (mounted) setState(() => _planActualId = 'basico');
  }
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero ──
              _HeroSection(
                esAnual: _esAnual,
                onToggle: (v) => setState(() => _esAnual = v),
                isMobile: isMobile,
              ),

              const SizedBox(height: 24),

              // ── Cards ──
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    // Limita el ancho máximo en Web para que no se vean demasiado anchas
                    maxWidth: 1300, 
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : isTablet ? 24 : 48,
                    ),
                    child: isMobile
                        ? Column(
                            children: _planes
                                .map((p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: _PlanCard(
                                        plan: p,
                                        esAnual: _esAnual,
                                        onSeleccionar: () => _irAlCheckout(p),
                                        planActualId: _planActualId,
                                      ),
                                    ))
                                .toList(),
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _planes
                                  .map((p) => Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            left: p == _planes.first ? 0 : 12,
                                            right: p == _planes.last ? 0 : 12,
                                          ),
                                          child: _PlanCard(
                                            plan: p,
                                            esAnual: _esAnual,
                                            onSeleccionar: () => _irAlCheckout(p),
                                            planActualId: _planActualId,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 64),

              // ── Por qué ser Premium ──
              _WhyPremiumSection(isMobile: isMobile),

              const SizedBox(height: 64),

              // ── Footer ──
              _Footer(isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }

  void _irAlCheckout(PlanModel plan) {
    if (plan.id == 'basico') return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          planNombre: plan.nombre,
          monto: _esAnual ? plan.precioAnual : plan.precioMensual,
          esAnual: _esAnual,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// HERO SECTION
// ═══════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final bool esAnual;
  final ValueChanged<bool> onToggle;
  final bool isMobile;

  const _HeroSection({
    required this.esAnual,
    required this.onToggle,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, isMobile ? 40 : 72, 24, 0),
      child: Column(
        children: [
          Text(
            'Lleva tu experiencia al siguiente nivel',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: isMobile ? 28 : 44,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Únete a la comunidad premium de U-NITE y desbloquea herramientas\nexclusivas diseñadas para maximizar tu éxito académico y comercial en el campus.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          _BillingToggle(esAnual: esAnual, onToggle: onToggle),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TOGGLE MENSUAL / ANUAL
// ═══════════════════════════════════════════════════════
class _BillingToggle extends StatelessWidget {
  final bool esAnual;
  final ValueChanged<bool> onToggle;

  const _BillingToggle({required this.esAnual, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Mensual',
          style: GoogleFonts.lexend(
            fontSize: 15,
            fontWeight: !esAnual ? FontWeight.w700 : FontWeight.w400,
            color: !esAnual ? const Color(0xFF1A1A1A) : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => onToggle(!esAnual),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52,
            height: 28,
            decoration: BoxDecoration(
              color: esAnual ? const Color(0xFFFF6100) : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: esAnual ? 26 : 2,
                  top: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Text(
              'Anual',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: esAnual ? FontWeight.w700 : FontWeight.w400,
                color: esAnual ? const Color(0xFF1A1A1A) : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedOpacity(
              opacity: esAnual ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '-20%',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// CARD DE PLAN
// ═══════════════════════════════════════════════════════
class _PlanCard extends StatefulWidget {
  final PlanModel plan;
  final bool esAnual;
  final VoidCallback onSeleccionar;
  final String? planActualId;

  const _PlanCard({
    required this.plan,
    required this.esAnual,
    required this.onSeleccionar,
    this.planActualId,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.plan.id == 'legend') {
      return _LegendPlanCard(
        plan: widget.plan,
        esAnual: widget.esAnual,
        onSeleccionar: widget.onSeleccionar,
        planActualId: widget.planActualId,
      );
    }

    final precio = widget.esAnual
        ? widget.plan.precioAnual
        : widget.plan.precioMensual;
    final esPro = widget.plan.esMasPopular;
    final esPlanActual = widget.plan.id == (widget.planActualId ?? 'basico');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(
          0,
          _hovered ? -4 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esPlanActual
                ? const Color(0xFF22C55E)
                : esPro
                    ? const Color(0xFFFF6100)
                    : _hovered
                        ? const Color(0xFFFF6100).withOpacity(0.4)
                        : widget.plan.borderColor,
            width: esPro || esPlanActual ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: esPlanActual
                  ? const Color(0xFF22C55E).withOpacity(_hovered ? 0.15 : 0.08)
                  : esPro
                      ? const Color(0xFFFF6100).withOpacity(_hovered ? 0.18 : 0.10)
                      : Colors.black.withOpacity(_hovered ? 0.10 : 0.05),
              blurRadius: _hovered ? 24 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Parte superior (badge + contenido) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge "Más popular" o "Tu plan"
                if (esPro || esPlanActual)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(0, -14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: esPlanActual
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFFF6100),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (esPlanActual) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              esPlanActual ? 'TU PLAN' : 'MÁS POPULAR',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.fromLTRB(28, (esPro || esPlanActual) ? 8 : 28, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nombre
                      Text(
                        widget.plan.nombre,
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Precio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${precio == 0 ? '0' : precio.toStringAsFixed(2)}',
                            style: GoogleFonts.lexend(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: esPro
                                  ? const Color(0xFFFF6100)
                                  : const Color(0xFF1A1A1A),
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Text(
                              '/mes',
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (widget.esAnual && !esPlanActual) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Facturado anualmente',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Features
                      ...widget.plan.features.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                f.disponible
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.cancel_outlined,
                                size: 20,
                                color: f.disponible
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFD1D5DB),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  f.texto,
                                  style: GoogleFonts.lexend(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: f.disponible
                                        ? const Color(0xFF374151)
                                        : const Color(0xFFB0B7C3),
                                    decoration: f.disponible
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Botón (siempre al fondo) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
              child: _PlanButton(
                texto: esPlanActual ? 'Plan actual' : 'Seleccionar Plan',
                backgroundColor: widget.plan.buttonColor,
                textColor: widget.plan.buttonTextColor,
                borderColor: widget.plan.buttonBorderColor,
                esPrimario: esPro && !esPlanActual,
                esDeshabilitado: esPlanActual,
                onTap: widget.onSeleccionar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CAMPUS LEGEND — TARJETA PREMIUM CON ANIMACIONES
// ═══════════════════════════════════════════════════════
class _Particle {
  double x, y, size, speed, opacity, angle;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
  });
}

class _LegendPlanCard extends StatefulWidget {
  final PlanModel plan;
  final bool esAnual;
  final VoidCallback onSeleccionar;
  final String? planActualId;

  const _LegendPlanCard({
    required this.plan,
    required this.esAnual,
    required this.onSeleccionar,
    this.planActualId,
  });

  @override
  State<_LegendPlanCard> createState() => _LegendPlanCardState();
}

class _LegendPlanCardState extends State<_LegendPlanCard>
    with TickerProviderStateMixin {
  bool _hovered = false;

  late AnimationController _shimmerCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _borderCtrl;
  late Animation<double> _shimmerAnim;
  late Animation<double> _glowAnim;

  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random(42);

  static const _bgCard  = Color(0xFF181C24);
  static const _gold1   = Color(0xFFFFD060);
  static const _gold2   = Color(0xFFFF9500);
  static const _gold3   = Color(0xFFFFC040);
  static const _textPrim = Color(0xFFF5F0E8);
  static const _textSec  = Color(0xFF9A8F7A);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x:       _rng.nextDouble(),
        y:       _rng.nextDouble(),
        size:    1.2 + _rng.nextDouble() * 2.2,
        speed:   0.15 + _rng.nextDouble() * 0.25,
        opacity: 0.25 + _rng.nextDouble() * 0.55,
        angle:   _rng.nextDouble() * math.pi * 2,
      ));
    }
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _borderCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
    _glowAnim    = CurvedAnimation(parent: _glowCtrl,    curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _particleCtrl.dispose();
    _glowCtrl.dispose();
    _borderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final precio = widget.esAnual ? widget.plan.precioAnual : widget.plan.precioMensual;
    final esPlanActual = widget.plan.id == (widget.planActualId ?? 'basico');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        child: AnimatedBuilder(
          animation: Listenable.merge([_shimmerAnim, _particleCtrl, _glowAnim, _borderCtrl]),
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Glow exterior
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _gold2.withOpacity((_hovered ? 0.38 : 0.18) + _glowAnim.value * (_hovered ? 0.18 : 0.08)),
                          blurRadius: _hovered ? 40 : 22,
                          spreadRadius: _hovered ? 3 : 0,
                        ),
                        BoxShadow(
                          color: _gold1.withOpacity(0.07 + _glowAnim.value * 0.05),
                          blurRadius: 60,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                // Tarjeta
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(18)),
                    child: Stack(
                      children: [
                        // Fondo radial animado
                        Positioned.fill(child: CustomPaint(painter: _LegendBgPainter(shimmer: _shimmerAnim.value, glow: _glowAnim.value))),
                        // Partículas
                        Positioned.fill(child: CustomPaint(painter: _ParticlePainter(particles: _particles, progress: _particleCtrl.value, goldColor: _gold1))),
                        // Borde superior con shimmer
                        Positioned(top: 0, left: 0, right: 0, height: 2,
                          child: CustomPaint(painter: _ShimmerLinePainter(progress: _borderCtrl.value, color1: _gold1, color2: _gold2))),
                        // Contenido
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge "TU PLAN"
                                if (esPlanActual)
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Transform.translate(
                                      offset: const Offset(0, -14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 13),
                                            const SizedBox(width: 5),
                                            Text('TU PLAN', style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(28, esPlanActual ? 8 : 28, 28, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Label ÉLITE
                                      Row(children: [
                                        ShaderMask(
                                          shaderCallback: (b) => const LinearGradient(colors: [_gold1, _gold2]).createShader(b),
                                          child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                                        ),
                                        const SizedBox(width: 6),
                                        ShaderMask(
                                          shaderCallback: (b) => const LinearGradient(colors: [_gold1, _gold2]).createShader(b),
                                          child: Text('ÉLITE', style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.5)),
                                        ),
                                      ]),
                                      const SizedBox(height: 10),
                                      // Nombre
                                      Text(widget.plan.nombre, style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrim, height: 1.1)),
                                      const SizedBox(height: 10),
                                      // Precio con shimmer dorado
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (b) => LinearGradient(
                                              colors: [_gold1, _gold2, _gold3],
                                              stops: [
                                                (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                                                _shimmerAnim.value.clamp(0.0, 1.0),
                                                (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                                              ],
                                            ).createShader(b),
                                            child: Text(
                                              '\$${precio == 0 ? '0' : precio.toStringAsFixed(2)}',
                                              style: GoogleFonts.lexend(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 6, left: 5),
                                            child: Text('/mes', style: GoogleFonts.lexend(fontSize: 14, color: _textSec, fontWeight: FontWeight.w400)),
                                          ),
                                        ],
                                      ),
                                      if (widget.esAnual && !esPlanActual) ...[
                                        const SizedBox(height: 4),
                                        Text('Facturado anualmente', style: GoogleFonts.lexend(fontSize: 12, color: _textSec)),
                                      ],
                                      // Separador dorado
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.symmetric(vertical: 18),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [_gold2.withOpacity(0), _gold2.withOpacity(0.5), _gold2.withOpacity(0)]),
                                        ),
                                      ),
                                      // Features
                                      ...widget.plan.features.map((f) => Padding(
                                        padding: const EdgeInsets.only(bottom: 13),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ShaderMask(
                                              shaderCallback: (b) => const LinearGradient(colors: [_gold1, _gold2]).createShader(b),
                                              child: const Icon(Icons.check_circle_outline_rounded, size: 19, color: Colors.white),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(f.texto, style: GoogleFonts.lexend(fontSize: 13.5, fontWeight: FontWeight.w400, color: _textPrim.withOpacity(0.88), height: 1.35))),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Botón
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                              child: esPlanActual
                                  ? _LegendCurrentPlanButton()
                                  : _LegendSelectButton(hovered: _hovered, onTap: widget.onSeleccionar, shimmer: _shimmerAnim.value),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LegendBgPainter extends CustomPainter {
  final double shimmer, glow;
  _LegendBgPainter({required this.shimmer, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(r, Paint()..shader = RadialGradient(
      center: const Alignment(0.7, -0.6), radius: 1.1,
      colors: [const Color(0xFFFF9500).withOpacity(0.13 + glow * 0.07), const Color(0xFFFFD060).withOpacity(0.05 + glow * 0.03), Colors.transparent],
    ).createShader(r));
    canvas.drawRect(r, Paint()..shader = RadialGradient(
      center: const Alignment(-0.8, 0.9), radius: 0.8,
      colors: [const Color(0xFFFF6100).withOpacity(0.08 + glow * 0.04), Colors.transparent],
    ).createShader(r));
    final sx = -size.width * 0.4 + shimmer * size.width * 1.8;
    canvas.drawRect(r, Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Colors.transparent, const Color(0xFFFFD060).withOpacity(0.06), const Color(0xFFFFFFFF).withOpacity(0.04), const Color(0xFFFFD060).withOpacity(0.06), Colors.transparent],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    ).createShader(Rect.fromLTWH(sx, 0, size.width * 0.6, size.height)));
  }

  @override
  bool shouldRepaint(_LegendBgPainter old) => old.shimmer != shimmer || old.glow != glow;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color goldColor;
  _ParticlePainter({required this.particles, required this.progress, required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y - progress * p.speed) % 1.0;
      final dx = p.x + math.sin(progress * math.pi * 2 + p.angle) * 0.04;
      final px = dx.clamp(0.0, 1.0) * size.width;
      final py = (dy < 0 ? dy + 1.0 : dy) * size.height;
      canvas.drawCircle(
        Offset(px, py), p.size,
        Paint()..color = goldColor.withOpacity(p.opacity * (0.4 + 0.6 * math.sin(progress * math.pi * 2 + p.angle).abs())),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _ShimmerLinePainter extends CustomPainter {
  final double progress;
  final Color color1, color2;
  _ShimmerLinePainter({required this.progress, required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = progress * (size.width + size.width * 0.6) - size.width * 0.3;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = LinearGradient(
        colors: [Colors.transparent, color2.withOpacity(0.4), color1, color2.withOpacity(0.4), Colors.transparent],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(cx - 80, 0, 160, size.height)));
  }

  @override
  bool shouldRepaint(_ShimmerLinePainter old) => old.progress != progress;
}

class _LegendSelectButton extends StatefulWidget {
  final bool hovered;
  final VoidCallback onTap;
  final double shimmer;
  const _LegendSelectButton({required this.hovered, required this.onTap, required this.shimmer});

  @override
  State<_LegendSelectButton> createState() => _LegendSelectButtonState();
}

class _LegendSelectButtonState extends State<_LegendSelectButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 50,
          transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _pressed
                  ? [const Color(0xFFCC7000), const Color(0xFFAA5500)]
                  : widget.hovered
                      ? [const Color(0xFFFFE080), const Color(0xFFFFB830)]
                      : [const Color(0xFFFFD060), const Color(0xFFFF9500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF9500).withOpacity(widget.hovered ? 0.55 : 0.30), blurRadius: widget.hovered ? 22 : 12, offset: const Offset(0, 4)),
              BoxShadow(color: const Color(0xFFFFD060).withOpacity(widget.hovered ? 0.25 : 0.10), blurRadius: widget.hovered ? 35 : 10, spreadRadius: widget.hovered ? 2 : 0),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: _BtnShimmerPainter(progress: widget.shimmer),
                  child: Container(),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFF3D2000), size: 18),
                    const SizedBox(width: 8),
                    Text('Seleccionar Plan', style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF2D1800), letterSpacing: 0.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BtnShimmerPainter extends CustomPainter {
  final double progress;
  _BtnShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.5 + progress * size.width * 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = LinearGradient(
        colors: [Colors.transparent, Colors.white.withOpacity(0.22), Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x, 0, size.width * 0.5, size.height)));
  }

  @override
  bool shouldRepaint(_BtnShimmerPainter old) => old.progress != progress;
}

class _LegendCurrentPlanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
        color: const Color(0xFF22C55E).withOpacity(0.12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18),
          const SizedBox(width: 8),
          Text('Plan actual', style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF4ADE80))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BOTÓN DE PLAN
// ═══════════════════════════════════════════════════════
class _PlanButton extends StatefulWidget {
  final String texto;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool esPrimario;
  final bool esDeshabilitado;
  final VoidCallback onTap;

  const _PlanButton({
    required this.texto,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.esPrimario,
    required this.esDeshabilitado,
    required this.onTap,
  });

  @override
  State<_PlanButton> createState() => _PlanButtonState();
}

class _PlanButtonState extends State<_PlanButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = !widget.esDeshabilitado;
    final esPlanActual = widget.esDeshabilitado;

    // Si es "Plan actual", usamos estilo propio independiente del plan
    if (esPlanActual) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF22C55E),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22C55E),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Plan actual',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }

    final bgColor = _pressed
        ? const Color(0xFFCC4D00)
        : _hovered
            ? (widget.esPrimario
                ? const Color(0xFFE55A00)
                : const Color(0xFFFFF3EE))
            : widget.backgroundColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 1.5)
                : null,
            boxShadow: widget.esPrimario
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6100)
                          .withOpacity(_hovered ? 0.35 : 0.2),
                      blurRadius: _hovered ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.texto,
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: widget.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SECCIÓN "POR QUÉ SER PREMIUM"
// ═══════════════════════════════════════════════════════
class _WhyPremiumSection extends StatelessWidget {
  final bool isMobile;
  const _WhyPremiumSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48),
      child: isMobile
          ? Column(
              children: _buildCards(),
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildCards()
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: c,
                          ),
                        ))
                    .toList(),
              ),
            ),
    );
  }

  List<Widget> _buildCards() {
    return [
      _WhyCard(
        icono: Icons.emoji_events_outlined,
        iconColor: const Color(0xFF22C55E),
        bgColor: const Color(0xFFEFFFEA),
        titulo: '¿Por qué ser Premium?',
        descripcion:
            'Los usuarios premium de U-NITE venden sus productos un 65% más rápido gracias a la visibilidad prioritaria y generan una mayor confianza con sus insignias exclusivas de perfil.',
        esPrincipal: true,
      ),
      _WhyCard(
        icono: Icons.access_time_rounded,
        iconColor: const Color(0xFFFF6100),
        bgColor: Colors.white,
        titulo: 'Early Access',
        descripcion:
            'Recibe notificaciones 2 horas antes de que los libros de texto más buscados salgan al público general.',
      ),
      _WhyCard(
        icono: Icons.people_outline_rounded,
        iconColor: const Color(0xFF6366F1),
        bgColor: Colors.white,
        titulo: 'StudyMatch',
        descripcion:
            'Filtra compañeros de estudio por promedio, carrera y disponibilidad horaria de forma exacta.',
      ),
    ];
  }
}

class _WhyCard extends StatefulWidget {
  final IconData icono;
  final Color iconColor;
  final Color bgColor;
  final String titulo;
  final String descripcion;
  final bool esPrincipal;

  const _WhyCard({
    required this.icono,
    required this.iconColor,
    required this.bgColor,
    required this.titulo,
    required this.descripcion,
    this.esPrincipal = false,
  });

  @override
  State<_WhyCard> createState() => _WhyCardState();
}

class _WhyCardState extends State<_WhyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(28),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.iconColor.withOpacity(0.4)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.iconColor
                  .withOpacity(_hovered ? 0.12 : 0.04),
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icono, color: widget.iconColor, size: 32),
            const SizedBox(height: 16),
            Text(
              widget.titulo,
              style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: widget.esPrincipal
                    ? const Color(0xFF166534)
                    : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.descripcion,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: widget.esPrincipal
                    ? const Color(0xFF166534)
                    : const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final bool isMobile;
  const _Footer({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 28,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: isMobile
          ? Column(
              children: [
                Text(
                  'U-NITE',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '© 2024 U-NITE Campus Marketplace',
                  style: GoogleFonts.lexend(
                      fontSize: 12, color: const Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  children: ['Terms', 'Privacy', 'Support', 'Contact']
                      .map((t) => Text(
                            t,
                            style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: const Color(0xFF6B7280)),
                          ))
                      .toList(),
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  'U-NITE',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                Text(
                  '© 2024 U-NITE Campus Marketplace',
                  style: GoogleFonts.lexend(
                      fontSize: 12, color: const Color(0xFF9CA3AF)),
                ),
                const Spacer(),
                Row(
                  children: ['Terms', 'Privacy', 'Support', 'Contact']
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(
                              t,
                              style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280)),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
    );
  }
}