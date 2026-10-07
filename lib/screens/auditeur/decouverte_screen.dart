import 'package:app_mobile_music_underground/screens/artiste/playlist.dart';
import 'package:app_mobile_music_underground/screens/auditeur/profil_screen.dart';
import 'package:app_mobile_music_underground/screens/auditeur/recherche_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/services/auth_service.dart';
import 'package:app_mobile_music_underground/screens/auditeur/lecteur_screen.dart';
import 'package:app_mobile_music_underground/screens/auditeur/playlist_auditeur.dart';

/// Écran de découverte — Zik237 (Auditeur)

class DecouverteScreen extends StatefulWidget {
  const DecouverteScreen({super.key});

  @override
  State<DecouverteScreen> createState() => _DecouverteScreenState();
}

class _DecouverteScreenState extends State<DecouverteScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  List<Map<String, dynamic>> _titres = [];
  bool _isLoading = true;
  String? _selectedVille;
  String? _selectedGenre;
  int _currentNavIndex = 0;

  final List<String> _villes = [
    'Toutes',
    'Yaoundé',
    'Douala',
    'Bafoussam',
    'Bamenda',
  ];

  final List<String> _genres = [
    'Tous',
    'Trap 237',
    'Bikutsi',
    'Mbolé',
    'Afro-drill',
    'Afrobeats',
  ];

  @override
  void initState() {
    super.initState();
    _loadTitres();
  }

  Future<void> _loadTitres() async {
    setState(() => _isLoading = true);

    try {
      var query = _supabase
          .from('titres')
          .select('''
            id, titre, audio_url, pochette_url,
            genre_principal, ville, nb_ecoutes,
            nb_ecoutes_7j, score_decouverte, publie,
            utilisateurs!artiste_id (
              id, nom_affichage, ville
            )
          ''')
          .eq('publie', true);

      if (_selectedVille != null && _selectedVille != 'Toutes') {
        query = query.eq('ville', _selectedVille!);
      }
      if (_selectedGenre != null && _selectedGenre != 'Tous') {
        query = query.eq('genre_principal', _selectedGenre!);
      }

      final data = await query
          .order('score_decouverte', ascending: false)
          .limit(30);

      setState(() {
        _titres = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de chargement. Vérifie ta connexion.');
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

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violetDark,
          onRefresh: _loadTitres,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _DecouverteHeader(onSignOut: _handleSignOut),
              ),
              // Filtres Ville
              SliverToBoxAdapter(
                child: _FiltreChips(
                  items: _villes,
                  selected: _selectedVille ?? 'Toutes',
                  onSelected: (ville) {
                    setState(() =>
                    _selectedVille = ville == 'Toutes' ? null : ville);
                    _loadTitres();
                  },
                ),
              ),
              // Filtres Genre
              SliverToBoxAdapter(
                child: _FiltreChips(
                  items: _genres,
                  selected: _selectedGenre ?? 'Tous',
                  onSelected: (genre) {
                    setState(() =>
                    _selectedGenre = genre == 'Tous' ? null : genre);
                    _loadTitres();
                  },
                  isGenre: true,
                ),
              ),
              // Titre section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 14),
                  child: Text(
                    'En ce moment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              // Liste
              _isLoading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.violetDark,
                    strokeWidth: 2.5,
                  ),
                ),
              )
                  : _titres.isEmpty
                  ? SliverFillRemaining(
                child: _EmptyState(onRetry: _loadTitres),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _TitreCard(
                      titre: _titres[index],
                      index: index,
                    ),
                    childCount: _titres.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _AuditeurBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _DecouverteHeader extends StatelessWidget {
  final VoidCallback onSignOut;
  const _DecouverteHeader({required this.onSignOut});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final nom = user?.userMetadata?['nom_affichage'] ?? 'Auditeur';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          // Recherche
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/recherche');
              },
              icon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          GestureDetector(
            onTap: onSignOut,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.violetDark, Color(0xFF5B2C8A)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violetDark.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
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

// ─── FILTRE CHIPS ─────────────────────────────────────────────────────────────
class _FiltreChips extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool isGenre;

  const _FiltreChips({
    required this.items,
    required this.selected,
    required this.onSelected,
    this.isGenre = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, isGenre ? 16 : 8, 20, 8),
          child: Text(
            isGenre ? 'Genre' : 'Ville',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.4,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item == selected;
              return GestureDetector(
                onTap: () => onSelected(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.violetDark
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.violetDark
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: AppColors.violetDark.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── CARTE TITRE ─────────────────────────────────────────────────────────────
class _TitreCard extends StatelessWidget {
  final Map<String, dynamic> titre;
  final int index;

  const _TitreCard({
    required this.titre,
    required this.index,
  });

  static const List<Color> _pochetteCouleurs = [
    Color(0xFF7F77DD),
    Color(0xFFD4537E),
    Color(0xFFEF9F27),
    Color(0xFF2EAF8A),
    Color(0xFF534AB7),
  ];

  @override
  Widget build(BuildContext context) {
    final artiste = titre['utilisateurs'] as Map<String, dynamic>?;
    final nomArtiste = artiste?['nom_affichage'] ?? 'Artiste inconnu';
    final nbEcoutes7j = titre['nb_ecoutes_7j'] as int? ?? 0;
    final nbEcoutes = titre['nb_ecoutes'] as int? ?? 0;
    final genre = titre['genre_principal'] as String? ?? '';
    final ville = titre['ville'] as String? ?? '';
    final couleur = _pochetteCouleurs[index % _pochetteCouleurs.length];
    final isNew = nbEcoutes < 100;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LecteurScreen(titre: titre),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pochette
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: couleur.withOpacity(0.35)),
              ),
              child: titre['pochette_url'] != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  titre['pochette_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.music_note_rounded,
                    color: couleur,
                    size: 26,
                  ),
                ),
              )
                  : Icon(
                Icons.music_note_rounded,
                color: couleur,
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
                    titre['titre'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$nomArtiste${ville.isNotEmpty ? ' · $ville' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.violetLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.violetMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.violetDark.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Nouveau',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.violetDark,
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
            const SizedBox(width: 10),

            // Stats + Play
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isNew)
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatNumber(nbEcoutes7j),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  '${_formatNumber(nbEcoutes)} écoutes',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.violetDark.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 22,
                    color: AppColors.violetDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ─── ÉTAT VIDE ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.violetLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_off_rounded,
                size: 42,
                color: AppColors.violetMid,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Aucun titre trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essaie un autre filtre ou reviens plus tard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.violetDark,
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM NAV ──────────────────────────────────────────────────────────────
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
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetDark.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Recherche',
                isActive: currentIndex == 1,
                onTap: () {
                  onTap(1);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RechercheScreen(),
                      ),
                  );
                },
              ),
              _NavItem(
                icon: Icons.queue_music_rounded,
                label: 'Playlists',
                isActive: currentIndex == 2,
                onTap: () {
                  onTap(2);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaylistAuditeur(),
                    ),
                  );
                },
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: currentIndex == 3,
                onTap: () {
                  onTap(3);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfilScreen(),
                    ),
                  );
                },
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive
                  ? AppColors.accentAuditeur
                  : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? AppColors.accentAuditeur
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}