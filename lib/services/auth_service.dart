import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'authentification — Zik237
/// Gère toutes les interactions avec Supabase Auth :
/// inscription, connexion, déconnexion, OTP, reset mot de passe.
///
/// Usage depuis n'importe quel écran :
/// ```dart
/// final authService = AuthService();
/// await authService.signIn(email: 'email', password: 'mdp');
/// ```

class AuthService {
  // Client Supabase global (initialisé dans main.dart)
  final _supabase = Supabase.instance.client;

  // ── Utilisateur courant ────────────────────────────────────────────────
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ────────────────────────────────────────────────────────────────────────
  // INSCRIPTION
  // ────────────────────────────────────────────────────────────────────────

  /// Crée un compte avec email + mot de passe.
  /// Insère aussi le profil dans la table `utilisateurs`.
  ///
  /// Retourne null si succès, un message d'erreur sinon.
  Future<String?> signUp({
    required String email,
    required String password,
    required String nomAffichage,
    required String role, // 'auditeur' ou 'artiste'
    String? ville,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nom_affichage': nomAffichage,
          'role': role,
          'ville': ville,
        },
      );

      if (response.user == null) {
        return 'Inscription échouée. Réessaie.';
      }

      // Insérer le profil dans la table utilisateurs
      await _supabase.from('utilisateurs').insert({
        'id': response.user!.id,
        'email': email,
        'nom_affichage': nomAffichage,
        'role': role,
        'ville': ville,
        'verifie': false,
      });

      // Si artiste → créer aussi le profil artiste
      if (role == 'artiste') {
        await _supabase.from('profils_artiste').insert({
          'id': response.user!.id,
        });
      }

      return null; // succès
    } on AuthException catch (e) {
      return _handleAuthError(e.message);
    } catch (e) {
      return 'Une erreur est survenue. Réessaie.';
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // CONNEXION
  // ────────────────────────────────────────────────────────────────────────

  /// Connecte un utilisateur avec email + mot de passe.
  /// Retourne null si succès, un message d'erreur sinon.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null; // succès
    } on AuthException catch (e) {
      return _handleAuthError(e.message);
    } catch (e) {
      return 'Une erreur est survenue. Réessaie.';
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // VÉRIFICATION OTP
  // ────────────────────────────────────────────────────────────────────────

  /// Vérifie le code OTP reçu par email ou SMS.
  /// Retourne null si succès, un message d'erreur sinon.
  Future<String?> verifyOtp({
    required String contact,
    required String code,
    required bool isEmail,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        type: isEmail ? OtpType.email : OtpType.sms,
        email: isEmail ? contact : null,
        phone: isEmail ? null : contact,
        token: code,
      );

      // Marquer le compte comme vérifié dans la table utilisateurs
      final userId = currentUser?.id;
      if (userId != null) {
        await _supabase
            .from('utilisateurs')
            .update({'verifie': true})
            .eq('id', userId);
      }

      return null; // succès
    } on AuthException catch (e) {
      return _handleAuthError(e.message);
    } catch (e) {
      return 'Code invalide ou expiré.';
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // RENVOYER L'OTP
  // ────────────────────────────────────────────────────────────────────────

  /// Renvoie un nouveau code OTP par email ou SMS.
  /// Retourne null si succès, un message d'erreur sinon.
  Future<String?> resendOtp({
    required String contact,
    required bool isEmail,
  }) async {
    try {
      if (isEmail) {
        await _supabase.auth.resend(
          type: OtpType.email,
          email: contact,
        );
      } else {
        await _supabase.auth.resend(
          type: OtpType.sms,
          phone: contact,
        );
      }
      return null; // succès
    } on AuthException catch (e) {
      return _handleAuthError(e.message);
    } catch (e) {
      return 'Impossible de renvoyer le code. Réessaie.';
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // MOT DE PASSE OUBLIÉ
  // ────────────────────────────────────────────────────────────────────────

  /// Envoie un email de réinitialisation du mot de passe.
  /// Retourne null si succès, un message d'erreur sinon.
  Future<String?> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'zik237://reset-password',
        // redirectTo = deep link vers ton app Flutter
        // À configurer dans Supabase Dashboard → Auth → URL Configuration
      );
      return null; // succès
    } on AuthException catch (e) {
      return _handleAuthError(e.message);
    } catch (e) {
      return 'Une erreur est survenue. Réessaie.';
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // METTRE À JOUR LE MOT DE PASSE
  // ────────────────────────────────────────────────────────────────────────

  /// Met à jour le mot de passe après réinitialisation.
  /// Retourne null si succès, un message d'erreur sinon.
  Future<String?> updatePassword({required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null; // succès
    } on AuthException catch (e) {
      return _handleAuthError(e.message);
    } catch (e) {
      return 'Impossible de mettre à jour le mot de passe.';
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // CONNEXION GOOGLE (OAuth)
  // ────────────────────────────────────────────────────────────────────────

  /// Lance le flux OAuth Google.
  /// Retourne null si succès, un message d'erreur sinon.
  Future<String?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'zik237://login-callback',
      );
      return null;
    } on AuthException catch (e) {
      return _handleAuthError(e.message);
    } catch (e) {
      return 'Connexion Google échouée. Réessaie.';
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // RÉCUPÉRER LE RÔLE DE L'UTILISATEUR
  // ────────────────────────────────────────────────────────────────────────

  /// Retourne le rôle de l'utilisateur connecté ('auditeur' ou 'artiste').
  /// Utile pour rediriger vers le bon écran après connexion.
  Future<String?> getUserRole() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('utilisateurs')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // DÉCONNEXION
  // ────────────────────────────────────────────────────────────────────────

  /// Déconnecte l'utilisateur et efface la session locale.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ────────────────────────────────────────────────────────────────────────
  // GESTION DES ERREURS
  // ────────────────────────────────────────────────────────────────────────

  /// Traduit les messages d'erreur Supabase en français.
  String _handleAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Vérifie ton email avant de te connecter.';
    }
    if (message.contains('User already registered')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (message.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (message.contains('Token has expired')) {
      return 'Le code a expiré. Demande un nouveau code.';
    }
    if (message.contains('Otp has expired')) {
      return 'Le code a expiré. Demande un nouveau code.';
    }
    if (message.contains('Invalid OTP')) {
      return 'Code incorrect. Vérifie et réessaie.';
    }
    if (message.contains('rate limit')) {
      return 'Trop de tentatives. Attends quelques minutes.';
    }
    if (message.contains('network')) {
      return 'Pas de connexion internet. Vérifie ta connexion.';
    }
    return 'Une erreur est survenue : $message';
  }
}