
import 'package:flutter/material.dart';

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key, 
    required this.icon, 
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFFF3EAD5)),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
}