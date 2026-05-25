import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'market.dart';
import 'package:flutter/services.dart';

// Definición de tipos de transacción
enum TransactionType { venta, alquiler, trueque }

class PublicarArticuloPage extends StatefulWidget {
  const PublicarArticuloPage({super.key});

  @override
  State<PublicarArticuloPage> createState() => _PublicarArticuloPageState();
}

class _PublicarArticuloPageState extends State<PublicarArticuloPage> {
  final Set<TransactionType> _selectedTypes = {TransactionType.venta};
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List<Map<String, dynamic>> _rentalOptions = [
    {'controller': TextEditingController(), 'unit': 'Día'},
  ];
  final TextEditingController _tradeForController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<Uint8List> _selectedImages = [];

  String? _selectedCategory;
  String? _selectedCondition;
  bool _campusPickup = true;
  bool _isLoading = false;
  bool _acceptsTrade = false;
  String? _titleError;
  String? _descriptionError;
  String? _priceError;
  bool _isHoveringPublicar = false;
  bool _isPressingPublicar = false;
  String? _pressingCondition;
  String? _hoveringInput; // para rastrear cuál input tiene hover
  final Map<String, FocusNode> _focusNodes = {}; // para rastrear foco por label
  final FocusNode _costoPorDiaFocusNode = FocusNode();
  TransactionType? _hoveringTab;
  TransactionType? _pressingTab;

  String _mapCondicion(String condicion) {
    switch (condicion) {
      case 'Nuevo':
        return 'Nuevo';
      case 'Como nuevo':
        return 'Usado - Como nuevo';
      case 'Bueno':
        return 'Usado - Buen estado';
      case 'Regular':
        return 'Regular';
      default:
        return condicion;
    }
  }

  Future<void> _publicarArticulo() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para publicar.')),
      );
      return;
    }

    bool hasError = false;

    if (_titleController.text.trim().isEmpty) {
      setState(
        () => _titleError = 'El nombre del artículo no puede estar vacío.',
      );
      hasError = true;
    } else {
      setState(() => _titleError = null);
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(
        () => _descriptionError = 'La descripción no puede estar vacía.',
      );
      hasError = true;
    } else {
      setState(() => _descriptionError = null);
    }

    if (_selectedTypes.contains(TransactionType.venta)) {
      final priceText = _priceController.text.trim();
      final price = double.tryParse(priceText);
      if (priceText.isEmpty || price == null || price < 0) {
        setState(
          () => _priceError = 'Ingresa un precio válido (número positivo).',
        );
        hasError = true;
      } else {
        setState(() => _priceError = null);
      }
    } else {
      setState(() => _priceError = null);
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      // 1. Subir imágenes al storage de Supabase
      final List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        try {
          final bytes = _selectedImages[i];
          final path =
              '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await supabase.storage
              .from('foto_producto')
              .uploadBinary(path, bytes);
          final url = supabase.storage.from('foto_producto').getPublicUrl(path);
          imageUrls.add(url);
        } catch (_) {
          // Si el bucket no existe o falla, simplemente no se agrega la imagen
        }
      }

      // 2. Construir el JSON de modalidades
      final Map<String, dynamic> modalidades = {};
      if (_selectedTypes.contains(TransactionType.venta)) {
        modalidades['venta'] = {
          'precio': double.tryParse(_priceController.text) ?? 0.0,
        };
      }
      if (_selectedTypes.contains(TransactionType.alquiler)) {
        modalidades['alquiler'] = _rentalOptions
            .map(
              (opt) => {
                'costo': double.tryParse(opt['controller'].text) ?? 0.0,
                'unidad_tiempo': opt['unit'],
              },
            )
            .toList();
      }
      if (_acceptsTrade) {
        modalidades['trueque'] = {
          'descripcion': _tradeForController.text.trim(),
        };
      }
      modalidades['campus_pickup'] = _campusPickup;
      modalidades['imagenes'] = imageUrls;

      // 3. Insertar el anuncio en la tabla
      await supabase.from('anuncios_marketplace').insert({
        'vendedor_id': user.id,
        'titulo': _titleController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
        'categoria': _selectedCategory,
        'estado_producto': _selectedCondition != null
            ? _mapCondicion(_selectedCondition!)
            : null,
        'disponible': true,
        'fecha_publicacion': DateTime.now().toIso8601String(),
        'detalles_modalidades': modalidades,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Artículo publicado exitosamente!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al publicar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _costoPorDiaFocusNode.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definición de colores basada en home_page.dart
    const Color primaryOrange = Color(0xFFF25A22);
    const Color background = Color(0xFFFBFBFB);
    const Color darkText = Color(0xFF2E3137);
    const Color unselectedGrey = Color(0xFFDCDDDE);
    const Color headerOliveGreen = Color(0xFF5F6F5A);
    const Color borderInput = Color(0xFFE3BFB1);
    const Color unselectedConditionBg = Color(0xFFF0F0F0);
    const Color activeGreen = Color(0xFFA5DC86); // Para el badge de activo
    // Estilos de texto
    const TextStyle headerStyle = TextStyle(
      fontSize: 36,
      //fontFamily: 'Urbanist',
      fontWeight: FontWeight.bold,
      color: darkText,
      letterSpacing: -1,
    );
    const TextStyle descriptionHeaderStyle = TextStyle(
      fontSize: 16,
      //fontFamily: 'Lexend',
      color: headerOliveGreen,
      height: 1.4,
    );
    const TextStyle labelStyle = TextStyle(
      fontSize: 14,
      //fontFamily: 'Outfit',
      color: Color(0xFF8F7065),
      fontWeight: FontWeight.bold,
    );
    const TextStyle inputStyle = TextStyle(
      fontSize: 16,
      //fontFamily: 'Outfit',
      color: darkText,
      height: 1.3,
    );

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              // Agregamos Center para que en Web quede al medio
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 60.0,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isDesktop = constraints.maxWidth > 900;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título principal
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Crear artículo', style: headerStyle),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isDesktop
                                      ? constraints.maxWidth * 0.6
                                      : constraints.maxWidth,
                                ),
                                child: const Text(
                                  'Completa los detalles para publicar en tu comunidad universitaria.',
                                  style: descriptionHeaderStyle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60),

                          // Diseño Responsivo principal
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: buildMainForm(
                                    headerStyle,
                                    descriptionHeaderStyle,
                                    labelStyle,
                                    inputStyle,
                                    primaryOrange,
                                    darkText,
                                    borderInput,
                                    unselectedConditionBg,
                                    background,
                                  ),
                                ),
                                const SizedBox(width: 50),
                                Expanded(
                                  flex: 2,
                                  child: buildRightPanel(
                                    labelStyle,
                                    primaryOrange,
                                    darkText,
                                    unselectedGrey,
                                    background,
                                    activeGreen,
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                buildMainForm(
                                  headerStyle,
                                  descriptionHeaderStyle,
                                  labelStyle,
                                  inputStyle,
                                  primaryOrange,
                                  darkText,
                                  borderInput,
                                  unselectedConditionBg,
                                  background,
                                ),
                                const SizedBox(height: 40),
                                buildRightPanel(
                                  labelStyle,
                                  primaryOrange,
                                  darkText,
                                  unselectedGrey,
                                  background,
                                  activeGreen,
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MarketPage()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2E3137),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMainForm(
    TextStyle headerStyle,
    TextStyle descriptionHeaderStyle,
    TextStyle labelStyle,
    TextStyle inputStyle,
    Color primaryOrange,
    Color darkText,
    Color borderInput,
    Color unselectedConditionBg,
    Color background,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab Bar Custom
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    buildTabItem(
                      'Venta',
                      TransactionType.venta,
                      primaryOrange,
                      darkText,
                      background,
                    ),
                    buildTabItem(
                      'Alquiler',
                      TransactionType.alquiler,
                      primaryOrange,
                      darkText,
                      background,
                    ),
                    buildTabItem(
                      'Trueque',
                      TransactionType.trueque,
                      primaryOrange,
                      darkText,
                      background,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Campo Título
              buildInputField(
                labelStyle,
                inputStyle,
                borderInput,
                'Título',
                controller: _titleController,
                hintText: '¿Qué estás ofreciendo?',
                errorText: _titleError,
              ),
              const SizedBox(height: 20),

              // Campos Categoría y Precio (Dinamico)
              // Campos Categoría y Precio (Dinamico)
              Row(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Importante para que Categoría no se centre al añadir campos
                children: [
                  Expanded(
                    flex: 1, // Le damos 1/3 del espacio
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Categoría', style: labelStyle),
                        const SizedBox(height: 5),
                        buildDropdownInput(
                          borderInput,
                          inputStyle,
                          'Seleccionar',
                          value: _selectedCategory,
                          items: [
                            'Libros',
                            'Herramientas',
                            'Accesorios',
                            'Electrónica',
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          },
                          hoverKey: 'Categoría',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Panel de precio dinámico según el tipo de transacción
                  if (_selectedTypes.contains(TransactionType.venta) ||
                      _selectedTypes.contains(TransactionType.alquiler))
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Input de Venta ---
                          if (_selectedTypes.contains(
                            TransactionType.venta,
                          )) ...[
                            buildInputField(
                              labelStyle,
                              inputStyle,
                              borderInput,
                              'Precio fijo para venta',
                              controller: _priceController,
                              hintText: '\$ 0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              errorText: _priceError, // ← AGREGA ESTO
                              inputFormatters: [
                                // ← AGREGA ESTO
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                            ),
                            if (_selectedTypes.contains(
                              TransactionType.alquiler,
                            ))
                              const SizedBox(height: 15),
                          ],

                          // --- Inputs de Alquiler ---
                          if (_selectedTypes.contains(TransactionType.alquiler))
                            ...List.generate(_rentalOptions.length, (index) {
                              bool isFirst = index == 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Columna de Costo
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (isFirst) ...[
                                            Text(
                                              'Costo por Día',
                                              style: labelStyle,
                                            ),
                                            const SizedBox(height: 5),
                                          ],
                                          MouseRegion(
                                            onEnter: (_) => setState(
                                              () => _hoveringInput =
                                                  'costo_$index',
                                            ),
                                            onExit: (_) => setState(() {
                                              if (_hoveringInput ==
                                                  'costo_$index')
                                                _hoveringInput = null;
                                            }),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 130,
                                              ),
                                              curve: Curves.easeOut,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color:
                                                      _costoPorDiaFocusNode
                                                          .hasFocus
                                                      ? const Color(0xFFF25A22)
                                                      : _hoveringInput ==
                                                            'costo_$index'
                                                      ? const Color(
                                                          0xFFE3BFB1,
                                                        ).withValues(alpha: 0.8)
                                                      : borderInput,
                                                  width:
                                                      _costoPorDiaFocusNode
                                                          .hasFocus
                                                      ? 1.8
                                                      : 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow:
                                                    _costoPorDiaFocusNode
                                                        .hasFocus
                                                    ? [
                                                        BoxShadow(
                                                          color:
                                                              const Color(
                                                                0xFFF25A22,
                                                              ).withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 15,
                                                  ),
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller:
                                                          _rentalOptions[index]['controller'],
                                                      focusNode:
                                                          _costoPorDiaFocusNode,
                                                      style: inputStyle,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration: InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        hintText: '\$ 0.00',
                                                        hintStyle: inputStyle
                                                            .copyWith(
                                                              color:
                                                                  const Color(
                                                                    0xFF8C95A3,
                                                                  ),
                                                            ),
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
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
                                    const SizedBox(width: 10),

                                    // Columna de Unidad
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (isFirst) ...[
                                            Text('Unidad', style: labelStyle),
                                            const SizedBox(height: 5),
                                          ],
                                          SizedBox(
                                            height: 48,
                                            child: buildDropdownInput(
                                              borderInput,
                                              inputStyle,
                                              'Seleccionar',
                                              value:
                                                  _rentalOptions[index]['unit'],
                                              items: [
                                                'Día',
                                                'Hora',
                                                'Semana',
                                                'Mes',
                                              ],
                                              onChanged: (val) {
                                                setState(() {
                                                  _rentalOptions[index]['unit'] =
                                                      val;
                                                });
                                              },
                                              hoverKey: 'Unidad_$index',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Botón + o Papelera
                                    Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: isFirst
                                          ? GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _rentalOptions.add({
                                                    'controller':
                                                        TextEditingController(),
                                                    'unit': 'Hora',
                                                  });
                                                });
                                              },
                                              child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: Container(
                                                  width: 25,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF2D4B03,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _rentalOptions.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                              child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: const SizedBox(
                                                  width: 25,
                                                  height: 25,
                                                  child: Center(
                                                    child: FaIcon(
                                                      FontAwesomeIcons.trashCan,
                                                      color: Color(0xFF8F7065),
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Switch de Aceptar Trueque
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderInput),
                ),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: primaryOrange, size: 24),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aceptar trueque',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2E3137),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Activa esta opción si estás dispuesto a recibir otros artículos como intercambio.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _acceptsTrade,
                      activeColor: primaryOrange,
                      onChanged: (val) {
                        setState(() {
                          _acceptsTrade = val;
                          if (val) {
                            _selectedTypes.add(TransactionType.trueque);
                          } else {
                            _selectedTypes.remove(TransactionType.trueque);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Campo de Intereses de Trueque dinámico
              if (_acceptsTrade) ...[
                buildInputField(
                  labelStyle,
                  inputStyle,
                  borderInput,
                  'Intereses de trueque (Cosas de interés)',
                  controller: _tradeForController,
                  hintText: '¿Qué te interesaría recibir a cambio?',
                ),
                const SizedBox(height: 20),
              ],

              // Campo Descripción
              buildInputField(
                labelStyle,
                inputStyle,
                borderInput,
                'Descripción',
                controller: _descriptionController,
                hintText:
                    'Cuéntanos más sobre el artículo que estás ofreciendo...',
                maxLines: 6,
                errorText: _descriptionError,
              ),
              const SizedBox(height: 20),

              // Sección de Condición
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Condición', style: labelStyle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      buildConditionButton(
                        'Nuevo',
                        primaryOrange,
                        darkText,
                        borderInput,
                        unselectedConditionBg,
                      ),
                      buildConditionButton(
                        'Como nuevo',
                        primaryOrange,
                        darkText,
                        borderInput,
                        unselectedConditionBg,
                      ),
                      buildConditionButton(
                        'Bueno',
                        primaryOrange,
                        darkText,
                        borderInput,
                        unselectedConditionBg,
                      ),
                      buildConditionButton(
                        'Regular',
                        primaryOrange,
                        darkText,
                        borderInput,
                        unselectedConditionBg,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tarjeta de Entrega en Campus
        buildCampusPickupCard(primaryOrange, darkText, Colors.white),
      ],
    );
  }

  Widget buildRightPanel(
    TextStyle labelStyle,
    Color primaryOrange,
    Color darkText,
    Color unselectedGrey,
    Color background,
    Color activeGreen,
  ) {
    return Column(
      children: [
        // Sección Item Photos
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fotos del artículo', style: labelStyle),
              const SizedBox(height: 15),

              // Área de Drag and Drop
              DropTarget(
                onDragDone: (details) async {
                  for (final file in details.files) {
                    final bytes = await file.readAsBytes();
                    setState(() {
                      _selectedImages.add(bytes);
                    });
                  }
                },
                child: GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                      allowMultiple: true,
                      withData: true,
                    );
                    if (result != null) {
                      setState(() {
                        for (var file in result.files) {
                          if (file.bytes != null) {
                            _selectedImages.add(file.bytes!);
                          }
                        }
                      });
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: DottedBorder(
                      color: const Color(0xFFE3BFB1),
                      strokeWidth: 2,
                      dashPattern: const [8, 4],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(10),

                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          // Eliminamos el border: Border.all(...) anterior
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.cloudArrowUp,
                              color: Color(0xFFDCDDDE),
                              size: 40,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Arrastra y suelta las imágenes",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "o haz clic para buscar en tu equipo",
                              style: TextStyle(
                                color: Color(0xFFDCDDDE),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Miniaturas de fotos
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._selectedImages.asMap().entries.map((entry) {
                    int index = entry.key;
                    Uint8List imageBytes = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(right: 10, bottom: 10),
                      child: Stack(
                        clipBehavior:
                            Clip.none, // Permite que la 'x' sobresalga un poco
                        children: [
                          // Minitaura de la imagen
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE3BFB1),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ),
                          // Botón de eliminar (X)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12, // Tamaño del icono
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Cuadro con el "+"
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.image,
                        allowMultiple: true,
                        withData: true,
                      );
                      if (result != null) {
                        setState(() {
                          for (var file in result.files) {
                            if (file.bytes != null) {
                              _selectedImages.add(file.bytes!);
                            }
                          }
                        });
                      }
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: DottedBorder(
                        color: const Color(0xFFE3BFB1),
                        strokeWidth: 1.5,
                        dashPattern: const [4, 2],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(8),
                        child: const SizedBox(
                          width: 70,
                          height: 70,
                          child: Icon(Icons.add, color: Color(0xFFE3BFB1)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tarjeta de Visibilidad
        buildVisibilityCard(darkText, activeGreen, Colors.white),
        const SizedBox(height: 30),

        // Botón Publicar
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringPublicar = true),
          onExit: (_) => setState(() {
            _isHoveringPublicar = false;
            _isPressingPublicar = false;
          }),
          child: GestureDetector(
            onTap: _isLoading ? null : _publicarArticulo,
            onTapDown: (_) => setState(() => _isPressingPublicar = true),
            onTapUp: (_) => setState(() => _isPressingPublicar = false),
            onTapCancel: () => setState(() => _isPressingPublicar = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: _isPressingPublicar
                    ? const Color(0xFFBF4518)
                    : _isHoveringPublicar
                    ? const Color(0xFFFF7043)
                    : const Color(0xFFF25A22),
                borderRadius: BorderRadius.circular(10),
                boxShadow: _isHoveringPublicar
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFF25A22,
                          ).withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              transform: Matrix4.identity()
                ..scale(_isPressingPublicar ? 0.97 : 1.0),
              transformAlignment: Alignment.center,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Publicar',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.send, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // Widgets Auxiliares Reutilizables

  Widget buildTabItem(
    String title,
    TransactionType type,
    Color primaryOrange,
    Color darkText,
    Color background,
  ) {
    bool isSelected = _selectedTypes.contains(type);
    bool isHovering = _hoveringTab == type;
    bool isPressing = _pressingTab == type;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveringTab = type),
        onExit: (_) => setState(() {
          if (_hoveringTab == type) _hoveringTab = null;
          if (_pressingTab == type) _pressingTab = null;
        }),
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedTypes.contains(type)) {
                _selectedTypes.remove(type);
                if (type == TransactionType.trueque) {
                  _acceptsTrade = false;
                }
              } else {
                _selectedTypes.add(type);
                if (type == TransactionType.trueque) {
                  _acceptsTrade = true;
                }
              }
            });
          },
          onTapDown: (_) => setState(() => _pressingTab = type),
          onTapUp: (_) => setState(() => _pressingTab = null),
          onTapCancel: () => setState(() => _pressingTab = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? isPressing
                        ? const Color(0xFF1E3202)
                        : isHovering
                        ? const Color(0xFF3A5F05)
                        : const Color(0xFF2D4B03)
                  : isPressing
                  ? const Color(0xFFE0E0E0)
                  : isHovering
                  ? const Color(0xFFEAE8E8)
                  : const Color(0xFFF5F3F3),
              borderRadius: BorderRadius.circular(9),
              boxShadow: isSelected && isHovering
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2D4B03).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            transform: Matrix4.identity()..scale(isPressing ? 0.95 : 1.0),
            transformAlignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : darkText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(
    TextStyle labelStyle,
    TextStyle inputStyle,
    Color borderInput,
    String label, {
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;
    final focusNode = _getFocusNode(label);
    final bool isFocused = focusNode.hasFocus;
    final bool isHovering = _hoveringInput == label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 5),
        MouseRegion(
          onEnter: (_) => setState(() => _hoveringInput = label),
          onExit: (_) => setState(() {
            if (_hoveringInput == label) _hoveringInput = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: hasError
                    ? Colors.red.shade400
                    : isFocused
                    ? const Color(0xFFF25A22)
                    : isHovering
                    ? const Color(0xFFE3BFB1).withValues(alpha: 0.8)
                    : borderInput,
                width: isFocused ? 1.8 : 1.0,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF25A22).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: inputStyle,
              keyboardType: keyboardType,
              maxLines: maxLines,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: inputStyle.copyWith(color: const Color(0xFF8C95A3)),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget buildTextField(
    Color borderInput,
    TextStyle inputStyle, {
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderInput),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: TextField(
        controller: controller,
        style: inputStyle,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: inputStyle.copyWith(color: const Color(0xFF8C95A3)),
        ),
      ),
    );
  }

  Widget buildDropdownInput(
    Color borderInput,
    TextStyle inputStyle,
    String hintText, {
    String? value,
    required List<String> items,
    required Function onChanged,
    String? hoverKey,
  }) {
    final bool isHovering = _hoveringInput == (hoverKey ?? hintText);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveringInput = hoverKey ?? hintText),
      onExit: (_) => setState(() {
        if (_hoveringInput == (hoverKey ?? hintText)) _hoveringInput = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isHovering ? const Color(0xFFF25A22) : borderInput,
            width: isHovering ? 1.8 : 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isHovering
              ? [
                  BoxShadow(
                    color: const Color(0xFFF25A22).withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hintText, style: inputStyle),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFA5B2BC),
            ),
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: inputStyle),
              );
            }).toList(),
            onChanged: (newValue) => onChanged(newValue),
          ),
        ),
      ),
    );
  }

  FocusNode _getFocusNode(String key) {
    return _focusNodes.putIfAbsent(key, () {
      final node = FocusNode();
      node.addListener(() => setState(() {}));
      return node;
    });
  }

  Widget buildConditionButton(
    String title,
    Color primaryOrange,
    Color darkText,
    Color borderInput,
    Color unselectedBg,
  ) {
    bool isSelected = _selectedCondition == title;
    bool isPressing = _pressingCondition == title;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCondition = title;
          });
        },
        onTapDown: (_) => setState(() => _pressingCondition = title),
        onTapUp: (_) => setState(() => _pressingCondition = null),
        onTapCancel: () => setState(() => _pressingCondition = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6100)
                : isPressing
                ? const Color(0xFFE0E0E0)
                : unselectedBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6100).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          transform: Matrix4.identity()..scale(isPressing ? 0.93 : 1.0),
          transformAlignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: darkText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCampusPickupCard(
    Color primaryOrange,
    Color darkText,
    Color background,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFA5B2BC), size: 24),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entrega solo en el campus',
                    style: TextStyle(
                      //fontFamily: 'Outfit',
                      fontSize: 18,
                      color: Color(0xFF2E3137),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Disponible en la Universidad Metropolitana',
                    style: TextStyle(
                      //fontFamily: 'Outfit',
                      fontSize: 16,
                      color: const Color(0xFF5F6F5A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Checkbox(
            value: _campusPickup,
            onChanged: (val) {
              setState(() {
                _campusPickup = val!;
              });
            },
            activeColor: primaryOrange,
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ],
      ),
    );
  }

  Widget buildVisibilityCard(
    Color darkText,
    Color activeGreen,
    Color background,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Visibilidad del anuncio',
                style: TextStyle(
                  //fontFamily: 'Outfit',
                  fontSize: 16,
                  color: Color(0xFF8C95A3),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: activeGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'ACTIVO',
                  style: TextStyle(
                    //fontFamily: 'Outfit',
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Tu artículo será visible para los estudiantes en el feed principal del campus y en las búsquedas por categoría.',
            style: TextStyle(
              //fontFamily: 'Outfit',
              fontSize: 16,
              color: darkText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
