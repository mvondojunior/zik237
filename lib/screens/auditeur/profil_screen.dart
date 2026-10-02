import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/core/app_text_field.dart';
import 'package:app_mobile_music_underground/services/auth_service.dart';

/// Écran profil utilisateur — Zik237
/// Affiche et permet de modifier les informations du compte connecté.
/// Fonctionne pour les deux rôles : Auditeur et Artiste.

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  final _nomController = TextEditingController();
  final _villeController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  Map<String, dynamic>? _profil;
  Map<String, dynamic>? _profilArtiste;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _villeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Charger le profil depuis Supabase ───────────────────────────────────
  Future<void> _loadProfil() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      final profil = await _supabase
          .from('utilisateurs')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _profil = profil;
        _role = profil['role'] as String?;
        _nomController.text = profil['nom_affichage'] ?? '';
        _villeController.text = profil['ville'] ?? '';
      });

      // Si artiste → charger le profil artiste aussi
      if (_role == 'artiste') {
        final profilArtiste = await _supabase
            .from('profils_artiste')
            .select()
            .eq('id', userId)
            .single();

        setState(() {
          _profilArtiste = profilArtiste;
          _bioController.text = profilArtiste['bio'] ?? '';
        });
      }
    } catch (e) {
      _showSnackBar('Erreur de chargement du profil.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Sauvegarder les modifications ───────────────────────────────────────
  Future<void> _sauvegarder() async {
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      // Mettre à jour la table utilisateurs
      await _supabase.from('utilisateurs').update({
        'nom_affichage': _nomController.text.trim(),
        'ville': _villeController.text.trim(),
      }).eq('id', userId);

      // Si artiste → mettre à jour la bio
      if (_role == 'artiste') {
        await _supabase.from('profils_artiste').update({
          'bio': _bioController.text.trim(),
          'ville_artiste': _villeController.text.trim(),
        }).eq('id', userId);
      }

      setState(() => _isEditing = false);
      _showSnackBar('Profil mis à jour avec succès !');
      await _loadProfil();
    } catch (e) {
      _showSnackBar('Erreur lors de la sauvegarde.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── Déconnexion ─────────────────────────────────────────────────────────
  Future<void> _handleSignOut() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Se déconnecter',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Es-tu sûr de vouloir te déconnecter de Zik237 ?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _authService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                    (route) => false,
              );
            },
            child: const Text(
              'Se déconnecter',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final isArtiste = _role == 'artiste';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.violetDark,
          strokeWidth: 2,
        ),
      )
          : CustomScrollView(
        slivers: [
          // ── HEADER ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfilHeader(
              nom: _profil?['nom_affichage'] ?? '',
              ville: _profil?['ville'] ?? '',
              role: _role ?? 'auditeur',
              estPremium:
              _profilArtiste?['est_premium'] as bool? ?? false,
              isEditing: _isEditing,
              onEdit: () => setState(() => _isEditing = true),
              onCancel: () => setState(() => _isEditing = false),
            ),
          ),

          // ── STATS (Artiste seulement) ───────────────────────
          if (isArtiste && _profilArtiste != null)
            SliverToBoxAdapter(
              child: _ArtisteStats(
                totalEcoutes:
                _profilArtiste?['total_ecoutes'] as int? ?? 0,
                totalPourboires:
                _profilArtiste?['total_pourboires'] as int? ?? 0,
              ),
            ),

          // ── FORMULAIRE ─────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Nom d'affichage
                _SectionTitle(title: 'Informations personnelles'),
                const SizedBox(height: 12),
                AppInputLabel(label: "Nom d'affichage"),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _nomController,
                  hint: 'Ton nom ou pseudo',
                  icon: Icons.person_outline_rounded,
                  isFocused: _isEditing,
                ),
                const SizedBox(height: 14),

                // Email (non modifiable)
                AppInputLabel(label: 'Email'),
                const SizedBox(height: 6),
                _ReadOnlyField(
                  value: _supabase.auth.currentUser?.email ?? '',
                  icon: Icons.mail_outline_rounded,
                ),
                const SizedBox(height: 14),

                // Ville
                AppInputLabel(label: 'Ville'),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _villeController,
                  hint: 'Yaoundé, Douala...',
                  icon: Icons.location_on_outlined,
                  isFocused: _isEditing,
                ),

                // Bio (Artiste seulement)
                if (isArtiste) ...[
                  const SizedBox(height: 14),
                  AppInputLabel(label: 'Bio'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 200,
                    enabled: _isEditing,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                      'Parle un peu de toi et de ta musique...',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      filled: _isEditing,
                      fillColor: AppColors.violetLight,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.borderFocused,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],

                // Bouton sauvegarder
                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'Sauvegarder',
                    isLoading: _isSaving,
                    onPressed: _sauvegarder,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── OPTIONS ──────────────────────────────────
                _SectionTitle(title: 'Paramètres'),
                const SizedBox(height: 12),

                _OptionItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _OptionItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Confidentialité',
                  onTap: () {},
                ),
                _OptionItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Aide et support',
                  onTap: () {},
                ),
                _OptionItem(
                  icon: Icons.info_outline_rounded,
                  label: 'À propos de Zik237',
                  onTap: () {},
                ),

                const SizedBox(height: 16),

                // Déconnexion
                _OptionItem(
                  icon: Icons.logout_rounded,
                  label: 'Se déconnecter',
                  labelColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: _handleSignOut,
                  showArrow: false,
                ),

                const SizedBox(height: 8),

                // Version
                Center(
                  child: Text(
                    'Zik237 v1.0.0 — IAI Cameroun 2025',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HEADER PROFIL ────────────────────────────────────────────────────────────
class _ProfilHeader extends StatelessWidget {
  final String nom;
  final String ville;
  final String role;
  final bool estPremium;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _ProfilHeader({
    required this.nom,
    required this.ville,
    required this.role,
    required this.estPremium,
    required this.isEditing,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isArtiste = role == 'artiste';
    final accentColor =
    isArtiste ? AppColors.accentArtiste : AppColors.accentAuditeur;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isArtiste
                ? const Color(0xFF1E3A2F)
                : const Color(0xFF1E1B3A),
            AppColors.background,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Column(
        children: [
          // Avatar + bouton éditer
          Stack(
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, AppColors.violetDark],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              if (!isEditing)
                Positioned(
                  right: MediaQuery.of(context).size.width / 2 - 60,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Nom
          Text(
            nom,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Ville + rôle
          Text(
            '${ville.isNotEmpty ? '$ville · ' : ''}${isArtiste ? 'Artiste' : 'Auditeur'}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Badge rôle + premium
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isArtiste
                          ? Icons.mic_rounded
                          : Icons.headphones_rounded,
                      size: 13,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isArtiste ? 'Artiste' : 'Auditeur',
                      style: TextStyle(
                        fontSize: 11,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (estPremium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── STATS ARTISTE ────────────────────────────────────────────────────────────
class _ArtisteStats extends StatelessWidget {
  final int totalEcoutes;
  final int totalPourboires;

  const _ArtisteStats({
    required this.totalEcoutes,
    required this.totalPourboires,
  });

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'Écoutes totales',
              value: _fmt(totalEcoutes),
              icon: Icons.headphones_rounded,
              color: AppColors.accentArtiste,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatBox(
              label: 'Pourboires (FCFA)',
              value: _fmt(totalPourboires),
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: color, width: 2.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

// ─── CHAMP NON MODIFIABLE ─────────────────────────────────────────────────────
class _ReadOnlyField extends StatelessWidget {
  final String value;
  final IconData icon;

  const _ReadOnlyField({required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ─── TITRE DE SECTION ─────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ─── OPTION ITEM ──────────────────────────────────────────────────────────────
class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  final bool showArrow;

  const _OptionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: labelColor ?? AppColors.textPrimary,
                  fontWeight: labelColor != null
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
