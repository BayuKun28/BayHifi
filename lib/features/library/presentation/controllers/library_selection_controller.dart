import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../player/domain/track.dart';

/// Immutable state representing multi-track selection inside the library
@immutable
class LibrarySelectionState {
  final Set<String> selectedTrackIds;

  const LibrarySelectionState({
    this.selectedTrackIds = const {},
  });

  bool get isSelecting => selectedTrackIds.isNotEmpty;
  int get count => selectedTrackIds.length;
  bool isSelected(String id) => selectedTrackIds.contains(id);

  LibrarySelectionState copyWith({
    Set<String>? selectedTrackIds,
  }) {
    return LibrarySelectionState(
      selectedTrackIds: selectedTrackIds ?? this.selectedTrackIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibrarySelectionState &&
          setEquals(other.selectedTrackIds, selectedTrackIds);

  @override
  int get hashCode => selectedTrackIds.hashCode;
}

/// StateNotifier managing multi-track selection operations
class LibrarySelectionNotifier extends StateNotifier<LibrarySelectionState> {
  LibrarySelectionNotifier() : super(const LibrarySelectionState());

  /// Toggle selection for a single track
  void toggle(String trackId) {
    AppHaptics.selectionClick();
    final updated = Set<String>.from(state.selectedTrackIds);
    if (updated.contains(trackId)) {
      updated.remove(trackId);
    } else {
      updated.add(trackId);
    }
    state = state.copyWith(selectedTrackIds: updated);
  }

  /// Select a single track
  void select(String trackId) {
    if (state.selectedTrackIds.contains(trackId)) return;
    AppHaptics.selectionClick();
    final updated = Set<String>.from(state.selectedTrackIds)..add(trackId);
    state = state.copyWith(selectedTrackIds: updated);
  }

  /// Deselect a single track
  void deselect(String trackId) {
    if (!state.selectedTrackIds.contains(trackId)) return;
    AppHaptics.selectionClick();
    final updated = Set<String>.from(state.selectedTrackIds)..remove(trackId);
    state = state.copyWith(selectedTrackIds: updated);
  }

  /// Select all tracks in the provided list
  void selectAll(List<Track> tracks) {
    AppHaptics.selectionClick();
    final updated = tracks.map((t) => t.id).toSet();
    state = state.copyWith(selectedTrackIds: updated);
  }

  /// Deselect all tracks
  void deselectAll() {
    AppHaptics.selectionClick();
    state = const LibrarySelectionState();
  }

  /// Clear selection silently without haptic (e.g. on tab switch or screen disposal)
  void clear() {
    if (state.selectedTrackIds.isNotEmpty) {
      state = const LibrarySelectionState();
    }
  }
}

/// Global provider for library multi-track selection state
final librarySelectionProvider =
    StateNotifierProvider<LibrarySelectionNotifier, LibrarySelectionState>(
  (ref) => LibrarySelectionNotifier(),
);
