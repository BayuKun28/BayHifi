# ProGuard / R8 rules for Baydev HiFi Release Build

# AudioService Keep Rules
-keep class com.ryanheise.audioservice.** { *; }
-keep interface com.ryanheise.audioservice.** { *; }

# AndroidX Media & MediaSession Compat
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.MediaBrowserServiceCompat { *; }
-keep class androidx.media.session.MediaButtonReceiver { *; }

# Flutter Plugin Registrant & Engine Reflection
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# SoLoud Native bindings & FFI
-keep class com.flutter.soloud.** { *; }
