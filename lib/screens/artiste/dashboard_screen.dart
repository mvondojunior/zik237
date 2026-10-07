import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/screens/artiste/upload_screen.dart';
import 'package:app_mobile_music_underground/screens/auditeur/decouverte_screen.dart';
import 'package:app_mobile_music_underground/screens/auditeur/recherche_screen.dart';
import 'package:app_mobile_music_underground/screens/artiste/playlist.dart';
import 'package:app_mobile_music_underground/screens/artiste/profil_artiste_screen.dart';
import 'package:app_mobile_music_underground/screens/artiste/pourboire_screen_artiste.dart';

/// Dashboard Artiste — Zik237
/// L'artiste est aussi un auditeur — il a accès aux deux modes.
/// Mode Artiste : stats, titres, revenus, upload.
/// Mode Auditeur : découverte, recherche, playlists.
/// Couleur dominante : violet (cohérent entre les deux modes).

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  // Mode actif : 'artiste' ou 'auditeur'
  String _modeActif = 'artiste';
  int _navIndex = 0;

  // Données artiste
  Map<String, dynamic>? _utilisateur;
  Map<String, dynamic>? _profilArtiste;
  List<Map<String, dynamic>> _titres = [];
  List<int> _ecoutes7j = [0, 0, 0, 0, 0, 0, 0];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonnees();
  }

  // ── Charger les données depuis Supabase ─────────────────────────────────
  Future<void> _loadDonnees() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      final utilisateur = await _supabase
          .from('utilisateurs')
          .select()
          .eq('id', userId)
          .single();

      final profilArtiste = await _supabase
          .from('profils_artiste')
          .select()
          .eq('id', userId)
          .single();

      final titres = await _supabase
          .from('titres')
          .select()
          .eq('artiste_id', userId)
          .order('nb_ecoutes', ascending: false)
          .limit(4);

      setState(() {
        _utilisateur = utilisateur;
        _profilArtiste = profilArtiste;
        _titres = List<Map<String, dynamic>>.from(titres);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatNumber(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  // ── Basculer entre mode artiste et auditeur ─────────────────────────────
  void _switchMode(String mode) {
    setState(() {
      _modeActif = mode;
      _navIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.violetMid,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return _modeActif == 'artiste'
        ? _ArtisteDashboard(
      utilisateur: _utilisateur,
      profilArtiste: _profilArtiste,
      titres: _titres,
      ecoutes7j: _ecoutes7j,
      onSwitchMode: () => _switchMode('auditeur'),
      onRefresh: _loadDonnees,
      formatNumber: _formatNumber,
    )
        : _AuditeurDashboard(
      utilisateur: _utilisateur,
      onSwitchMode: () => _switchMode('artiste'),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODE ARTISTE
// ══════════════════════════════════════════════════════════════════════════════
class _ArtisteDashboard extends StatefulWidget {
  final Map<String, dynamic>? utilisateur;
  final Map<String, dynamic>? profilArtiste;
  final List<Map<String, dynamic>> titres;
  final List<int> ecoutes7j;
  final VoidCallback onSwitchMode;
  final Future<void> Function() onRefresh;
  final String Function(int) formatNumber;

  const _ArtisteDashboard({
    required this.utilisateur,
    required this.profilArtiste,
    required this.titres,
    required this.ecoutes7j,
    required this.onSwitchMode,
    required this.onRefresh,
    required this.formatNumber,
  });

  @override
  State<_ArtisteDashboard> createState() => _ArtisteDashboardState();
}

class _ArtisteDashboardState extends State<_ArtisteDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final nom = widget.utilisateur?['nom_affichage'] ?? '';
    final ville = widget.utilisateur?['ville'] ?? '';
    final estPremium =
        widget.profilArtiste?['est_premium'] as bool? ?? false;
    final totalEcoutes =
        widget.profilArtiste?['total_ecoutes'] as int? ?? 0;
    final totalPourboires =
        widget.profilArtiste?['total_pourboires'] as int? ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.violetMid,
        backgroundColor: AppColors.surface,
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────────
              _ArtisteHeader(
                nom: nom,
                ville: ville,
                estPremium: estPremium,
                onSwitchMode: widget.onSwitchMode,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    const _SectionTitle(title: 'Vue d\'ensemble'),
                    const SizedBox(height: 16),
                    _StatsGrid(
                      totalEcoutes: totalEcoutes,
                      totalPourboires: totalPourboires,
                      nbTitres: widget.titres.length,
                      formatNumber: widget.formatNumber,
                    ),
                    const SizedBox(height: 32),

                    // Graphique
                    const _SectionTitle(title: 'Écoutes — 7 derniers jours'),
                    const SizedBox(height: 16),
                    _EcoutesChart(data: widget.ecoutes7j),
                    const SizedBox(height: 32),

                    // Mes titres
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mes titres',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/mestitres'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.violetMid.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Voir tout',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.violetMid,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...widget.titres.map((t) => _TitreCard(
                      titre: t,
                      formatNumber: widget.formatNumber,
                    )),
                    const SizedBox(height: 28),

                    // Bouton publier
                    AppPrimaryButton(
                      label: '+ Publier un nouveau titre',
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UploadScreen(),
                          ),
                        );
                        widget.onRefresh();
                      },
                      color: AppColors.violetMid,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom nav artiste
      bottomNavigationBar: _ArtisteBottomNav(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() => _navIndex = index);
          switch (index) {
            case 0:
              break; // déjà sur le dashboard
            case 1:
              Navigator.of(context).pushNamed('/mestitres');
              break;
            case 2:
              Navigator.of(context).pushNamed('/revenus');
              break;
            case 3:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ProfilArtisteScreen(),
              ));
              break;
          }
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODE AUDITEUR (pour l'artiste qui écoute)
// ══════════════════════════════════════════════════════════════════════════════
class _AuditeurDashboard extends StatefulWidget {
  final Map<String, dynamic>? utilisateur;
  final VoidCallback onSwitchMode;

  const _AuditeurDashboard({
    required this.utilisateur,
    required this.onSwitchMode,
  });

  @override
  State<_AuditeurDashboard> createState() => _AuditeurDashboardState();
}

class _AuditeurDashboardState extends State<_AuditeurDashboard> {
  int _navIndex = 0;

  final List<Widget> _screens = const [
    DecouverteScreen(),
    RechercheScreen(),
    Playlist(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Bandeau mode auditeur en haut
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.violetDark,
            boxShadow: [
              BoxShadow(
                color: AppColors.violetDark.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mode Auditeur',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onSwitchMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.violetMid.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.violetMid.withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.mic_rounded,
                            size: 14, color: AppColors.violetMid),
                        SizedBox(width: 6),
                        Text(
                          'Mode Artiste',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.violetMid,
                            fontWeight: FontWeight.w600,
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
      ),

      // Contenu de l'onglet actif
      body: IndexedStack(
        index: _navIndex,
        children: _screens,
      ),

      // Bottom nav auditeur
      bottomNavigationBar: _AuditeurBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}

// ─── HEADER ARTISTE ───────────────────────────────────────────────────────────
class _ArtisteHeader extends StatelessWidget {
  final String nom;
  final String ville;
  final bool estPremium;
  final VoidCallback onSwitchMode;

  const _ArtisteHeader({
    required this.nom,
    required this.ville,
    required this.estPremium,
    required this.onSwitchMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.violetDark,
            const Color(0xFF1A0F2E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetDark.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // MENU DÉROULANT (haut à gauche)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'auditeur') {
                        onSwitchMode();
                      }
                    },
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: AppColors.surface,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'artiste',
                        child: Row(
                          children: [
                            Icon(Icons.mic_rounded,
                                size: 18, color: AppColors.violetMid),
                            SizedBox(width: 10),
                            Text(
                              'Mode Artiste',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'auditeur',
                        child: Row(
                          children: [
                            Icon(Icons.headphones_rounded,
                                size: 18, color: AppColors.violetMid),
                            SizedBox(width: 10),
                            Text(
                              'Mode Auditeur',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.violetMid.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.violetMid.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.menu_rounded,
                              size: 16, color: AppColors.violetMid),
                          SizedBox(width: 6),
                          Text(
                            'Mode Artiste',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.violetMid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: AppColors.violetMid),
                        ],
                      ),
                    ),
                  ),

                  // Badge Premium (si premium)
                  if (estPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.violetMid.withOpacity(0.3),
                            AppColors.violetMid.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.violetMid.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.star_rounded,
                              size: 14, color: AppColors.violetMid),
                          SizedBox(width: 5),
                          Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.violetMid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Profil
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.violetMid,
                          AppColors.violetDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.violetMid.withOpacity(0.5),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violetMid.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.55),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ville.isNotEmpty ? ville : 'Cameroun',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── STATS GRID ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final int totalEcoutes;
  final int totalPourboires;
  final int nbTitres;
  final String Function(int) formatNumber;

  const _StatsGrid({
    required this.totalEcoutes,
    required this.totalPourboires,
    required this.nbTitres,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Écoutes',
            value: formatNumber(totalEcoutes),
            icon: Icons.headphones_rounded,
            color: AppColors.violetMid,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'FCFA reçus',
            value: formatNumber(totalPourboires),
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Titres',
            value: nbTitres.toString(),
            icon: Icons.music_note_rounded,
            color: AppColors.violetMid,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GRAPHIQUE ÉCOUTES ────────────────────────────────────────────────────────
class _EcoutesChart extends StatelessWidget {
  final List<int> data;
  const _EcoutesChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final jours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(data.length, (i) {
          final ratio = maxVal > 0 ? data[i] / maxVal : 0.0;
          final isMax = data[i] == maxVal && maxVal > 0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isMax)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    data[i] >= 1000
                        ? '${(data[i] / 1000).toStringAsFixed(1)}k'
                        : '${data[i]}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.violetMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                width: 26,
                height: (70 * ratio).clamp(4.0, 70.0),
                decoration: BoxDecoration(
                  gradient: isMax
                      ? LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.violetMid,
                      AppColors.violetMid.withOpacity(0.7),
                    ],
                  )
                      : null,
                  color: isMax
                      ? null
                      : AppColors.violetSoft.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isMax
                      ? [
                    BoxShadow(
                      color: AppColors.violetMid.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                jours[i],
                style: TextStyle(
                  fontSize: 11,
                  color: isMax
                      ? AppColors.violetMid
                      : AppColors.textMuted,
                  fontWeight: isMax ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── CARTE TITRE ─────────────────────────────────────────────────────────────
class _TitreCard extends StatelessWidget {
  final Map<String, dynamic> titre;
  final String Function(int) formatNumber;

  static const List<Color> _couleurs = [
    Color(0xFF7F77DD),
    Color(0xFFD4537E),
    Color(0xFFEF9F27),
    Color(0xFF2EAF8A),
  ];

  const _TitreCard({
    required this.titre,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final bool publie = titre['publie'] as bool? ?? true;
    final String nom = titre['titre'] as String? ?? '';
    final int ecoutes = titre['nb_ecoutes'] as int? ?? 0;
    final String genre = titre['genre_principal'] as String? ?? '';
    final Color color = titre.containsKey('color')
        ? titre['color'] as Color
        : _couleurs[nom.hashCode.abs() % _couleurs.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withOpacity(0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pochette
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(Icons.music_note_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      size: 14,
                      color: publie
                          ? AppColors.violetMid
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${formatNumber(ecoutes)} écoutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: publie
                            ? AppColors.violetMid
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (genre.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.violetLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.violetMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: publie
                      ? AppColors.violetMid.withOpacity(0.12)
                      : AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  publie ? 'Publié' : 'Masqué',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: publie
                        ? AppColors.violetMid
                        : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textMuted.withOpacity(0.7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── SECTION TITLE ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ─── BOTTOM NAV ARTISTE ───────────────────────────────────────────────────────
class _ArtisteBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ArtisteBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(0.8),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                color: AppColors.violetMid,
              ),
              _NavItem(
                icon: Icons.music_note_rounded,
                label: 'Titres',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                color: AppColors.violetMid,
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Revenus',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                color: AppColors.violetMid,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                color: AppColors.violetMid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BOTTOM NAV AUDITEUR ──────────────────────────────────────────────────────
class _AuditeurBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AuditeurBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(0.8),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                color: AppColors.violetMid,
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Recherche',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                color: AppColors.violetMid,
              ),
              _NavItem(
                icon: Icons.queue_music_rounded,
                label: 'Playlists',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                color: AppColors.violetMid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NAV ITEM ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? color : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}