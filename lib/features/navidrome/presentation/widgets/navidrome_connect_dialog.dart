import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
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
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedCloudSync, color: primaryColor, size: 24),
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
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 20, color: Color(0xFF90A4AE)),
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
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF00E676) : Colors.orangeAccent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: isConnected ? HugeIcons.strokeRoundedCloudCheck : HugeIcons.strokeRoundedCloudOff,
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
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'http://192.168.1.100:4533',
                  prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedServer, size: 20, color: Color(0xFF90A4AE)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Server URL is required' : null,
              ),
              const SizedBox(height: 12),

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 20, color: Color(0xFF90A4AE)),
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
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, size: 20, color: Color(0xFF90A4AE)),
                  suffixIcon: IconButton(
                    icon: HugeIcon(
                      icon: _obscurePassword ? HugeIcons.strokeRoundedViewOffSlash : HugeIcons.strokeRoundedView,
                      size: 18,
                      color: const Color(0xFF90A4AE),
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
                          : const HugeIcon(icon: HugeIcons.strokeRoundedLink01, size: 18, color: Colors.black),
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
