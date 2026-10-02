import 'package:app_mobile_music_underground/screens/artiste/profil_artiste_screen.dart';
import 'package:app_mobile_music_underground/screens/artiste/upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';

/// Tableau de bord artiste — Zik237

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // TODO: remplacer par les données réelles
  final String _nomArtiste = 'Kev.237';
  final String _ville = 'Douala';
  final String _genre = 'Trap 237';
  final bool _estPremium = true;

  final int _totalEcoutes = 4200;
  final int _totalAbonnes = 312;
  final int _totalPourboires = 8500;
  final int _nbTitres = 8;

  final List<int> _ecoutes7j = [180, 240, 310, 280, 420, 390, 510];

  final List<Map<String, dynamic>> _titres = [
    {
      'titre': 'Nuit Blanche',
      'ecoutes': 4200,
      'genre': 'Trap 237',
      'publie': true,
      'color': const Color(0xFF7F77DD),
    },
    {
      'titre': 'Sans Repos',
      'ecoutes': 1800,
      'genre': 'Trap 237',
      'publie': true,
      'color': const Color(0xFFD4537E),
    },
    {
      'titre': '237 Life',
      'ecoutes': 950,
      'genre': 'Afro-drill',
      'publie': true,
      'color': const Color(0xFFEF9F27),
    },
    {
      'titre': 'Braise',
      'ecoutes': 420,
      'genre': 'Trap 237',
      'publie': false,
      'color': const Color(0xFF2EAF8A),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _DashboardHeader(
              nomArtiste: _nomArtiste,
              ville: _ville,
              genre: _genre,
              estPremium: _estPremium,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  const _SectionTitle(title: 'Vue d\'ensemble'),
                  const SizedBox(height: 14),
                  _StatsRow(
                    totalEcoutes: _totalEcoutes,
                    totalAbonnes: _totalAbonnes,
                    totalPourboires: _totalPourboires,
                    nbTitres: _nbTitres,
                  ),
                  const SizedBox(height: 28),

                  // Graphique
                  const _SectionTitle(title: 'Écoutes — 7 derniers jours'),
                  const SizedBox(height: 14),
                  _EcoutesChart(data: _ecoutes7j),
                  const SizedBox(height: 28),

                  // Mes titres
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mes titres',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: navigation vers MesTitresScreen
                        },
                        child: const Text(
                          'Voir tout',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.accentArtiste,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._titres.map((t) => _TitreCard(titre: t)),
                  const SizedBox(height: 28),

                  // Bouton publier
                  AppPrimaryButton(
                    label: '+ Publier un nouveau titre',
                    onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UploadScreen(),
                          ),
                      );
                    },
                    color: AppColors.accentArtiste,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ArtistBottomNav(),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final String nomArtiste;
  final String ville;
  final String genre;
  final bool estPremium;

  const _DashboardHeader({
    required this.nomArtiste,
    required this.ville,
    required this.genre,
    required this.estPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A3A2F),
            Color(0xFF0F2A22),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentArtiste.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Mode Artiste',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accentArtiste,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (estPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentArtiste.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentArtiste.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.accentArtiste,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accentArtiste,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Profil
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentArtiste,
                          const Color(0xFF0F6E56),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentArtiste.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 4),
                        Text(
                          '$ville · $genre',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfilArtisteScreen(),
                            ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
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

// ─── SECTION TITLE ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ─── STATS ROW ───────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int totalEcoutes;
  final int totalAbonnes;
  final int totalPourboires;
  final int nbTitres;

  const _StatsRow({
    required this.totalEcoutes,
    required this.totalAbonnes,
    required this.totalPourboires,
    required this.nbTitres,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.85,
      children: [
        _StatCard(
          label: 'Écoutes totales',
          value: _formatNumber(totalEcoutes),
          icon: Icons.headphones_rounded,
          accentColor: AppColors.violetMid,
        ),
        _StatCard(
          label: 'Abonnés',
          value: _formatNumber(totalAbonnes),
          icon: Icons.people_rounded,
          accentColor: AppColors.accentArtiste,
        ),
        _StatCard(
          label: 'Pourboires',
          value: '${_formatNumber(totalPourboires)} F',
          icon: Icons.account_balance_wallet_rounded,
          accentColor: AppColors.success,
        ),
        _StatCard(
          label: 'Titres publiés',
          value: nbTitres.toString(),
          icon: Icons.music_note_rounded,
          accentColor: AppColors.warning,
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const Spacer(),
            ],
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
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── MINI GRAPHIQUE ──────────────────────────────────────────────────────────
class _EcoutesChart extends StatelessWidget {
  final List<int> data;
  const _EcoutesChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    final jours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      height: 130,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(data.length, (i) {
          final ratio = data[i] / maxVal;
          final isMax = data[i] == maxVal.toInt();
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isMax)
                Text(
                  _formatNumber(data[i]),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.accentArtiste,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: 26,
                height: 70 * ratio,
                decoration: BoxDecoration(
                  gradient: isMax
                      ? LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.accentArtiste,
                      AppColors.accentArtiste.withOpacity(0.7),
                    ],
                  )
                      : null,
                  color: isMax
                      ? null
                      : AppColors.accentArtiste.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                jours[i],
                style: TextStyle(
                  fontSize: 11,
                  color: isMax
                      ? AppColors.accentArtiste
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

  String _formatNumber(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();
}

// ─── CARTE TITRE ─────────────────────────────────────────────────────────────
class _TitreCard extends StatelessWidget {
  final Map<String, dynamic> titre;
  const _TitreCard({required this.titre});

  @override
  Widget build(BuildContext context) {
    final bool publie = titre['publie'] as bool;
    final Color color = titre['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pochette
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(Icons.music_note_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre['titre'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      size: 13,
                      color: publie
                          ? AppColors.accentArtiste
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatNumber(titre['ecoutes'] as int)} écoutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: publie
                            ? AppColors.accentArtiste
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.violetLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        titre['genre'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.violetMid,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: publie
                      ? AppColors.accentArtiste.withOpacity(0.12)
                      : AppColors.border.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  publie ? 'Publié' : 'Masqué',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: publie
                        ? AppColors.accentArtiste
                        : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();
}

// ─── BOTTOM NAV ARTISTE ──────────────────────────────────────────────────────
class _ArtistBottomNav extends StatelessWidget {
  const _ArtistBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                isActive: true,
              ),
              _NavItem(
                icon: Icons.music_note_rounded,
                label: 'Titres',
                isActive: false,
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Revenus',
                isActive: false,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigation
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.accentArtiste : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.accentArtiste : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}