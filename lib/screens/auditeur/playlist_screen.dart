import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/core/app_text_field.dart';
import 'package:app_mobile_music_underground/screens/auditeur/lecteur_screen.dart';

/// Écran playlists — Zik237 (Auditeur)
/// Liste des playlists de l'utilisateur + détail d'une playlist sélectionnée.

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  // ── Charger les playlists depuis Supabase ───────────────────────────────
  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      final data = await _supabase
          .from('playlists')
          .select('''
            id, nom, description, publique, created_at,
            playlists_titres (
              titre_id,
              titres (
                id, titre, audio_url, pochette_url,
                genre_principal, nb_ecoutes,
                utilisateurs!artiste_id ( nom_affichage )
              )
            )
          ''')
          .eq('auditeur_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _playlists = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de chargement des playlists.');
    }
  }

  // ── Créer une nouvelle playlist ─────────────────────────────────────────
  void _showCreatePlaylistSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreatePlaylistSheet(
        onCreate: (nom, description) async {
          Navigator.of(context).pop();
          await _creerPlaylist(nom, description);
        },
      ),
    );
  }

  Future<void> _creerPlaylist(String nom, String description) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('playlists').insert({
        'auditeur_id': userId,
        'nom': nom,
        'description': description,
        'publique': false,
      });
      await _loadPlaylists();
      _showSnackBar('Playlist "$nom" créée !');
    } catch (e) {
      _showSnackBar('Erreur lors de la création.');
    }
  }

  // ── Supprimer une playlist ──────────────────────────────────────────────
  Future<void> _supprimerPlaylist(String playlistId, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Supprimer la playlist',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Es-tu sûr de vouloir supprimer "$nom" ?',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
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
            .from('playlists')
            .delete()
            .eq('id', playlistId);
        await _loadPlaylists();
        _showSnackBar('Playlist supprimée.');
      } catch (e) {
        _showSnackBar('Erreur lors de la suppression.');
      }
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
                  const Text(
                    'Mes playlists',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Bouton créer
                  GestureDetector(
                    onTap: _showCreatePlaylistSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.violetDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Nouvelle',
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

            // ── CONTENU ─────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.violetDark,
                  strokeWidth: 2,
                ),
              )
                  : _playlists.isEmpty
                  ? _EmptyState(
                onCreer: _showCreatePlaylistSheet,
              )
                  : RefreshIndicator(
                color: AppColors.violetDark,
                onRefresh: _loadPlaylists,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: _playlists.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    final titres = (playlist['playlists_titres']
                    as List?)
                        ?.map((pt) =>
                    pt['titres'] as Map<String, dynamic>)
                        .toList() ??
                        [];

                    return _PlaylistCard(
                      playlist: playlist,
                      nbTitres: titres.length,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(
                              playlist: playlist,
                              titres: titres,
                            ),
                          ),
                        );
                      },
                      onSupprimer: () => _supprimerPlaylist(
                        playlist['id'],
                        playlist['nom'],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARTE PLAYLIST ───────────────────────────────────────────────────────────
class _PlaylistCard extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final int nbTitres;
  final VoidCallback onTap;
  final VoidCallback onSupprimer;

  static const List<Color> _couleurs = [
    Color(0xFF7F77DD), Color(0xFFD4537E),
    Color(0xFFEF9F27), Color(0xFF2EAF8A),
    Color(0xFF534AB7),
  ];

  const _PlaylistCard({
    required this.playlist,
    required this.nbTitres,
    required this.onTap,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final nom = playlist['nom'] as String? ?? '';
    final description = playlist['description'] as String? ?? '';
    final publique = playlist['publique'] as bool? ?? false;
    final colorIndex = nom.hashCode % _couleurs.length;
    final couleur = _couleurs[colorIndex.abs()];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Icône playlist
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [couleur, couleur.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.queue_music_rounded,
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
                    nom,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$nbTitres titre${nbTitres > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      Icon(
                        publique
                            ? Icons.public_rounded
                            : Icons.lock_outline_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        publique ? 'Publique' : 'Privée',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu
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
                if (value == 'supprimer') onSupprimer();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'supprimer',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Supprimer',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ÉTAT VIDE ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreer;
  const _EmptyState({required this.onCreer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.queue_music_rounded,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune playlist',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crée ta première playlist\npour organiser tes titres préférés',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: '+ Créer une playlist',
            onPressed: onCreer,
          ),
        ],
      ),
    );
  }
}

// ─── SHEET CRÉER PLAYLIST ─────────────────────────────────────────────────────
class _CreatePlaylistSheet extends StatefulWidget {
  final void Function(String nom, String description) onCreate;
  const _CreatePlaylistSheet({required this.onCreate});

  @override
  State<_CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<_CreatePlaylistSheet> {
  final _nomController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
            const Text(
              'Nouvelle playlist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Nom
            const AppInputLabel(label: 'Nom de la playlist'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _nomController,
              hint: 'Ex: Mes titres 237 préférés',
              icon: Icons.queue_music_rounded,
              isFocused: true,
            ),
            const SizedBox(height: 14),

            // Description
            const AppInputLabel(label: 'Description (optionnel)'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _descController,
              hint: 'Une courte description...',
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 24),

            AppPrimaryButton(
              label: 'Créer la playlist',
              onPressed: () {
                if (_nomController.text.trim().isEmpty) return;
                widget.onCreate(
                  _nomController.text.trim(),
                  _descController.text.trim(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ÉCRAN DÉTAIL PLAYLIST ────────────────────────────────────────────────────
class PlaylistDetailScreen extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final List<Map<String, dynamic>> titres;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.titres,
  });

  static const List<Color> _couleurs = [
    Color(0xFF7F77DD), Color(0xFFD4537E),
    Color(0xFFEF9F27), Color(0xFF2EAF8A),
    Color(0xFF534AB7),
  ];

  @override
  Widget build(BuildContext context) {
    final nom = playlist['nom'] as String? ?? '';
    final description = playlist['description'] as String? ?? '';
    final colorIndex = nom.hashCode % _couleurs.length;
    final couleur = _couleurs[colorIndex.abs()];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 220,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [couleur, AppColors.violetDark],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.queue_music_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${titres.length} titre${titres.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton tout jouer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: titres.isNotEmpty
                          ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                LecteurScreen(titre: titres.first),
                          ),
                        );
                      }
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Tout jouer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violetDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.shuffle_rounded,
                      color: AppColors.violetMid,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des titres
          titres.isEmpty
              ? const SliverFillRemaining(
            child: Center(
              child: Text(
                'Aucun titre dans cette playlist',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
              : SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final titre = titres[index];
                  final couleur =
                  _couleurs[index % _couleurs.length];
                  final artiste =
                  titre['utilisateurs'] as Map<String, dynamic>?;

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              LecteurScreen(titre: titre),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: couleur.withOpacity(0.2),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.music_note_rounded,
                              color: couleur, size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                                Text(
                                  artiste?['nom_affichage'] ??
                                      'Artiste',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.play_circle_rounded,
                            size: 26,
                            color: AppColors.violetDark,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: titres.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}