import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/core/app_text_field.dart';

/// Écran de connexion — Zik237
/// Utilise uniquement les composants de core/ pour rester propre et maintenable.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    // TODO: remplacer par AuthService.signIn(email, password)
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
  }

  void _handleGoogleSignIn() {
    // TODO: Google Sign-In via Supabase
  }

  void _goToRegister() {
    // TODO: context.go('/register') avec GoRouter
  }

  void _goToForgotPassword() {
    // TODO: context.go('/forgot-password') avec GoRouter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────
            const _LoginHeader(),

            // ── FORMULAIRE ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Titre
                  const Text(
                    'Connecte-toi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Découvre la scène underground 237',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email
                  const AppInputLabel(label: 'Email ou téléphone'),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _emailController,
                    hint: 'nom@email.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    isFocused: true,
                  ),
                  const SizedBox(height: 16),

                  // Mot de passe
                  const AppInputLabel(label: 'Mot de passe'),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _passwordController,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _goToForgotPassword,
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.violetMid,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton connexion
                  AppPrimaryButton(
                    label: 'Se connecter',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Séparateur
                  const AppDivider(),
                  const SizedBox(height: 20),

                  // Google
                  AppSocialButton(
                    label: 'Continuer avec Google',
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 28),

                  // Lien inscription
                  Center(
                    child: GestureDetector(
                      onTap: _goToRegister,
                      child: RichText(
                        text: const TextSpan(
                          text: 'Pas encore de compte ? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: "S'inscrire",
                              style: TextStyle(
                                color: AppColors.violetDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

// ─── HEADER ─────────────────────────────────────────────────────────────────
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          Container(height: 220, color: AppColors.violetDark),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(height: 80, color: AppColors.background),
            ),
          ),
          Positioned(
            top: 56, left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white, size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Bienvenue sur',
                    style: TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 1.2)),
                const Text('Zik237',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600,
                        color: Colors.white, letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WAVE CLIPPER ────────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.15, 0, size.width * 0.3, size.height * 0.35);
    path.quadraticBezierTo(
        size.width * 0.45, size.height * 0.7, size.width * 0.6, size.height * 0.2);
    path.quadraticBezierTo(
        size.width * 0.75, 0, size.width * 0.88, size.height * 0.3);
    path.quadraticBezierTo(
        size.width * 0.95, size.height * 0.5, size.width, size.height * 0.15);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}
