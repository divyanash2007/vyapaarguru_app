# Keep rules for Flutter release builds

# Keep Kotlin metadata
-keepattributes *Annotation*

# Prevent R8 from stripping Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (deferred components) — referenced by Flutter engine
# but not always included. Tell R8 to ignore missing classes.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
