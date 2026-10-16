import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../core/widgets/studio_artwork_lightbox.dart';
import '../../data/artist_metadata_service.dart';

/// Refined Studio Artist Avatar Widget
/// Displays online artist photo if found, falling back to local track album art, or studio avatar icon.
class ArtistAvatarWidget extends StatefulWidget {
  final String artistName;
  final Uint8List? fallbackCoverBytes;
  final String? fallbackCoverUrl;
  final double radius;
  final double iconSize;
  final VoidCallback? onTap;
  final bool enableLightboxOnTap;

  const ArtistAvatarWidget({
    super.key,
    required this.artistName,
    this.fallbackCoverBytes,
    this.fallbackCoverUrl,
    this.radius = 24,
    this.iconSize = 20,
    this.onTap,
    this.enableLightboxOnTap = false,
  });

  @override
  State<ArtistAvatarWidget> createState() => _ArtistAvatarWidgetState();
}

class _ArtistAvatarWidgetState extends State<ArtistAvatarWidget> {
  String? _onlineImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAvatar();
  }

  @override
  void didUpdateWidget(covariant ArtistAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artistName != widget.artistName) {
      _fetchAvatar();
    }
  }

  Future<void> _fetchAvatar() async {
    final url = await ArtistMetadataService.instance.getArtistImageUrl(widget.artistName);
    if (mounted) {
      setState(() {
        _onlineImageUrl = url;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    Widget avatar;

    if (_onlineImageUrl != null && _onlineImageUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(_onlineImageUrl!),
      );
    } else if (widget.fallbackCoverBytes != null && widget.fallbackCoverBytes!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: MemoryImage(widget.fallbackCoverBytes!),
      );
    } else if (widget.fallbackCoverUrl != null && widget.fallbackCoverUrl!.isNotEmpty) {
      final cleanUrl = widget.fallbackCoverUrl!.trim();
      if (cleanUrl.startsWith('http')) {
        avatar = CircleAvatar(
          radius: widget.radius,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          backgroundImage: NetworkImage(cleanUrl),
        );
      } else {
        final filePath = cleanUrl.startsWith('file://')
            ? Uri.parse(cleanUrl).toFilePath()
            : cleanUrl;
        final file = File(filePath);
        if (file.existsSync()) {
          avatar = CircleAvatar(
            radius: widget.radius,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: FileImage(file),
          );
        } else {
          avatar = _buildFallbackIcon(primary);
        }
      }
    } else {
      avatar = _buildFallbackIcon(primary);
    }

    if (widget.onTap != null || widget.enableLightboxOnTap) {
      return GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else if (widget.enableLightboxOnTap) {
            AppHaptics.selectionClick();
            StudioArtworkLightbox.show(
              context,
              bytes: widget.fallbackCoverBytes,
              url: _onlineImageUrl ?? widget.fallbackCoverUrl,
              title: widget.artistName,
              subtitle: 'Artist Discography',
              formatTag: 'ARTIST PROFILE',
            );
          }
        },
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallbackIcon(Color primary) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: primary.withValues(alpha: 0.15),
      child: _isLoading
          ? SizedBox(
              width: widget.iconSize * 0.8,
              height: widget.iconSize * 0.8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: primary.withValues(alpha: 0.6),
              ),
            )
          : Icon(
              LucideIcons.user,
              color: primary,
              size: widget.iconSize,
            ),
    );
  }
}
