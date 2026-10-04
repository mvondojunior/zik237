import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';

/// Écran pourboire — Zik237 (Auditeur)
/// Permet à l'auditeur d'envoyer un pourboire à un artiste via Mobile Money.
/// Reçoit en paramètre l'artiste et le titre concerné.

class PourboireScreen extends StatefulWidget {
  final Map<String, dynamic> artiste;
  final Map<String, dynamic>? titre;

  const PourboireScreen({
    super.key,
    required this.artiste,
    this.titre,
  });

  @override
  State<PourboireScreen> createState() => _PourboireScreenState();
}

class _PourboireScreenState extends State<PourboireScreen> {
  final _supabase = Supabase.instance.client;

  int? _montantSelectionne;
  String _operateur = 'mtn'; // 'mtn' ou 'orange'
  bool _isLoading = false;
  bool _transactionReussie = false;

  final List<int> _montants = [100, 250, 500, 1000, 2000, 5000];

  // ── Calculer la commission ──────────────────────────────────────────────
  int get _commission {
    if (_montantSelectionne == null) return 0;
    final estPremium =
        widget.artiste['profils_artiste']?['est_premium'] as bool? ?? false;
    return (_montantSelectionne! * (estPremium ? 0.05 : 0.10)).round();
  }

  int get _montantNet {
    if (_montantSelectionne == null) return 0;
    return _montantSelectionne! - _commission;
  }

  // ── Initier le pourboire ────────────────────────────────────────────────
  Future<void> _envoyerPourboire() async {
    if (_montantSelectionne == null) {
      _showSnackBar('Choisis un montant');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auditeurId = _supabase.auth.currentUser!.id;
      final artisteId = widget.artiste['id'] as String;

      // Enregistrer la transaction en base
      await _supabase.from('pourboires').insert({
        'auditeur_id': auditeurId,
        'artiste_id': artisteId,
        'titre_id': widget.titre?['id'],
        'montant_fcfa': _montantSelectionne,
        'commission_fcfa': _commission,
        'montant_net_fcfa': _montantNet,
        'operateur': _operateur,
        'statut': 'en_attente',
      });

      // TODO: appel API MTN MoMo ou Orange Money
      // final response = await MobileMoneyService().initierTransaction(
      //   montant: _montantSelectionne!,
      //   operateur: _operateur,
      //   numeroArtiste: widget.artiste['profils_artiste']['mobile_money_numero'],
      // );

      // Simulation
      await Future.delayed(const Duration(seconds: 2));

      // Mettre à jour le statut
      await _supabase
          .from('pourboires')
          .update({'statut': 'confirme'})
          .eq('auditeur_id', auditeurId)
          .eq('statut', 'en_attente');

      // Mettre à jour total_pourboires de l'artiste
      await _supabase.rpc('incrementer_pourboires', params: {
        'artiste_id': artisteId,
        'montant': _montantNet,
      });

      setState(() {
        _isLoading = false;
        _transactionReussie = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur lors de l\'envoi. Réessaie.');
    }
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

  @override
  Widget build(BuildContext context) {
    final nomArtiste =
        widget.artiste['nom_affichage'] as String? ?? 'Artiste';
    final titreName = widget.titre?['titre'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _transactionReussie
            ? _SuccessState(
          nomArtiste: nomArtiste,
          montant: _montantSelectionne!,
          montantNet: _montantNet,
          onRetour: () => Navigator.of(context).pop(),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────
              _PourboireHeader(
                onBack: () => Navigator.of(context).pop(),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── INFO ARTISTE ──────────────────────────
                    _ArtisteInfo(
                      nomArtiste: nomArtiste,
                      titreName: titreName,
                      artiste: widget.artiste,
                    ),
                    const SizedBox(height: 28),

                    // ── MONTANTS ──────────────────────────────
                    const Text(
                      'Choisir le montant (FCFA)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                      children: _montants.map((montant) {
                        final isSelected =
                            montant == _montantSelectionne;
                        return GestureDetector(
                          onTap: () => setState(
                                  () => _montantSelectionne = montant),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.violetDark
                                  : AppColors.surface,
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.violetDark
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$montant',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ── OPÉRATEUR ─────────────────────────────
                    const Text(
                      'Opérateur Mobile Money',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _OperateurCard(
                            label: 'MTN MoMo',
                            color: const Color(0xFFFFCC00),
                            isSelected: _operateur == 'mtn',
                            onTap: () => setState(
                                    () => _operateur = 'mtn'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OperateurCard(
                            label: 'Orange Money',
                            color: const Color(0xFFFF6600),
                            isSelected: _operateur == 'orange',
                            onTap: () => setState(
                                    () => _operateur = 'orange'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── RÉCAPITULATIF ─────────────────────────
                    if (_montantSelectionne != null) ...[
                      _Recapitulatif(
                        montant: _montantSelectionne!,
                        commission: _commission,
                        montantNet: _montantNet,
                        nomArtiste: nomArtiste,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── BOUTON ENVOYER ────────────────────────
                    AppPrimaryButton(
                      label: _montantSelectionne != null
                          ? 'Envoyer $_montantSelectionne FCFA via ${_operateur == 'mtn' ? 'MTN MoMo' : 'Orange Money'}'
                          : 'Choisir un montant',
                      isLoading: _isLoading,
                      onPressed: _envoyerPourboire,
                    ),
                    const SizedBox(height: 12),

                    // Note sécurité
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Transaction sécurisée via Mobile Money',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _PourboireHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _PourboireHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          Container(height: 150, color: AppColors.violetDark),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(height: 50, color: AppColors.background),
            ),
          ),
          Positioned(
            top: 48, left: 16,
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
            top: 50, left: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  'Envoyer un pourboire',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 50, right: 24,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INFO ARTISTE ─────────────────────────────────────────────────────────────
class _ArtisteInfo extends StatelessWidget {
  final String nomArtiste;
  final String? titreName;
  final Map<String, dynamic> artiste;

  const _ArtisteInfo({
    required this.nomArtiste,
    required this.titreName,
    required this.artiste,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentArtiste, Color(0xFF0F6E56)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomArtiste,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (titreName != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.music_note_rounded,
                        size: 13,
                        color: AppColors.violetMid,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          titreName!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Badge Premium
          if (artiste['profils_artiste']?['est_premium'] == true)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentArtiste.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentArtiste.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.star_rounded,
                      size: 12, color: AppColors.accentArtiste),
                  SizedBox(width: 3),
                  Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.accentArtiste,
                      fontWeight: FontWeight.w600,
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

// ─── CARTE OPÉRATEUR ──────────────────────────────────────────────────────────
class _OperateurCard extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _OperateurCard({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── RÉCAPITULATIF ────────────────────────────────────────────────────────────
class _Recapitulatif extends StatelessWidget {
  final int montant;
  final int commission;
  final int montantNet;
  final String nomArtiste;

  const _Recapitulatif({
    required this.montant,
    required this.commission,
    required this.montantNet,
    required this.nomArtiste,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.violetLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.violetSoft),
      ),
      child: Column(
        children: [
          _LigneRecap(
            label: 'Montant envoyé',
            value: '$montant FCFA',
          ),
          const Divider(color: AppColors.border, height: 20),
          _LigneRecap(
            label: 'Commission Zik237',
            value: '- $commission FCFA',
            valueColor: AppColors.error,
          ),
          const Divider(color: AppColors.border, height: 20),
          _LigneRecap(
            label: '$nomArtiste recevra',
            value: '$montantNet FCFA',
            valueColor: AppColors.success,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _LigneRecap extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _LigneRecap({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── ÉTAT SUCCÈS ──────────────────────────────────────────────────────────────
class _SuccessState extends StatelessWidget {
  final String nomArtiste;
  final int montant;
  final int montantNet;
  final VoidCallback onRetour;

  const _SuccessState({
    required this.nomArtiste,
    required this.montant,
    required this.montantNet,
    required this.onRetour,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône succès
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.success.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 46,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Pourboire envoyé !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'Tu as envoyé ',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$montant FCFA',
                  style: const TextStyle(
                    color: AppColors.violetDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' à '),
                TextSpan(
                  text: nomArtiste,
                  style: const TextStyle(
                    color: AppColors.violetDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                    text: '. Il recevra '),
                TextSpan(
                  text: '$montantNet FCFA',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' sur son compte Mobile Money.'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Confettis emoji
          const Text('🎵 💰 🎶',
              style: TextStyle(fontSize: 32)
          ),
          const SizedBox(height: 32),

          AppPrimaryButton(
            label: 'Retour',
            onPressed: onRetour,
          ),
        ],
      ),
    );
  }
}

// ─── WAVE CLIPPER ─────────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
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
  bool shouldReclip(_WaveClipper oldClipper) => false;
}