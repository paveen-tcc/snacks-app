# Protect Microsoft Authentication Library (MSAL) classes
-keep class com.microsoft.identity.** { *; }
-keep interface com.microsoft.identity.** { *; }

# Protect Flutter plugins
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }

# Keep MSAL Browser classes
-keep class com.microsoft.identity.client.** { *; }