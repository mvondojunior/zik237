import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';
import 'package:app_mobile_music_underground/core/app_button.dart';
import 'package:app_mobile_music_underground/core/app_text_field.dart';
import 'package:app_mobile_music_underground/services/auth_service.dart';

/// Écran d'inscription — Zik237
class RegisterScreen extends StatefulWidget {
const RegisterScreen({super.key});

@override
State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
final _authService = AuthService();

final _nomController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmPasswordController = TextEditingController();

bool _obscurePassword = true;
bool _obscureConfirm = true;
bool _isLoading = false;

String _selectedRole = 'auditeur';
String? _selectedVille;

final List<String> _villes = [
'Yaoundé',
'Douala',
'Bafoussam',
'Bamenda',
'Garoua',
'Maroua',
'Ngaoundéré',
'Bertoua',
'Ebolowa',
'Kribi',
];

@override
void dispose() {
_nomController.dispose();
_emailController.dispose();
_passwordController.dispose();
_confirmPasswordController.dispose();
super.dispose();
}

Future<void> _handleRegister() async {
final nom = _nomController.text.trim();
final email = _emailController.text.trim();
final password = _passwordController.text;
final confirm = _confirmPasswordController.text;

// Vérification des champs
if (nom.isEmpty ||
email.isEmpty ||
password.isEmpty ||
confirm.isEmpty) {
_showSnackBar('Merci de remplir tous les champs');
return;
}

// Vérification des mots de passe
if (password != confirm) {
_showSnackBar('Les mots de passe ne correspondent pas');
return;
}

// Longueur minimale
if (password.length < 8) {
_showSnackBar(
'Le mot de passe doit contenir au moins 8 caractères',
);
return;
}

// Vérification simple de l'email
if (!email.contains('@')) {
_showSnackBar('Adresse email invalide');
return;
}

setState(() => _isLoading = true);

final error = await _authService.signUp(
email: email,
password: password,
nomAffichage: nom,
role: _selectedRole,
ville: _selectedVille,
);

if (!mounted) return;

setState(() => _isLoading = false);

if (error != null) {
_showSnackBar(error);
} else {
// Inscription réussie :
// retour vers l'écran de connexion.
_showSnackBar('Compte créé avec succès');

Navigator.of(context).pop();
}
}

void _showSnackBar(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: AppColors.violetDark,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
);
}

void _goBack() => Navigator.of(context).pop();

void _goToLogin() => Navigator.of(context).pop();

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.background,
body: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
child: Column(
children: [
_RegisterHeader(onBack: _goBack),

Padding(
padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

// Choix du rôle
const Text(
'Tu es...',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w500,
color: AppColors.textSecondary,
letterSpacing: 0.2,
),
),

const SizedBox(height: 12),

_RoleSelector(
selectedRole: _selectedRole,
onRoleChanged: (role) {
setState(() => _selectedRole = role);
},
),

const SizedBox(height: 28),

// Nom d'affichage
const AppInputLabel(
label: 'Nom d\'affichage',
),

const SizedBox(height: 8),

AppTextField(
controller: _nomController,
hint: 'Ton nom ou pseudo',
icon: Icons.person_outline_rounded,
isFocused: true,
),

const SizedBox(height: 18),

// Email
const AppInputLabel(
label: 'Email',
),

const SizedBox(height: 8),

AppTextField(
controller: _emailController,
hint: 'nom@email.com',
icon: Icons.mail_outline_rounded,
keyboardType: TextInputType.emailAddress,
),

const SizedBox(height: 18),

// Mot de passe
const AppInputLabel(
label: 'Mot de passe',
),

const SizedBox(height: 8),

AppTextField(
controller: _passwordController,
hint: 'Minimum 8 caractères',
icon: Icons.lock_outline_rounded,
obscureText: _obscurePassword,
suffixIcon: IconButton(
icon: Icon(
_obscurePassword
? Icons.visibility_off_outlined
    : Icons.visibility_outlined,
color: AppColors.textMuted,
size: 20,
),
onPressed: () {
setState(() {
_obscurePassword = !_obscurePassword;
});
},
),
),

const SizedBox(height: 18),

// Confirmer mot de passe
const AppInputLabel(
label: 'Confirmer le mot de passe',
),

const SizedBox(height: 8),

AppTextField(
controller: _confirmPasswordController,
hint: 'Répète ton mot de passe',
icon: Icons.lock_outline_rounded,
obscureText: _obscureConfirm,
textInputAction: TextInputAction.done,
suffixIcon: IconButton(
icon: Icon(
_obscureConfirm
? Icons.visibility_off_outlined
    : Icons.visibility_outlined,
color: AppColors.textMuted,
size: 20,
),
onPressed: () {
setState(() {
_obscureConfirm = !_obscureConfirm;
});
},
),
),

const SizedBox(height: 18),

// Ville
const AppInputLabel(
label: 'Ta ville',
),

const SizedBox(height: 8),

_VilleDropdown(
villes: _villes,
selectedVille: _selectedVille,
onChanged: (ville) {
setState(() => _selectedVille = ville);
},
),

const SizedBox(height: 32),

// Bouton
AppPrimaryButton(
label: 'Créer mon compte',
isLoading: _isLoading,
onPressed: _handleRegister,
),

const SizedBox(height: 20),

// Conditions
Center(
child: RichText(
textAlign: TextAlign.center,
text: const TextSpan(
text: "En t'inscrivant tu acceptes nos ",
style: TextStyle(
color: AppColors.textMuted,
fontSize: 12,
height: 1.5,
),
children: [
TextSpan(
text: "conditions d'utilisation",
style: TextStyle(
color: AppColors.violetDark,
fontWeight: FontWeight.w600,
),
),
],
),
),
),

const SizedBox(height: 28),

// Lien connexion
Center(
child: GestureDetector(
onTap: _goToLogin,
child: RichText(
text: const TextSpan(
text: 'Déjà un compte ? ',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 14,
),
children: [
TextSpan(
text: 'Se connecter',
style: TextStyle(
color: AppColors.violetDark,
fontWeight: FontWeight.w700,
),
),
],
),
),
),
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


// ─── HEADER ──────────────────────────────────────────────────────────────────

class _RegisterHeader extends StatelessWidget {
final VoidCallback onBack;

const _RegisterHeader({
required this.onBack,
});

@override
Widget build(BuildContext context) {
return SizedBox(
height: 180,
child: Stack(
children: [
Container(
height: 180,
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
AppColors.violetDark,
Color(0xFF5B2C8A),
],
),
),
),

Positioned(
bottom: 0,
left: 0,
right: 0,
child: ClipPath(
clipper: _RegisterWaveClipper(),
child: Container(
height: 55,
color: AppColors.background,
),
),
),

Positioned(
top: 50,
left: 12,
child: IconButton(
onPressed: onBack,
icon: const Icon(
Icons.arrow_back_ios_new_rounded,
color: Colors.white70,
size: 20,
),
),
),

const Positioned(
top: 54,
left: 56,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Zik237',
style: TextStyle(
fontSize: 12,
color: Colors.white60,
letterSpacing: 1.4,
fontWeight: FontWeight.w500,
),
),

SizedBox(height: 6),

Text(
'Créer un compte',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.w700,
color: Colors.white,
letterSpacing: -0.6,
),
),
],
),
),
],
),
);
}
}


// ─── WAVE ────────────────────────────────────────────────────────────────────

class _RegisterWaveClipper extends CustomClipper<Path> {
@override
Path getClip(Size size) {
final path = Path();

path.moveTo(0, size.height);
path.lineTo(0, size.height * 0.45);

path.quadraticBezierTo(
size.width * 0.2,
0,
size.width * 0.4,
size.height * 0.4,
);

path.quadraticBezierTo(
size.width * 0.6,
size.height * 0.85,
size.width * 0.8,
size.height * 0.25,
);

path.quadraticBezierTo(
size.width * 0.92,
0,
size.width,
size.height * 0.35,
);

path.lineTo(size.width, size.height);
path.close();

return path;
}

@override
bool shouldReclip(_RegisterWaveClipper oldClipper) => false;
}


// ─── SÉLECTEUR DE RÔLE ───────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
final String selectedRole;
final ValueChanged<String> onRoleChanged;

const _RoleSelector({
required this.selectedRole,
required this.onRoleChanged,
});

@override
Widget build(BuildContext context) {
return Row(
children: [
_RoleCard(
label: 'Auditeur',
icon: Icons.headphones_rounded,
isSelected: selectedRole == 'auditeur',
onTap: () => onRoleChanged('auditeur'),
),

const SizedBox(width: 14),

_RoleCard(
label: 'Artiste',
icon: Icons.mic_rounded,
isSelected: selectedRole == 'artiste',
onTap: () => onRoleChanged('artiste'),
),
],
);
}
}


// ─── ROLE CARD ───────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
final String label;
final IconData icon;
final bool isSelected;
final VoidCallback onTap;

const _RoleCard({
required this.label,
required this.icon,
required this.isSelected,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return Expanded(
child: GestureDetector(
onTap: onTap,
child: AnimatedContainer(
duration: const Duration(milliseconds: 220),
curve: Curves.easeOutCubic,
padding: const EdgeInsets.symmetric(vertical: 18),
decoration: BoxDecoration(
color: isSelected
? AppColors.violetLight
    : Colors.transparent,
border: Border.all(
color: isSelected
? AppColors.violetDark
    : AppColors.border,
width: isSelected ? 1.8 : 1.0,
),
borderRadius: BorderRadius.circular(16),
boxShadow: isSelected
? [
BoxShadow(
color: AppColors.violetDark.withOpacity(0.18),
blurRadius: 12,
offset: const Offset(0, 4),
),
]
    : [],
),
child: Column(
children: [
AnimatedScale(
scale: isSelected ? 1.08 : 1.0,
duration: const Duration(milliseconds: 220),
child: Icon(
icon,
size: 26,
color: isSelected
? AppColors.violetDark
    : AppColors.textMuted,
),
),

const SizedBox(height: 8),

Text(
label,
style: TextStyle(
fontSize: 14,
fontWeight: isSelected
? FontWeight.w700
    : FontWeight.w500,
color: isSelected
? AppColors.violetDark
    : AppColors.textSecondary,
),
),
],
),
),
),
);
}
}


// ─── DROPDOWN VILLE ──────────────────────────────────────────────────────────

class _VilleDropdown extends StatelessWidget {
final List<String> villes;
final String? selectedVille;
final ValueChanged<String?> onChanged;

const _VilleDropdown({
required this.villes,
required this.selectedVille,
required this.onChanged,
});

@override
Widget build(BuildContext context) {
return DropdownButtonFormField<String>(
value: selectedVille,

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
vertical: 16,
),

border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppColors.border,
),
),

enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppColors.border,
),
),

focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppColors.violetDark,
width: 1.6,
),
),
),

items: villes
    .map(
(ville) => DropdownMenuItem(
value: ville,
child: Text(
ville,
style: const TextStyle(
fontSize: 14,
color: AppColors.textPrimary,
),
),
),
)
    .toList(),
onChanged: onChanged,
);
}
}
