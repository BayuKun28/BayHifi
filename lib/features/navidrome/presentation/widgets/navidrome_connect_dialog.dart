import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/subsonic_models.dart';
import '../../../library/presentation/controllers/library_controller.dart';

/// Modal dialog untuk konfigurasi koneksi server Navidrome / Subsonic
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
                    child: Icon(Icons.cloud_sync_rounded, color: primaryColor, size: 24),
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
                    icon: const Icon(Icons.close, size: 20),
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
                    Icon(
                      isConnected ? Icons.cloud_done : Icons.cloud_off,
                      size: 16,
                      color: isConnected ? const Color(0xFF00E676) : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isConnected
                            ? 'Terhubung: ${libraryState.navidromeConfig?.serverUrl}'
                            : 'Belum Terhubung ke Server',
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
                  prefixIcon: const Icon(Icons.dns_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'URL Server wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Username wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Password wajib diisi' : null,
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
                        child: const Text('Putuskan'),
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
                          : const Icon(Icons.link, size: 18),
                      label: Text(isConnecting ? 'Menghubungkan...' : (isConnected ? 'Sinkron Ulang' : 'Hubungkan')),
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
