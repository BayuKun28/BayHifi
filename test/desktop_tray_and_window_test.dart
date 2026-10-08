// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/legacy.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/core/desktop/desktop_tray_service.dart';
import 'package:baydev_hifi/core/desktop/desktop_window_service.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/docking_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('baydev_tray_test_');
    await LocalPersistenceService.instance.init(
      customPath: '${tempDir.path}/storage.json',
    );
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('DesktopTrayService Unit Tests', () {
    test('singleton instance exists and handles callbacks', () {
      final trayService = DesktopTrayService.instance;
      expect(trayService, isNotNull);

      bool playPauseCalled = false;
      bool nextCalled = false;
      bool prevCalled = false;
      bool muteCalled = false;
      bool dspCalled = false;
      bool autoEqCalled = false;

      trayService.onPlayPause = () => playPauseCalled = true;
      trayService.onNext = () => nextCalled = true;
      trayService.onPrevious = () => prevCalled = true;
      trayService.onToggleMute = () => muteCalled = true;
      trayService.onToggleDspRack = () => dspCalled = true;
      trayService.onOpenAutoEq = () => autoEqCalled = true;

      trayService.onTrayMenuItemClick(MenuItem(key: 'play_pause', label: 'Play/Pause'));
      expect(playPauseCalled, isTrue);

      trayService.onTrayMenuItemClick(MenuItem(key: 'next_track', label: 'Next'));
      expect(nextCalled, isTrue);

      trayService.onTrayMenuItemClick(MenuItem(key: 'previous_track', label: 'Prev'));
      expect(prevCalled, isTrue);

      trayService.onTrayMenuItemClick(MenuItem(key: 'toggle_mute', label: 'Mute'));
      expect(muteCalled, isTrue);

      trayService.onTrayMenuItemClick(MenuItem(key: 'dsp_status', label: 'DSP'));
      expect(dspCalled, isTrue);

      trayService.onTrayMenuItemClick(MenuItem(key: 'autoeq_status', label: 'AutoEQ'));
      expect(autoEqCalled, isTrue);
    });

    test('updatePlaybackState updates internal telemetry safely', () async {
      final trayService = DesktopTrayService.instance;

      const track = Track(
        id: 'flac_studio_01',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: Duration(minutes: 5, seconds: 55),
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
      );

      await trayService.updatePlaybackState(
        currentTrack: track,
        isPlaying: true,
        volume: 0.85,
        isMuted: false,
        dspPresetName: 'Studio Warm Tube',
        autoEqTarget: 'Harman 2019v2 Target',
        isDspActive: true,
      );

      // Verify that no exceptions are thrown when updating state without trayManager native binding attached
      expect(true, isTrue);
    });
  });

  group('DesktopWindowService Unit Tests', () {
    test('singleton instance exists and manages window geometry persistence', () async {
      final windowService = DesktopWindowService.instance;
      expect(windowService, isNotNull);

      await LocalPersistenceService.instance.saveWindowDimensions(
        width: 1440,
        height: 900,
        x: 100,
        y: 100,
        isMaximized: false,
      );

      final saved = LocalPersistenceService.instance.getWindowDimensions();
      expect(saved, isNotNull);
      expect(saved!['width'], 1440);
      expect(saved['height'], 900);
      expect(saved['isMaximized'], isFalse);

      final closeToTray = LocalPersistenceService.instance.getSetting<bool>(
        'desktop_close_to_tray',
        true,
      );
      expect(closeToTray, isTrue);
    });
  });

  group('DockingSettingsScreen Widget Tests', () {
    testWidgets('renders DockingSettingsScreen with all sections and launches properly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DockingSettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STUDIO WORKSTATION & DOCKING'), findsOneWidget);
      expect(find.text('STUDIO WORKSTATION & DOCK'), findsOneWidget);
      expect(find.text('LAUNCH STUDIO DOCKING MODE'), findsOneWidget);

      // Verify Desktop System Tray Card elements
      expect(find.text('Linux & Desktop Tray Quick Controls'), findsOneWidget);
      expect(find.text('TRAY DAEMON: ONLINE'), findsOneWidget);
      expect(find.text('Minimize to Tray on Close'), findsOneWidget);
      expect(find.text('System Tray Track Telemetry Tooltip'), findsOneWidget);

      // Verify Features
      expect(find.text('High-Contrast Studio Clock'), findsOneWidget);
      expect(find.text('Dual Analog VU Meters'), findsOneWidget);
      expect(find.text('Extra-Large Touch Targets'), findsOneWidget);
    });
  });
}
