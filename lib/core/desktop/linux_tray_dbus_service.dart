// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/legacy.dart';
import 'desktop_tray_service_io.dart';

/// Linux D-Bus StatusNotifierItem & DBusMenu Native Implementation.
/// Mengimplementasikan spesifikasi FreeDesktop / KDE `org.kde.StatusNotifierItem`
/// dan `com.canonical.dbusmenu` secara langsung menggunakan `package:dbus`.
///
/// Solusi ini 100% native, tidak bergantung pada FFI C++ yang tidak lengkap,
/// serta terbukti kompatibel dengan GNOME Shell (AppIndicator extension),
/// KDE Plasma, Waybar, Polybar, dan XFCE.
class LinuxTrayDbusService {
  static LinuxTrayDbusService? _instance;
  static LinuxTrayDbusService get instance => _instance ??= LinuxTrayDbusService._();

  LinuxTrayDbusService._();

  DBusClient? _client;
  _StatusNotifierItemObject? _sniObject;
  _DBusMenuObject? _menuObject;
  _DBusMenuObject? _menuBarObject;
  DesktopTrayService? _trayService;
  DesktopTrayService get trayService => _trayService ?? DesktopTrayService.instance;
  set trayService(DesktopTrayService? service) => _trayService = service;
  bool _isInitialized = false;
  String _serviceName = '';

  bool get isInitialized => _isInitialized;

  /// Inisialisasi service D-Bus StatusNotifierItem & DBusMenu
  Future<void> init({required DesktopTrayService trayService}) async {
    if (kIsWeb || !Platform.isLinux) return;
    if (_isInitialized) return;

    _trayService = trayService;

    try {
      _client = DBusClient.session();
      _serviceName = 'org.kde.StatusNotifierItem-$pid-1';

      _sniObject = _StatusNotifierItemObject(this);
      _menuObject = _DBusMenuObject(this, DBusObjectPath('/StatusNotifierItem/Menu'));
      _menuBarObject = _DBusMenuObject(this, DBusObjectPath('/MenuBar'));

      await _client!.registerObject(_sniObject!);
      await _client!.registerObject(_menuObject!);
      await _client!.registerObject(_menuBarObject!);

      final requestResult = await _client!.requestName(
        _serviceName,
        flags: {
          DBusRequestNameFlag.replaceExisting,
          DBusRequestNameFlag.doNotQueue,
        },
      );

      debugPrint('[LinuxTrayDbus] Requested D-Bus Name $_serviceName: $requestResult');

      // Muat icon pixmap dari asset
      await _loadIconPixmap();

      // Daftarkan ke StatusNotifierWatcher (KDE dan Canonical)
      await _registerWithWatcher();

      _isInitialized = true;
      debugPrint('[LinuxTrayDbus] Initialized successfully as $_serviceName');
    } catch (e, stack) {
      debugPrint('[LinuxTrayDbus] Init error: $e\n$stack');
    }
  }

  /// Memuat icon dari asset dan mengonversi ke format ARGB32 untuk DBus Pixmap
  Future<void> _loadIconPixmap() async {
    try {
      // Buat default 32x32 studio audiophile icon pixmap (ARGB32)
      const int size = 32;
      final bytes = Uint8List(size * size * 4);
      
      // Warna Studio Amber / Mint untuk icon tray
      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          final int offset = (y * size + x) * 4;
          final double dx = (x - size / 2.0) / (size / 2.0);
          final double dy = (y - size / 2.0) / (size / 2.0);
          final double dist = dx * dx + dy * dy;

          if (dist <= 0.85) {
            // Lingkaran luar (Amber studio tone)
            if (dist >= 0.65 || (x >= 12 && x <= 20 && y >= 8 && y <= 24)) {
              bytes[offset + 0] = 255; // Alpha
              bytes[offset + 1] = 245; // Red
              bytes[offset + 2] = 166; // Green
              bytes[offset + 3] = 35;  // Blue
            } else {
              // Background subtle dark
              bytes[offset + 0] = 230; // Alpha
              bytes[offset + 1] = 30;  // Red
              bytes[offset + 2] = 34;  // Green
              bytes[offset + 3] = 42;  // Blue
            }
          } else {
            // Transparan
            bytes[offset + 0] = 0;
            bytes[offset + 1] = 0;
            bytes[offset + 2] = 0;
            bytes[offset + 3] = 0;
          }
        }
      }

      _sniObject?.setIconPixmap(size, size, bytes);
    } catch (e) {
      debugPrint('[LinuxTrayDbus] Error generating icon pixmap: $e');
    }
  }

  /// Pendaftaran ke org.kde.StatusNotifierWatcher & com.canonical.StatusNotifierWatcher
  Future<void> _registerWithWatcher() async {
    if (_client == null || _serviceName.isEmpty) return;

    // 1. KDE StatusNotifierWatcher
    try {
      final kdeWatcher = DBusRemoteObject(
        _client!,
        name: 'org.kde.StatusNotifierWatcher',
        path: DBusObjectPath('/StatusNotifierWatcher'),
      );
      await kdeWatcher.callMethod(
        'org.kde.StatusNotifierWatcher',
        'RegisterStatusNotifierItem',
        [DBusString(_serviceName)],
      );
      debugPrint('[LinuxTrayDbus] Registered with org.kde.StatusNotifierWatcher');
    } catch (e) {
      debugPrint('[LinuxTrayDbus] KDE Watcher registration note: $e');
    }

    // 2. Canonical StatusNotifierWatcher
    try {
      final canonicalWatcher = DBusRemoteObject(
        _client!,
        name: 'com.canonical.StatusNotifierWatcher',
        path: DBusObjectPath('/StatusNotifierWatcher'),
      );
      await canonicalWatcher.callMethod(
        'com.canonical.StatusNotifierWatcher',
        'RegisterStatusNotifierItem',
        [DBusString(_serviceName)],
      );
      debugPrint('[LinuxTrayDbus] Registered with com.canonical.StatusNotifierWatcher');
    } catch (e) {
      debugPrint('[LinuxTrayDbus] Canonical Watcher registration note: $e');
    }
  }

  /// Perbarui list item context menu
  Future<void> updateMenu(List<MenuItem> items) async {
    if (!_isInitialized) return;
    _menuObject?.updateMenuItems(items);
    _menuBarObject?.updateMenuItems(items);
  }

  /// Perbarui tooltip StatusNotifierItem
  void updateTooltip({required String title, required String body}) {
    if (!_isInitialized || _sniObject == null) return;
    _sniObject!.updateTooltip(title, body);
  }

  // ─── Event Dispatching ke DesktopTrayService ─────────────────────────────

  void notifyIconActivated(int x, int y) {
    debugPrint('[LinuxTrayDbus] >>> TRAY ICON ACTIVATED (Left-Click at $x, $y) <<<');
    trayService.onTrayIconMouseDown();
  }

  void notifyIconSecondaryActivated(int x, int y) {
    debugPrint('[LinuxTrayDbus] >>> TRAY ICON SECONDARY ACTIVATED (Middle-Click at $x, $y) <<<');
    trayService.onPlayPause?.call();
  }

  void notifyContextMenuRequested(int x, int y) {
    debugPrint('[LinuxTrayDbus] >>> TRAY CONTEXT MENU REQUESTED (Right-Click at $x, $y) <<<');
    trayService.onTrayIconRightMouseDown();
  }

  void notifyIconScrolled(int delta, String orientation) {
    debugPrint('[LinuxTrayDbus] >>> TRAY ICON SCROLLED: delta=$delta, orientation=$orientation <<<');
    if (orientation == 'vertical' || orientation.isEmpty) {
      if (delta > 0) {
        // Scroll Up -> Next or Volume Up
        trayService.onNext?.call();
      } else {
        // Scroll Down -> Previous or Volume Down
        trayService.onPrevious?.call();
      }
    }
  }

  void notifyMenuItemClicked(MenuItem menuItem) {
    debugPrint('[LinuxTrayDbus] >>> TRAY MENU ITEM CLICKED: "${menuItem.label}" (key: ${menuItem.key}) <<<');
    trayService.onTrayMenuItemClick(menuItem);
  }

  /// Dispose D-Bus Client
  Future<void> dispose() async {
    if (!_isInitialized) return;
    try {
      if (_client != null) {
        await _client!.close();
      }
      _isInitialized = false;
      debugPrint('[LinuxTrayDbus] Disposed');
    } catch (e) {
      debugPrint('[LinuxTrayDbus] Error disposing: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Object: /StatusNotifierItem (`org.kde.StatusNotifierItem`)
// ─────────────────────────────────────────────────────────────────────────────

class _StatusNotifierItemObject extends DBusObject {
  final LinuxTrayDbusService _service;

  final String _title = 'Baydev HiFi';
  String _tooltipTitle = 'Baydev HiFi — Studio Audiophile Player';
  String _tooltipBody = 'Ready';
  DBusArray _iconPixmap = DBusArray(DBusSignature('(iiay)'), const []);

  _StatusNotifierItemObject(this._service)
      : super(DBusObjectPath('/StatusNotifierItem'));

  void setIconPixmap(int width, int height, Uint8List argbBytes) {
    _iconPixmap = DBusArray(DBusSignature('(iiay)'), [
      DBusStruct([
        DBusInt32(width),
        DBusInt32(height),
        DBusArray.byte(argbBytes),
      ]),
    ]);
    emitSignal('org.kde.StatusNotifierItem', 'NewIcon', const []);
  }

  void updateTooltip(String title, String body) {
    _tooltipTitle = title;
    _tooltipBody = body;
    emitSignal('org.kde.StatusNotifierItem', 'NewToolTip', const []);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'org.kde.StatusNotifierItem',
        methods: [
          DBusIntrospectMethod(
            'ContextMenu',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'x'),
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'y'),
            ],
          ),
          DBusIntrospectMethod(
            'Activate',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'x'),
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'y'),
            ],
          ),
          DBusIntrospectMethod(
            'SecondaryActivate',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'x'),
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'y'),
            ],
          ),
          DBusIntrospectMethod(
            'Scroll',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'delta'),
              DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'orientation'),
            ],
          ),
        ],
        signals: [
          DBusIntrospectSignal('NewTitle'),
          DBusIntrospectSignal('NewIcon'),
          DBusIntrospectSignal('NewAttentionIcon'),
          DBusIntrospectSignal('NewOverlayIcon'),
          DBusIntrospectSignal('NewToolTip'),
          DBusIntrospectSignal(
            'NewStatus',
            args: [
              DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.out, name: 'status'),
            ],
          ),
        ],
        properties: [
          DBusIntrospectProperty('Category', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Id', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Title', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Status', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('WindowId', DBusSignature('i'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('IconName', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('IconPixmap', DBusSignature('a(iiay)'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('OverlayIconName', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('OverlayIconPixmap', DBusSignature('a(iiay)'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('AttentionIconName', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('AttentionIconPixmap', DBusSignature('a(iiay)'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('AttentionMovieName', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('ToolTip', DBusSignature('(sa(iiay)ss)'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('ItemIsMenu', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Menu', DBusSignature('o'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('IconThemePath', DBusSignature('s'), access: DBusPropertyAccess.read),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.kde.StatusNotifierItem') {
      if (methodCall.name == 'Activate') {
        final x = methodCall.values.isNotEmpty ? (methodCall.values[0] as DBusInt32).value : 0;
        final y = methodCall.values.length > 1 ? (methodCall.values[1] as DBusInt32).value : 0;
        _service.notifyIconActivated(x, y);
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'SecondaryActivate') {
        final x = methodCall.values.isNotEmpty ? (methodCall.values[0] as DBusInt32).value : 0;
        final y = methodCall.values.length > 1 ? (methodCall.values[1] as DBusInt32).value : 0;
        _service.notifyIconSecondaryActivated(x, y);
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'ContextMenu') {
        final x = methodCall.values.isNotEmpty ? (methodCall.values[0] as DBusInt32).value : 0;
        final y = methodCall.values.length > 1 ? (methodCall.values[1] as DBusInt32).value : 0;
        _service.notifyContextMenuRequested(x, y);
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'Scroll') {
        final delta = methodCall.values.isNotEmpty ? (methodCall.values[0] as DBusInt32).value : 0;
        final orientation = methodCall.values.length > 1 ? (methodCall.values[1] as DBusString).value : '';
        _service.notifyIconScrolled(delta, orientation);
        return DBusMethodSuccessResponse();
      }
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.kde.StatusNotifierItem') {
      switch (name) {
        case 'Category':
          return DBusMethodSuccessResponse([const DBusString('ApplicationStatus')]);
        case 'Id':
          return DBusMethodSuccessResponse([const DBusString('baydev_hifi')]);
        case 'Title':
          return DBusMethodSuccessResponse([DBusString(_title)]);
        case 'Status':
          return DBusMethodSuccessResponse([const DBusString('Active')]);
        case 'WindowId':
          return DBusMethodSuccessResponse([const DBusInt32(0)]);
        case 'IconName':
          return DBusMethodSuccessResponse([const DBusString('multimedia-player')]);
        case 'IconPixmap':
          return DBusMethodSuccessResponse([_iconPixmap]);
        case 'OverlayIconName':
        case 'AttentionIconName':
        case 'AttentionMovieName':
        case 'IconThemePath':
          return DBusMethodSuccessResponse([const DBusString('')]);
        case 'OverlayIconPixmap':
        case 'AttentionIconPixmap':
          return DBusMethodSuccessResponse([
            DBusArray(DBusSignature('(iiay)'), const []),
          ]);
        case 'ToolTip':
          return DBusMethodSuccessResponse([
            DBusStruct([
              const DBusString('multimedia-player'),
              DBusArray(DBusSignature('(iiay)'), const []),
              DBusString(_tooltipTitle),
              DBusString(_tooltipBody),
            ]),
          ]);
        case 'ItemIsMenu':
          return DBusMethodSuccessResponse([const DBusBoolean(false)]);
        case 'Menu':
          return DBusMethodSuccessResponse([DBusObjectPath('/StatusNotifierItem/Menu')]);
      }
    }
    return DBusMethodErrorResponse.unknownProperty();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Object: /StatusNotifierItem/Menu & /MenuBar (`com.canonical.dbusmenu`)
// ─────────────────────────────────────────────────────────────────────────────

class _DBusMenuObject extends DBusObject {
  final LinuxTrayDbusService _service;
  final Map<int, MenuItem> _itemsById = {};
  int _menuRevision = 1;

  _DBusMenuObject(this._service, DBusObjectPath path) : super(path);

  void updateMenuItems(List<MenuItem> items) {
    _itemsById.clear();
    int idCounter = 1;

    for (final item in items) {
      final id = idCounter++;
      item.id = id;
      _itemsById[id] = item;
    }

    _menuRevision++;
    emitSignal(
      'com.canonical.dbusmenu',
      'LayoutUpdated',
      [
        DBusUint32(_menuRevision),
        const DBusInt32(0),
      ],
    );
    debugPrint('[LinuxTrayDbus] DBusMenu LayoutUpdated (revision: $_menuRevision, ${_itemsById.length} items)');
  }

  DBusValue _buildRootLayoutVariant() {
    final children = <DBusValue>[];

    for (final entry in _itemsById.entries) {
      final id = entry.key;
      final item = entry.value;

      final Map<DBusValue, DBusValue> props = {};

      if (item.type == 'separator') {
        props[const DBusString('type')] = const DBusVariant(DBusString('separator'));
        props[const DBusString('visible')] = const DBusVariant(DBusBoolean(true));
      } else {
        props[const DBusString('label')] = DBusVariant(DBusString(item.label ?? ''));
        props[const DBusString('enabled')] = DBusVariant(DBusBoolean(!item.disabled));
        props[const DBusString('visible')] = const DBusVariant(DBusBoolean(true));

        if (item.type == 'checkbox') {
          props[const DBusString('toggle-type')] = const DBusVariant(DBusString('checkmark'));
          props[const DBusString('toggle-state')] = DBusVariant(DBusInt32(item.checked == true ? 1 : 0));
        }
      }

      children.add(
        DBusVariant(
          DBusStruct([
            DBusInt32(id),
            DBusDict(DBusSignature('s'), DBusSignature('v'), props),
            DBusArray(DBusSignature('v'), const []),
          ]),
        ),
      );
    }

    final rootProps = <DBusValue, DBusValue>{
      const DBusString('children-display'): const DBusVariant(DBusString('submenu')),
    };

    return DBusStruct([
      const DBusInt32(0),
      DBusDict(DBusSignature('s'), DBusSignature('v'), rootProps),
      DBusArray(DBusSignature('v'), children),
    ]);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'com.canonical.dbusmenu',
        methods: [
          DBusIntrospectMethod(
            'GetLayout',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'parentId'),
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'recursionDepth'),
              DBusIntrospectArgument(DBusSignature('as'), DBusArgumentDirection.in_, name: 'propertyNames'),
              DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.out, name: 'revision'),
              DBusIntrospectArgument(DBusSignature('(ia{sv}av)'), DBusArgumentDirection.out, name: 'layout'),
            ],
          ),
          DBusIntrospectMethod(
            'GetGroupProperties',
            args: [
              DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.in_, name: 'ids'),
              DBusIntrospectArgument(DBusSignature('as'), DBusArgumentDirection.in_, name: 'propertyNames'),
              DBusIntrospectArgument(DBusSignature('a(ia{sv})'), DBusArgumentDirection.out, name: 'properties'),
            ],
          ),
          DBusIntrospectMethod(
            'GetProperty',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'id'),
              DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'name'),
              DBusIntrospectArgument(DBusSignature('v'), DBusArgumentDirection.out, name: 'value'),
            ],
          ),
          DBusIntrospectMethod(
            'Event',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'id'),
              DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'eventId'),
              DBusIntrospectArgument(DBusSignature('v'), DBusArgumentDirection.in_, name: 'data'),
              DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.in_, name: 'timestamp'),
            ],
          ),
          DBusIntrospectMethod(
            'EventGroup',
            args: [
              DBusIntrospectArgument(DBusSignature('a(isvu)'), DBusArgumentDirection.in_, name: 'events'),
              DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.out, name: 'idErrors'),
            ],
          ),
          DBusIntrospectMethod(
            'AboutToShow',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.in_, name: 'id'),
              DBusIntrospectArgument(DBusSignature('b'), DBusArgumentDirection.out, name: 'needUpdate'),
            ],
          ),
          DBusIntrospectMethod(
            'AboutToShowGroup',
            args: [
              DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.in_, name: 'ids'),
              DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.out, name: 'updatesNeeded'),
              DBusIntrospectArgument(DBusSignature('ai'), DBusArgumentDirection.out, name: 'idErrors'),
            ],
          ),
        ],
        signals: [
          DBusIntrospectSignal(
            'ItemsPropertiesUpdated',
            args: [
              DBusIntrospectArgument(DBusSignature('a(ia{sv})'), DBusArgumentDirection.out, name: 'updatedProps'),
              DBusIntrospectArgument(DBusSignature('a(ias)'), DBusArgumentDirection.out, name: 'removedProps'),
            ],
          ),
          DBusIntrospectSignal(
            'LayoutUpdated',
            args: [
              DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.out, name: 'revision'),
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.out, name: 'parent'),
            ],
          ),
          DBusIntrospectSignal(
            'ItemActivationRequested',
            args: [
              DBusIntrospectArgument(DBusSignature('i'), DBusArgumentDirection.out, name: 'id'),
              DBusIntrospectArgument(DBusSignature('u'), DBusArgumentDirection.out, name: 'timestamp'),
            ],
          ),
        ],
        properties: [
          DBusIntrospectProperty('Version', DBusSignature('u'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('TextDirection', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Status', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('IconThemePath', DBusSignature('as'), access: DBusPropertyAccess.read),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'com.canonical.dbusmenu') {
      if (methodCall.name == 'GetLayout') {
        return DBusMethodSuccessResponse([
          DBusUint32(_menuRevision),
          _buildRootLayoutVariant(),
        ]);
      } else if (methodCall.name == 'GetGroupProperties') {
        final List<DBusValue> propsList = [];
        if (methodCall.values.isNotEmpty && methodCall.values[0] is DBusArray) {
          final idArray = methodCall.values[0] as DBusArray;
          for (final idVal in idArray.children) {
            if (idVal is DBusInt32) {
              final item = _itemsById[idVal.value];
              if (item != null) {
                final Map<DBusValue, DBusValue> map = {};
                map[const DBusString('label')] = DBusVariant(DBusString(item.label ?? ''));
                map[const DBusString('enabled')] = DBusVariant(DBusBoolean(!item.disabled));
                map[const DBusString('visible')] = const DBusVariant(DBusBoolean(true));
                propsList.add(
                  DBusStruct([
                    idVal,
                    DBusDict(DBusSignature('s'), DBusSignature('v'), map),
                  ]),
                );
              }
            }
          }
        }
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('(ia{sv})'), propsList),
        ]);
      } else if (methodCall.name == 'GetProperty') {
        final id = (methodCall.values[0] as DBusInt32).value;
        final name = (methodCall.values[1] as DBusString).value;
        final item = _itemsById[id];
        if (item != null) {
          if (name == 'label') return DBusMethodSuccessResponse([DBusVariant(DBusString(item.label ?? ''))]);
          if (name == 'enabled') return DBusMethodSuccessResponse([DBusVariant(DBusBoolean(!item.disabled))]);
          if (name == 'visible') return DBusMethodSuccessResponse([const DBusVariant(DBusBoolean(true))]);
        }
        return DBusMethodSuccessResponse([const DBusVariant(DBusString(''))]);
      } else if (methodCall.name == 'Event') {
        final id = (methodCall.values[0] as DBusInt32).value;
        final eventId = (methodCall.values[1] as DBusString).value;
        debugPrint('[LinuxTrayDbus] Event received: id=$id, eventId=$eventId');

        if (eventId == 'clicked' || eventId == 'activated') {
          final item = _itemsById[id];
          if (item != null) {
            _service.notifyMenuItemClicked(item);
          } else {
            debugPrint('[LinuxTrayDbus] Clicked item id=$id not found in menu');
          }
        }
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'EventGroup') {
        if (methodCall.values.isNotEmpty && methodCall.values[0] is DBusArray) {
          final eventsArray = methodCall.values[0] as DBusArray;
          for (final ev in eventsArray.children) {
            if (ev is DBusStruct && ev.children.length >= 2) {
              final id = (ev.children[0] as DBusInt32).value;
              final eventId = (ev.children[1] as DBusString).value;
              if (eventId == 'clicked' || eventId == 'activated') {
                final item = _itemsById[id];
                if (item != null) {
                  _service.notifyMenuItemClicked(item);
                }
              }
            }
          }
        }
        return DBusMethodSuccessResponse([DBusArray.int32(const [])]);
      } else if (methodCall.name == 'AboutToShow') {
        return DBusMethodSuccessResponse([const DBusBoolean(false)]);
      } else if (methodCall.name == 'AboutToShowGroup') {
        return DBusMethodSuccessResponse([
          DBusArray.int32(const []),
          DBusArray.int32(const []),
        ]);
      }
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'com.canonical.dbusmenu') {
      switch (name) {
        case 'Version':
          return DBusMethodSuccessResponse([const DBusUint32(3)]);
        case 'TextDirection':
          return DBusMethodSuccessResponse([const DBusString('ltr')]);
        case 'Status':
          return DBusMethodSuccessResponse([const DBusString('normal')]);
        case 'IconThemePath':
          return DBusMethodSuccessResponse([DBusArray.string(const [])]);
      }
    }
    return DBusMethodErrorResponse.unknownProperty();
  }
}
