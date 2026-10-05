import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/services/auth_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late AuthService authService;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockClient.auth).thenReturn(mockAuth);

    authService = AuthService(client: mockClient);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // signIn
  // ──────────────────────────────────────────────────────────────────────────
  group('signIn', () {
    test('retourne null quand la connexion réussit', () async {
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => MockAuthResponse());

      final error = await authService.signIn(
        email: 'test@test.com',
        password: 'password123',
      );

      expect(error, isNull);
    });

    test('retourne "Email ou mot de passe incorrect" si mauvais identifiants', () async {
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(const AuthException('Invalid login credentials'));

      final error = await authService.signIn(
        email: 'wrong@test.com',
        password: 'wrong',
      );

      expect(error, 'Email ou mot de passe incorrect.');
    });

    test('retourne message si email non confirmé', () async {
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(const AuthException('Email not confirmed'));

      final error = await authService.signIn(
        email: 'test@test.com',
        password: 'password123',
      );

      expect(error, 'Vérifie ton email avant de te connecter.');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // signUp
  // ──────────────────────────────────────────────────────────────────────────
  group('signUp', () {
    test('retourne erreur si email déjà utilisé', () async {
      when(() => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      )).thenThrow(const AuthException('User already registered'));

      final error = await authService.signUp(
        email: 'existant@test.com',
        password: 'password123',
        nomAffichage: 'Test',
        role: 'auditeur',
      );

      expect(error, 'Un compte existe déjà avec cet email.');
    });

    test('retourne erreur si mot de passe trop court', () async {
      when(() => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      )).thenThrow(const AuthException('Password should be at least 6 characters'));

      final error = await authService.signUp(
        email: 'test@test.com',
        password: '123',
        nomAffichage: 'Test',
        role: 'auditeur',
      );

      expect(error, 'Le mot de passe doit contenir au moins 8 caractères.');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getUserRole (version simplifiée)
  // ──────────────────────────────────────────────────────────────────────────
  group('getUserRole', () {
    test('retourne null si aucun utilisateur connecté', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final role = await authService.getUserRole();

      expect(role, isNull);
    });
  });
}