# --- ML Kit & Google Play Services ---
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# --- Ignorar advertencias de lenguajes secundarios/opcionales ---
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# --- Reglas generales de compilación ---
-ignorewarnings
-keepattributes *Annotation*
-keepattributes Signature
-keep class io.flutter.** { *; }