import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/subsonic_models.dart';
import '../../../library/presentation/controllers/library_controller.dart';

/// Modal dialog for Navidrome / Subsonic Server Connection Configuration
class NavidromeConnectDialog extends ConsumerStatefulWidget {
  const NavidromeConnectDialog({super.key});

  @override
  ConsumerState<NavidromeConnectDialog> createState() => _NavidromeConnectDialogState();
}

class _NavidromeConnectDialogState extends ConsumerState<NavidromeConnectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final currentConfig = ref.read(unifiedLibraryProvider).navidromeConfig;
    _urlController = TextEditingController(text: currentConfig?.serverUrl ?? 'http://192.168.1.100:4533');
    _usernameController = TextEditingController(text: currentConfig?.username ?? 'audiophile');
    _passwordController = TextEditingController(text: currentConfig?.password ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final isConnected = libraryState.navidromeConnectionStatus == NavidromeConnectionStatus.connected;
    final isConnecting = libraryState.isConnectingNavidrome;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Dialog(
      backgroundColor: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.0,
        ),
      ),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(
                        context,
                        primaryColor,
                        isSolid: isSolid,
                        translucentAlpha: 0.15,
                        solidBlendAlpha: 0.20,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.cloud, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NAVIDROME CLOUD',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Subsonic Lossless Audio Stream',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Server Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? StudioSurfaceTheme.tintedContainer(context, const Color(0xFF00E676), isSolid: isSolid, translucentAlpha: 0.15, solidBlendAlpha: 0.20)
                      : StudioSurfaceTheme.tintedContainer(context, Colors.orange, isSolid: isSolid, translucentAlpha: 0.12, solidBlendAlpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? LucideIcons.cloud : LucideIcons.cloudOff,
                      size: 16,
                      color: isConnected ? const Color(0xFF00E676) : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isConnected
                            ? 'Connected: ${libraryState.navidromeConfig?.serverUrl}'
                            : 'Not Connected to Server',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isConnected ? const Color(0xFF00E676) : Colors.orangeAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Server URL Field
              TextFormField(
                controller: _urlController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  labelStyle: const TextStyle(fontSize: 13),
                  hintText: 'http://192.168.1.100:4533',
                  prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(LucideIcons.server, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Server URL is required' : null,
              ),
              const SizedBox(height: 12),

              // Username Field
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(fontSize: 13),
                  prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(LucideIcons.user, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Username is required' : null,
              ),
              const SizedBox(height: 12),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(fontSize: 13),
                  prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(LucideIcons.lock, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Password is required' : null,
              ),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  if (isConnected)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(unifiedLibraryProvider.notifier).disconnectNavidrome();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ),
                  if (isConnected) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isConnecting
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                final config = SubsonicServerConfig(
                                  serverUrl: _urlController.text.trim(),
                                  username: _usernameController.text.trim(),
                                  password: _passwordController.text,
                                );
                                final success = await ref
                                    .read(unifiedLibraryProvider.notifier)
                                    .connectNavidrome(config);
                                if (context.mounted && success) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                      icon: isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.link, size: 18, color: Colors.black),
                      label: Text(isConnecting ? 'Connecting...' : (isConnected ? 'Re-Sync' : 'Connect')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
