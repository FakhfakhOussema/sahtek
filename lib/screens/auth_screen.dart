import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginFormKey    = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  // Login
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Register
  final _regEmailCtrl    = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _fullNameCtrl    = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureReg   = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose(); _passwordCtrl.dispose();
    _regEmailCtrl.dispose(); _regPasswordCtrl.dispose();
    _usernameCtrl.dispose(); _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.instance.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erreur de connexion. Vérifiez votre réseau.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.instance.signUp(
        email:    _regEmailCtrl.text.trim(),
        password: _regPasswordCtrl.text,
        username: _usernameCtrl.text.trim(),
        fullName: _fullNameCtrl.text.trim(),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erreur lors de la création du compte.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            children: [
              // ── Logo ──────────────────────────────────────────
              const _Logo(),
              const SizedBox(height: 36),

              // ── Tabs ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _TabBar(controller: _tabs),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: SizedBox(
                        height: _tabs.index == 0 ? 260 : 360,
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _LoginForm(
                              formKey:       _loginFormKey,
                              emailCtrl:     _emailCtrl,
                              passwordCtrl:  _passwordCtrl,
                              obscure:       _obscureLogin,
                              onToggle:      () => setState(() => _obscureLogin = !_obscureLogin),
                              onSubmit:      _login,
                            ),
                            _RegisterForm(
                              formKey:       _registerFormKey,
                              emailCtrl:     _regEmailCtrl,
                              passwordCtrl:  _regPasswordCtrl,
                              usernameCtrl:  _usernameCtrl,
                              fullNameCtrl:  _fullNameCtrl,
                              obscure:       _obscureReg,
                              onToggle:      () => setState(() => _obscureReg = !_obscureReg),
                              onSubmit:      _register,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Error
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.danger, fontSize: 13))),
                          ]),
                        ),
                      ),

                    // Submit button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: _SubmitButton(
                        label: _tabs.index == 0 ? 'Se connecter' : 'Créer mon compte',
                        loading: _loading,
                        onTap: _tabs.index == 0 ? _login : _register,
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

// ── Logo ─────────────────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
            blurRadius: 20, offset: const Offset(0, 8),
          )],
        ),
        child: const Icon(Icons.monitor_heart_rounded,
            color: Colors.white, size: 44),
      ),
      const SizedBox(height: 16),
      const Text('Sahtek',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
              color: AppTheme.primary, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text('Suivi de glycémie connecté',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
    ]);
  }
}

// ── Tab bar ──────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: 'Connexion'), Tab(text: 'Inscription')],
      ),
    );
  }
}

// ── Login form ───────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passwordCtrl;
  final bool obscure;
  final VoidCallback onToggle, onSubmit;
  const _LoginForm({required this.formKey, required this.emailCtrl,
      required this.passwordCtrl, required this.obscure,
      required this.onToggle, required this.onSubmit});
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Field(ctrl: emailCtrl, label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v?.contains('@') ?? false) ? null : 'Email invalide'),
          const SizedBox(height: 14),
          _Field(ctrl: passwordCtrl, label: 'Mot de passe',
              icon: Icons.lock_outline_rounded,
              obscure: obscure, onToggle: onToggle,
              validator: (v) => (v?.length ?? 0) >= 6 ? null : '6 caractères minimum'),
        ],
      ),
    );
  }
}

// ── Register form ─────────────────────────────────────────────────────────────
class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passwordCtrl, usernameCtrl, fullNameCtrl;
  final bool obscure;
  final VoidCallback onToggle, onSubmit;
  const _RegisterForm({required this.formKey, required this.emailCtrl,
      required this.passwordCtrl, required this.usernameCtrl,
      required this.fullNameCtrl, required this.obscure,
      required this.onToggle, required this.onSubmit});
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Field(ctrl: fullNameCtrl, label: 'Nom complet',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v?.isNotEmpty ?? false) ? null : 'Requis'),
          const SizedBox(height: 12),
          _Field(ctrl: usernameCtrl, label: 'Nom d\'utilisateur',
              icon: Icons.alternate_email_rounded,
              validator: (v) => (v?.length ?? 0) >= 3 ? null : '3 caractères minimum'),
          const SizedBox(height: 12),
          _Field(ctrl: emailCtrl, label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v?.contains('@') ?? false) ? null : 'Email invalide'),
          const SizedBox(height: 12),
          _Field(ctrl: passwordCtrl, label: 'Mot de passe',
              icon: Icons.lock_outline_rounded,
              obscure: obscure, onToggle: onToggle,
              validator: (v) => (v?.length ?? 0) >= 6 ? null : '6 caractères minimum'),
        ],
      ),
    );
  }
}

// ── Reusable field ────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggle;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  const _Field({required this.ctrl, required this.label, required this.icon,
      this.obscure = false, this.onToggle, this.validator, this.keyboardType});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
        suffixIcon: onToggle != null
            ? IconButton(
                onPressed: onToggle,
                icon: Icon(obscure ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined, size: 18),
              )
            : null,
      ),
    );
  }
}

// ── Submit button ─────────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SubmitButton({required this.label, required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
