import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';

/// Écran lecteur audio — Zik237 (Auditeur)

class LecteurScreen extends StatefulWidget {
  final Map<String, dynamic> titre;

  const LecteurScreen({super.key, required this.titre});

  @override
  State<LecteurScreen> createState() => _LecteurScreenState();
}

class _LecteurScreenState extends State<LecteurScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _player = AudioPlayer();
  late AnimationController _rotationController;

  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isLiked = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final List<int> _montants = [100, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _initPlayer();
    _enregistrerEcoute();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    try {
      final audioUrl = widget.titre['audio_url'] as String?;
      if (audioUrl == null) return;

      await _player.setUrl(audioUrl);

      _player.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      });

      _player.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _duration = duration);
        }
      });

      _player.playingStream.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
          if (playing) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
          }
        }
      });

      setState(() => _isLoading = false);
      await _player.play();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de lecture. Vérifie ta connexion.');
    }
  }

  Future<void> _enregistrerEcoute() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('ecoutes').insert({
        'titre_id': widget.titre['id'],
        'auditeur_id': userId,
        'ville_auditeur': null,
        'completed': false,
      });
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seekTo(double value) async {
    final position = Duration(
      milliseconds: (value * _duration.inMilliseconds).toInt(),
    );
    await _player.seek(position);
  }

  void _showPourboireSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PourboireSheet(
        artiste: widget.titre['utilisateurs'] as Map<String, dynamic>?,
        montants: _montants,
        onEnvoyer: (montant) {
          Navigator.of(context).pop();
          _showSnackBar('Pourboire de $montant FCFA envoyé !');
        },
      ),
    );
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final artiste = widget.titre['utilisateurs'] as Map<String, dynamic>?;
    final nomArtiste = artiste?['nom_affichage'] ?? 'Artiste inconnu';
    final titreName = widget.titre['titre'] as String? ?? '';
    final genre = widget.titre['genre_principal'] as String? ?? '';
    final ville = widget.titre['ville'] as String? ?? '';
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 30,
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'EN ÉCOUTE',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        genre,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.violetMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: menu options
                    },
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // ── POCHETTE ────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Center(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (_, child) => Transform.rotate(
                    angle: _isPlaying
                        ? _rotationController.value * 2 * 3.14159
                        : 0,
                    child: child,
                  ),
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violetDark.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.titre['pochette_url'] != null
                          ? Image.network(
                        widget.titre['pochette_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const _DefaultPochette(),
                      )
                          : const _DefaultPochette(),
                    ),
                  ),
                ),
              ),
            ),

            // ── INFOS TITRE ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titreName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$nomArtiste${ville.isNotEmpty ? ' · $ville' : ''}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isLiked = !_isLiked),
                    icon: Icon(
                      _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isLiked ? AppColors.error : AppColors.textMuted,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // ── PROGRESSION ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: AppColors.violetDark,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.violetDark,
                      overlayColor: AppColors.violetDark.withOpacity(0.15),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: _seekTo,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── CONTRÔLES ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.shuffle_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await _player.seek(Duration.zero);
                    },
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: AppColors.textPrimary,
                      size: 38,
                    ),
                  ),
                  // Play / Pause
                  GestureDetector(
                    onTap: _isLoading ? null : _togglePlay,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.violetDark,
                            Color(0xFF5B2C8A),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violetDark.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await _player.seek(_duration);
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.textPrimary,
                      size: 38,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await _player.setLoopMode(
                        _player.loopMode == LoopMode.one
                            ? LoopMode.off
                            : LoopMode.one,
                      );
                    },
                    icon: const Icon(
                      Icons.repeat_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // ── POURBOIRE ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: GestureDetector(
                onTap: _showPourboireSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.violetDark.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: AppColors.violetDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Soutenir $nomArtiste',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
    );
  }
}

// ─── POCHETTE PAR DÉFAUT ──────────────────────────────────────────────────────
class _DefaultPochette extends StatelessWidget {
  const _DefaultPochette();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.violetMid, AppColors.violetDark],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white54,
        size: 80,
      ),
    );
  }
}

// ─── SHEET POURBOIRE ──────────────────────────────────────────────────────────
class _PourboireSheet extends StatefulWidget {
  final Map<String, dynamic>? artiste;
  final List<int> montants;
  final ValueChanged<int> onEnvoyer;

  const _PourboireSheet({
    required this.artiste,
    required this.montants,
    required this.onEnvoyer,
  });

  @override
  State<_PourboireSheet> createState() => _PourboireSheetState();
}

class _PourboireSheetState extends State<_PourboireSheet> {
  int? _montantSelectionne;

  @override
  Widget build(BuildContext context) {
    final nomArtiste = widget.artiste?['nom_affichage'] ?? 'l\'artiste';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),

          Text(
            'Soutenir $nomArtiste',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choisis un montant (FCFA)',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),

          // Montants
          Row(
            children: widget.montants.map((montant) {
              final isSelected = montant == _montantSelectionne;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _montantSelectionne = montant),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.violetDark
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.violetDark
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color:
                            AppColors.violetDark.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                            : null,
                      ),
                      child: Text(
                        '$montant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          const Text(
            '10% de commission prélevée par Zik237',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 22),

          AppPrimaryButton(
            label: _montantSelectionne != null
                ? 'Envoyer $_montantSelectionne FCFA via MoMo'
                : 'Choisir un montant',
            onPressed: _montantSelectionne != null
                ? () => widget.onEnvoyer(_montantSelectionne!)
                : () {},
          ),
        ],
      ),
    );
  }
}