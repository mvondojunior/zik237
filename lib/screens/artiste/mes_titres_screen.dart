import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/screens/artiste/upload_screen.dart';

/// Écran mes titres — Zik237 (Artiste)
/// Liste tous les titres publiés et masqués de l'artiste connecté.
/// Permet de publier, masquer ou supprimer un titre.

class MesTitresScreen extends StatefulWidget {
  const MesTitresScreen({super.key});

  @override
  State<MesTitresScreen> createState() => _MesTitresScreenState();
}

class _MesTitresScreenState extends State<MesTitresScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _titresPublies = [];
  List<Map<String, dynamic>> _titresMasques = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTitres();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Charger les titres depuis Supabase ──────────────────────────────────
  Future<void> _loadTitres() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      final data = await _supabase
          .from('titres')
          .select()
          .eq('artiste_id', userId)
          .order('created_at', ascending: false);

      final titres = List<Map<String, dynamic>>.from(data);

      setState(() {
        _titresPublies =
            titres.where((t) => t['publie'] == true).toList();
        _titresMasques =
            titres.where((t) => t['publie'] == false).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de chargement des titres.');
    }
  }

  // ── Changer la visibilité d'un titre ────────────────────────────────────
  Future<void> _toggleVisibilite(
      String titreId, bool estPublie) async {
    try {
      await _supabase
          .from('titres')
          .update({'publie': !estPublie})
          .eq('id', titreId);
      await _loadTitres();
      _showSnackBar(
        estPublie ? 'Titre masqué.' : 'Titre publié !',
      );
    } catch (e) {
      _showSnackBar('Erreur. Réessaie.');
    }
  }

  // ── Supprimer un titre ──────────────────────────────────────────────────
  Future<void> _supprimerTitre(
      String titreId, String nomTitre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Supprimer le titre',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Es-tu sûr de vouloir supprimer "$nomTitre" ? '
              'Cette action est irréversible.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase
            .from('titres')
            .delete()
            .eq('id', titreId);
        await _loadTitres();
        _showSnackBar('Titre supprimé.');
      } catch (e) {
        _showSnackBar('Erreur lors de la suppression.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentArtiste,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mes titres',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${_titresPublies.length + _titresMasques.length} titre${(_titresPublies.length + _titresMasques.length) > 1 ? 's' : ''} au total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Bouton uploader
                  GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UploadScreen(),
                        ),
                      );
                      _loadTitres();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentArtiste,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Publier',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── TABS ────────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              labelColor: AppColors.accentArtiste,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.accentArtiste,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Publiés (${_titresPublies.length})'),
                Tab(text: 'Masqués (${_titresMasques.length})'),
              ],
            ),

            // ── CONTENU ─────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentArtiste,
                  strokeWidth: 2,
                ),
              )
                  : TabBarView(
                controller: _tabController,
                children: [
                  // Onglet Publiés
                  _TitresList(
                    titres: _titresPublies,
                    estPublie: true,
                    onRefresh: _loadTitres,
                    onToggleVisibilite: _toggleVisibilite,
                    onSupprimer: _supprimerTitre,
                    onPublier: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UploadScreen(),
                        ),
                      );
                      _loadTitres();
                    },
                  ),

                  // Onglet Masqués
                  _TitresList(
                    titres: _titresMasques,
                    estPublie: false,
                    onRefresh: _loadTitres,
                    onToggleVisibilite: _toggleVisibilite,
                    onSupprimer: _supprimerTitre,
                    onPublier: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UploadScreen(),
                        ),
                      );
                      _loadTitres();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LISTE DES TITRES ─────────────────────────────────────────────────────────
class _TitresList extends StatelessWidget {
  final List<Map<String, dynamic>> titres;
  final bool estPublie;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String id, bool publie) onToggleVisibilite;
  final Future<void> Function(String id, String nom) onSupprimer;
  final VoidCallback onPublier;

  static const List<Color> _couleurs = [
    Color(0xFF7F77DD), Color(0xFFD4537E),
    Color(0xFFEF9F27), Color(0xFF2EAF8A),
    Color(0xFF534AB7),
  ];

  const _TitresList({
    required this.titres,
    required this.estPublie,
    required this.onRefresh,
    required this.onToggleVisibilite,
    required this.onSupprimer,
    required this.onPublier,
  });

  @override
  Widget build(BuildContext context) {
    if (titres.isEmpty) {
      return _EmptyState(
        estPublie: estPublie,
        onPublier: onPublier,
      );
    }

    return RefreshIndicator(
      color: AppColors.accentArtiste,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: titres.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final titre = titres[index];
          final couleur = _couleurs[index % _couleurs.length];
          final nbEcoutes = titre['nb_ecoutes'] as int? ?? 0;
          final nbEcoutes7j = titre['nb_ecoutes_7j'] as int? ?? 0;
          final genre = titre['genre_principal'] as String? ?? '';
          final nom = titre['titre'] as String? ?? '';
          final publie = titre['publie'] as bool? ?? false;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: publie
                    ? AppColors.accentArtiste.withOpacity(0.3)
                    : AppColors.border,
                width: publie ? 1.2 : 0.5,
              ),
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
                        color: couleur.withOpacity(0.4)),
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
                      Text(
                        nom,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.headphones_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${_fmt(nbEcoutes)} écoutes',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (nbEcoutes7j > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.trending_up_rounded,
                              size: 12,
                              color: AppColors.accentArtiste,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '+${_fmt(nbEcoutes7j)} cette semaine',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accentArtiste,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu contextuel
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'visibilite') {
                      onToggleVisibilite(
                          titre['id'], publie);
                    } else if (value == 'supprimer') {
                      onSupprimer(titre['id'], nom);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'visibilite',
                      child: Row(
                        children: [
                          Icon(
                            publie
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.violetMid,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            publie ? 'Masquer' : 'Publier',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'supprimer',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Supprimer',
                            style:
                            TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();
}

// ─── ÉTAT VIDE ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool estPublie;
  final VoidCallback onPublier;

  const _EmptyState({
    required this.estPublie,
    required this.onPublier,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              estPublie
                  ? Icons.music_note_rounded
                  : Icons.visibility_off_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              estPublie
                  ? 'Aucun titre publié'
                  : 'Aucun titre masqué',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              estPublie
                  ? 'Publie ton premier titre\npour le partager avec le monde 237 !'
                  : 'Les titres masqués n\'apparaissent\npas dans le fil de découverte.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (estPublie) ...[
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: '+ Publier un titre',
                onPressed: onPublier,
                color: AppColors.accentArtiste,
              ),
            ],
          ],
        ),
      ),
    );
  }
}