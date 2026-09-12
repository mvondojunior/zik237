import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';

/// Écran de recherche — Zik237 (Auditeur)
/// Recherche en temps réel sur les titres et les artistes.
/// Filtre par genre local et ville.

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  late TabController _tabController;

  List<Map<String, dynamic>> _titresResultats = [];
  List<Map<String, dynamic>> _artistesResultats = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _query = '';

  // Genres populaires pour la page de découverte par genre
  final List<Map<String, dynamic>> _genres = [
    {'label': 'Trap 237',  'color': const Color(0xFF7F77DD), 'icon': Icons.music_note_rounded},
    {'label': 'Bikutsi',   'color': const Color(0xFFD4537E), 'icon': Icons.music_note_rounded},
    {'label': 'Mbolé',     'color': const Color(0xFFEF9F27), 'icon': Icons.music_note_rounded},
    {'label': 'Afro-drill','color': const Color(0xFF2EAF8A), 'icon': Icons.music_note_rounded},
    {'label': 'Afrobeats', 'color': const Color(0xFF534AB7), 'icon': Icons.music_note_rounded},
    {'label': 'Makossa',   'color': const Color(0xFF993C1D), 'icon': Icons.music_note_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Focus automatique sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Recherche avec debounce ──────────────────────────────────────────────
  Future<void> _rechercher(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _titresResultats = [];
        _artistesResultats = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _query = query.trim();
    });

    try {
      // Recherche titres
      final titresData = await _supabase
          .from('titres')
          .select('''
            id, titre, audio_url, pochette_url,
            genre_principal, ville, nb_ecoutes, publie,
            utilisateurs!artiste_id (
              id, nom_affichage
            )
          ''')
          .eq('publie', true)
          .ilike('titre', '%$query%')
          .order('nb_ecoutes', ascending: false)
          .limit(20);

      // Recherche artistes
      final artistesData = await _supabase
          .from('utilisateurs')
          .select('''
            id, nom_affichage, ville,
            profils_artiste (
              bio, total_ecoutes, est_premium
            )
          ''')
          .eq('role', 'artiste')
          .ilike('nom_affichage', '%$query%')
          .limit(10);

      setState(() {
        _titresResultats = List<Map<String, dynamic>>.from(titresData);
        _artistesResultats = List<Map<String, dynamic>>.from(artistesData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de recherche. Vérifie ta connexion.');
    }
  }

  // ── Recherche par genre ──────────────────────────────────────────────────
  Future<void> _rechercherParGenre(String genre) async {
    _searchController.text = genre;
    await _rechercher(genre);
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _titresResultats = [];
      _artistesResultats = [];
      _hasSearched = false;
      _query = '';
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER + CHAMP RECHERCHE ──────────────────────────────
            _SearchHeader(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _rechercher,
              onClear: _clearSearch,
              onBack: () => Navigator.of(context).pop(),
            ),

            // ── CONTENU ──────────────────────────────────────────────
            Expanded(
              child: _hasSearched
                  ? _SearchResults(
                query: _query,
                titres: _titresResultats,
                artistes: _artistesResultats,
                isLoading: _isLoading,
                tabController: _tabController,
              )
                  : _GenreGrid(
                genres: _genres,
                onGenreSelected: _rechercherParGenre,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HEADER RECHERCHE ─────────────────────────────────────────────────────────
class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;

  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Bouton retour
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),

          // Champ de recherche
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Titre, artiste, genre...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GRILLE GENRES (état initial) ────────────────────────────────────────────
class _GenreGrid extends StatelessWidget {
  final List<Map<String, dynamic>> genres;
  final ValueChanged<String> onGenreSelected;

  const _GenreGrid({
    required this.genres,
    required this.onGenreSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parcourir par genre',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            itemCount: genres.length,
            itemBuilder: (context, index) {
              final genre = genres[index];
              final color = genre['color'] as Color;
              return GestureDetector(
                onTap: () => onGenreSelected(genre['label'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        genre['icon'] as IconData,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      Text(
                        genre['label'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── RÉSULTATS DE RECHERCHE ───────────────────────────────────────────────────
class _SearchResults extends StatelessWidget {
  final String query;
  final List<Map<String, dynamic>> titres;
  final List<Map<String, dynamic>> artistes;
  final bool isLoading;
  final TabController tabController;

  const _SearchResults({
    required this.query,
    required this.titres,
    required this.artistes,
    required this.isLoading,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.violetDark,
          strokeWidth: 2,
        ),
      );
    }

    final totalResultats = titres.length + artistes.length;

    if (totalResultats == 0) {
      return _NoResults(query: query);
    }

    return Column(
      children: [
        // Nombre de résultats
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Text(
                '$totalResultats résultat${totalResultats > 1 ? 's' : ''} pour ',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '"$query"',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.violetDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Tabs Titres / Artistes
        TabBar(
          controller: tabController,
          labelColor: AppColors.violetDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.violetDark,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Titres (${titres.length})'),
            Tab(text: 'Artistes (${artistes.length})'),
          ],
        ),

        // Contenu des tabs
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // Onglet Titres
              titres.isEmpty
                  ? _NoResults(query: query)
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: titres.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _TitreResultCard(titre: titres[index], index: index),
              ),

              // Onglet Artistes
              artistes.isEmpty
                  ? _NoResults(query: query)
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: artistes.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _ArtisteResultCard(artiste: artistes[index]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── CARTE TITRE (résultat) ───────────────────────────────────────────────────
class _TitreResultCard extends StatelessWidget {
  final Map<String, dynamic> titre;
  final int index;

  static const List<Color> _couleurs = [
    Color(0xFF7F77DD), Color(0xFFD4537E),
    Color(0xFFEF9F27), Color(0xFF2EAF8A),
    Color(0xFF534AB7),
  ];

  const _TitreResultCard({required this.titre, required this.index});

  @override
  Widget build(BuildContext context) {
    final artiste = titre['utilisateurs'] as Map<String, dynamic>?;
    final nomArtiste = artiste?['nom_affichage'] ?? 'Artiste inconnu';
    final couleur = _couleurs[index % _couleurs.length];

    return GestureDetector(
      onTap: () {
        // TODO: navigation vers LecteurScreen avec ce titre
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
            // Pochette
            Container(
              width: 48,
              height: 48,
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
                    color: couleur, size: 22,
                  ),
                ),
              )
                  : Icon(Icons.music_note_rounded, color: couleur, size: 22),
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
                  Text(
                    nomArtiste,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.violetLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      titre['genre_principal'] as String? ?? '',
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
  }
}

// ─── CARTE ARTISTE (résultat) ─────────────────────────────────────────────────
class _ArtisteResultCard extends StatelessWidget {
  final Map<String, dynamic> artiste;

  const _ArtisteResultCard({required this.artiste});

  @override
  Widget build(BuildContext context) {
    final profil = artiste['profils_artiste'] as Map<String, dynamic>?;
    final totalEcoutes = profil?['total_ecoutes'] as int? ?? 0;
    final estPremium = profil?['est_premium'] as bool? ?? false;
    final ville = artiste['ville'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        // TODO: navigation vers ProfilArtisteScreen
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
            // Avatar artiste
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentArtiste, Color(0xFF0F6E56)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        artiste['nom_affichage'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (estPremium) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.accentArtiste,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ville.isNotEmpty ? ville : 'Cameroun',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatNumber(totalEcoutes)} écoutes',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Flèche
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
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

// ─── AUCUN RÉSULTAT ───────────────────────────────────────────────────────────
class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat pour "$query"',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Essaie un autre mot-clé\nou parcours les genres ci-dessus',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
