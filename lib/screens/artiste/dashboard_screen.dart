import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';

/// Tableau de bord artiste — Zik237
/// Affiche les statistiques d'écoutes, les revenus des pourboires,
/// la liste des titres publiés et un accès rapide à l'upload.

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // TODO: remplacer par les données réelles via ArtisteService / Riverpod provider
  final String _nomArtiste = 'Kev.237';
  final String _ville = 'Douala';
  final String _genre = 'Trap 237';
  final bool _estPremium = true;

  final int _totalEcoutes = 4200;
  final int _totalAbonnes = 312;
  final int _totalPourboires = 8500;
  final int _nbTitres = 8;

  // Écoutes sur 7 jours (données pour le mini graphique)
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
        child: Column(
          children: [
            // ── HEADER ARTISTE ───────────────────────────────────────────
            _DashboardHeader(
              nomArtiste: _nomArtiste,
              ville: _ville,
              genre: _genre,
              estPremium: _estPremium,
            ),

            // ── CONTENU ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── STATS RAPIDES ──
                  _SectionTitle(title: 'Vue d\'ensemble'),
                  const SizedBox(height: 12),
                  _StatsRow(
                    totalEcoutes: _totalEcoutes,
                    totalAbonnes: _totalAbonnes,
                    totalPourboires: _totalPourboires,
                    nbTitres: _nbTitres,
                  ),
                  const SizedBox(height: 28),

                  // ── MINI GRAPHIQUE 7 JOURS ──
                  _SectionTitle(title: 'Écoutes — 7 derniers jours'),
                  const SizedBox(height: 12),
                  _EcoutesChart(data: _ecoutes7j),
                  const SizedBox(height: 28),

                  // ── MES TITRES ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mes titres',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
                            color: AppColors.violetMid,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._titres.map((t) => _TitreCard(titre: t)).toList(),
                  const SizedBox(height: 24),

                  // ── BOUTON PUBLIER ──
                  AppPrimaryButton(
                    label: '+ Publier un nouveau titre',
                    onPressed: () {
                      // TODO: navigation vers UploadScreen
                    },
                    color: AppColors.accentArtiste,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── BOTTOM NAV ARTISTE ──
      bottomNavigationBar: _ArtistBottomNav(),
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A2F), AppColors.background],
          stops: [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne du haut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mode Artiste',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accentArtiste,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (estPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentArtiste.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentArtiste.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 13, color: AppColors.accentArtiste),
                          const SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.accentArtiste,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Profil
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentArtiste,
                          const Color(0xFF0F6E56),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.violetMid.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomArtiste,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$ville · $genre',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // TODO: navigation vers EditProfilScreen
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
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
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
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
      childAspectRatio: 2.2,
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
          label: 'Pourboires (FCFA)',
          value: _formatNumber(totalPourboires),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(color: accentColor, width: 2.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MINI GRAPHIQUE ÉCOUTES ──────────────────────────────────────────────────
class _EcoutesChart extends StatelessWidget {
  final List<int> data;
  const _EcoutesChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    final jours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
                    fontSize: 9,
                    color: AppColors.accentArtiste,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: 24,
                height: 60 * ratio,
                decoration: BoxDecoration(
                  color: isMax
                      ? AppColors.accentArtiste
                      : AppColors.violetSoft.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                jours[i],
                style: TextStyle(
                  fontSize: 10,
                  color: isMax
                      ? AppColors.accentArtiste
                      : AppColors.textMuted,
                  fontWeight:
                  isMax ? FontWeight.w700 : FontWeight.w400,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: publie ? AppColors.accentArtiste : AppColors.border,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Pochette
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(Icons.music_note_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre['titre'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      size: 12,
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
                    Text(
                      titre['genre'] as String,
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

          // Statut + menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: publie
                      ? AppColors.accentArtiste.withOpacity(0.1)
                      : AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  publie ? 'Publié' : 'Masqué',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: publie
                        ? AppColors.accentArtiste
                        : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Icon(
                Icons.more_vert_rounded,
                size: 18,
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
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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
        // TODO: navigation selon l'onglet
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? AppColors.accentArtiste : AppColors.textMuted,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
              isActive ? FontWeight.w600 : FontWeight.w400,
              color:
              isActive ? AppColors.accentArtiste : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
