import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerExpansionController extends StateNotifier<bool> {
  PlayerExpansionController() : super(false); // Collapsed by default

  void expand() => state = true;
  void collapse() => state = false;
  void toggle() => state = !state;
}

final playerExpansionProvider =
    StateNotifierProvider<PlayerExpansionController, bool>((ref) {
  return PlayerExpansionController();
});
