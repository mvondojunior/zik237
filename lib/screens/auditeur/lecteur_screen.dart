import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';

/// Écran lecteur audio — Zik237 (Auditeur)
/// Lecture streaming depuis Supabase Storage via just_audio.
/// Gère : lecture/pause, progression, volume, pourboire.

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

  // Montants pourboire disponibles
  final List<int> _montants = [100, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _initPlayer();
    _enregistrerEcoute();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _player.dispose();
    super.dispose();
  }

  // ── Initialiser le lecteur ────────────────────────────────────────────────
  Future<void> _initPlayer() async {
    try {
      final audioUrl = widget.titre['audio_url'] as String?;
      if (audioUrl == null) return;

      await _player.setUrl(audioUrl);

      // Écoute de la progression
      _player.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      });

      // Écoute de la durée totale
      _player.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _duration = duration);
        }
      });

      // Écoute état lecture
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

  // ── Enregistrer l'écoute en base ─────────────────────────────────────────
  Future<void> _enregistrerEcoute() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('ecoutes').insert({
        'titre_id': widget.titre['id'],
        'auditeur_id': userId,
        'ville_auditeur': null, // TODO: récupérer la ville de l'utilisateur
        'completed': false,
      });
    } catch (_) {
      // Silencieux — une écoute manquée n'est pas critique
    }
  }

  // ── Lecture / Pause ───────────────────────────────────────────────────────
  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  // ── Seek (déplacer la progression) ───────────────────────────────────────
  Future<void> _seekTo(double value) async {
    final position = Duration(
      milliseconds: (value * _duration.inMilliseconds).toInt(),
    );
    await _player.seek(position);
  }

  // ── Afficher le sheet de pourboire ────────────────────────────────────────
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
          // TODO: navigation vers PourboreScreen avec montant et artiste
          _showSnackBar('Pourboire de $montant FCFA envoyé ! 💰');
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
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ── Formater la durée ─────────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final artiste =
    widget.titre['utilisateurs'] as Map<String, dynamic>?;
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'En écoute',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        genre,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.violetMid,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: menu options (partager, ajouter à playlist...)
                    },
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // ── POCHETTE ANIMÉE ──────────────────────────────────────
            Expanded(
              flex: 4,
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
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violetDark.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.titre['pochette_url'] != null
                          ? Image.network(
                        widget.titre['pochette_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _DefaultPochette(),
                      )
                          : _DefaultPochette(),
                    ),
                  ),
                ),
              ),
            ),

            // ── INFOS TITRE ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titreName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$nomArtiste${ville.isNotEmpty ? ' · $ville' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton like
                  IconButton(
                    onPressed: () =>
                        setState(() => _isLiked = !_isLiked),
                    icon: Icon(
                      _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isLiked
                          ? AppColors.error
                          : AppColors.textMuted,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // ── BARRE DE PROGRESSION ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: AppColors.violetDark,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.violetDark,
                      overlayColor:
                      AppColors.violetDark.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: _seekTo,
                    ),
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── CONTRÔLES ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.shuffle_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                  // Précédent
                  IconButton(
                    onPressed: () async {
                      await _player.seek(Duration.zero);
                    },
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: AppColors.textPrimary,
                      size: 36,
                    ),
                  ),
                  // Play / Pause
                  GestureDetector(
                    onTap: _isLoading ? null : _togglePlay,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.violetDark,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                            AppColors.violetDark.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Suivant
                  IconButton(
                    onPressed: () async {
                      await _player.seek(_duration);
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.textPrimary,
                      size: 36,
                    ),
                  ),
                  // Repeat
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

            // ── BOUTON POURBOIRE ─────────────────────────────────────
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showPourboireSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 18,
                              color: AppColors.violetMid,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Soutenir $nomArtiste',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    final nomArtiste =
        widget.artiste?['nom_affichage'] ?? 'l\'artiste';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
          const SizedBox(height: 20),

          // Titre
          Text(
            'Soutenir $nomArtiste',
            style: const TextStyle(
              fontSize: 18,
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
          const SizedBox(height: 20),

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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.violetDark
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.violetDark
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        '$montant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
          const SizedBox(height: 12),

          // Note commission
          Text(
            '10% de commission prélevée par Zik237',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Bouton envoyer
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