import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<String?> mostrarDialogUrgencia(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _UrgenciaDialog(),
  );
}

class _UrgenciaDialog extends StatefulWidget {
  const _UrgenciaDialog();

  @override
  State<_UrgenciaDialog> createState() => _UrgenciaDialogState();
}

class _UrgenciaDialogState extends State<_UrgenciaDialog> {
  String? _seleccion;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 500, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBE0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Color(0xFFF36900), size: 28),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              '¿Con qué urgencia\nnecesitas este producto?',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esto ayudará al vendedor a\npriorizar tu solicitud.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: const Color(0xFF5B4137),
              ),
            ),
            const SizedBox(height: 24),

            // Opciones
            Row(
              children: [
                ('baja', '🟢', 'Baja', 'No corre prisa'),
                ('media', '🟡', 'Media', 'Lo necesito pronto'),
                ('alta', '🔴', 'Alta', 'Lo necesito urgente'),
              ].map((opcion) {
                final (valor, emoji, label, sublabel) = opcion;
                final isSelected = _seleccion == valor;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _seleccion = valor),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFEBE0)
                            : const Color(0xFFF5F3F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF36900)
                              : const Color(0xFFE3BFB1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 8),
                          Text(label,
                              style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A))),
                          const SizedBox(height: 4),
                          Text(sublabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lexend(
                                  fontSize: 11,
                                  color: const Color(0xFF5B4137))),
                          if (isSelected) ...[
                            const SizedBox(height: 8),
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFFF36900), size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Botón continuar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _seleccion == null
                    ? null
                    : () => Navigator.pop(context, _seleccion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF36900),
                  disabledBackgroundColor: const Color(0xFFE3BFB1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Continuar al chat',
                  style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}