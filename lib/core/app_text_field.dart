import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';

/// Champ de saisie réutilisable pour toute l'application Zik237.
///
/// Usage basique :
/// ```dart
/// AppTextField(
///   controller: _emailController,
///   hint: 'nom@email.com',
///   icon: Icons.mail_outline_rounded,
/// )
/// ```
///
/// Avec mot de passe :
/// ```dart
/// AppTextField(
///   controller: _passwordController,
///   hint: '••••••••',
///   icon: Icons.lock_outline_rounded,
///   obscureText: true,
///   suffixIcon: IconButton(...),
/// )
/// ```

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool isFocused;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.isFocused = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        errorText: errorText,
        errorStyle: const TextStyle(
          fontSize: 11,
          color: AppColors.error,
        ),
        prefixIcon: Icon(
          icon,
          color: isFocused ? AppColors.violetMid : AppColors.textMuted,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: isFocused,
        fillColor: isFocused ? AppColors.violetLight : Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isFocused ? AppColors.borderFocused : AppColors.border,
            width: isFocused ? 1.5 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderFocused,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Label au-dessus d'un champ de saisie.
///
/// Usage :
/// ```dart
/// AppInputLabel(label: 'Email ou téléphone'),
/// SizedBox(height: 6),
/// AppTextField(...),
/// ```
class AppInputLabel extends StatelessWidget {
  final String label;

  const AppInputLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
