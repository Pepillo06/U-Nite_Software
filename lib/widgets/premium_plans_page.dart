import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  const _PlanCard({
    required this.plan,
    required this.esAnual,
    required this.onSeleccionar,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final precio = widget.esAnual
        ? widget.plan.precioAnual
        : widget.plan.precioMensual;
    final esPro = widget.plan.esMasPopular;
    final esBasico = widget.plan.id == 'basico';

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
            color: esPro
                ? const Color(0xFFFF6100)
                : _hovered
                    ? const Color(0xFFFF6100).withOpacity(0.4)
                    : widget.plan.borderColor,
            width: esPro ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: esPro
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
                // Badge "Más popular"
                if (esPro)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(0, -14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6100),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'MÁS POPULAR',
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.fromLTRB(28, esPro ? 8 : 28, 28, 0),
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

                      if (widget.esAnual && !esBasico) ...[
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
                texto: esBasico ? 'Plan actual' : 'Seleccionar Plan',
                backgroundColor: widget.plan.buttonColor,
                textColor: widget.plan.buttonTextColor,
                borderColor: widget.plan.buttonBorderColor,
                esPrimario: esPro,
                esDeshabilitado: esBasico,
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
    final bgColor = _pressed && isActive
        ? const Color(0xFFCC4D00)
        : _hovered && isActive
            ? (widget.esPrimario
                ? const Color(0xFFE55A00)
                : const Color(0xFFFFF3EE))
            : widget.backgroundColor;

    return MouseRegion(
      cursor: isActive
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => isActive ? setState(() => _pressed = true) : null,
        onTapUp: (_) {
          if (isActive) {
            setState(() => _pressed = false);
            widget.onTap();
          }
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
            boxShadow: widget.esPrimario && isActive
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