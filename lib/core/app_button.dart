import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';

/// Bouton principal plein — utilisé pour toutes les actions primaires.
///
/// Usage :
/// ```dart
/// AppPrimaryButton(
///   label: 'Se connecter',
///   onPressed: _handleLogin,
/// )
///
/// // Avec état chargement :
/// AppPrimaryButton(
///   label: 'Se connecter',
///   isLoading: _isLoading,
///   onPressed: _handleLogin,
/// )
/// ```
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.violetDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.violetSoft,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Bouton outlined — utilisé pour les connexions sociales (Google, etc.).
///
/// Usage :
/// ```dart
/// AppSocialButton(
///   label: 'Continuer avec Google',
///   icon: Icons.g_mobiledata_rounded,
///   onPressed: _handleGoogleSignIn,
/// )
/// ```
class AppSocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AppSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.violetMid, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// Séparateur horizontal avec texte central — utilisé entre les méthodes de connexion.
///
/// Usage :
/// ```dart
/// AppDivider(label: 'ou'),
/// ```
class AppDivider extends StatelessWidget {
  final String label;

  const AppDivider({super.key, this.label = 'ou'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 0.8),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 0.8),
        ),
      ],
    );
  }
}



