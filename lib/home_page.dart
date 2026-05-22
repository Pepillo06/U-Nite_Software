import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui'; // Necesario para el efecto de Blur
import 'login_page.dart';
import 'register_page.dart';
import 'theme.dart';
import 'market.dart';

// ═══════════════════════════════════════════════════════════════
//  HOME PAGE
// ═══════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UColors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Navbar(),
            _HeroSection(),
            _WhyUNITESection(),
            _CatalogSection(),
            _StudyGroupSection(),
            _RentalSection(),
            _CTASection(),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  NAVBAR
// ═══════════════════════════════════════════════════════════════
class _Navbar extends StatelessWidget {
  const _Navbar();

  @override
  Widget build(BuildContext context) {
    // Detectamos si es una pantalla pequeña (menos de 600px)
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: UColors.white,
      // Reducimos el padding horizontal en móvil (de 40 a 15)
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 15 : 40,
        vertical: 16,
      ),
      child: Row(
        children: [
          // Logo: En móvil ocultamos el texto del logo si es muy pequeño para ganar espacio
          Row(
            children: [
              Image.asset(
                'images/Logo_U-NITE_SoloU.png',
                height: isMobile ? 35 : 45,
              ),
              if (!isMobile) // Solo muestra el texto del logo en pantallas grandes
                Image.asset('images/Logo_texto_U-NITE.png', height: 20),
            ],
          ),

          const Spacer(),

          // Iniciar Sesión: Ajustamos padding y tamaño de letra
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              // Padding dinámico: más pequeño en móvil
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 10 : 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Iniciar Sesión',
              style: TextStyle(
                color: UColors.textDark,
                fontWeight: FontWeight.w700,
                // Fuente más pequeña en móvil
                fontSize: isMobile ? 13 : 15,
              ),
            ),
          ),

          // Entrar como invitado
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketPage()),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 10 : 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Entrar como invitado',
              style: TextStyle(
                color: UColors.orange,
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 13 : 15,
              ),
            ),
          ),

          SizedBox(width: isMobile ? 4 : 12),

          // Registrarse: Ya tiene lógica responsiva interna
          UButtonPrimary(
            text: 'Registrarse',
            style: UButtonStyle.green,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HERO SECTION
// ═══════════════════════════════════════════════════════════════
// Mantenemos tu clase principal pero con el "Switch"
class _HeroSection extends StatefulWidget {
  const _HeroSection();

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  final PageController _pageController = PageController(initialPage: 1000);
  int _virtualPage = 1000;
  Timer? _timer;

  final List<Map<String, dynamic>> slides = [
    {
      'badge': 'COMUNIDAD UNIVERSITARIA',
      'badgeColor': const Color.fromARGB(195, 170, 212, 150),
      'badgeTextColor': UColors.greenDark,
      'titlePart1': 'Conecta con tu ',
      'titlePart2': 'Campus',
      'description':
          'Descubre compañeros, únete a grupos de estudio y mantente al día con todo lo que sucede en la comunidad U-NITE.',
      'image': 'images/hero_students.png',
      'btnColor': UColors.orange,
    },
    {
      'badge': 'MARKETPLACE EXCLUSIVO',
      'badgeColor': const Color.fromARGB(134, 255, 166, 133),
      'badgeTextColor': UColors.orange,
      'titlePart1': 'Tu ',
      'titlePart2': 'Marketplace Universitario',
      'description':
          'La red exclusiva para comprar, vender, alquilar e intercambiar entre estudiantes de forma segura y sencilla.',
      'image': 'images/hero_notebook.png',
      'btnColor': UColors.greenDark,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (Timer timer) {
      _virtualPage++;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _virtualPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AQUÍ EL SWITCH: Detectamos el ancho
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Stack(
      children: [
        SizedBox(
          // En móvil le damos un poco más de altura total para que quepa todo en vertical
          height: isMobile ? 750 : 600,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _virtualPage = page),
            itemBuilder: (context, index) {
              final slide = slides[index % slides.length];
              // Decidimos qué constructor usar según el dispositivo
              return isMobile
                  ? _buildMobileSlide(slide)
                  : _buildWebSlide(slide);
            },
          ),
        ),
        // Flechas (opcional ocultarlas en móvil si prefieren swipe)
        if (!isMobile) ...[
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: _NavButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: _NavButton(
              icon: Icons.arrow_forward_ios,
              onTap: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- TU CÓDIGO ACTUAL (VERSIÓN WEB) INTACTO ---
  Widget _buildWebSlide(Map<String, dynamic> slide) {
    final Color primaryColor = slide['btnColor'];
    final Color secondaryColor = primaryColor == UColors.orange
        ? UColors.greenDark
        : UColors.orange;
    final UButtonStyle currentButtonStyle =
        (slide['btnColor'].value == UColors.orange.value)
        ? UButtonStyle.orange
        : UButtonStyle.green;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            primaryColor.withOpacity(0.30),
            primaryColor.withOpacity(0),
            secondaryColor.withOpacity(0.30),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 70),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _buildTextContent(
              slide,
              currentButtonStyle,
              isMobile: false,
            ),
          ),
          const SizedBox(width: 40),
          Expanded(flex: 5, child: _buildImageContent(slide, isMobile: false)),
        ],
      ),
    );
  }

  // --- NUEVA VERSIÓN MÓVIL ---
  Widget _buildMobileSlide(Map<String, dynamic> slide) {
    final Color primaryColor = slide['btnColor'];
    final UButtonStyle currentButtonStyle =
        (slide['btnColor'].value == UColors.orange.value)
        ? UButtonStyle.orange
        : UButtonStyle.green;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, // Gradiente de arriba a abajo en móvil
          end: Alignment.bottomCenter,
          colors: [primaryColor.withOpacity(0.30), Colors.white],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // En móvil, primero el texto y luego la imagen (o viceversa)
          _buildTextContent(slide, currentButtonStyle, isMobile: true),
          const SizedBox(height: 40),
          _buildImageContent(slide, isMobile: true),
        ],
      ),
    );
  }

  // Métodos auxiliares para no repetir código de widgets internos
  Widget _buildTextContent(
    Map<String, dynamic> slide,
    UButtonStyle style, {
    required bool isMobile,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: slide['badgeColor'],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            slide['badge'],
            style: GoogleFonts.lexend(
              color: slide['badgeTextColor'],
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 25),
        RichText(
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          text: TextSpan(
            style: GoogleFonts.lexend(
              color: UColors.textDark,
              fontSize: isMobile ? 32 : 50,
              height: 1.1,
            ),
            children: [
              TextSpan(text: slide['titlePart1']),
              TextSpan(
                text: slide['titlePart2'],
                style: TextStyle(color: slide['btnColor']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          slide['description'],
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.lexend(
            color: UColors.textGray,
            fontSize: isMobile ? 15 : 17,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 35),
        Row(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            UButtonPrimary(
              text: 'Empezar',
              style: style,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
            const SizedBox(width: 12),
            UButtonSecondary(text: 'Saber más', style: style, onPressed: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildImageContent(
    Map<String, dynamic> slide, {
    required bool isMobile,
  }) {
    return SizedBox(
      height: isMobile ? 250 : 450,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(
          slide['image'],
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: slide['btnColor'].withOpacity(0.1),
            child: Icon(Icons.image, color: slide['btnColor'], size: 50),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WHY U-NITE SECTION
// ═══════════════════════════════════════════════════════════════
class _WhyUNITESection extends StatelessWidget {
  const _WhyUNITESection();

  @override
  Widget build(BuildContext context) {
    // Ya no necesitamos la variable isMobile para el alineamiento si queremos todo centrado

    return Container(
      color: UColors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            // 1. CAMBIAMOS ESTO A CENTER PARA TODO (WEB Y MÓVIL)
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- TÍTULO ---
              const Text(
                '¿Por qué usar U-NITE?',
                // 2. FORZAMOS EL CENTRADO DEL TEXTO
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: UColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 12),

              // --- LÍNEA NARANJA ---
              // Al estar en una Column con CrossAxisAlignment.center,
              // el Container se centrará automáticamente.
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: UColors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 50),

              // --- FILA DE TARJETAS ---
              Wrap(
                spacing: 30,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: [
                  // ... tus ConstrainedBox con las _FeatureCard (se mantienen igual)
                  _buildCard(
                    iconData: Icons.shield_rounded,
                    iconBg: const Color(0xFFD4EDDA),
                    iconColor: const Color(0xFF2E7D32),
                    title: 'Seguridad',
                    description:
                        'Transacciones protegidas y sistema de reputación interna para que compres y vendas con total tranquilidad.',
                  ),
                  _buildCard(
                    iconData: Icons.savings_rounded,
                    iconBg: const Color(0xFFD6E4FF),
                    iconColor: UColors.blueIcon,
                    title: 'Ahorro',
                    description:
                        'Precios pensados para estudiantes. Encuentra materiales y gadgets a una fracción de su costo original.',
                  ),
                  _buildCard(
                    iconData: Icons.groups_rounded,
                    iconBg: const Color(0xFFFFEDD8),
                    iconColor: UColors.orange,
                    title: 'Grupos de Estudio',
                    description:
                        'Encuentra compañeros para tus materias y únete a grupos de estudio específicos de tu facultad.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pequeña función auxiliar para no repetir tanto código de las tarjetas
  Widget _buildCard({
    required IconData iconData,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: _FeatureCard(
        iconData: iconData,
        iconBg: iconBg,
        iconColor: iconColor,
        title: title,
        description: description,
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData iconData;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;

  const _FeatureCard({
    required this.iconData,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  // Variable para controlar si el mouse está encima
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    // MouseRegion detecta el movimiento del ratón
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click, // Cambia el puntero a una mano
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 250,
        ), // Duración de la transición
        curve: Curves.easeOutCubic, // Curva de animación fluida
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
        // EFECTO DE ESCALA Y POSICIÓN
        transform: isHovered
            ? (Matrix4.identity()
                ..translate(0, -12, 0)
                ..scale(1.03))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: UColors.white,
          borderRadius: BorderRadius.circular(
            20,
          ), // Un poco más redondeado se ve más moderno
          boxShadow: [
            BoxShadow(
              // Si hay hover, la sombra es más grande y suave
              color: isHovered
                  ? Colors.black.withOpacity(0.12)
                  : Colors.black.withOpacity(0.07),
              blurRadius: isHovered ? 30 : 20,
              offset: isHovered ? const Offset(0, 15) : const Offset(0, 4),
            ),
          ],
          // El borde se vuelve sutilmente más oscuro en hover
          border: Border.all(
            color: isHovered
                ? UColors.greenDark.withOpacity(0.3)
                : UColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono con animación sutil de escala
            AnimatedScale(
              duration: const Duration(milliseconds: 250),
              scale: isHovered ? 1.1 : 1.0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.iconData, color: widget.iconColor, size: 28),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: UColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: UColors.textGray,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CATALOG SECTION
// ═══════════════════════════════════════════════════════════════
class _CatalogSection extends StatelessWidget {
  const _CatalogSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: UColors.decoracionVignette,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 20
            : 40, // Reducimos un poco el padding lateral en Web para pegar más las tarjetas al borde
        vertical: 60,
      ),
      child: Center(
        // Center para que el ConstrainedBox funcione
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1300,
          ), // Aumentamos de 900 a 1200 para dar más aire en Web
          child: Column(
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                'EXPLORA EL CAMPUS',
                style: GoogleFonts.lexend(
                  color: UColors.textGray,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              isMobile
                  ? Column(
                      children: [
                        _titleText(),
                        const SizedBox(height: 10),
                        _viewAllButton(),
                      ],
                    )
                  : Row(
                      children: [
                        _titleText(),
                        const Spacer(),
                        _viewAllButton(),
                      ],
                    ),

              const SizedBox(height: 40),

              Center(
                child: Wrap(
                  spacing: 30, // Más espacio horizontal entre tarjetas en Web
                  runSpacing: 30,
                  alignment: WrapAlignment.center,
                  children: const [
                    _ProductCard(
                      imageAsset: 'images/catalog_books.jpg',
                      category: 'Libros',
                      title: 'Ecuaciones Diferenciales',
                      price: '\$10.00',
                      location: 'Campus Norte',
                    ),
                    _ProductCard(
                      imageAsset: 'images/catalog_laptop.jpg',
                      category: 'Electrónica',
                      title: 'Laptop Ultrabook 13"',
                      price: '\$500.00',
                      location: 'Facultad de Ingeniería',
                    ),
                    _ProductCard(
                      imageAsset: 'images/catalog_calculator.jpg',
                      category: 'Accesorios',
                      title: 'Calculadora Gráfica TI-84',
                      price: '\$50.00',
                      location: 'Campus Sur',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleText() {
    return const Center(
      // Agrega este Center
      child: Text(
        'Lo que puedes encontrar',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: UColors.textDark,
          fontWeight: FontWeight.w900,
          fontSize: 32,
        ),
      ),
    );
  }

  Widget _viewAllButton() {
    return TextButton.icon(
      onPressed: () {},
      icon: const Text(
        'Ver todo el catálogo',
        style: TextStyle(
          color: UColors.orange,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      label: const Icon(Icons.arrow_forward, color: UColors.orange, size: 20),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final String imageAsset;
  final String category;
  final String title;
  final String price;
  final String location;

  const _ProductCard({
    required this.imageAsset,
    required this.category,
    required this.title,
    required this.price,
    required this.location,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    // --- CAMBIO EN EL TAMAÑO ---
    // En Web ahora miden 350px de ancho para verse más imponentes
    final double cardWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.85
        : 350;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: cardWidth,
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            20,
          ), // Un poco más redondeado para el nuevo tamaño
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.06),
              blurRadius: _isHovered ? 25 : 18,
              offset: _isHovered ? const Offset(0, 15) : const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: isMobile
                        ? 220
                        : 260, // Aumentamos la altura de la imagen en Web
                    width: double.infinity,
                    child: Image.asset(widget.imageAsset, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.category,
                      style: const TextStyle(
                        color: UColors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20), // Más padding interno
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w800, // Un poco más de grosor
                      fontSize: 18, // Texto más grande
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.price,
                    style: const TextStyle(
                      color: UColors.orange,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STUDY GROUP SECTION
// ═══════════════════════════════════════════════════════════════
class _StudyGroupSection extends StatelessWidget {
  const _StudyGroupSection();

  @override
  Widget build(BuildContext context) {
    // Detectamos si es pantalla móvil
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      decoration: UColors.decoracionVignette,
      // Ajustamos el padding: menos horizontal en móvil
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 25 : 60,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          // Si es móvil usamos Column, si es Web usamos Row
          child: isMobile
              ? Column(
                  children: [
                    _buildImage(isMobile),
                    const SizedBox(height: 40),
                    _buildTextContent(isMobile),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: _buildImage(isMobile)),
                    const SizedBox(width: 60),
                    Expanded(flex: 5, child: _buildTextContent(isMobile)),
                  ],
                ),
        ),
      ),
    );
  }

  // Widget de imagen separado para mayor limpieza
  Widget _buildImage(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: isMobile ? 300 : 380, // Un poco más baja en móvil
        width: double.infinity,
        child: Image.asset(
          'images/study_group.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFFFDE8E0),
            child: const Icon(Icons.groups, size: 50, color: UColors.orange),
          ),
        ),
      ),
    );
  }

  // Widget de texto separado
  Widget _buildTextContent(bool isMobile) {
    return Column(
      // Centramos el texto si es móvil
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge "ACADEMIC PULSE"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFDE8E0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: UColors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.school_outlined, size: 14, color: UColors.orange),
              SizedBox(width: 6),
              Text(
                'ACADEMIC PULSE',
                style: TextStyle(
                  color: UColors.orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text(
          'Encuentra a tu equipo de estudio',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: UColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: isMobile ? 28 : 36, // Un poco más pequeño en móvil
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No estudies solo. Conéctate con compañeros de tu misma facultad, comparte recursos y prepárate para tus exámenes en conjunto. La red académica más grande de tu campus.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: UColors.textGray,
            fontSize: isMobile ? 15 : 16,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 35),
        // El botón ahora se ve mejor centrado en móvil
        UButtonPrimary(
          text: 'Explorar grupos',
          icon: Icons.group_add,
          onPressed: () {},
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RENTAL SECTION
// ═══════════════════════════════════════════════════════════════
class _RentalSection extends StatefulWidget {
  const _RentalSection();

  @override
  State<_RentalSection> createState() => _RentalSectionState();
}

class _RentalSectionState extends State<_RentalSection> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _rentalItems = [
    {'image': 'images/rental_camera.jpg', 'icon': Icons.camera_alt_outlined},
    {'image': 'images/rental_calculator.png', 'icon': Icons.calculate_outlined},
    {'image': 'images/rental_labcoat.png', 'icon': Icons.science_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(
          () => _currentIndex = (_currentIndex + 1) % _rentalItems.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 950;
    final currentItem = _rentalItems[_currentIndex];

    return Container(
      // Padding exterior que se ajusta en móvil
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: 80,
      ),
      child: Container(
        // En móvil dejamos que la altura sea automática (flexible)
        height: isMobile ? null : 550,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 30 : 40),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [UColors.greenDark, Color(0xFF2E6300)],
          ),
          boxShadow: [
            BoxShadow(
              color: UColors.greenDark.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 30 : 40),
          child: Stack(
            children: [
              // --- ICONO DE FONDO ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: Align(
                  key: ValueKey('bg_icon_$_currentIndex'),
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: isMobile
                        ? const Offset(-30, -30)
                        : const Offset(-60, -60),
                    child: Icon(
                      currentItem['icon'],
                      size: isMobile ? 250 : 400,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
              ),

              // --- CONTENIDO PRINCIPAL ---
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 30 : 70,
                  vertical: isMobile ? 40 : 0,
                ),
                child: isMobile
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPhotoStack(currentItem, isMobile),
                          const SizedBox(height: 40),
                          _buildTextContent(isMobile),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 5, child: _buildTextContent(isMobile)),
                          const SizedBox(width: 60),
                          Expanded(
                            flex: 5,
                            child: _buildPhotoStack(currentItem, isMobile),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget de Textos separado
  Widget _buildTextContent(bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBadge(),
        const SizedBox(height: 25),
        Text(
          '¿Lo necesitas solo por un trimestre?\nAlquila.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: isMobile ? 28 : 38,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Ya no tienes que comprar todo. Alquila cámaras, calculadoras, batas o diversos materiales de otros compañeros. Flexible y directo.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        UButtonPrimary(
          text: 'Ver opciones de alquiler',
          style: UButtonStyle.green,
          icon: Icons.auto_awesome_motion_outlined,
          onPressed: () {},
        ),
      ],
    );
  }

  // Widget del Stack de fotos animado
  Widget _buildPhotoStack(Map<String, dynamic> currentItem, bool isMobile) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        switchInCurve: Curves.easeOutQuart,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isEntering = child.key == ValueKey('image_$_currentIndex');

          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              double blur = (1 - animation.value) * 12;
              double slide = isEntering
                  ? (1 - animation.value) * 100
                  : (animation.value - 1) * 100;

              return Opacity(
                opacity: animation.value,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translate(slide)
                      ..scale(0.85 + (animation.value * 0.15)),
                    child: child,
                  ),
                ),
              );
            },
          );
        },
        child: _buildPhotoCard(currentItem['image'], isMobile),
      ),
    );
  }

  Widget _buildPhotoCard(String imagePath, bool isMobile) {
    return Container(
      key: ValueKey('image_$_currentIndex'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(
          imagePath,
          height: isMobile ? 280 : 420, // Altura ajustada para móvil
          width: isMobile ? double.infinity : 600,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            height: isMobile ? 280 : 420,
            color: Colors.white10,
            child: const Icon(Icons.image, color: Colors.white24, size: 50),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Text(
        'NUEVO: ALQUILER FLEX',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CTA SECTION
// ═══════════════════════════════════════════════════════════════
class _CTASection extends StatelessWidget {
  const _CTASection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 25 : 60,
        vertical: 80,
      ),
      child: Column(
        children: [
          Text(
            '¿Listo para unirte a tu comunidad?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: UColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: isMobile ? 28 : 36, // Un poco más pequeño en móvil
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isMobile
                ? 'Crea tu cuenta hoy mismo y empieza a ahorrar mientras conectas con miles de estudiantes.'
                : 'Crea tu cuenta hoy mismo y empieza a ahorrar\nmientras conectas con miles de estudiantes.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UColors.textGray,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          UButtonPrimary(
            text: 'Crear cuenta',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
          ),
          const SizedBox(height: 30),

          // --- SOLUCIÓN AL OVERFLOW DE BADGES ---
          isMobile
              ? Column(
                  // En móvil, uno sobre otro
                  children: const [
                    _CheckBadge(text: 'Verificación rápida'),
                    SizedBox(height: 12),
                    _CheckBadge(text: 'Sin comisiones ocultas'),
                  ],
                )
              : Row(
                  // En web, uno al lado del otro
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _CheckBadge(text: 'Verificación rápida'),
                    SizedBox(width: 24),
                    _CheckBadge(text: 'Sin comisiones ocultas'),
                  ],
                ),
        ],
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  final String text;
  const _CheckBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min, // Importante para que Column no los estire
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF4CAF50),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: UColors.textGray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FOOTER
// ═══════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    return Container(
      color: const Color(0xFFF8F8F8),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 30 : 60,
        vertical: 40,
      ),
      child: Column(
        // Usamos Column como base
        children: [
          isMobile
              ? Column(
                  // DISEÑO MÓVIL
                  children: [
                    _buildBrand(),
                    const SizedBox(height: 30),
                    _buildLinks(isMobile),
                    const SizedBox(height: 30),
                    _buildIcons(),
                  ],
                )
              : Row(
                  // DISEÑO WEB
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrand(),
                    const Spacer(),
                    _buildLinks(isMobile),
                    const SizedBox(width: 32),
                    _buildIcons(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'U-NITE',
          style: TextStyle(
            color: UColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '© 2026 U-NITE. El marketplace exclusivo para\ntu comunidad universitaria.',
          style: TextStyle(color: UColors.textGray, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLinks(bool isMobile) {
    // Si es móvil, usamos un Wrap para que los links no se desborden
    return Wrap(
      alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
      spacing: 20,
      runSpacing: 10,
      children: const [
        _FooterLink('Privacidad'),
        _FooterLink('Términos de Uso'),
        _FooterLink('Centro de Ayuda'),
        _FooterLink('Contacto'),
      ],
    );
  }

  Widget _buildIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _FooterIcon(Icons.share_outlined),
        const SizedBox(width: 12),
        _FooterIcon(Icons.language_outlined),
      ],
    );
  }
}

// Widgets de apoyo (Sin cambios necesarios, solo limpieza)
class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: UColors.textGray,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FooterIcon extends StatelessWidget {
  final IconData icon;
  const _FooterIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        color: Colors.white,
      ),
      child: Icon(icon, size: 16, color: UColors.textGray),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPER — placeholder cuando no está la imagen
// ═══════════════════════════════════════════════════════════════
// Widget _imagePlaceholder(String name, Color bg) {
//   return Container(
//     color: bg,
//     child: Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.image_outlined, color: Colors.white54, size: 36),
//           const SizedBox(height: 8),
//           Text(
//             name,
//             style: const TextStyle(color: Colors.white70, fontSize: 11),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     ),
//   );
// }

// ═══════════════════════════════════════════════════════════════
//  WIDGETS DE BOTONES MULTICOLOR (Naranja y Verde)
// ═══════════════════════════════════════════════════════════════

// 1. Definición del Enum para que no de error en 'style'
enum UButtonStyle { orange, green }

// 2. BOTÓN PRIMARIO (CORREGIDO)
class UButtonPrimary extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final UButtonStyle style;
  final IconData? icon;

  const UButtonPrimary({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = UButtonStyle.orange,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Detectamos el ancho para ajustar tamaños
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 600;

    final List<Color> colors = style == UButtonStyle.orange
        ? [const Color(0xFFE8521A), const Color(0xFFFF8E53)]
        : [const Color(0xFF245000), const Color(0xFF4CAF7D)];

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 300,
      ), // Evita que crezca demasiado
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: colors),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 20 : 35,
                vertical: isSmall ? 10 : 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: isSmall ? 18 : 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    // <--- Esto evita el overflow
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        fontSize: isSmall ? 13 : 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 3. BOTÓN SECUNDARIO (CORREGIDO)
class UButtonSecondary extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final UButtonStyle style;
  final IconData? icon;

  const UButtonSecondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = UButtonStyle.orange,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 600;

    final List<Color> gradientColors = style == UButtonStyle.orange
        ? [const Color(0xFFE8521A), const Color(0xFFFF8E53)]
        : [const Color(0xFF245000), const Color(0xFF4CAF7D)];

    return CustomPaint(
      painter: GradientOutlinePainter(
        gradient: LinearGradient(colors: gradientColors),
        radius: 30,
        strokeWidth: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 30,
              vertical: isSmall ? 9 : 11,
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: gradientColors,
              ).createShader(Offset.zero & bounds.size),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: isSmall ? 18 : 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    // <--- Esto evita el overflow
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: isSmall ? 13 : 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 4. EL PAINTER (Necesario para el borde del botón secundario)
class GradientOutlinePainter extends CustomPainter {
  final LinearGradient gradient;
  final double radius;
  final double strokeWidth;

  GradientOutlinePainter({
    required this.gradient,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Offset.zero & size;
    RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        icon: Icon(icon, color: UColors.textGray.withOpacity(0.5), size: 30),
        onPressed: onTap,
      ),
    );
  }
}
