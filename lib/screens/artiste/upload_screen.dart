import 'dart:io';
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
  String? _audioFileName;
  String? _genreSelectionne;
  String? _genreIASuggestion;
  double? _genreIAConfiance;
  String? _villeSelectionnee;
  bool _isLoading = false;
  bool _isAnalyzingIA = false;
  double _uploadProgress = 0.0;

  final List<String> _genres = [
    'Trap 237', 'Bikutsi', 'Mbolé', 'Afro-drill',
    'Afrobeats', 'Makossa', 'Gospel', 'Autre',
  ];

  final List<String> _villes = [
    'Yaoundé', 'Douala', 'Bafoussam', 'Bamenda',
    'Garoua', 'Maroua', 'Ngaoundéré', 'Kribi',
  ];

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  // ── Sélectionner le fichier audio ────────────────────────────────────────
  Future<void> _selectionnerAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _audioFile = file;
        _audioFileName = result.files.single.name;
        _genreIASuggestion = null;
        _genreIAConfiance = null;
      });
      // Lancer la classification IA après sélection
      await _classifierGenreIA(file);
    }
  }

  // ── Sélectionner la pochette ─────────────────────────────────────────────
  Future<void> _selectionnerPochette() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _pochetteFile = File(image.path));
    }
  }

  // ── Appel microservice IA ────────────────────────────────────────────────
  Future<void> _classifierGenreIA(File audioFile) async {
    setState(() => _isAnalyzingIA = true);

    try {
      // TODO: remplacer par l'URL réelle de ton microservice FastAPI
      // Exemple :
      // final request = http.MultipartRequest(
      //   'POST',
      //   Uri.parse('https://ton-microservice.onrender.com/predict-genre'),
      // );
      // request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
      // final response = await request.send();
      // final body = await response.stream.bytesToString();
      // final data = jsonDecode(body);
      // setState(() {
      //   _genreIASuggestion = data['genre_predit'];
      //   _genreIAConfiance = data['confiance'];
      //   _genreSelectionne = _genreIASuggestion;
      // });

      // Simulation en attendant le microservice
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _genreIASuggestion = 'Trap 237';
        _genreIAConfiance = 0.82;
        _genreSelectionne = _genreIASuggestion;
      });
    } catch (e) {
      // Si le microservice est indisponible → l'artiste choisit manuellement
      _showSnackBar('Classification IA indisponible. Choisis le genre manuellement.');
    } finally {
      setState(() => _isAnalyzingIA = false);
    }
  }

  // ── Publier le titre ─────────────────────────────────────────────────────
  Future<void> _publier() async {
    // Validations
    if (_audioFile == null) {
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

      // 1. Upload fichier audio
      setState(() => _uploadProgress = 0.1);
      final audioPath = 'audio/$userId/$titreId.mp3';
      await _supabase.storage.from('audio').upload(
        audioPath,
        _audioFile!,
        fileOptions: const FileOptions(contentType: 'audio/mpeg'),
      );
      final audioUrl = _supabase.storage.from('audio').getPublicUrl(audioPath);
      setState(() => _uploadProgress = 0.5);

      // 2. Upload pochette (si sélectionnée)
      String? pochetteUrl;
      if (_pochetteFile != null) {
        final pochettePath = 'pochettes/$userId/$titreId.jpg';
        await _supabase.storage.from('pochettes').upload(
          pochettePath,
          _pochetteFile!,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        pochetteUrl = _supabase.storage
            .from('pochettes')
            .getPublicUrl(pochettePath);
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
    } catch (e) {
      _showSnackBar('Erreur lors de la publication. Réessaie.');
    } finally {
      setState(() => _isLoading = false);
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────────────
              _UploadHeader(onBack: () => Navigator.of(context).pop()),

              // ── FORMULAIRE ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── POCHETTE ──
                    const AppInputLabel(label: 'Pochette du titre'),
                    const SizedBox(height: 8),
                    _PochetteSelector(
                      file: _pochetteFile,
                      onTap: _selectionnerPochette,
                    ),
                    const SizedBox(height: 20),

                    // ── FICHIER AUDIO ──
                    const AppInputLabel(label: 'Fichier audio'),
                    const SizedBox(height: 8),
                    _AudioSelector(
                      fileName: _audioFileName,
                      isAnalyzing: _isAnalyzingIA,
                      onTap: _selectionnerAudio,
                    ),
                    const SizedBox(height: 20),

                    // ── NOM DU TITRE ──
                    const AppInputLabel(label: 'Titre du morceau'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _titreController,
                      hint: 'Ex: Nuit Blanche',
                      icon: Icons.title_rounded,
                      isFocused: true,
                    ),
                    const SizedBox(height: 20),

                    // ── GENRE (avec suggestion IA) ──
                    Row(
                      children: [
                        const AppInputLabel(label: 'Genre'),
                        if (_genreIASuggestion != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.violetLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 11,
                                  color: AppColors.violetMid,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Suggestion IA · ${(_genreIAConfiance! * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.violetMid,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chips de genre
                    _isAnalyzingIA
                        ? Container(
                      height: 40,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.violetMid,
                            ),
                          ),
                          const SizedBox(width: 10),
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
                      spacing: 8,
                      runSpacing: 8,
                      children: _genres.map((genre) {
                        final isSelected = genre == _genreSelectionne;
                        final isIASuggestion =
                            genre == _genreIASuggestion;
                        return GestureDetector(
                          onTap: () => setState(
                                  () => _genreSelectionne = genre),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentArtiste
                                  : isIASuggestion
                                  ? AppColors.violetLight
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentArtiste
                                    : isIASuggestion
                                    ? AppColors.violetMid
                                    : AppColors.border,
                                width: isSelected || isIASuggestion
                                    ? 1.5
                                    : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isIASuggestion && !isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 11,
                                      color: AppColors.violetMid,
                                    ),
                                  ),
                                Text(
                                  genre,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
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
                    const SizedBox(height: 20),

                    // ── VILLE ──
                    const AppInputLabel(label: 'Ville'),
                    const SizedBox(height: 8),
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
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.borderFocused,
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
                    const SizedBox(height: 32),

                    // ── BARRE DE PROGRESSION ──
                    if (_isLoading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: AppColors.surface,
                          color: AppColors.accentArtiste,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _uploadProgress < 0.5
                            ? 'Upload audio...'
                            : _uploadProgress < 0.8
                            ? 'Upload pochette...'
                            : 'Enregistrement en base...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── BOUTON PUBLIER ──
                    AppPrimaryButton(
                      label: 'Publier le titre',
                      isLoading: _isLoading,
                      onPressed: _publier,
                      color: AppColors.accentArtiste,
                    ),
                    const SizedBox(height: 12),

                    // Note sécurité
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Publié via ton compte artiste vérifié',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
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

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _UploadHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _UploadHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A2F), AppColors.background],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Publier un titre',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 44), // équilibre avec le bouton retour
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
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file != null
                ? AppColors.accentArtiste
                : AppColors.border,
            width: file != null ? 1.5 : 1.0,
            style: file != null ? BorderStyle.solid : BorderStyle.solid,
          ),
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
          children: const [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 8),
            Text(
              'Ajouter une pochette',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Optionnel — JPEG ou PNG',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        )
            : Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black38,
          ),
          child: const Center(
            child: Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 28,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.accentArtiste.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile ? AppColors.accentArtiste : AppColors.border,
            width: hasFile ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.accentArtiste.withOpacity(0.15)
                    : AppColors.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasFile
                    ? Icons.audio_file_rounded
                    : Icons.upload_file_rounded,
                color: hasFile
                    ? AppColors.accentArtiste
                    : AppColors.textMuted,
                size: 22,
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
                      fontSize: 13,
                      fontWeight: hasFile
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: hasFile
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasFile
                        ? isAnalyzing
                        ? 'Analyse IA en cours...'
                        : 'MP3 · Appuie pour changer'
                        : 'MP3 ou WAV — max 50 Mo',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasFile
                          ? AppColors.accentArtiste
                          : AppColors.textMuted,
                      fontStyle: isAnalyzing
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile && !isAnalyzing)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentArtiste,
                size: 22,
              )
            else if (isAnalyzing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentArtiste,
                ),
              ),
          ],
        ),
      ),
    );
  }
}









