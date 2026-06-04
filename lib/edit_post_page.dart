import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/unite_header.dart';

enum EditTransactionType { venta, alquiler, trueque }

class EditarArticuloPage extends StatefulWidget {
  final Map<String, dynamic> anuncio;

  const EditarArticuloPage({super.key, required this.anuncio});

  @override
  State<EditarArticuloPage> createState() => _EditarArticuloPageState();
}

class _EditarArticuloPageState extends State<EditarArticuloPage> {
  final _supabase = Supabase.instance.client;

  final Set<EditTransactionType> _selectedTypes = {};
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List<Map<String, dynamic>> _rentalOptions = [];
  final TextEditingController _tradeForController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Imágenes: URLs existentes (ya subidas) + bytes nuevos
  final List<String> _existingImageUrls = [];
  final List<Uint8List> _newImageBytes = [];

  String? _selectedCategory;
  String? _selectedCondition;
  final Set<String> _selectedCampusUniversidades = {};

  final List<String> _universidadesCampus = [
    "Universidad Metropolitana",
    "Universidad Católica Andrés Bello",
    "Universidad Santa María",
    "Universidad Central de Venezuela",
    "Universidad Monteávila",
    "Universidad Simón Bolívar",
  ];

  bool _isLoading = false;
  bool _acceptsTrade = false;
  String? _titleError;
  String? _descriptionError;
  String? _priceError;
  bool _isHoveringGuardar = false;
  bool _isPressingGuardar = false;
  String? _pressingCondition;
  String? _hoveringInput;
  final Map<String, FocusNode> _focusNodes = {};
  final FocusNode _costoPorDiaFocusNode = FocusNode();
  EditTransactionType? _hoveringTab;
  EditTransactionType? _pressingTab;

  @override
  void initState() {
    super.initState();
    _loadAnuncioData();
  }

  void _loadAnuncioData() {
    final a = widget.anuncio;
    _titleController.text = a['titulo'] ?? '';
    _descriptionController.text = a['descripcion'] ?? '';
    _selectedCategory = a['categoria'];
    _selectedCondition = a['estado_producto'];

    final modalidades = a['detalles_modalidades'] as Map<String, dynamic>? ?? {};

    // Venta
    if (modalidades.containsKey('venta')) {
      _selectedTypes.add(EditTransactionType.venta);
      final precio = modalidades['venta']?['precio'];
      _priceController.text = precio?.toString() ?? '';
    }

    // Alquiler
    if (modalidades.containsKey('alquiler')) {
      _selectedTypes.add(EditTransactionType.alquiler);
      final alquilerList = modalidades['alquiler'] as List<dynamic>? ?? [];
      for (final opt in alquilerList) {
        _rentalOptions.add({
          'controller': TextEditingController(text: opt['costo']?.toString() ?? ''),
          'unit': opt['unidad_tiempo'] ?? 'Día',
        });
      }
    }
    if (_rentalOptions.isEmpty && _selectedTypes.contains(EditTransactionType.alquiler)) {
      _rentalOptions.add({'controller': TextEditingController(), 'unit': 'Día'});
    }

    // Trueque
    if (modalidades.containsKey('trueque')) {
      _selectedTypes.add(EditTransactionType.trueque);
      _acceptsTrade = true;
      _tradeForController.text = modalidades['trueque']?['descripcion'] ?? '';
    }

    // Campus
    final campusRaw = modalidades['campus_pickup'];
    if (campusRaw is List) {
      _selectedCampusUniversidades.addAll(campusRaw.map((e) => e.toString()));
    }

    // Imágenes existentes
    final imagenesRaw = modalidades['imagenes'] as List<dynamic>? ?? [];
    _existingImageUrls.addAll(imagenesRaw.map((e) => e.toString()));

    // Si no tiene ningún tipo seleccionado, poner venta por defecto
    if (_selectedTypes.isEmpty) {
      _selectedTypes.add(EditTransactionType.venta);
    }
    if (_rentalOptions.isEmpty) {
      _rentalOptions.add({'controller': TextEditingController(), 'unit': 'Día'});
    }
  }

  String _mapCondicion(String condicion) {
    switch (condicion) {
      case 'Nuevo': return 'Nuevo';
      case 'Como nuevo': return 'Como nuevo';
      case 'Bueno': return 'Bueno';
      case 'Regular': return 'Regular';
      default: return condicion;
    }
  }

  Future<void> _guardarCambios() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    bool hasError = false;

    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = 'El nombre del artículo no puede estar vacío.');
      hasError = true;
    } else {
      setState(() => _titleError = null);
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _descriptionError = 'La descripción no puede estar vacía.');
      hasError = true;
    } else {
      setState(() => _descriptionError = null);
    }

    if (_selectedTypes.contains(EditTransactionType.venta)) {
      final priceText = _priceController.text.trim();
      final price = double.tryParse(priceText);
      if (priceText.isEmpty || price == null || price < 0) {
        setState(() => _priceError = 'Ingresa un precio válido (número positivo).');
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
      // Subir imágenes nuevas
      final List<String> newUrls = [];
      for (int i = 0; i < _newImageBytes.length; i++) {
        try {
          final bytes = _newImageBytes[i];
          final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await _supabase.storage.from('foto_producto').uploadBinary(path, bytes);
          final url = _supabase.storage.from('foto_producto').getPublicUrl(path);
          newUrls.add(url);
        } catch (_) {}
      }

      // Combinar URLs existentes (no eliminadas) + nuevas
      final List<String> allImageUrls = [..._existingImageUrls, ...newUrls];

      // Construir modalidades
      final Map<String, dynamic> modalidades = {};
      if (_selectedTypes.contains(EditTransactionType.venta)) {
        modalidades['venta'] = {
          'precio': double.tryParse(_priceController.text) ?? 0.0,
        };
      }
      if (_selectedTypes.contains(EditTransactionType.alquiler)) {
        modalidades['alquiler'] = _rentalOptions.map((opt) => {
          'costo': double.tryParse(opt['controller'].text) ?? 0.0,
          'unidad_tiempo': opt['unit'],
        }).toList();
      }
      if (_acceptsTrade) {
        modalidades['trueque'] = {
          'descripcion': _tradeForController.text.trim(),
        };
      }
      modalidades['campus_pickup'] = _selectedCampusUniversidades.toList();
      modalidades['imagenes'] = allImageUrls;

      await _supabase.from('anuncios_marketplace').update({
        'titulo': _titleController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
        'categoria': _selectedCategory,
        'estado_producto': _selectedCondition != null ? _mapCondicion(_selectedCondition!) : null,
        'detalles_modalidades': modalidades,
      }).eq('id', widget.anuncio['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Artículo actualizado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarPublicacion() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¿Eliminar publicación?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Esta acción no se puede deshacer. El artículo será eliminado permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('anuncios_marketplace')
          .update({'disponible': false})
          .eq('id', widget.anuncio['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación eliminada.'), backgroundColor: Colors.black87),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
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
    _titleController.dispose();
    _priceController.dispose();
    _tradeForController.dispose();
    _descriptionController.dispose();
    for (final opt in _rentalOptions) {
      (opt['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF25A22);
    const Color background = Color(0xFFFBFBFB);
    const Color darkText = Color(0xFF2E3137);
    const Color unselectedGrey = Color(0xFFDCDDDE);
    const Color headerOliveGreen = Color(0xFF5F6F5A);
    const Color borderInput = Color(0xFFE3BFB1);
    const Color unselectedConditionBg = Color(0xFFF0F0F0);
    const Color activeGreen = Color(0xFFA5DC86);

    const TextStyle headerStyle = TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: darkText,
      letterSpacing: -1,
    );
    const TextStyle descriptionHeaderStyle = TextStyle(
      fontSize: 16,
      color: headerOliveGreen,
      height: 1.4,
    );
    const TextStyle labelStyle = TextStyle(
      fontSize: 14,
      color: Color(0xFF8F7065),
      fontWeight: FontWeight.bold,
    );
    const TextStyle inputStyle = TextStyle(
      fontSize: 16,
      color: darkText,
      height: 1.3,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: const UniteHeader(currentIndex: 1),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 900;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Editar artículo', style: headerStyle),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? constraints.maxWidth * 0.6 : constraints.maxWidth,
                            ),
                            child: const Text(
                              'Modifica los detalles de tu publicación. Los cambios se reflejarán de inmediato en el marketplace.',
                              style: descriptionHeaderStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildMainForm(labelStyle, inputStyle, primaryOrange, darkText, borderInput, unselectedConditionBg, background),
                            ),
                            const SizedBox(width: 50),
                            Expanded(
                              flex: 2,
                              child: _buildRightPanel(labelStyle, primaryOrange, darkText, unselectedGrey, background, activeGreen),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildMainForm(labelStyle, inputStyle, primaryOrange, darkText, borderInput, unselectedConditionBg, background),
                            const SizedBox(height: 40),
                            _buildRightPanel(labelStyle, primaryOrange, darkText, unselectedGrey, background, activeGreen),
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
    );
  }

  Widget _buildMainForm(
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
              // Tabs Venta / Alquiler
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTabItem('Venta', EditTransactionType.venta, primaryOrange, darkText, background),
                    _buildTabItem('Alquiler', EditTransactionType.alquiler, primaryOrange, darkText, background),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Título
              _buildInputField(labelStyle, inputStyle, borderInput, 'Título',
                controller: _titleController,
                hintText: '¿Qué estás ofreciendo?',
                errorText: _titleError,
              ),
              const SizedBox(height: 20),

              // Categoría + Precio
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Categoría', style: labelStyle),
                        const SizedBox(height: 5),
                        _buildDropdownInput(
                          borderInput, inputStyle, 'Seleccionar',
                          value: _selectedCategory,
                          items: ['Libros', 'Herramientas', 'Accesorios', 'Electrónica'],
                          onChanged: (val) => setState(() => _selectedCategory = val),
                          hoverKey: 'Categoría',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  if (_selectedTypes.contains(EditTransactionType.venta) ||
                      _selectedTypes.contains(EditTransactionType.alquiler))
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedTypes.contains(EditTransactionType.venta)) ...[
                            _buildInputField(labelStyle, inputStyle, borderInput, 'Precio fijo para venta',
                              controller: _priceController,
                              hintText: '\$ 0.00',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              errorText: _priceError,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            ),
                            if (_selectedTypes.contains(EditTransactionType.alquiler))
                              const SizedBox(height: 15),
                          ],

                          if (_selectedTypes.contains(EditTransactionType.alquiler))
                            ...List.generate(_rentalOptions.length, (index) {
                              bool isFirst = index == 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (isFirst) ...[
                                            Text('Costo por Día', style: labelStyle),
                                            const SizedBox(height: 5),
                                          ],
                                          MouseRegion(
                                            onEnter: (_) => setState(() => _hoveringInput = 'costo_$index'),
                                            onExit: (_) => setState(() {
                                              if (_hoveringInput == 'costo_$index') _hoveringInput = null;
                                            }),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 130),
                                              curve: Curves.easeOut,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color: _costoPorDiaFocusNode.hasFocus
                                                      ? const Color(0xFFF25A22)
                                                      : _hoveringInput == 'costo_$index'
                                                      ? const Color(0xFFE3BFB1).withValues(alpha: 0.8)
                                                      : const Color(0xFFE3BFB1),
                                                  width: _costoPorDiaFocusNode.hasFocus ? 1.8 : 1.0,
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 15),
                                              alignment: Alignment.centerLeft,
                                              child: TextField(
                                                controller: _rentalOptions[index]['controller'],
                                                focusNode: _costoPorDiaFocusNode,
                                                style: const TextStyle(fontSize: 16, color: Color(0xFF2E3137)),
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: '\$ 0.00',
                                                  hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF8C95A3)),
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (isFirst) ...[
                                            Text('Unidad', style: labelStyle),
                                            const SizedBox(height: 5),
                                          ],
                                          SizedBox(
                                            height: 48,
                                            child: _buildDropdownInput(
                                              const Color(0xFFE3BFB1),
                                              const TextStyle(fontSize: 16, color: Color(0xFF2E3137)),
                                              'Seleccionar',
                                              value: _rentalOptions[index]['unit'],
                                              items: ['Día', 'Hora', 'Semana', 'Mes'],
                                              onChanged: (val) => setState(() => _rentalOptions[index]['unit'] = val),
                                              hoverKey: 'Unidad_$index',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: isFirst
                                          ? GestureDetector(
                                              onTap: () => setState(() => _rentalOptions.add({
                                                'controller': TextEditingController(),
                                                'unit': 'Hora',
                                              })),
                                              child: MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: Container(
                                                  width: 25, height: 25,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2D4B03),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                                                ),
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () => setState(() => _rentalOptions.removeAt(index)),
                                              child: MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: const SizedBox(
                                                  width: 25, height: 25,
                                                  child: Center(
                                                    child: FaIcon(FontAwesomeIcons.trashCan, color: Color(0xFF8F7065), size: 20),
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

              // Switch trueque
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE3BFB1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: primaryOrange, size: 24),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Aceptar trueque',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E3137))),
                          const SizedBox(height: 4),
                          Text(
                            'Activa esta opción si estás dispuesto a recibir otros artículos como intercambio.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                            _selectedTypes.add(EditTransactionType.trueque);
                          } else {
                            _selectedTypes.remove(EditTransactionType.trueque);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_acceptsTrade) ...[
                _buildInputField(labelStyle, inputStyle, borderInput, 'Intereses de trueque (Cosas de interés)',
                  controller: _tradeForController,
                  hintText: '¿Qué te interesaría recibir a cambio?',
                ),
                const SizedBox(height: 20),
              ],

              // Descripción
              _buildInputField(labelStyle, inputStyle, borderInput, 'Descripción',
                controller: _descriptionController,
                hintText: 'Cuéntanos más sobre el artículo que estás ofreciendo...',
                maxLines: 6,
                errorText: _descriptionError,
              ),
              const SizedBox(height: 20),

              // Condición
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Condición', style: labelStyle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildConditionButton('Nuevo', primaryOrange, darkText, const Color(0xFFE3BFB1), unselectedConditionBg),
                      _buildConditionButton('Como nuevo', primaryOrange, darkText, const Color(0xFFE3BFB1), unselectedConditionBg),
                      _buildConditionButton('Bueno', primaryOrange, darkText, const Color(0xFFE3BFB1), unselectedConditionBg),
                      _buildConditionButton('Regular', primaryOrange, darkText, const Color(0xFFE3BFB1), unselectedConditionBg),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCampusPickupCard(primaryOrange, darkText, Colors.white),
      ],
    );
  }

  Widget _buildRightPanel(
    TextStyle labelStyle,
    Color primaryOrange,
    Color darkText,
    Color unselectedGrey,
    Color background,
    Color activeGreen,
  ) {
    return Column(
      children: [
        // Fotos
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

              // Área drag & drop
              DropTarget(
                onDragDone: (details) async {
                  for (final file in details.files) {
                    final bytes = await file.readAsBytes();
                    setState(() => _newImageBytes.add(bytes));
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
                          if (file.bytes != null) _newImageBytes.add(file.bytes!);
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
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.cloudArrowUp, color: Color(0xFFDCDDDE), size: 40),
                            SizedBox(height: 10),
                            Text("Arrastra y suelta las imágenes",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("o haz clic para buscar en tu equipo",
                              style: TextStyle(color: Color(0xFFDCDDDE), fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Miniaturas: existentes + nuevas
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // URLs existentes
                  ..._existingImageUrls.asMap().entries.map((entry) {
                    int index = entry.key;
                    String url = entry.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE3BFB1)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(url, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                        Positioned(
                          top: -6, right: -6,
                          child: GestureDetector(
                            onTap: () => setState(() => _existingImageUrls.removeAt(index)),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  // Bytes nuevos
                  ..._newImageBytes.asMap().entries.map((entry) {
                    int index = entry.key;
                    Uint8List bytes = entry.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE3BFB1)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(bytes, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                        Positioned(
                          top: -6, right: -6,
                          child: GestureDetector(
                            onTap: () => setState(() => _newImageBytes.removeAt(index)),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  // Botón "+"
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
                            if (file.bytes != null) _newImageBytes.add(file.bytes!);
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
                          width: 70, height: 70,
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

        _buildVisibilityCard(darkText, activeGreen, Colors.white),
        const SizedBox(height: 20),

        // Botón Guardar cambios
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringGuardar = true),
          onExit: (_) => setState(() {
            _isHoveringGuardar = false;
            _isPressingGuardar = false;
          }),
          child: GestureDetector(
            onTap: _isLoading ? null : _guardarCambios,
            onTapDown: (_) => setState(() => _isPressingGuardar = true),
            onTapUp: (_) => setState(() => _isPressingGuardar = false),
            onTapCancel: () => setState(() => _isPressingGuardar = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: _isPressingGuardar
                    ? const Color(0xFFBF4518)
                    : _isHoveringGuardar
                    ? const Color(0xFFFF7043)
                    : const Color(0xFFF25A22),
                borderRadius: BorderRadius.circular(10),
                boxShadow: _isHoveringGuardar
                    ? [BoxShadow(color: const Color(0xFFF25A22).withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6))]
                    : [],
              ),
              transform: Matrix4.identity()..scale(_isPressingGuardar ? 0.97 : 1.0),
              transformAlignment: Alignment.center,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Guardar cambios',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        Icon(Icons.save_outlined, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botón Eliminar publicación
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isLoading ? null : _eliminarPublicacion,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Eliminar publicación',
                    style: TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Widgets auxiliares (misma firma y lógica que post_item.dart) ──

  Widget _buildTabItem(String title, EditTransactionType type, Color primaryOrange, Color darkText, Color background) {
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
                if (type == EditTransactionType.trueque) _acceptsTrade = false;
              } else {
                _selectedTypes.add(type);
                if (type == EditTransactionType.trueque) _acceptsTrade = true;
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
                  ? isPressing ? const Color(0xFF1E3202) : isHovering ? const Color(0xFF3A5F05) : const Color(0xFF2D4B03)
                  : isPressing ? const Color(0xFFE0E0E0) : isHovering ? const Color(0xFFEAE8E8) : const Color(0xFFF5F3F3),
              borderRadius: BorderRadius.circular(9),
              boxShadow: isSelected && isHovering
                  ? [BoxShadow(color: const Color(0xFF2D4B03).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            transform: Matrix4.identity()..scale(isPressing ? 0.95 : 1.0),
            transformAlignment: Alignment.center,
            child: Text(title,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : darkText,
                fontWeight: FontWeight.bold,
              )),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
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
                    : isFocused ? const Color(0xFFF25A22)
                    : isHovering ? const Color(0xFFE3BFB1).withValues(alpha: 0.8)
                    : borderInput,
                width: isFocused ? 1.8 : 1.0,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isFocused
                  ? [BoxShadow(color: const Color(0xFFF25A22).withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
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
          Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildDropdownInput(
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
              ? [BoxShadow(color: const Color(0xFFF25A22).withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hintText, style: inputStyle),
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA5B2BC)),
            items: items.map<DropdownMenuItem<String>>((String val) {
              return DropdownMenuItem<String>(value: val, child: Text(val, style: inputStyle));
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

  Widget _buildConditionButton(String title, Color primaryOrange, Color darkText, Color borderInput, Color unselectedBg) {
    bool isSelected = _selectedCondition == title;
    bool isPressing = _pressingCondition == title;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedCondition = title),
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
                : isPressing ? const Color(0xFFE0E0E0)
                : unselectedBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [BoxShadow(color: const Color(0xFFFF6100).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          transform: Matrix4.identity()..scale(isPressing ? 0.93 : 1.0),
          transformAlignment: Alignment.center,
          child: Text(title,
            style: TextStyle(fontSize: 14, color: darkText, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildCampusPickupCard(Color primaryOrange, Color darkText, Color background) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFA5B2BC), size: 24),
              const SizedBox(width: 12),
              const Text('Entrega en campus',
                style: TextStyle(fontSize: 18, color: Color(0xFF2E3137), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 36),
            child: Text('Selecciona en qué universidades puedes hacer la entrega.',
              style: TextStyle(fontSize: 13, color: Color(0xFF5F6F5A))),
          ),
          const SizedBox(height: 16),
          ..._universidadesCampus.map((uni) {
            final isSelected = _selectedCampusUniversidades.contains(uni);
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCampusUniversidades.remove(uni);
                  } else {
                    _selectedCampusUniversidades.add(uni);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCampusUniversidades.add(uni);
                          } else {
                            _selectedCampusUniversidades.remove(uni);
                          }
                        });
                      },
                      activeColor: primaryOrange,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    Text(uni,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? const Color(0xFF2E3137) : const Color(0xFF8C95A3),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVisibilityCard(Color darkText, Color activeGreen, Color background) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
              const Text('Visibilidad del anuncio',
                style: TextStyle(fontSize: 16, color: Color(0xFF8C95A3), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: activeGreen, borderRadius: BorderRadius.circular(15)),
                child: const Text('ACTIVO',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Tu artículo será visible para los estudiantes en el feed principal del campus y en las búsquedas por categoría.',
            style: TextStyle(fontSize: 16, color: darkText, height: 1.3),
          ),
        ],
      ),
    );
  }
}