import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/services/auth_service.dart';

/// Écran de découverte — Zik237 (Auditeur)
/// Affiche le fil de titres triés par score de découverte,
/// filtrables par ville et genre local.

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
    'Toutes', 'Yaoundé', 'Douala', 'Bafoussam', 'Bamenda',
  ];

  final List<String> _genres = [
    'Tous', 'Trap 237', 'Bikutsi', 'Mbolé', 'Afro-drill', 'Afrobeats',
  ];

  @override
  void initState() {
    super.initState();
    _loadTitres();
  }

  // ── Charger les titres depuis Supabase ──────────────────────────────────
  Future<void> _loadTitres() async {
    setState(() => _isLoading = true);

    try {
      // Construction de la requête avec les filtres AVANT order/limit
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

      // Appliquer les filtres optionnels avant order/limit
      if (_selectedVille != null && _selectedVille != 'Toutes') {
        query = query.eq('ville', _selectedVille!);
      }
      if (_selectedGenre != null && _selectedGenre != 'Tous') {
        query = query.eq('genre_principal', _selectedGenre!);
      }

      // order et limit en dernier
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
          borderRadius: BorderRadius.circular(10),
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
            slivers: [
              // ── HEADER ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _DecouverteHeader(
                  onSignOut: _handleSignOut,
                ),
              ),

              // ── FILTRES VILLE ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FiltreChips(
                  items: _villes,
                  selected: _selectedVille ?? 'Toutes',
                  onSelected: (ville) {
                    setState(() => _selectedVille =
                    ville == 'Toutes' ? null : ville);
                    _loadTitres();
                  },
                ),
              ),

              // ── FILTRES GENRE ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FiltreChips(
                  items: _genres,
                  selected: _selectedGenre ?? 'Tous',
                  onSelected: (genre) {
                    setState(() => _selectedGenre =
                    genre == 'Tous' ? null : genre);
                    _loadTitres();
                  },
                  isGenre: true,
                ),
              ),

              // ── TITRE SECTION ─────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'En ce moment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // ── LISTE DES TITRES ──────────────────────────────────────
              _isLoading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.violetDark,
                    strokeWidth: 2,
                  ),
                ),
              )
                  : _titres.isEmpty
                  ? SliverFillRemaining(
                child: _EmptyState(
                  onRetry: _loadTitres,
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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

      // ── BOTTOM NAV AUDITEUR ───────────────────────────────────────────
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final nom = user?.userMetadata?['nom_affichage'] ?? 'Auditeur';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonsoir 👋',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                nom,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Bouton recherche
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/recherche');
                },
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
              // Avatar
              GestureDetector(
                onTap: onSignOut,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.violetDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
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
    return SizedBox(
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
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
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
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
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

  // Couleurs de pochette selon l'index
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
        // TODO: navigation vers LecteurScreen avec ce titre
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Pochette
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: couleur.withOpacity(0.4),
                ),
              ),
              child: titre['pochette_url'] != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  titre['pochette_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.music_note_rounded,
                    color: couleur,
                    size: 24,
                  ),
                ),
              )
                  : Icon(
                Icons.music_note_rounded,
                color: couleur,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre du morceau
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
                  // Artiste + ville
                  Text(
                    '$nomArtiste${ville.isNotEmpty ? ' · $ville' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Genre
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.violetLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      genre,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.violetMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Stats + badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Badge nouveau ou croissance
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.violetDark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Nouveau',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.violetDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatNumber(nbEcoutes7j),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                // Total écoutes
                Text(
                  '${_formatNumber(nbEcoutes)} écoutes',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                // Bouton play
                const Icon(
                  Icons.play_circle_rounded,
                  size: 28,
                  color: AppColors.violetDark,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_off_rounded,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun titre trouvé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essaie un autre filtre',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Réessayer',
              style: TextStyle(
                color: AppColors.violetDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BOTTOM NAV AUDITEUR ─────────────────────────────────────────────────────
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
            color: AppColors.violetDark.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  // TODO: navigation vers RechercheScreen
                },
              ),
              _NavItem(
                icon: Icons.queue_music_rounded,
                label: 'Playlists',
                isActive: currentIndex == 2,
                onTap: () {
                  onTap(2);
                  // TODO: navigation vers PlaylistScreen
                },
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: currentIndex == 3,
                onTap: () {
                  onTap(3);
                  // TODO: navigation vers ProfilScreen
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
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
              isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? AppColors.accentAuditeur
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}