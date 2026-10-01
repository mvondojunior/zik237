import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/core/app_text_field.dart';
import 'package:app_mobile_music_underground/services/auth_service.dart';

/// Écran mot de passe oublié — Zik237
/// L'utilisateur saisit son email et reçoit un lien de réinitialisation.

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailEnvoye = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Saisis ton adresse email');
      return;
    }
    if (!email.contains('@')) {
      _showSnackBar('Adresse email invalide');
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.resetPassword(email: email);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error);
    } else {
      setState(() => _emailEnvoye = true);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.violetDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _ForgotPasswordHeader(
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: _emailEnvoye
                  ? _SuccessState(
                email: _emailController.text.trim(),
                onRetour: () => Navigator.of(context).pop(),
                onRenvoyer: () {
                  setState(() => _emailEnvoye = false);
                },
              )
                  : _FormState(
                emailController: _emailController,
                isLoading: _isLoading,
                onSubmit: _handleReset,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _ForgotPasswordHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _ForgotPasswordHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        children: [
          // Dégradé comme Login & Register
          Container(
            height: 190,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.violetDark,
                  Color(0xFF5B2C8A),
                ],
              ),
            ),
          ),

          // Vague améliorée
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _ForgotWaveClipper(),
              child: Container(
                height: 65,
                color: AppColors.background,
              ),
            ),
          ),

          // Bouton retour
          Positioned(
            top: 50,
            left: 12,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),

          // Titre
          const Positioned(
            top: 54,
            left: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zik237',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Mot de passe oublié',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),

          // Icône
          Positioned(
            top: 52,
            right: 24,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FORMULAIRE ──────────────────────────────────────────────────────────────
class _FormState extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _FormState({
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Réinitialiser ton\nmot de passe',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Saisis l\'adresse email associée à ton compte.\nNous t\'enverrons un lien pour réinitialiser ton mot de passe.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),

        const AppInputLabel(label: 'Adresse email'),
        const SizedBox(height: 8),
        AppTextField(
          controller: emailController,
          hint: 'nom@email.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          isFocused: true,
        ),
        const SizedBox(height: 36),

        AppPrimaryButton(
          label: 'Envoyer le lien',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 24),

        Center(
          child: GestureDetector(
            onTap: onBack,
            child: RichText(
              text: const TextSpan(
                text: 'Tu t\'en souviens ? ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Se connecter',
                    style: TextStyle(
                      color: AppColors.violetDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ÉTAT SUCCÈS ─────────────────────────────────────────────────────────────
class _SuccessState extends StatelessWidget {
  final String email;
  final VoidCallback onRetour;
  final VoidCallback onRenvoyer;

  const _SuccessState({
    required this.email,
    required this.onRetour,
    required this.onRenvoyer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),

        // Icône succès
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.violetLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.violetDark.withOpacity(0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.violetDark.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 42,
            color: AppColors.violetDark,
          ),
        ),
        const SizedBox(height: 28),

        const Text(
          'Email envoyé !',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 14),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: 'Un lien de réinitialisation a été envoyé à\n',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: AppColors.violetDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: '\nVérifie ta boîte mail et clique sur le lien.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.violetMid,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Le lien expire dans 60 minutes.\nPense aussi à vérifier tes spams.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        AppPrimaryButton(
          label: 'Retour à la connexion',
          onPressed: onRetour,
        ),
        const SizedBox(height: 16),

        // Bouton secondaire pour renvoyer
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onRenvoyer,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.violetDark,
              side: const BorderSide(color: AppColors.violetDark, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Renvoyer le lien',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── WAVE CLIPPER AMÉLIORÉE ───────────────────────────────────────────────────
class _ForgotWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.45);

    path.quadraticBezierTo(
      size.width * 0.2,
      0,
      size.width * 0.4,
      size.height * 0.4,
    );

    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.85,
      size.width * 0.8,
      size.height * 0.25,
    );

    path.quadraticBezierTo(
      size.width * 0.92,
      0,
      size.width,
      size.height * 0.35,
    );

    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_ForgotWaveClipper oldClipper) => false;
}