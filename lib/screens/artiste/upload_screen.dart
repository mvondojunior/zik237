import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/core/app_text_field.dart';

/// Écran d'upload d'un titre — Zik237 (Artiste)
/// Permet à l'artiste de publier un morceau avec :
/// pochette, fichier audio, titre, genre (suggestion IA), ville.
/// Couleur dominante : violet (cohérent avec le dashboard).

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _supabase = Supabase.instance.client;
  final _titreController = TextEditingController();

  File? _audioFile;
  File? _pochetteFile;
  Uint8List? _audioBytes; // fallback si path null
  Uint8List? _pochetteBytes;
  String? _audioFileName;
  String? _genreSelectionne;
  String? _genreIASuggestion;
  double? _genreIAConfiance;
  String? _villeSelectionnee;
  bool _isLoading = false;
  bool _isAnalyzingIA = false;
  double _uploadProgress = 0.0;

  final List<String> _genres = [
    'Trap 237',
    'Bikutsi',
    'Mbolé',
    'Afro-drill',
    'Afrobeats',
    'Makossa',
    'Gospel',
    'Autre',
  ];

  final List<String> _villes = [
    'Yaoundé',
    'Douala',
    'Bafoussam',
    'Bamenda',
    'Garoua',
    'Maroua',
    'Ngaoundéré',
    'Kribi',
  ];

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  // ── Sélectionner le fichier audio ────────────────────────────────────────
  // Compatible file_picker ^12.1.1
  Future<void> _selectionnerAudio() async {
    try {
      // FileType.audio échoue souvent sur Android → custom + extensions
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      );

      if (file == null) return; // utilisateur a annulé

      // withData est déprécié en v12 → on lit les bytes explicitement
      final bytes = await file.readAsBytes();

      setState(() {
        _audioFileName = file.name;
        _genreIASuggestion = null;
        _genreIAConfiance = null;
        _audioBytes = bytes;

        if (file.path != null) {
          _audioFile = File(file.path!);
        } else {
          _audioFile = null; // on utilisera les bytes
        }
      });

      // Analyse IA
      if (_audioFile != null) {
        await _classifierGenreIA(_audioFile!);
      } else if (_audioBytes != null) {
        setState(() {
          _genreIASuggestion = 'Trap 237';
          _genreIAConfiance = 0.80;
          _genreSelectionne = _genreIASuggestion;
        });
      }
    } catch (e) {
      debugPrint('Erreur sélection audio: $e');
      _showSnackBar('Impossible de sélectionner le fichier audio. Réessaie.');
    }
  }

  // ── Sélectionner la pochette ─────────────────────────────────────────────
  Future<void> _selectionnerPochette() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _pochetteBytes = bytes;
        // path peut être temporaire sur Android 13+ → on garde aussi les bytes
        _pochetteFile = File(image.path);
      });
    } catch (e) {
      _showSnackBar('Impossible de sélectionner la pochette. Réessaie.');
    }
  }

  // ── Appel microservice IA ────────────────────────────────────────────────
  Future<void> _classifierGenreIA(File audioFile) async {
    setState(() => _isAnalyzingIA = true);

    try {
      // TODO: remplacer par l'URL réelle de ton microservice FastAPI
      // Simulation en attendant le microservice
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _genreIASuggestion = 'Trap 237';
        _genreIAConfiance = 0.82;
        _genreSelectionne = _genreIASuggestion;
      });
    } catch (e) {
      _showSnackBar(
          'Classification IA indisponible. Choisis le genre manuellement.');
    } finally {
      setState(() => _isAnalyzingIA = false);
    }
  }

  // ── Publier le titre ─────────────────────────────────────────────────────
  Future<void> _publier() async {
    // On accepte soit un File, soit des bytes
    if (_audioFile == null && _audioBytes == null) {
      _showSnackBar('Sélectionne un fichier audio');
      return;
    }
    if (_titreController.text.trim().isEmpty) {
      _showSnackBar('Saisis le titre du morceau');
      return;
    }
    if (_genreSelectionne == null) {
      _showSnackBar('Choisis un genre');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;
      final titreId = DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Upload fichier audio (File ou bytes)
      setState(() => _uploadProgress = 0.1);
      final audioPath = 'audio/$userId/$titreId.mp3';

      if (_audioFile != null) {
        await _supabase.storage.from('audio').upload(
          audioPath,
          _audioFile!,
          fileOptions: const FileOptions(
            contentType: 'audio/mpeg',
            upsert: true,
          ),
        );
      } else if (_audioBytes != null) {
        await _supabase.storage.from('audio').uploadBinary(
          audioPath,
          _audioBytes!,
          fileOptions: const FileOptions(
            contentType: 'audio/mpeg',
            upsert: true,
          ),
        );
      }

      final audioUrl = _supabase.storage.from('audio').getPublicUrl(audioPath);
      setState(() => _uploadProgress = 0.5);

      // 2. Upload pochette (si sélectionnée)
      String? pochetteUrl;
      if (_pochetteFile != null || _pochetteBytes != null) {
        final pochettePath = 'pochettes/$userId/$titreId.jpg';

        if (_pochetteFile != null) {
          await _supabase.storage.from('pochettes').upload(
            pochettePath,
            _pochetteFile!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
        } else if (_pochetteBytes != null) {
          await _supabase.storage.from('pochettes').uploadBinary(
            pochettePath,
            _pochetteBytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
        }

        pochetteUrl =
            _supabase.storage.from('pochettes').getPublicUrl(pochettePath);
      }
      setState(() => _uploadProgress = 0.8);

      // 3. Insérer en base de données
      await _supabase.from('titres').insert({
        'artiste_id': userId,
        'titre': _titreController.text.trim(),
        'audio_url': audioUrl,
        'pochette_url': pochetteUrl,
        'genre_principal': _genreSelectionne,
        'genre_ia_suggestion': _genreIASuggestion,
        'genre_ia_confiance': _genreIAConfiance,
        'ville': _villeSelectionnee,
        'publie': true,
        'nb_ecoutes': 0,
        'nb_ecoutes_7j': 0,
        'score_decouverte': 0.0,
      });

      setState(() => _uploadProgress = 1.0);

      if (!mounted) return;
      _showSnackBar('Titre publié avec succès ! 🎵');
      Navigator.of(context).pop();
    } catch (e, stack) {
      debugPrint('========== ERREUR PUBLICATION ==========');
      debugPrint('Erreur: $e');
      debugPrint('Stack: $stack');
      debugPrint('========================================');

      // Affiche l’erreur réelle à l’écran (temporaire pour debug)
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.violetMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────────────
              _UploadHeader(onBack: () => Navigator.of(context).pop()),

              // ── FORMULAIRE ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── POCHETTE ──
                    const _SectionLabel(label: 'Pochette du titre'),
                    const SizedBox(height: 10),
                    _PochetteSelector(
                      file: _pochetteFile,
                      onTap: _selectionnerPochette,
                    ),
                    const SizedBox(height: 24),

                    // ── FICHIER AUDIO ──
                    const _SectionLabel(label: 'Fichier audio'),
                    const SizedBox(height: 10),
                    _AudioSelector(
                      fileName: _audioFileName,
                      isAnalyzing: _isAnalyzingIA,
                      onTap: _selectionnerAudio,
                    ),
                    const SizedBox(height: 24),

                    // ── NOM DU TITRE ──
                    const _SectionLabel(label: 'Titre du morceau'),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _titreController,
                      hint: 'Ex: Nuit Blanche',
                      icon: Icons.title_rounded,
                      isFocused: true,
                    ),
                    const SizedBox(height: 24),

                    // ── GENRE (avec suggestion IA) ──
                    Row(
                      children: [
                        const _SectionLabel(label: 'Genre'),
                        if (_genreIASuggestion != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.violetMid.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.violetMid.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 12,
                                  color: AppColors.violetMid,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'IA · ${(_genreIAConfiance! * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.violetMid,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Chips de genre
                    _isAnalyzingIA
                        ? Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.violetMid.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.violetMid,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Analyse IA en cours...',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                        : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _genres.map((genre) {
                        final isSelected = genre == _genreSelectionne;
                        final isIASuggestion =
                            genre == _genreIASuggestion;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _genreSelectionne = genre),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.violetMid
                                  : isIASuggestion
                                  ? AppColors.violetMid
                                  .withOpacity(0.1)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.violetMid
                                    : isIASuggestion
                                    ? AppColors.violetMid
                                    .withOpacity(0.5)
                                    : AppColors.border,
                                width: isSelected || isIASuggestion
                                    ? 1.5
                                    : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: AppColors.violetMid
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isIASuggestion && !isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 5),
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 12,
                                      color: AppColors.violetMid,
                                    ),
                                  ),
                                Text(
                                  genre,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : isIASuggestion
                                        ? AppColors.violetMid
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ── VILLE ──
                    const _SectionLabel(label: 'Ville'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _villeSelectionnee,
                      hint: const Text(
                        'Yaoundé, Douala...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.violetMid.withOpacity(0.7),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppColors.border.withOpacity(0.8),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppColors.border.withOpacity(0.8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.violetMid,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: _villes
                          .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v,
                            style: const TextStyle(fontSize: 14)),
                      ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _villeSelectionnee = v),
                    ),
                    const SizedBox(height: 36),

                    // ── BARRE DE PROGRESSION ──
                    if (_isLoading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor:
                          AppColors.violetMid.withOpacity(0.12),
                          color: AppColors.violetMid,
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _uploadProgress < 0.5
                            ? 'Upload audio...'
                            : _uploadProgress < 0.8
                            ? 'Upload pochette...'
                            : 'Enregistrement en base...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── BOUTON PUBLIER ──
                    AppPrimaryButton(
                      label: 'Publier le titre',
                      isLoading: _isLoading,
                      onPressed: _publier,
                      color: AppColors.violetMid,
                    ),
                    const SizedBox(height: 16),

                    // Note sécurité
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 14,
                              color: AppColors.violetMid.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Publié via ton compte artiste vérifié',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _UploadHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _UploadHeader({required this.onBack});

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
            color: AppColors.violetDark.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Publier un titre',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 48), // équilibre avec le bouton retour
        ],
      ),
    );
  }
}

// ─── SÉLECTEUR POCHETTE ───────────────────────────────────────────────────────
class _PochetteSelector extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;

  const _PochetteSelector({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: file != null
                ? AppColors.violetMid
                : AppColors.border.withOpacity(0.8),
            width: file != null ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: file != null
                  ? AppColors.violetMid.withOpacity(0.15)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          image: file != null
              ? DecorationImage(
            image: FileImage(file!),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: file == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.violetMid.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 26,
                color: AppColors.violetMid,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ajouter une pochette',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Optionnel — JPEG ou PNG',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted.withOpacity(0.9),
              ),
            ),
          ],
        )
            : Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.45),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SÉLECTEUR AUDIO ──────────────────────────────────────────────────────────
class _AudioSelector extends StatelessWidget {
  final String? fileName;
  final bool isAnalyzing;
  final VoidCallback onTap;

  const _AudioSelector({
    required this.fileName,
    required this.isAnalyzing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.violetMid.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? AppColors.violetMid
                : AppColors.border.withOpacity(0.8),
            width: hasFile ? 1.6 : 1.2,
          ),
          boxShadow: hasFile
              ? [
            BoxShadow(
              color: AppColors.violetMid.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.violetMid.withOpacity(0.15)
                    : AppColors.violetMid.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hasFile
                    ? Icons.audio_file_rounded
                    : Icons.upload_file_rounded,
                color: hasFile
                    ? AppColors.violetMid
                    : AppColors.violetMid.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? fileName! : 'Sélectionner un fichier audio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      hasFile ? FontWeight.w600 : FontWeight.w500,
                      color: hasFile
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFile
                        ? isAnalyzing
                        ? 'Analyse IA en cours...'
                        : 'MP3 · Appuie pour changer'
                        : 'MP3 ou WAV — max 50 Mo',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile
                          ? AppColors.violetMid
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                      isAnalyzing ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile && !isAnalyzing)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.violetMid.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.violetMid,
                  size: 18,
                ),
              )
            else if (isAnalyzing)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.violetMid,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
