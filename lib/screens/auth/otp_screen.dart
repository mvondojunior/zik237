import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/services/auth_service.dart';

/// Écran de vérification OTP — Zik237 (version améliorée)

class OtpScreen extends StatefulWidget {
  final String contact;
  final bool isEmail;

  const OtpScreen({
    super.key,
    required this.contact,
    this.isEmail = true,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();
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

  String get _otpCode => _controllers.map((c) => c.text).join();
  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  Future<void> _handleVerify() async {
    if (!_isOtpComplete) {
      _showSnackBar('Merci de saisir les 6 chiffres du code');
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.verifyOtp(
      contact: widget.contact,
      code: _otpCode,
      isEmail: widget.isEmail,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error);
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } else {
      final role = await _authService.getUserRole();
      if (!mounted) return;

      _showSnackBar('Compte vérifié avec succès !');

      if (role == 'artiste') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboardscreen',
              (route) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/decouvertescreen',
              (route) => false,
        );
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    final error = await _authService.resendOtp(
      contact: widget.contact,
      isEmail: widget.isEmail,
    );

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error);
    } else {
      _startCountdown();
      _showSnackBar('Code renvoyé sur ${_maskedContact(widget.contact)}');
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
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

  void _goBack() => Navigator.of(context).pop();

  void _onOtpFieldChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isOtpComplete) _handleVerify();
      }
    }
    setState(() {});
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _maskedContact(String contact) {
    if (widget.isEmail) {
      final parts = contact.split('@');
      if (parts.length != 2) return contact;
      final name = parts[0];
      if (name.length <= 2) return contact;
      return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@${parts[1]}';
    } else {
      if (contact.length < 4) return contact;
      return '${'X' * (contact.length - 2)}${contact.substring(contact.length - 2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _OtpHeader(onBack: _goBack),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Titre
                  const Text(
                    'Vérifie ton code',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sous-titre
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),

                  // Champs OTP
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

                  // Bouton vérifier
                  AppPrimaryButton(
                    label: 'Vérifier',
                    isLoading: _isLoading,
                    onPressed: _handleVerify,
                  ),
                  const SizedBox(height: 28),

                  // Renvoyer le code
                  Center(
                    child: _canResend
                        ? GestureDetector(
                      onTap: _handleResend,
                      child: const Text(
                        'Renvoyer le code',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.violetDark,
                          fontWeight: FontWeight.w700,
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Changer de contact
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
}

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _OtpHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _OtpHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          Container(
            height: 180,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _OtpWaveClipper(),
              child: Container(height: 55, color: AppColors.background),
            ),
          ),
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
                  'Vérification',
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
          Positioned(
            top: 54,
            right: 24,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
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

class _OtpWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.45);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.45);
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_OtpWaveClipper oldClipper) => false;
}

// ─── CHAMP OTP (amélioré) ────────────────────────────────────────────────────
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
    final hasValue = controller.text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 58,
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.violetDark,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: hasValue
                ? AppColors.violetLight
                : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasValue ? AppColors.violetDark : AppColors.border,
                width: hasValue ? 1.8 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.violetDark,
                width: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}