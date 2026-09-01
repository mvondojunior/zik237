import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';

/// Écran de vérification OTP — Zik237
/// Affiché après l'inscription pour confirmer l'email ou le numéro de téléphone.
/// Reçoit en paramètre le contact (email ou téléphone) auquel le code a été envoyé.

class OtpScreen extends StatefulWidget {
  final String contact; // email ou numéro de téléphone
  final bool isEmail;   // true = email, false = téléphone

  const OtpScreen({
    super.key,
    required this.contact,
    this.isEmail = true,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 6 champs OTP
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _canResend = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Focus automatique sur le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Compte à rebours pour renvoyer le code ──
  void _startCountdown() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  // ── Code OTP complet ──
  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  bool get _isOtpComplete =>
      _controllers.every((c) => c.text.isNotEmpty);

  // ── Vérifier le code ──
  Future<void> _handleVerify() async {
    if (!_isOtpComplete) {
      _showSnackBar('Merci de saisir les 6 chiffres du code');
      return;
    }
    setState(() => _isLoading = true);
    // TODO: remplacer par AuthService.verifyOtp(
    //   contact: widget.contact,
    //   code: _otpCode,
    // )
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    // TODO: si succès → context.go('/home') ou context.go('/register-artiste')
    // selon le rôle choisi lors de l'inscription
  }

  // ── Renvoyer le code ──
  Future<void> _handleResend() async {
    if (!_canResend) return;
    // TODO: AuthService.resendOtp(contact: widget.contact)
    _startCountdown();
    _showSnackBar('Code renvoyé sur ${widget.contact}');
    // Vider les champs
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
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

  void _goBack() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────
            _OtpHeader(onBack: _goBack),

            // ── CONTENU ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Titre
                  const Text(
                    'Vérifie ton code',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sous-titre avec contact masqué
                  RichText(
                    text: TextSpan(
                      text: 'Un code à 6 chiffres a été envoyé à ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: _maskedContact(widget.contact),
                          style: const TextStyle(
                            color: AppColors.violetDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── CHAMPS OTP ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                          (index) => _OtpField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) =>
                            _onOtpFieldChanged(value, index),
                        onBackspace: () => _onBackspace(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── BOUTON VÉRIFIER ──
                  AppPrimaryButton(
                    label: 'Vérifier',
                    isLoading: _isLoading,
                    onPressed: _handleVerify,
                  ),
                  const SizedBox(height: 28),

                  // ── RENVOYER LE CODE ──
                  Center(
                    child: _canResend
                        ? GestureDetector(
                      onTap: _handleResend,
                      child: const Text(
                        'Renvoyer le code',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.violetDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        : RichText(
                      text: TextSpan(
                        text: 'Renvoyer dans ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          TextSpan(
                            text: '${_secondsRemaining}s',
                            style: const TextStyle(
                              color: AppColors.violetMid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── CHANGER DE CONTACT ──
                  Center(
                    child: GestureDetector(
                      onTap: _goBack,
                      child: const Text(
                        'Mauvais email ou téléphone ?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
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

  // ── Gestion de la saisie OTP ──
  void _onOtpFieldChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Passer au champ suivant
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Dernier champ → fermer le clavier
        _focusNodes[index].unfocus();
        // Vérifier automatiquement si complet
        if (_isOtpComplete) _handleVerify();
      }
    }
    setState(() {}); // Mettre à jour l'état visuel
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  // ── Masquer partiellement le contact ──
  String _maskedContact(String contact) {
    if (widget.isEmail) {
      // exemple : p***e@gmail.com
      final parts = contact.split('@');
      if (parts.length != 2) return contact;
      final name = parts[0];
      if (name.length <= 2) return contact;
      return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@${parts[1]}';
    } else {
      // exemple : 6XX XXX X89
      if (contact.length < 4) return contact;
      return '${'X' * (contact.length - 2)}${contact.substring(contact.length - 2)}';
    }
  }
}

// ─── HEADER OTP ──────────────────────────────────────────────────────────────
class _OtpHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _OtpHeader({required this.onBack});

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
              clipper: _OtpWaveClipper(),
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
                  'Vérification',
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
          // Icône OTP
          Positioned(
            top: 54, right: 24,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WAVE CLIPPER OTP ────────────────────────────────────────────────────────
class _OtpWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_OtpWaveClipper oldClipper) => false;
}

// ─── CHAMP OTP INDIVIDUEL ────────────────────────────────────────────────────
class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.violetDark,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: controller.text.isNotEmpty
                ? AppColors.violetLight
                : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: controller.text.isNotEmpty
                    ? AppColors.violetDark
                    : AppColors.border,
                width: controller.text.isNotEmpty ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.violetDark,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
