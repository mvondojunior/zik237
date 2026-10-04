import 'package:app_mobile_music_underground/screens/auditeur/pourboire_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/screens/auditeur/lecteur_screen.dart';
import 'package:app_mobile_music_underground/screens/auditeur/pourboire_screen.dart';

/// Écran profil artiste — Vue Auditeur — Zik237
/// Affiche le profil public d'un artiste avec ses titres,
/// ses statistiques et le bouton de pourboire.

class ProfilScreenForArtiste extends StatefulWidget {
  final String artisteId;

  const ProfilScreenForArtiste({super.key, required this.artisteId});

  @override
  State<ProfilScreenForArtiste> createState() => _ProfilArtisteScreenState();
}

class _ProfilArtisteScreenState extends State<ProfilScreenForArtiste>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  Map<String, dynamic>? _artiste;
  Map<String, dynamic>? _profilArtiste;
  List<Map<String, dynamic>> _titres = [];
  bool _isLoading = true;
  bool _isSuivi = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfil();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Charger le profil depuis Supabase ───────────────────────────────────
  Future<void> _loadProfil() async {
    setState(() => _isLoading = true);

    try {
      // Charger les infos de l'artiste
      final artiste = await _supabase
          .from('utilisateurs')
          .select()
          .eq('id', widget.artisteId)
          .single();

      // Charger le profil artiste
      final profilArtiste = await _supabase
          .from('profils_artiste')
          .select()
          .eq('id', widget.artisteId)
          .single();

      // Charger les titres publiés
      final titres = await _supabase
          .from('titres')
          .select()
          .eq('artiste_id', widget.artisteId)
          .eq('publie', true)
          .order('nb_ecoutes', ascending: false);

      setState(() {
        _artiste = artiste;
        _profilArtiste = profilArtiste;
        _titres = List<Map<String, dynamic>>.from(titres);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de chargement du profil.');
    }
  }

  // ── Suivre / Ne plus suivre ─────────────────────────────────────────────
  void _toggleSuivi() {
    setState(() => _isSuivi = !_isSuivi);
    _showSnackBar(
      _isSuivi
          ? 'Tu suis maintenant ${_artiste?['nom_affichage']}'
          : 'Tu ne suis plus ${_artiste?['nom_affichage']}',
    );
    // TODO: mettre à jour la table followers en base
  }

  // ── Afficher le sheet de pourboire ──────────────────────────────────────
  void _showPourboireSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PourboireSheet(
        nomArtiste: _artiste?['nom_affichage'] ?? 'l\'artiste',
        onEnvoyer: (montant) {
          Navigator.of(context).pop();
          _showSnackBar('Pourboire de $montant FCFA envoyé ! 💰');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PourboireScreen(artiste: {},),
            ),
          );
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

  String _formatNumber(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.violetDark,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final nomArtiste = _artiste?['nom_affichage'] ?? 'Artiste';
    final ville = _artiste?['ville'] ?? '';
    final bio = _profilArtiste?['bio'] ?? '';
    final totalEcoutes = _profilArtiste?['total_ecoutes'] as int? ?? 0;
    final totalPourboires = _profilArtiste?['total_pourboires'] as int? ?? 0;
    final estPremium = _profilArtiste?['est_premium'] as bool? ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── APP BAR ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.violetDark,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfilHeader(
                nomArtiste: nomArtiste,
                ville: ville,
                bio: bio,
                estPremium: estPremium,
                totalEcoutes: totalEcoutes,
                totalPourboires: totalPourboires,
                isSuivi: _isSuivi,
                onToggleSuivi: _toggleSuivi,
                onPourboire: _showPourboireSheet,
                formatNumber: _formatNumber,
              ),
            ),
          ),

          // ── TABS ──────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.violetDark,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.violetDark,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Titres (${_titres.length})'),
                  const Tab(text: 'À propos'),
                ],
              ),
            ),
          ),
        ],

        // ── CONTENU TABS ──────────────────────────────────────────
        body: TabBarView(
          controller: _tabController,
          children: [
            // Onglet Titres
            _TitresList(
              titres: _titres,
              nomArtiste: nomArtiste,
            ),

            // Onglet À propos
            _APropos(
              bio: bio,
              ville: ville,
              totalEcoutes: totalEcoutes,
              totalPourboires: totalPourboires,
              estPremium: estPremium,
              formatNumber: _formatNumber,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HEADER PROFIL ────────────────────────────────────────────────────────────
class _ProfilHeader extends StatelessWidget {
  final String nomArtiste;
  final String ville;
  final String bio;
  final bool estPremium;
  final int totalEcoutes;
  final int totalPourboires;
  final bool isSuivi;
  final VoidCallback onToggleSuivi;
  final VoidCallback onPourboire;
  final String Function(int) formatNumber;

  const _ProfilHeader({
    required this.nomArtiste,
    required this.ville,
    required this.bio,
    required this.estPremium,
    required this.totalEcoutes,
    required this.totalPourboires,
    required this.isSuivi,
    required this.onToggleSuivi,
    required this.onPourboire,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.violetDark, Color(0xFF2A2650)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentAuditeur, AppColors.violetDark],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),

          // Nom + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nomArtiste,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (estPremium) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: AppColors.accentArtiste,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Ville
          if (ville.isNotEmpty)
            Text(
              ville,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
          const SizedBox(height: 14),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                label: 'Écoutes',
                value: formatNumber(totalEcoutes),
              ),
              const SizedBox(width: 24),
              _StatChip(
                label: 'FCFA reçus',
                value: formatNumber(totalPourboires),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Boutons
          Row(
            children: [
              // Suivre
              Expanded(
                child: GestureDetector(
                  onTap: onToggleSuivi,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSuivi
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isSuivi
                          ? Border.all(color: Colors.white30)
                          : null,
                    ),
                    child: Text(
                      isSuivi ? 'Suivi ✓' : 'Suivre',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSuivi
                            ? Colors.white
                            : AppColors.violetDark,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Pourboire
              Expanded(
                child: GestureDetector(
                  onTap: onPourboire,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Soutenir',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── STAT CHIP ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}

// ─── LISTE DES TITRES ─────────────────────────────────────────────────────────
class _TitresList extends StatelessWidget {
  final List<Map<String, dynamic>> titres;
  final String nomArtiste;

  static const List<Color> _couleurs = [
    Color(0xFF7F77DD), Color(0xFFD4537E),
    Color(0xFFEF9F27), Color(0xFF2EAF8A),
    Color(0xFF534AB7),
  ];

  const _TitresList({required this.titres, required this.nomArtiste});

  @override
  Widget build(BuildContext context) {
    if (titres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.music_off_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Aucun titre publié',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: titres.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final titre = titres[index];
        final couleur = _couleurs[index % _couleurs.length];
        final nbEcoutes = titre['nb_ecoutes'] as int? ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LecteurScreen(titre: {
                  ...titre,
                  'utilisateurs': {'nom_affichage': nomArtiste},
                }),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                // Numéro
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),

                // Pochette
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: couleur.withOpacity(0.4)),
                  ),
                  child: titre['pochette_url'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      titre['pochette_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.music_note_rounded,
                        color: couleur, size: 20,
                      ),
                    ),
                  )
                      : Icon(Icons.music_note_rounded, color: couleur, size: 20),
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre['titre'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            titre['genre_principal'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Text(
                            ' · ',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const Icon(
                            Icons.headphones_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _fmt(nbEcoutes),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Play
                const Icon(
                  Icons.play_circle_rounded,
                  size: 28,
                  color: AppColors.violetDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();
}

// ─── À PROPOS ─────────────────────────────────────────────────────────────────
class _APropos extends StatelessWidget {
  final String bio;
  final String ville;
  final int totalEcoutes;
  final int totalPourboires;
  final bool estPremium;
  final String Function(int) formatNumber;

  const _APropos({
    required this.bio,
    required this.ville,
    required this.totalEcoutes,
    required this.totalPourboires,
    required this.estPremium,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          if (bio.isNotEmpty) ...[
            const Text(
              'Biographie',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                bio,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Infos
          const Text(
            'Informations',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Ville',
            value: ville.isNotEmpty ? ville : 'Non renseignée',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.headphones_rounded,
            label: 'Total écoutes',
            value: formatNumber(totalEcoutes),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Pourboires reçus (FCFA)',
            value: formatNumber(totalPourboires),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.star_rounded,
            label: 'Compte Premium',
            value: estPremium ? 'Oui ✓' : 'Non',
            valueColor: estPremium ? AppColors.accentArtiste : null,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.violetMid),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB BAR DELEGATE ─────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ─── SHEET POURBOIRE ──────────────────────────────────────────────────────────
class _PourboireSheet extends StatefulWidget {
  final String nomArtiste;
  final ValueChanged<int> onEnvoyer;

  const _PourboireSheet({
    required this.nomArtiste,
    required this.onEnvoyer,
  });

  @override
  State<_PourboireSheet> createState() => _PourboireSheetState();
}

class _PourboireSheetState extends State<_PourboireSheet> {
  int? _montant;
  final List<int> _montants = [100, 250, 500, 1000];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Soutenir ${widget.nomArtiste}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choisis un montant (FCFA)',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          Row(
            children: _montants.map((m) {
              final isSelected = m == _montant;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _montant = m),
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
                        ),
                      ),
                      child: Text(
                        '$m',
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
          const SizedBox(height: 10),

          const Text(
            '10% de commission prélevée par Zik237',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _montant != null
                  ? () => widget.onEnvoyer(_montant!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violetDark,
                disabledBackgroundColor: AppColors.violetSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _montant != null
                    ? 'Envoyer $_montant FCFA via MoMo'
                    : 'Choisir un montant',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}