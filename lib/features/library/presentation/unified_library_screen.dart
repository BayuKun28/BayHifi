import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

enum LibrarySourceFilter { all, offline, navidrome, hiRes }

class UnifiedLibraryScreen extends ConsumerStatefulWidget {
  const UnifiedLibraryScreen({super.key});

  @override
  ConsumerState<UnifiedLibraryScreen> createState() => _UnifiedLibraryScreenState();
}

class _UnifiedLibraryScreenState extends ConsumerState<UnifiedLibraryScreen> {
  LibrarySourceFilter _selectedFilter = LibrarySourceFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIFIED LIBRARY',
                        style: AppTypography.badge(color: AppColors.amberEq),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offline & Navidrome Cloud',
                        style: AppTypography.title(Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.sync, color: AppColors.amberEq),
                    tooltip: 'Sync Navidrome & Scan Local',
                  ),
                ],
              ),
            ),

            // Filter Chips Bar: [All Sources] [Offline Local] [Navidrome Cloud] [Hi-Res FLAC]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Sources', LibrarySourceFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('Offline Local', LibrarySourceFilter.offline),
                    const SizedBox(width: 8),
                    _buildFilterChip('Navidrome Cloud', LibrarySourceFilter.navidrome),
                    const SizedBox(width: 8),
                    _buildFilterChip('Hi-Res Lossless (24-bit)', LibrarySourceFilter.hiRes),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content List
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedFilter == LibrarySourceFilter.navidrome
                          ? Icons.cloud_outlined
                          : (_selectedFilter == LibrarySourceFilter.offline
                              ? Icons.folder_outlined
                              : Icons.library_music_outlined),
                      size: 64,
                      color: AppColors.amberEq.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getFilterTitle(_selectedFilter),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _getFilterSubtitle(_selectedFilter),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Action to scan or connect
                      },
                      icon: Icon(
                        _selectedFilter == LibrarySourceFilter.navidrome
                            ? Icons.add_link
                            : Icons.folder_open,
                        size: 16,
                      ),
                      label: Text(
                        _selectedFilter == LibrarySourceFilter.navidrome
                            ? 'Hubungkan Server Navidrome'
                            : 'Scan Folder Musik Lokal',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amberEq.withValues(alpha: 0.2),
                        foregroundColor: AppColors.amberEq,
                        side: const BorderSide(color: AppColors.amberEq, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, LibrarySourceFilter filter) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filter);
      },
      selectedColor: AppColors.amberEq,
      backgroundColor: const Color(0xFF141820),
      side: BorderSide(
        color: isSelected ? AppColors.amberEq : const Color(0xFF263238),
        width: 1.0,
      ),
      showCheckmark: false,
    );
  }

  String _getFilterTitle(LibrarySourceFilter filter) {
    switch (filter) {
      case LibrarySourceFilter.all:
        return 'Pustaka Musik Terpadu';
      case LibrarySourceFilter.offline:
        return 'File Audio Offline';
      case LibrarySourceFilter.navidrome:
        return 'Navidrome Subsonic Cloud';
      case LibrarySourceFilter.hiRes:
        return 'Koleksi Hi-Res Lossless';
    }
  }

  String _getFilterSubtitle(LibrarySourceFilter filter) {
    switch (filter) {
      case LibrarySourceFilter.all:
        return 'Semua lagu dari penyimpanan perangkat lokal dan streaming cloud Navidrome disatukan dalam satu antarmuka.';
      case LibrarySourceFilter.offline:
        return 'File FLAC, WAV, MP3 yang tersimpan di memori perangkat lokal dan siap dimainkan tanpa koneksi internet.';
      case LibrarySourceFilter.navidrome:
        return 'Streaming langsung dari server pribadi Navidrome via API Subsonic dengan caching lokal otomatis.';
      case LibrarySourceFilter.hiRes:
        return 'Lagu dengan kualitas 24-bit / 96kHz atau 192kHz untuk performa bit-perfect audio terbaik.';
    }
  }
}
