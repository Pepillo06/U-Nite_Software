import 'package:flutter/material.dart';

class AppColors {
  static const orange = Color(0xFFFF6B00);
  static const orangeDark = Color(0xFFCC5600);
  static const green = Color(0xFF00A859);
  static const greenDark = Color(0xFF00843D);
  static const bg = Color(0xFFF7F7F7);
  static const white = Colors.white;
}

class DuoButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color shadowColor;
  final VoidCallback onPressed;
  final double fontSize;

  const DuoButton({
    super.key,
    required this.text,
    required this.color,
    required this.shadowColor,
    required this.onPressed,
    this.fontSize = 16,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            bottom: BorderSide(
              color: _isPressed ? Colors.transparent : widget.shadowColor,
              width: _isPressed ? 0 : 4,
            ),
          ),
        ),
        child: Text(
          widget.text.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            // Texto naranja si el botón es blanco, blanco si el botón tiene color
            color: widget.color == Colors.white
                ? AppColors.orange
                : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: widget.fontSize,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
