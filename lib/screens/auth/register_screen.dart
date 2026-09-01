import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/core/app_text_field.dart';

/// Écran d'inscription — Zik237
/// L'utilisateur choisit son rôle (Auditeur ou Artiste),
/// renseigne ses informations et crée son compte.

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _selectedRole = 'auditeur'; // 'auditeur' ou 'artiste'
  String? _selectedVille;

  final List<String> _villes = [
    'Yaoundé',
    'Douala',
    'Bafoussam',
    'Bamenda',
    'Garoua',
    'Maroua',
    'Ngaoundéré',
    'Bertoua',
    'Ebolowa',
    'Kribi',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validation basique
    if (_nomController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Merci de remplir tous les champs');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Les mots de passe ne correspondent pas');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showSnackBar('Le mot de passe doit contenir au moins 8 caractères');
      return;
    }

    setState(() => _isLoading = true);
    // TODO: remplacer par AuthService.signUp(
    //   email: _emailController.text,
    //   password: _passwordController.text,
    //   nom: _nomController.text,
    //   role: _selectedRole,
    //   ville: _selectedVille,
    // )
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    // TODO: rediriger vers OtpScreen pour vérification
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.violetDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _goBack() {
    // TODO: context.pop() avec GoRouter
    Navigator.of(context).pop();
  }

  void _goToLogin() {
    // TODO: context.go('/login') avec GoRouter
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────
            _RegisterHeader(onBack: _goBack),

            // ── FORMULAIRE ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── CHOIX DU RÔLE ──
                  const Text(
                    'Tu es...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RoleSelector(
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) =>
                        setState(() => _selectedRole = role),
                  ),
                  const SizedBox(height: 22),

                  // ── NOM D'AFFICHAGE ──
                  const AppInputLabel(label: "Nom d'affichage"),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _nomController,
                    hint: 'Ton nom ou pseudo',
                    icon: Icons.person_outline_rounded,
                    isFocused: true,
                  ),
                  const SizedBox(height: 16),

                  // ── EMAIL ──
                  const AppInputLabel(label: 'Email ou téléphone'),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _emailController,
                    hint: 'nom@email.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // ── MOT DE PASSE ──
                  const AppInputLabel(label: 'Mot de passe'),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _passwordController,
                    hint: 'Minimum 8 caractères',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
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
                  const SizedBox(height: 16),

                  // ── CONFIRMER MOT DE PASSE ──
                  const AppInputLabel(label: 'Confirmer le mot de passe'),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _confirmPasswordController,
                    hint: 'Répète ton mot de passe',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── VILLE ──
                  const AppInputLabel(label: 'Ta ville'),
                  const SizedBox(height: 6),
                  _VilleDropdown(
                    villes: _villes,
                    selectedVille: _selectedVille,
                    onChanged: (ville) =>
                        setState(() => _selectedVille = ville),
                  ),
                  const SizedBox(height: 28),

                  // ── BOUTON CRÉER COMPTE ──
                  AppPrimaryButton(
                    label: 'Créer mon compte',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 16),

                  // ── CONDITIONS D'UTILISATION ──
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        text: "En t'inscrivant tu acceptes nos ",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.6,
                        ),
                        children: [
                          TextSpan(
                            text: "conditions d'utilisation",
                            style: TextStyle(
                              color: AppColors.violetDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── LIEN CONNEXION ──
                  Center(
                    child: GestureDetector(
                      onTap: _goToLogin,
                      child: RichText(
                        text: const TextSpan(
                          text: 'Déjà un compte ? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
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

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _RegisterHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _RegisterHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: Stack(
        children: [
          Container(height: 175, color: AppColors.violetDark),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipPath(
              clipper: _RegisterWaveClipper(),
              child: Container(height: 60, color: AppColors.background),
            ),
          ),
          Positioned(
            top: 52, left: 16,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          Positioned(
            top: 54, left: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Zik237',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WAVE CLIPPER REGISTER ───────────────────────────────────────────────────
class _RegisterWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.2, 0, size.width * 0.4, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.6, size.height * 0.8, size.width * 0.8, size.height * 0.2);
    path.quadraticBezierTo(
        size.width * 0.92, 0, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_RegisterWaveClipper oldClipper) => false;
}

// ─── SÉLECTEUR DE RÔLE ──────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoleCard(
          label: 'Auditeur',
          icon: Icons.headphones_rounded,
          isSelected: selectedRole == 'auditeur',
          onTap: () => onRoleChanged('auditeur'),
        ),
        const SizedBox(width: 12),
        _RoleCard(
          label: 'Artiste',
          icon: Icons.mic_rounded,
          isSelected: selectedRole == 'artiste',
          onTap: () => onRoleChanged('artiste'),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.violetLight : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.violetDark : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.violetDark
                    : AppColors.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isSelected
                      ? AppColors.violetDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DROPDOWN VILLE ──────────────────────────────────────────────────────────
class _VilleDropdown extends StatelessWidget {
  final List<String> villes;
  final String? selectedVille;
  final ValueChanged<String?> onChanged;

  const _VilleDropdown({
    required this.villes,
    required this.selectedVille,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedVille,
      hint: const Text(
        'Yaoundé, Douala...',
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textMuted,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
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
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderFocused,
            width: 1.5,
          ),
        ),
      ),
      items: villes
          .map((ville) => DropdownMenuItem(
        value: ville,
        child: Text(
          ville,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
