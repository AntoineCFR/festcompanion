import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfileTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool enabled;
  final TextStyle? labelStyle;
  final TextStyle? style;
  final Color? fillColor;
  final TextInputType? keyboardType;  // <-- Ajout du paramètre manquant

  const ProfileTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.enabled = true,
    this.labelStyle,
    this.style,
    this.fillColor,
    this.keyboardType,  // <-- Ajout ici aussi
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: labelStyle ?? const TextStyle(color: Colors.white70),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.surfaceAlt),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.surfaceAlt),
        ),
        filled: true,
        fillColor: fillColor ?? AppTheme.surface,
      ),
      style: style ?? const TextStyle(color: Colors.white),
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,  // <-- Passe le paramètre au TextField
    );
  }
}