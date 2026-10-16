import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../controllers/cloud_auth_controller.dart';
import '../../domain/cloud_auth_state.dart';

/// Dialog modal untuk Login & Registrasi BayHifi Cloud
class CloudAuthDialog extends ConsumerStatefulWidget {
  const CloudAuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CloudAuthDialog(),
    );
  }

  @override
  ConsumerState<CloudAuthDialog> createState() => _CloudAuthDialogState();
}

class _CloudAuthDialogState extends ConsumerState<CloudAuthDialog> {
  bool _isRegister = false;
  late final TextEditingController _serverController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(cloudAuthControllerProvider).serverUrl;
    _serverController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final serverUrl = _serverController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) return;

    final controller = ref.read(cloudAuthControllerProvider.notifier);
    bool success;
    if (_isRegister) {
      success = await controller.register(
        serverUrl: serverUrl,
        username: username,
        password: password,
        email: email.isNotEmpty ? email : null,
      );
    } else {
      success = await controller.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
    }

    if (!mounted) return;

    if (success) {
      AppHaptics.mediumImpact();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                LucideIcons.circleCheck,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isRegister ? 'Account created and connected!' : 'Welcome back, $username!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      AppHaptics.heavyImpact();
      final err = ref.read(cloudAuthControllerProvider).errorMessage ?? 'Connection or authentication failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  err,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(cloudAuthControllerProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isLoading = authState.status == CloudAuthStatus.loading;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.cloud,
                      size: 20,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BAYHIFI CLOUD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Sync Studio Wrapped & AutoEQ Profiles',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mode Toggle (Sign In vs Register)
              Row(
                children: [
                  Expanded(
                    child: _isRegister
                        ? M3EButton.outlined(
                            icon: Icon(
                              LucideIcons.logIn,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            label: const Text('SIGN IN'),
                            onPressed: isLoading
                                ? null
                                : () {
                                    AppHaptics.selectionClick();
                                    setState(() => _isRegister = false);
                                  },
                          )
                        : M3EButton.filled(
                            icon: Icon(
                              LucideIcons.logIn,
                              size: 16,
                              color: theme.colorScheme.onPrimary,
                            ),
                            label: const Text('SIGN IN'),
                            onPressed: isLoading
                                ? null
                                : () {
                                    AppHaptics.selectionClick();
                                    setState(() => _isRegister = false);
                                  },
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isRegister
                        ? M3EButton.filled(
                            icon: Icon(
                              LucideIcons.userPlus,
                              size: 16,
                              color: theme.colorScheme.onPrimary,
                            ),
                            label: const Text('REGISTER'),
                            onPressed: isLoading
                                ? null
                                : () {
                                    AppHaptics.selectionClick();
                                    setState(() => _isRegister = true);
                                  },
                          )
                        : M3EButton.outlined(
                            icon: Icon(
                              LucideIcons.userPlus,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            label: const Text('REGISTER'),
                            onPressed: isLoading
                                ? null
                                : () {
                                    AppHaptics.selectionClick();
                                    setState(() => _isRegister = true);
                                  },
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Server URL Field
              TextField(
                controller: _serverController,
                decoration: InputDecoration(
                  labelText: 'Server Host URL',
                  hintText: 'http://localhost:8111',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(
                      LucideIcons.server,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Username Field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(
                      LucideIcons.user,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(
                      LucideIcons.lock,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: () {
                      AppHaptics.selectionClick();
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // Optional Email Field (Only on Register)
              if (_isRegister) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email (Optional)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Icon(
                        LucideIcons.mail,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],

              // Error display if any
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              _isRegister
                  ? M3EButton.filled(
                      label: Text(isLoading ? 'CONNECTING...' : 'CREATE ACCOUNT'),
                      icon: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              LucideIcons.userPlus,
                              size: 18,
                              color: theme.colorScheme.onPrimary,
                            ),
                      onPressed: isLoading ? null : _submit,
                    )
                  : M3EButton.filled(
                      label: Text(isLoading ? 'CONNECTING...' : 'CONNECT & SIGN IN'),
                      icon: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              LucideIcons.logIn,
                              size: 18,
                              color: theme.colorScheme.onPrimary,
                            ),
                      onPressed: isLoading ? null : _submit,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
