import 'package:flutter/material.dart';

/// Palette de couleurs de l'application Zik237.
/// À importer dans tous les fichiers qui ont besoin de couleurs.
/// import 'package:zik237/core/app_colors.dart';

class AppColors {
  AppColors._(); // empêche l'instanciation

  // ── Fonds ──────────────────────────────────────────────────────────────
  static const Color background   = Color(0xFFFFFFFF);
  static const Color violetLight  = Color(0xFFF8F7FF); // fond champ actif
  static const Color surface      = Color(0xFFF2F1FB); // fond carte

  // ── Violet principal ───────────────────────────────────────────────────
  static const Color violetDark   = Color(0xFF3C3489); // boutons, header
  static const Color violetMid    = Color(0xFF534AB7); // icônes, accents
  static const Color violetSoft   = Color(0xFFB3ABF0); // éléments secondaires

  // ── Textes ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B8A);
  static const Color textMuted     = Color(0xFFAAAAAC);

  // ── Bordures ───────────────────────────────────────────────────────────
  static const Color border        = Color(0xFFE0DFF5);
  static const Color borderFocused = Color(0xFF3C3489);

  // ── Fonctionnelles ─────────────────────────────────────────────────────
  static const Color success  = Color(0xFF97C459); // confirmation, croissance
  static const Color error    = Color(0xFFD4537E); // erreurs, échecs
  static const Color warning  = Color(0xFFEF9F27); // avertissements

  // ── Spécifiques modes ──────────────────────────────────────────────────
  static const Color accentAuditeur = Color(0xFF7F77DD); // CTA côté auditeur
  static const Color accentArtiste  = Color(0xFF2EAF8A); // CTA côté artiste
}



