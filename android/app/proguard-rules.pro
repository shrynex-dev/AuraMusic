# Optimization flags
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep NewPipe classes
-keep class org.mozilla.javascript.** { *; }
-keep class org.schabi.newpipe.** { *; }

# Suppress warnings
-dontwarn java.beans.**
-dontwarn javax.script.**
-dontwarn jdk.dynalink.**
-dontwarn org.mozilla.javascript.**

# Keep Hive classes
-keep class * extends hive.HiveObjectAdapter
-keepclassmembers class * extends hive.HiveObject {
    <fields>;
}

# Keep audio service
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
